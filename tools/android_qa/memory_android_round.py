#!/usr/bin/env python3
"""Complete a real Memory round using only observed Android UI and real touches.

Start with Memory already open. No private app state, seed, save/prefs or source
data is read. The solver remembers only symbols that the accessibility hierarchy
actually exposed after real taps (including visible opponent turns). Every dump
and touch is saved. It fails rather than declaring a partial round successful.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import time
import xml.etree.ElementTree as ET

from android_ui import Android


CARD = re.compile(r"Memory Karte (\d+),\s*([^\n]+)")
RESULT = re.compile(r"Du:\s*(\d+)\s*Paare\s+Lumo:\s*(\d+)\s*Paare")
EMPTY_LABEL_RETRIES = 8


@dataclass
class Card:
    number: int
    symbol: str | None
    node: ET.Element

    @property
    def is_matched(self):
        # The actual APK exposes button: !isMatched as Android's card role.
        # An open Button is still a temporary pick, not an earned pair.
        return self.symbol is not None and self.node.get('class') == 'android.view.View'


def labels(root):
    return [value for node in root.iter('node')
            for key in ('text', 'content-desc')
            if (value := node.attrib.get(key, '').strip())]


def has_caption(root, caption):
    """Match an entire visible text line within merged Flutter semantics.

    The shared pause Card combines its title and instruction on one node:
    "Spiel pausiert\nDein aktueller Zug wartet auf dich.". Keep original nodes
    and bounds for tapping; a substring within another caption never matches.
    """
    return any(caption == line.strip() for value in labels(root)
               for line in value.splitlines())


def cards(root):
    result = {}
    for node in root.iter('node'):
        for key in ('text', 'content-desc'):
            match = CARD.search(node.attrib.get(key, ''))
            if not match:
                continue
            number = int(match[1])
            # Child Text semantics may be merged on the next line. The explicit
            # card label ends at its newline and never exposes a hidden symbol.
            face = match[2].strip()
            result[number] = Card(number, None if face == 'verdeckt' else face, node)
    return result


def result_scores(root):
    match = RESULT.search(' '.join(labels(root)))
    return (int(match[1]), int(match[2])) if match else None


def scoreboard_scores(root):
    values = labels(root)
    scores = []
    for caption in ('Du', 'Lumo 🦊'):
        found = [int(values[i+1]) for i, value in enumerate(values[:-1])
                 if value == caption and re.fullmatch(r'\d+', values[i+1])]
        if len(found) != 1 or not 0 <= found[0] <= 12:
            raise RuntimeError('Actual visible Memory pair scores are missing or ambiguous.')
        scores.append(found[0])
    if sum(scores) > 12:
        raise RuntimeError('Actual visible Memory pair scores exceed twelve.')
    return tuple(scores)


def settled_child_board(root):
    """Describe a real child turn with no temporarily open, unpaired card.

    uiautomator can take seconds while the opponent continues playing. Its
    hierarchy may combine earlier card nodes with a later child-turn footer.
    The public role and a second identical observation keep that mixed dump
    from being used as the next turn. No timer or game state is changed.
    """
    visible = cards(root)
    if ('Du bist dran! Tipp 2 Karten.' not in labels(root) or not visible
            or any(card.symbol is not None and not card.is_matched
                   for card in visible.values())):
        return None
    return (scoreboard_scores(root), tuple(
        (number, card.symbol, card.node.get('class'), card.node.get('bounds'))
        for number, card in sorted(visible.items())))


class Round:
    def __init__(self, android, out, timeout):
        self.android = android
        self.out = out
        out.mkdir(parents=True, exist_ok=True)
        self.deadline = time.monotonic() + timeout
        self.sequence = 0
        self.memory = {}  # Only learned by reading real visible labels.
        self.matched = set()
        self.turns = 0
        self.latest_root = None

    def record(self, event, **values):
        record = {'time_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                  'event': event, **values}
        with (self.out / 'actions.jsonl').open('a') as stream:
            stream.write(json.dumps(record, ensure_ascii=False) + '\n')
        print(json.dumps(record, ensure_ascii=False), flush=True)

    def frame(self, name='board'):
        for attempt in range(EMPTY_LABEL_RETRIES + 1):
            if time.monotonic() >= self.deadline:
                raise RuntimeError('Real Memory round timed out; retained evidence is a partial test.')
            root = self.android.dump()
            self.latest_root = root
            self.sequence += 1
            path = self.out / f'{self.sequence:03d}-{name}.xml'
            ET.ElementTree(root).write(path, encoding='utf-8', xml_declaration=True)
            visible = cards(root)
            observations = {number: card.symbol for number, card in visible.items()
                            if card.symbol is not None}
            for number, symbol in observations.items():
                previous = self.memory.get(number)
                if previous is not None and previous != symbol:
                    raise RuntimeError(f'Card {number} changed symbol mid-round: {previous!r} / {symbol!r}.')
                self.memory[number] = symbol
                if visible[number].is_matched:
                    self.matched.add(number)
            current_labels = labels(root)
            self.record('observed_ui', xml=str(path), visible_cards=sorted(visible),
                        visible_symbols=observations, labels=current_labels)
            if current_labels or attempt == EMPTY_LABEL_RETRIES:
                return root
            self.record('await_visible_android_content', retry=attempt + 1)
            time.sleep(.4)

    def screenshot(self, name):
        path = self.out / f'{self.sequence:03d}-{name}.png'
        data = self.android.adb('exec-out', 'screencap', '-p', binary=True)
        if not data.startswith(b'\x89PNG\r\n\x1a\n'):
            raise RuntimeError('Invalid Android screenshot.')
        path.write_bytes(data)
        self.record('screenshot', path=str(path))

    def tap_node(self, node, reason):
        left, top, right, bottom = self.android.bounds(node)
        if self.latest_root is not None:
            visible = []
            for candidate in self.latest_root.iter('node'):
                try:
                    visible.append(self.android.bounds(candidate))
                except RuntimeError:
                    pass
            if visible:
                right = min(right, max(b[2] for b in visible))
                bottom = min(bottom, max(b[3] for b in visible))
                left, top = max(0, left), max(0, top)
        if right <= left or bottom <= top:
            raise RuntimeError('The observed control has no actual visible touch area.')
        x, y = (left + right) // 2, (top + bottom) // 2
        self.record('real_touch', x=x, y=y, reason=reason,
                    label=node.attrib.get('text') or node.attrib.get('content-desc'),
                    bounds=[left, top, right, bottom])
        self.android.tap(x, y)

    def tap_label(self, root, label):
        nodes = [node for node in root.iter('node')
                 if label in (node.attrib.get('text'), node.attrib.get('content-desc'))
                 and node.attrib.get('enabled', 'true') == 'true']
        if len(nodes) != 1:
            raise RuntimeError(f'Expected one actual visible {label!r}, found {len(nodes)}.')
        self.tap_node(nodes[0], label)

    def visible_card(self, root, number):
        for _ in range(5):
            visible = cards(root)
            if number in visible:
                # Semantics includes only laid-out cards; ignore zero-size nodes.
                self.android.bounds(visible[number].node)
                return root, visible[number]
            if not visible:
                raise RuntimeError('Memory card grid is absent; refusing an unanchored swipe.')
            bounds = [self.android.bounds(card.node) for card in visible.values()]
            left, top = min(b[0] for b in bounds), min(b[1] for b in bounds)
            right, bottom = max(b[2] for b in bounds), max(b[3] for b in bounds)
            x = (left + right) // 2
            high, low = top + (bottom-top)//5, bottom - (bottom-top)//5
            down = number < min(visible)
            self.record('real_grid_scroll', target_card=number, x=x,
                        from_y=high if down else low, to_y=low if down else high)
            self.android.swipe(x, high if down else low, x, low if down else high, 500)
            time.sleep(.3)
            root = self.frame('scrolled-grid')
        raise RuntimeError(f'Card {number} could not be reached through real scrolling.')

    def ready(self):
        previous = None
        while True:
            root = self.frame()
            if result_scores(root) is not None:
                return root
            if has_caption(root, 'Spiel pausiert'):
                raise RuntimeError('Unexpected paused game; do not silently resume someone else\'s test.')
            current = settled_child_board(root)
            if current is not None and current == previous:
                self.matched.update(number for number, card in cards(root).items()
                                    if card.is_matched)
                return root
            previous = current
            time.sleep(.3)

    def pick(self, root, excluded=()):
        available = [number for number in range(1, 25)
                     if number not in self.matched and number not in excluded]
        for number in sorted(available, key=lambda n: (n in self.memory, n)):
            root, card = self.visible_card(root, number)
            if card.symbol is not None:
                if not card.is_matched:
                    raise RuntimeError('An unpaired Memory pick is already open; refusing to misclassify it.')
                self.matched.add(number)
                continue
            return root, card
        raise RuntimeError('No covered card remains, but no 12-pair result appeared.')

    def verify_grid_extremes(self, root):
        # Before either player moves, reach the actual last card and return
        # through the visible grid. This is real scrolling, not a board read.
        for number, name in ((24, 'fresh-bottom-row'), (1, 'fresh-return-to-first-row')):
            root, card = self.visible_card(root, number)
            if (card.symbol is not None or card.node.get('class') != 'android.widget.Button'
                    or card.node.get('clickable') != 'true'
                    or card.node.get('enabled', 'true') != 'true'
                    or any(other.symbol is not None for other in cards(root).values())):
                raise RuntimeError('Actual grid reachability check must retain a fresh, covered board.')
            parents = {child: parent for parent in root.iter() for child in parent}
            scroller = parents.get(card.node)
            while scroller is not None and scroller.get('scrollable') != 'true':
                scroller = parents.get(scroller)
            if scroller is None or scroller.get('enabled', 'true') != 'true':
                raise RuntimeError('Actual Memory card is not inside a visible enabled grid scroller.')
            left, top, right, bottom = self.android.bounds(card.node)
            grid_left, grid_top, grid_right, grid_bottom = self.android.bounds(scroller)
            if abs((right-left)-(bottom-top)) > 2:
                raise RuntimeError('Actual square Memory card is clipped; full extreme card must be visible.')
            if not (grid_left <= left < right <= grid_right
                    and grid_top <= top < bottom <= grid_bottom):
                raise RuntimeError('Actual extreme Memory card bounds extend outside the grid viewport.')
            self.screenshot(name)
            self.record('fresh_memory_grid_extreme_reachable', card=number,
                        bounds=[left, top, right, bottom],
                        grid_bounds=[grid_left, grid_top, grid_right, grid_bottom],
                        visible_cards=sorted(cards(root)), covered=True)
        return root

    def play(self):
        first = self.frame('initial-memory')
        if not cards(first):
            raise RuntimeError('Start this helper with Memory already open.')
        if any(card.symbol is not None for card in cards(first).values()):
            raise RuntimeError('Start with a fresh covered board, so no in-progress first pick is misclassified.')
        self.screenshot('initial-memory')
        self.verify_grid_extremes(first)
        while True:
            root = self.ready()
            scores = result_scores(root)
            if scores is not None:
                if sum(scores) != 12:
                    raise RuntimeError(f'Result has {sum(scores)} pairs, expected all twelve: {scores}.')
                self.record('complete_round_verified', child_pairs=scores[0], lumo_pairs=scores[1],
                            total_pairs=sum(scores), real_player_turns=self.turns,
                            observed_symbols=len(self.memory))
                self.screenshot('all-twelve-pairs-result')
                return root
            self.turns += 1
            # Prefer an actually remembered pair; otherwise reveal a new card.
            groups = {}
            for number, symbol in self.memory.items():
                if number not in self.matched:
                    groups.setdefault(symbol, []).append(number)
            pair = next((numbers[:2] for numbers in groups.values() if len(numbers) >= 2), None)
            if pair:
                root, first_card = self.visible_card(root, pair[0])
                if first_card.symbol is not None:
                    if not first_card.is_matched:
                        raise RuntimeError('An unpaired Memory pick appeared before the real first tap.')
                    self.matched.add(first_card.number)
                    continue
            else:
                root, first_card = self.pick(root)
            first_number = first_card.number
            before_scores = scoreboard_scores(root)
            self.tap_node(first_card.node, f'player turn {self.turns}, first card {first_number}')
            time.sleep(.2)
            changed_turn = False
            for _ in range(4):
                root = self.frame('first-card-revealed')
                if result_scores(root) is not None:
                    changed_turn = True
                    break
                card = cards(root).get(first_number)
                if (scoreboard_scores(root) != before_scores
                        or (card is not None and card.is_matched)):
                    self.record('first_touch_unconfirmed_board_changed', card=first_number,
                                scores_before=before_scores, scores_after=scoreboard_scores(root))
                    changed_turn = True
                    break
                if (card and card.symbol is not None
                        and card.node.get('class') == 'android.widget.Button'
                        and 'Du bist dran! Tipp 2 Karten.' in labels(root)):
                    first_symbol = card.symbol
                    break
                time.sleep(.5)
            else:
                raise RuntimeError('First real card tap was not observed as an exposed symbol.')
            if changed_turn:
                # Reobserve the actual turn; never substitute an opponent's
                # matched face for proof that this first touch was accepted.
                continue
            mates = [number for number, symbol in self.memory.items()
                     if number != first_number and number not in self.matched and symbol == first_symbol]
            second_card = None
            for number in mates:
                root, candidate = self.visible_card(root, number)
                if candidate.symbol is None:
                    second_card = candidate
                    break
                if not candidate.is_matched:
                    raise RuntimeError('Another unpaired Memory pick appeared during the child turn.')
                self.matched.add(number)
            if second_card is None:
                root, second_card = self.pick(root, excluded=[first_number])
            self.tap_node(second_card.node,
                          f'player turn {self.turns}, second card {second_card.number}; '
                          + ('observed matching symbol' if mates else 'discover another covered card'))
            # The first pick stays visible indefinitely; the second is a real
            # 850ms animation. Reading a later dump may miss that symbol, and
            # the solver never fills such missing information from app state.
            time.sleep(1.2)

    def after_result(self, root, package, background=False):
        self.tap_label(root, 'Nochmal!')
        self.memory.clear()
        self.matched.clear()
        time.sleep(.5)
        root = self.frame('restart-covered-board')
        visible = cards(root)
        if not visible or any(card.symbol is not None for card in visible.values()):
            raise RuntimeError('Actual result restart did not return to a new covered board.')
        self.record('restart_verified', covered_visible_cards=len(visible), known_symbols=0)
        self.screenshot('restart-covered-board')
        before = {number: card.symbol for number, card in visible.items()}
        self.android.key('4', 'KEY_BACK')
        time.sleep(.5)
        root = self.frame('android-back-pause')
        if not has_caption(root, 'Spiel pausiert'):
            raise RuntimeError('Real Android Back did not open Memory pause.')
        self.screenshot('android-back-pause')
        self.tap_label(root, 'Fortsetzen')
        time.sleep(.5)
        root = self.frame('resumed-memory')
        if has_caption(root, 'Spiel pausiert') or 'Du bist dran! Tipp 2 Karten.' not in labels(root):
            raise RuntimeError('Actual Fortsetzen did not resume Memory.')
        if before != {number: card.symbol for number, card in cards(root).items()}:
            raise RuntimeError('Board changed during explicit pause/resume.')
        self.record('android_back_resume_verified')
        if background:
            self.android.key('3', 'KEY_HOMEPAGE')
            time.sleep(1)
            self.android.foreground(package)
            time.sleep(1)
            root = self.frame('foreground-lifecycle-pause')
            if not has_caption(root, 'Spiel pausiert'):
                raise RuntimeError('Home/foreground did not retain a paused Memory round.')
            self.screenshot('foreground-lifecycle-pause')
            self.tap_label(root, 'Fortsetzen')
            time.sleep(.5)
            root = self.frame('lifecycle-resumed')
            if before != {number: card.symbol for number, card in cards(root).items()}:
                raise RuntimeError('Board changed after real background/foreground.')
            self.record('background_resume_verified')
        self.android.key('4', 'KEY_BACK')
        time.sleep(.5)
        root = self.frame('return-pause')
        self.tap_label(root, 'Zur Spieleauswahl')
        time.sleep(.8)
        root = self.frame('returned-games-selection')
        if cards(root) or not any('Lumo Spielewelt' in label for label in labels(root)):
            raise RuntimeError('Actual return button did not reach the Flutter games selection.')
        self.screenshot('returned-games-selection')
        self.record('return_to_games_verified')


def self_test():
    root = ET.fromstring('<hierarchy><node content-desc="Memory Karte 1, verdeckt&#10;?" '
                         'bounds="[0,0][10,10]"/><node content-desc="Memory Karte 2, 🦊&#10;🦊" '
                         'bounds="[10,0][20,10]"/><node content-desc="Du: 7 Paare    Lumo: 5 Paare"/>'
                         '</hierarchy>')
    assert cards(root)[1].symbol is None
    assert cards(root)[2].symbol == '🦊'
    assert result_scores(root) == (7, 5)
    assert result_scores(ET.fromstring('<hierarchy/>')) is None
    print('Parser self-test passed; no Android calls made.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', default='emulator-5554')
    parser.add_argument('--package', default='dev.ullmann.lumo.lumo_lernen.neu')
    parser.add_argument('--out', type=Path, default=Path(os.environ.get('LUMO_QA_DIR', 'android-qa-evidence'))/'memory-round')
    parser.add_argument('--timeout', type=int, default=1500)
    parser.add_argument('--fast-input', action='store_true')
    parser.add_argument('--background', action='store_true', help='Also verify real Home/foreground pause.')
    parser.add_argument('--result-only', action='store_true', help='Stop at the full result, without restart/return.')
    parser.add_argument('--self-test', action='store_true', help='Parser only; never connects to Android.')
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    round_ = Round(Android(args.serial, fast_input=args.fast_input), args.out, args.timeout)
    try:
        result = round_.play()
        if not args.result_only:
            round_.after_result(result, args.package, background=args.background)
        round_.record('test_finished', result_verified=True,
                      restart_pause_return_verified=not args.result_only,
                      background_verified=args.background and not args.result_only)
    except Exception as error:
        round_.record('test_failed', error=str(error), result='partial evidence only')
        raise


if __name__ == '__main__':
    main()
