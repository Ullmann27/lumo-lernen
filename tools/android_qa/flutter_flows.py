"""Real visible Flutter touches for the exact-APK Android check.

No database, preferences, engine hooks or deterministic test seeds are used.
Unsupported/missing UI is an error. Wallet verification compares visible home
stars, XP/level and daily completion before/after process restart.
"""
from __future__ import annotations

import json
import math
from pathlib import Path
import re
import time
import xml.etree.ElementTree as ET

from memory_android_round import Round as MemoryRound, labels
from cards_android_round import CardsRound, arithmetic
from android_ui import content_scroll_gesture

LEARNING_SELECTION_CAPTION = 'LUMO AKADEMIE'


def addition_prompt_from_labels(values):
    prompts = {value for value in visible_text_lines(values)
               if re.fullmatch(r'\d+\s*\+\s*\d+\s*=\s*\?', value)}
    if len(prompts) != 1:
        raise ValueError('The actual Plus-bis-10 task did not expose one unambiguous addition.')
    prompt = prompts.pop()
    operands = list(map(int, re.findall(r'\d+', prompt)))
    if len(operands) != 2 or min(operands) < 1 or sum(operands) > 10:
        raise ValueError('The visible addition does not belong to Plus bis 10.')
    return prompt


def apple_help_from_labels(values, prompt):
    hints = {value for value in visible_text_lines(values)
             if re.fullmatch(r'Zähle alle Äpfel zusammen: 🍎+ und 🍏+', value)}
    if len(hints) != 1:
        raise ValueError('The real module did not expose one local apple-count explanation.')
    hint = hints.pop()
    left, right = map(int, re.findall(r'\d+', prompt))
    if hint.count('🍎') != left or hint.count('🍏') != right:
        raise ValueError('Visible local apple help does not match the actual task operands.')
    return hint


def visible_text_lines(values):
    """Read lines from merged visible captions without changing UI nodes.

    Android combines neighbouring Flutter Text widgets into one content-desc.
    Keep original labels and bounds for finding/tapping controls and evidence;
    use this text-only view when interpreting profile and wallet fields.
    """
    return [line.strip() for value in values for line in value.splitlines() if line.strip()]


def profile_from_labels(values):
    lines = visible_text_lines(values)
    greetings = {line for line in lines if re.fullmatch(r'Hallo, .+!', line)}
    grades = {line for line in lines if re.fullmatch(r'Dein Lumo-Tag · [1-4]\. Klasse', line)}
    if len(greetings) != 1 or len(grades) != 1:
        raise ValueError('Actual visible home profile captions are missing or ambiguous.')
    return greetings | grades


def wallet_from_labels(values):
    """Only the concrete home-stat captions count; bare header digits do not."""
    values = visible_text_lines(values)
    # The real Android progress-bar value can be prepended to the merged
    # wallet caption, e.g. "0, 0 Sterne\nLevel 1\nHeute: ...". Accept
    # exactly that numeric prefix, then verify it against the daily progress.
    star_matches = [match for value in values
                    if (match := re.fullmatch(r'(?:(\d+), )?(\d+) Sterne', value))]
    stars = {int(match[2]) for match in star_matches}
    xp = {(int(match[1]), int(match[2])) for value in values
          if (match := re.fullmatch(r'(\d+) / 400 XP bis Level (\d+)', value))}
    daily = {(int(match[1]), int(match[2])) for value in values
             if (match := re.fullmatch(r'Heute: (\d+) von (\d+) Aufgaben', value))}
    if len(stars) != 1 or len(xp) != 1 or len(daily) != 1:
        raise ValueError('Visible home wallet/daily captions are missing or ambiguous.')
    xp_in_level, next_level = next(iter(xp))
    if not 0 <= xp_in_level < 400 or next_level < 2:
        raise ValueError('Invalid visible XP/level caption.')
    completed, goal = next(iter(daily))
    if goal < 1:
        raise ValueError('Invalid visible daily goal.')
    expected_progress = math.floor(min(completed / goal, 1)*100+.5)
    if any(match[1] is not None and int(match[1]) != expected_progress
           for match in star_matches):
        raise ValueError('Merged progress-bar value conflicts with visible daily progress.')
    return {'stars': next(iter(stars)), 'xp': (next_level-2)*400+xp_in_level,
            'level': next_level-1, 'daily_completed': completed, 'daily_goal': goal}


class FlutterChecks:
    def __init__(self, android, out, package):
        self.device = android
        self.out = out
        self.package = package
        self.frames = 0
        self.proof = {}
        self.profile_labels = set()

    def record(self, event, **values):
        record = {'time_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                  'event': event, **values}
        with (self.out/'flutter-actions.jsonl').open('a') as stream:
            stream.write(json.dumps(record, ensure_ascii=False)+'\n')
        print(json.dumps(record, ensure_ascii=False), flush=True)

    def frame(self, name):
        root = self.device.dump()
        self.frames += 1
        path = self.out/'screens'/f'flutter-{self.frames:03d}-{name}.xml'
        path.parent.mkdir(parents=True, exist_ok=True)
        ET.ElementTree(root).write(path, encoding='utf-8', xml_declaration=True)
        self.record('actual_flutter_ui', xml=str(path), labels=labels(root))
        return root

    def dimensions(self, root):
        boxes = []
        for node in root.iter('node'):
            try:
                boxes.append(self.device.bounds(node))
            except RuntimeError:
                pass
        if not boxes:
            raise RuntimeError('No actual display bounds in Android hierarchy.')
        return max(b[2] for b in boxes), max(b[3] for b in boxes)

    def targets(self, root, phrase, contains=False):
        parents = {child: parent for parent in root.iter() for child in parent}
        width, height = self.dimensions(root)
        targets = {}
        for node in root.iter('node'):
            values = (node.attrib.get('text', ''), node.attrib.get('content-desc', ''))
            if not any(phrase in value if contains else phrase == value for value in values):
                continue
            if node.attrib.get('enabled', 'true') != 'true':
                continue
            target = node
            while target in parents and target.attrib.get('clickable') != 'true':
                target = parents[target]
            # Captions must belong to an actual actionable widget, not the root.
            if target.attrib.get('clickable') != 'true':
                continue
            try:
                left, top, right, bottom = self.device.bounds(target)
            except RuntimeError:
                continue
            left, top, right, bottom = max(0, left), max(0, top), min(width, right), min(height, bottom)
            if right > left and bottom > top:
                targets[(left, top, right, bottom)] = target
        return sorted(targets, key=lambda b: (b[2]-b[0])*(b[3]-b[1]))

    def scroll(self, root, down=True):
        gesture = content_scroll_gesture(root)
        if gesture is None:
            self.record('no_visible_content_scroller')
            return False
        x, high, low = gesture['x'], gesture['high'], gesture['low']
        self.record('real_content_scroll', x=x, from_y=low if down else high,
                    to_y=high if down else low, bounds=gesture['bounds'])
        self.device.swipe(x, low if down else high, x, high if down else low, 350)
        time.sleep(.3)
        return True

    def top(self, timeout=45):
        # Navigator can expose an empty Semantics tree during its return
        # animation. It is not evidence that the retained page cannot scroll.
        # Wait for real content; never repeat Back or invent a swipe target.
        deadline = time.monotonic()+timeout
        gestures = 0
        while time.monotonic() < deadline:
            root = self.frame('scroll-to-top')
            if time.monotonic() >= deadline:
                break
            if not labels(root):
                self.record('await_visible_flutter_content')
                time.sleep(.4)
                continue
            if not self.scroll(root, down=False):
                return
            gestures += 1
            if gestures == 4:
                return
        raise RuntimeError('Flutter content did not become visible within the bounded top-scroll check.')

    # Each snapshot reconnects UiAutomation, which re-enables accessibility.
    # Flutter then rebuilds its Semantics tree asynchronously, so a snapshot
    # taken without an idle wait can briefly show only the empty FlutterView
    # (seen in run 37181279924 after a wrong Plus answer; app still in
    # front, no crash). Re-observe such frames without any input, bounded.
    EMPTY_FRAME_RETRIES = 8

    def labelled_frame(self, name):
        root = self.frame(name)
        for _ in range(self.EMPTY_FRAME_RETRIES):
            if labels(root):
                return root
            self.record('await_visible_flutter_content')
            time.sleep(.4)
            root = self.frame(name)
        return root

    def click(self, phrase, contains=False, scroll=False):
        for _ in range(12 if scroll else 1):
            root = self.labelled_frame('find-control')
            targets = self.targets(root, phrase, contains)
            if targets:
                left, top, right, bottom = targets[0]
                self.record('real_flutter_touch', caption=phrase,
                            bounds=[left, top, right, bottom])
                self.device.tap((left+right)//2, (top+bottom)//2)
                time.sleep(.5)
                return
            if scroll:
                if not self.scroll(root):
                    break
        raise RuntimeError(f'Actual visible actionable Flutter control absent: {phrase!r}')

    def wait(self, caption, timeout=45, scroll=False):
        deadline = time.monotonic()+timeout
        while time.monotonic() < deadline:
            root = self.frame('wait-caption')
            if any(caption in value for value in labels(root)):
                return root
            if scroll:
                self.scroll(root)
            else:
                time.sleep(.4)
        raise RuntimeError(f'Actual visible Flutter caption absent: {caption!r}')

    def home(self):
        self.click('Start')
        self.top()
        root = self.wait('Hallo,')
        try:
            profile = profile_from_labels(labels(root))
        except ValueError as error:
            raise RuntimeError(str(error)) from error
        if self.profile_labels and self.profile_labels != profile:
            raise RuntimeError(f'Visible profile changed: {self.profile_labels} / {profile}')
        self.profile_labels = profile

    def wallet(self, name):
        self.home()
        for _ in range(9):
            root = self.frame(name)
            try:
                value = wallet_from_labels(labels(root))
            except ValueError:
                self.scroll(root)
                continue
            self.device.capture(name)
            self.record('observed_visible_wallet', name=name, wallet=value,
                        profile=sorted(self.profile_labels))
            return value
        raise RuntimeError('Could not read complete actual visible home wallet/daily progress.')

    def learning(self):
        before = self.wallet('wallet-before-learning')
        self.top()
        self.click('Lernen', scroll=True)
        self.wait(LEARNING_SELECTION_CAPTION)
        # AppShell opens the actual Akademie. Its first-grade Plus topic is
        # a real Navigator exercise module, not the unused subject-selection
        # screen or the generic LearningContent route.
        self.click('1. Klasse', contains=True, scroll=True)
        self.click('Plus bis 10', contains=True, scroll=True)
        self.wait('Aufgabe 1 / 30')
        root = self.frame('actual-plus-module-prompt')
        prompt = addition_prompt_from_labels(labels(root))
        expected = arithmetic(prompt)
        if expected is None:
            raise RuntimeError('The actual visible addition cannot be evaluated.')
        answers = {value for value in visible_text_lines(labels(root))
                   if re.fullmatch(r'\d+', value) and self.targets(root, value)
                   and 0 <= int(value) <= 10}
        if len(answers) != 4 or expected not in answers:
            raise RuntimeError('The actual Plus module did not expose its four answer controls.')
        wrong = min(answers-{expected}, key=int)
        # This module reveals its real local explanation after two wrong
        # answers. Compute both from the public prompt, never from app state.
        for attempt in range(2):
            root = self.frame('plus-before-wrong-answer')
            if addition_prompt_from_labels(labels(root)) != prompt:
                raise RuntimeError('The actual task changed before the local-help check.')
            self.record('actual_learning_wrong_answer', prompt=prompt, answer=wrong,
                        attempt=attempt+1, correct=False)
            self.click(wrong, scroll=True)
            time.sleep(1)
        root = self.wait('Zähle alle Äpfel zusammen:', scroll=True)
        if addition_prompt_from_labels(labels(root)) != prompt:
            raise RuntimeError('The actual task changed while showing local help.')
        hint = apple_help_from_labels(labels(root), prompt)
        self.device.capture('flutter-local-task-help')
        self.record('actual_learning_solution', prompt=prompt, expected=expected,
                    source='visible Android prompt', local_help_observed=True,
                    visible_local_help=hint)
        self.click(expected, scroll=True)
        # The module advances only after the accepted answer and reward have
        # been saved. Require its actual next task counter before returning.
        self.wait('Aufgabe 2 / 30')
        self.device.capture('flutter-learning-answer')
        self.device.key('4', 'KEY_BACK')
        # Navigator restores the Akademie's actual topic scroll position.
        # Reach its hero through real upward gestures before checking return.
        self.top()
        self.wait(LEARNING_SELECTION_CAPTION)
        after = self.wallet('wallet-after-learning')
        if not (after['daily_completed'] >= before['daily_completed']+1
                and after['stars'] >= before['stars']+1 and after['xp'] >= before['xp']+5):
            raise RuntimeError(f'Correct help/answer did not produce actual visible progress/reward: {before} / {after}')
        self.proof['learning'] = {'route': 'Akademie → 1. Klasse → Plus bis 10 module',
                                  'prompt': prompt, 'answer': expected, 'wrong_answers': [wrong, wrong],
                                  'help': hint, 'next_actual_task': 'Aufgabe 2 / 30',
                                  'android_back_to_akademie': True,
                                  'wallet_before': before, 'wallet_after': after}
        self.top()

    def games(self):
        self.home()
        self.click('Spielen', contains=True, scroll=True)
        self.wait('Lumo Spielewelt')
        self.top()

    def boards(self):
        self.games()
        before_memory = self.wallet('wallet-before-memory')
        self.games()
        self.click('Memory mit Lumo', contains=True, scroll=True)
        self.wait('Memory Karte')
        memory = MemoryRound(self.device, self.out/'memory-round', timeout=600)
        result = memory.play()
        memory.after_result(result, self.package, background=True)
        after_memory = self.wallet('wallet-after-memory')
        if after_memory['stars'] < before_memory['stars']+2 or after_memory['xp'] <= before_memory['xp']:
            raise RuntimeError('Full actual Memory result did not reward the visible wallet.')
        self.games()
        self.click('Lumo Cards', contains=True, scroll=True)
        self.wait('Ziehen')
        cards = CardsRound(self.device, self.out/'cards-round', timeout=600, allow_unverified=True)
        result = cards.play()
        cards.after_result(result)
        after_cards = self.wallet('wallet-after-cards')
        if after_cards['stars'] <= after_memory['stars']:
            raise RuntimeError('Full actual Cards result did not reward the visible wallet.')
        self.proof['memory'] = {'total_pairs': 12, 'restart_back_background_return': True,
                                'wallet_before': before_memory, 'wallet_after': after_memory}
        self.proof['cards'] = {'complete_result': True, 'restart_back_return': True,
                               'verified_math_answers': cards.verified_answers,
                               'unverified_learning_answers': cards.unverified_answers,
                               'wallet_after': after_cards}

    def fold_and_restart(self):
        expected = self.wallet('wallet-before-fold-restart')
        sizes = [('904x2316', 'fold-outer'), ('1812x2176', 'fold-inner'),
                 ('904x2316', 'fold-return-outer')]
        for size, name in sizes:
            self.device.resize(size, '320')
            time.sleep(1)
            actual = self.wallet(name)
            if expected != actual:
                raise RuntimeError(f'Visible wallet changed on Fold-size switch: {expected} / {actual}')
            # Real navigation at each size checks actionable controls as well
            # as screenshots; no physical Samsung device is claimed.
            self.click('Lernen', scroll=True)
            self.wait(LEARNING_SELECTION_CAPTION)
            self.device.capture(name+'-learning-navigation')
            self.home()
        self.device.resize('720x1280', '320')
        time.sleep(1)
        self.device.adb('shell', 'am', 'force-stop', self.package)
        self.device.foreground(self.package)
        self.wait('Spielen', timeout=60)
        actual = self.wallet('wallet-after-offline-process-restart')
        if actual != expected:
            raise RuntimeError(f'Actual visible saved wallet/progress differs after restart: {expected} / {actual}')
        self.proof['fold_and_restart'] = {'emulated_sizes': [size for size, _ in sizes],
                                          'density': 320, 'wallet_before': expected,
                                          'wallet_after': actual,
                                          'profile': sorted(self.profile_labels),
                                          'physical_fold_tested': False}
        self.record('flutter_learning_games_fold_restart_passed', checks=self.proof)
        return self.proof
