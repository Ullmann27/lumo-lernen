#!/usr/bin/env python3
"""Real Cards touches driven only by the APK's visible Android semantics.

Start with Lumo Cards open. Requires the card accessibility labels introduced
in commit 68b8e1e. Never reads private hands, the draw deck, seeds or preferences.
Without --allow-unverified-answer it stops at an unsupported learning prompt.
Such an answer is explicitly unverified and never counts as a correct learning
test. The full result screen, restart and back/return are checked separately.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import time

from android_ui import Android
from memory_android_round import Round, has_caption, labels


def described_cards(root):
    return [node for node in root.iter('node')
            if node.attrib.get('content-desc', '').startswith('Lumo Karte, ')]


def is_result(root):
    values = labels(root)
    return 'Nochmal' in values and 'Zurueck' in values and any('gewinnt' in s for s in values)


def picker_color_button(root, color):
    """Find one enabled picker action, keeping its actual touch bounds.

    The game table remains below the color overlay in Flutter's semantics.
    A matching noninteractive color caption is not a picker button. Text may
    live on a child of the clickable node, so resolve the nearest actionable
    ancestor without inventing coordinates or choosing an ambiguous index.
    """
    colors = {'Rot', 'Gelb', 'Blau', 'Gruen'}
    if color not in colors:
        raise RuntimeError(f'Unknown actual picker color: {color!r}.')
    parents = {child: parent for parent in root.iter() for child in parent}

    def visible_enabled(node):
        while node is not None:
            if (node.get('enabled', 'true') != 'true'
                    or node.get('visible-to-user', 'true') != 'true'):
                return False
            node = parents.get(node)
        return True

    headings = [node for node in root.iter('node')
                if 'Waehle eine Farbe' in (node.get('text'), node.get('content-desc'))
                and visible_enabled(node)]
    if len(headings) != 1:
        raise RuntimeError(f'Expected one actual color picker heading, found {len(headings)}.')
    _, _, _, heading_bottom = Android.bounds(headings[0])
    targets = set()
    for label in root.iter('node'):
        if color not in (label.get('text'), label.get('content-desc')) or not visible_enabled(label):
            continue
        target = label
        while target is not None and target.get('clickable') != 'true':
            target = parents.get(target)
        if target is None or not visible_enabled(target):
            continue
        left, top, right, bottom = Android.bounds(target)
        if top < heading_bottom:
            continue
        text_left, text_top, text_right, text_bottom = Android.bounds(label)
        if not (left <= text_left < text_right <= right
                and top <= text_top < text_bottom <= bottom):
            continue
        # A shared clickable container for several colors is not a specific
        # color action, even if one descendant happens to have this caption.
        captions = {value for child in target.iter('node') for key in ('text', 'content-desc')
                    if (value := child.get(key)) in colors}
        if captions != {color}:
            continue
        targets.add(target)
    if len(targets) != 1:
        raise RuntimeError(f'Expected one actual enabled picker {color!r} button, found {len(targets)}.')
    return next(iter(targets))


def arithmetic(prompt):
    calculation = re.search(r'(\d+)\s*([+−\-×·x:÷])\s*(\d+)', prompt)
    if not calculation:
        return None
    a, operator, b = calculation.groups()
    a, b = int(a), int(b)
    if operator == '+':
        return str(a+b)
    if operator in ('−', '-'):
        return str(a-b)
    if operator in ('×', '·', 'x'):
        return str(a*b)
    return str(a//b) if b and a % b == 0 else None


class CardsRound(Round):
    def __init__(self, android, out, timeout, allow_unverified):
        super().__init__(android, out, timeout)
        self.allow_unverified = allow_unverified
        self.moves = 0
        self.verified_answers = 0
        self.unverified_answers = 0

    def learning_answer(self, root):
        heading = next(node for node in root.iter('node')
                       if 'Denkpause' in (node.attrib.get('text'), node.attrib.get('content-desc')))
        _, _, _, heading_bottom = self.android.bounds(heading)
        prompts = [node for node in root.iter('node')
                   if (text := node.attrib.get('text') or node.attrib.get('content-desc'))
                   and self.android.bounds(node)[1] >= heading_bottom
                   and ('?' in text or arithmetic(text) is not None)
                   and not text.startswith('Lumo Karte, ')]
        if len(prompts) != 1:
            raise RuntimeError('Cannot uniquely identify the actual learning prompt; retain partial evidence.')
        prompt_node = prompts[0]
        prompt = prompt_node.attrib.get('text') or prompt_node.attrib.get('content-desc')
        _, _, _, prompt_bottom = self.android.bounds(prompt_node)
        ignored = {'Ziehen', 'Avatar wechseln', 'Pausieren / Zurück', 'Audio-Einstellungen', 'LUMO! +1'}
        choices = [node for node in root.iter('node')
                   if node.attrib.get('clickable') == 'true'
                   and (text := node.attrib.get('text') or node.attrib.get('content-desc'))
                   and text not in ignored and not text.startswith('Lumo Karte, ')
                   and self.android.bounds(node)[1] >= prompt_bottom]
        if not 2 <= len(choices) <= 6:
            raise RuntimeError(f'Cannot safely identify the actual answer buttons ({len(choices)}).')
        expected = arithmetic(prompt)
        answer = (next((node for node in choices
                        if expected in (node.attrib.get('text'), node.attrib.get('content-desc'))), None)
                  if expected is not None else None)
        if answer is not None:
            self.verified_answers += 1
            self.record('visible_math_answer', prompt=prompt, expected=expected, verified=True)
        elif self.allow_unverified:
            answer = choices[0]
            self.unverified_answers += 1
            self.record('visible_unverified_answer', prompt=prompt,
                        chosen=answer.attrib.get('text') or answer.attrib.get('content-desc'),
                        verified=False, note='No correct-learning claim; real game flow only.')
        else:
            raise RuntimeError(f'Unsupported visible question: {prompt!r}; awaiting a real manual answer.')
        self.tap_node(answer, 'actual learning answer button')

    def play(self):
        idle = 0
        while True:
            root = self.frame('cards-game')
            values = labels(root)
            if is_result(root):
                self.screenshot('cards-complete-result')
                self.record('complete_cards_round_verified', moves=self.moves,
                            verified_math_answers=self.verified_answers,
                            unverified_learning_answers=self.unverified_answers,
                            result_labels=values)
                return root
            if has_caption(root, 'Spiel pausiert'):
                raise RuntimeError('Unexpected pause; no automatic takeover of another test.')
            if 'Waehle eine Farbe' in values:
                self.tap_node(picker_color_button(root, 'Rot'), 'actual clickable picker Rot button')
            elif 'Denkpause' in values:
                self.learning_answer(root)
            elif 'Ziehen' in values:
                visible = described_cards(root)
                playable = [node for node in visible
                            if node.attrib['content-desc'].endswith(', spielbar')]
                if not playable and len(visible) >= 2:
                    # Scroll the actual visible hand once before drawing. The
                    # action remains legal even when another playable card is
                    # beyond this viewport; no hidden cards are inspected.
                    hand = [node for node in visible
                            if node.attrib['content-desc'].endswith(', nicht spielbar')]
                    if len(hand) >= 2:
                        boxes = [self.android.bounds(node) for node in hand]
                        left = min(box[0] for box in boxes)
                        right = max(box[2] for box in boxes)
                        y = sum((box[1]+box[3])//2 for box in boxes)//len(boxes)
                        self.record('real_hand_scroll', x1=right-20, x2=left+20, y=y)
                        self.android.swipe(right-20, y, left+20, y, 450)
                        time.sleep(.3)
                        root = self.frame('cards-scrolled-hand')
                        playable = [node for node in described_cards(root)
                                    if node.attrib['content-desc'].endswith(', spielbar')]
                if playable:
                    self.tap_node(playable[0], 'visible playable card')
                else:
                    self.tap_label(root, 'Ziehen')
                self.moves += 1
                idle = 0
            else:
                idle += 1
                if idle > 18:
                    raise RuntimeError('No actual player action or result after 18 UI observations.')
            time.sleep(1)

    def after_result(self, root):
        self.tap_label(root, 'Nochmal')
        time.sleep(1)
        root = self.frame('cards-restarted')
        if is_result(root) or not described_cards(root) or 'Ziehen' not in labels(root):
            raise RuntimeError('Actual Cards restart did not show a new human turn.')
        self.record('cards_restart_verified', visible_card_labels=[
            node.attrib['content-desc'] for node in described_cards(root)])
        self.screenshot('cards-restarted')
        self.android.key('4', 'KEY_BACK')
        time.sleep(.5)
        root = self.frame('cards-back-pause')
        if not has_caption(root, 'Spiel pausiert'):
            raise RuntimeError('Actual Android Back did not pause Cards.')
        self.screenshot('cards-back-pause')
        self.tap_label(root, 'Fortsetzen')
        time.sleep(.5)
        root = self.frame('cards-resumed')
        if has_caption(root, 'Spiel pausiert') or 'Ziehen' not in labels(root):
            raise RuntimeError('Actual Cards Fortsetzen did not resume the human turn.')
        self.record('cards_back_resume_verified')
        self.android.key('4', 'KEY_BACK')
        time.sleep(.5)
        root = self.frame('cards-return-pause')
        self.tap_label(root, 'Zur Spieleauswahl')
        time.sleep(1)
        root = self.frame('cards-returned-games')
        if described_cards(root) or not any('Lumo Spielewelt' in value for value in labels(root)):
            raise RuntimeError('Actual Cards return did not reach the games selection.')
        self.screenshot('cards-returned-games')
        self.record('cards_return_verified')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', default='emulator-5554')
    parser.add_argument('--out', type=Path, default=Path(os.environ.get('LUMO_QA_DIR', 'android-qa-evidence'))/'cards-round')
    parser.add_argument('--timeout', type=int, default=1500)
    parser.add_argument('--fast-input', action='store_true')
    parser.add_argument('--allow-unverified-answer', action='store_true')
    parser.add_argument('--result-only', action='store_true')
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        assert arithmetic('Wie viel ist 7 + 4?') == '11'
        assert arithmetic('24 : 6 = ?') == '4'
        assert arithmetic('8 × 3 = ?') == '24'
        assert arithmetic('Was ist die Mehrzahl von Hund?') is None
        print('Visible arithmetic parser passed; no Android calls made.')
        return
    check = CardsRound(Android(args.serial, fast_input=args.fast_input),
                       args.out, args.timeout, args.allow_unverified_answer)
    try:
        root = check.play()
        if not args.result_only:
            check.after_result(root)
        check.record('cards_test_finished', result_verified=True,
                     restart_pause_return_verified=not args.result_only)
    except Exception as error:
        check.record('cards_test_failed', error=str(error), result='partial evidence only')
        raise


if __name__ == '__main__':
    main()
