"""Real visible Flutter touches for the exact-APK Android check.

No database, preferences, engine hooks or deterministic test seeds are used.
Unsupported/missing UI is an error. Wallet verification compares visible home
stars, XP/level and daily completion before/after process restart.
"""
from __future__ import annotations

import json
from pathlib import Path
import re
import time
import xml.etree.ElementTree as ET

from memory_android_round import Round as MemoryRound, labels
from cards_android_round import CardsRound, arithmetic


def wallet_from_labels(values):
    """Only the concrete home-stat captions count; bare header digits do not."""
    stars = {int(match[1]) for value in values
             if (match := re.fullmatch(r'(\d+) Sterne', value))}
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
        width, height = self.dimensions(root)
        # Use the content centre and leave navigation/companion bars untouched.
        x = round(width*.58)
        high, low = round(height*.29), round(height*.73)
        self.record('real_content_scroll', x=x, from_y=low if down else high,
                    to_y=high if down else low)
        self.device.swipe(x, low if down else high, x, high if down else low, 350)
        time.sleep(.3)

    def top(self):
        for _ in range(4):
            self.scroll(self.frame('scroll-to-top'), down=False)

    def click(self, phrase, contains=False, scroll=False):
        for _ in range(12 if scroll else 1):
            root = self.frame('find-control')
            targets = self.targets(root, phrase, contains)
            if targets:
                left, top, right, bottom = targets[0]
                self.record('real_flutter_touch', caption=phrase,
                            bounds=[left, top, right, bottom])
                self.device.tap((left+right)//2, (top+bottom)//2)
                time.sleep(.5)
                return
            if scroll:
                self.scroll(root)
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
        profile = {value for value in labels(root)
                   if value.startswith('Hallo,') or re.fullmatch(r'Dein Lumo-Tag · \d\. Klasse', value)}
        if len(profile) != 2:
            raise RuntimeError('Actual visible home profile captions are incomplete.')
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
        self.wait('Was möchtest du üben?')
        self.click('Plus bis 10', scroll=True)
        self.wait('Lumo, hilf mir', scroll=True)
        # The real GestureDetector merges its decorative emoji and caption
        # into one accessibility label: "✨\nLumo, hilf mir".
        self.click('Lumo, hilf mir', contains=True, scroll=True)
        self.wait('Lumo erklärt', scroll=True)
        self.device.capture('flutter-local-task-help')
        self.top()
        prompt = None
        for _ in range(10):
            root = self.frame('actual-learning-prompt')
            prompts = {value for value in labels(root)
                       if re.fullmatch(r'\d+\s*\+\s*\d+\s*=\s*\?', value)}
            if len(prompts) == 1:
                prompt = prompts.pop()
                break
            self.scroll(root)
        if prompt is None:
            raise RuntimeError('The chosen Plus-bis-10 task did not expose an unambiguous addition prompt.')
        expected = arithmetic(prompt)
        if expected is None:
            raise RuntimeError('The actual visible addition cannot be evaluated.')
        self.record('actual_learning_solution', prompt=prompt, expected=expected,
                    source='visible Android prompt', local_help_observed=True)
        self.click(expected, scroll=True)
        # Feedback advances automatically in this app. The durable, visible
        # daily count and earned wallet delta prove evaluation even if that
        # brief feedback has disappeared before a subsequent UI dump.
        time.sleep(1)
        self.device.capture('flutter-learning-answer')
        after = self.wallet('wallet-after-learning')
        if not (after['daily_completed'] >= before['daily_completed']+1
                and after['stars'] > before['stars'] and after['xp'] > before['xp']):
            raise RuntimeError(f'Correct help/answer did not produce actual visible progress/reward: {before} / {after}')
        self.proof['learning'] = {'prompt': prompt, 'answer': expected, 'help': 'local visible explanation',
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
            self.wait('Was möchtest du üben?')
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
