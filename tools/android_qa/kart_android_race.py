#!/usr/bin/env python3
"""Real ADB touch/OCR race check; start from an already opened native Kart screen.

No Godot debug commands, altered physics, teleports or save edits. Automatic gas
is the actual child-facing game mechanic. Evidence records every real touch.
"""
from __future__ import annotations
import argparse
import csv
import io
import json
import os
from pathlib import Path
import re
import subprocess
import time
import unicodedata

from android_ui import Android, ADB


def folded(text):
    return ''.join(c for c in unicodedata.normalize('NFKD', text) if not unicodedata.combining(c)).upper()


def read_frame(path):
    from PIL import Image
    with Image.open(path) as image:
        width, height = image.size
    raw = subprocess.run(['tesseract', str(path), 'stdout', '--psm', '11', 'tsv'],
                         capture_output=True, text=True, check=True, timeout=45).stdout
    grouped = {}
    words = []
    for row in csv.DictReader(io.StringIO(raw), delimiter='\t'):
        text = row.get('text', '').strip()
        if not text or float(row.get('conf', '-1')) < 5:
            continue
        box = {k: int(row[k]) for k in ('left', 'top', 'width', 'height')}
        box['text'] = text
        words.append(box)
        group = tuple(row[k] for k in ('block_num', 'par_num', 'line_num'))
        grouped.setdefault(group, []).append(box)
    lines = []
    for line_words in grouped.values():
        line_words.sort(key=lambda x: x['left'])
        left = min(w['left'] for w in line_words)
        top = min(w['top'] for w in line_words)
        right = max(w['left'] + w['width'] for w in line_words)
        bottom = max(w['top'] + w['height'] for w in line_words)
        lines.append({'text': ' '.join(w['text'] for w in line_words),
                      'left': left, 'top': top, 'width': right-left, 'height': bottom-top})
    frame = {'width': width, 'height': height, 'words': words, 'lines': lines,
             'text': '\n'.join(line['text'] for line in lines), 'tsv': raw}
    if marker(frame, 'Kleine Pause') or marker(frame, 'geschafft'):
        # Raw full-screen OCR misses pale captions on purple buttons. A real
        # central-panel crop at 2x preserves their actual screenshot positions.
        with Image.open(path) as source:
            origin_x, origin_y = int(.26*width), int(.155*height)
            crop = source.crop((origin_x, origin_y, int(.738*width), int(.86*height)))
            crop = crop.resize((crop.width*2, crop.height*2))
            buffer = io.BytesIO(); crop.save(buffer, format='PNG')
            central = subprocess.run(['tesseract', 'stdin', 'stdout', '--psm', '6', 'tsv'],
                                     input=buffer.getvalue(), capture_output=True, timeout=30).stdout.decode()
        groups = {}
        for row in csv.DictReader(io.StringIO(central), delimiter='\t'):
            text = row.get('text', '').strip()
            if not text or float(row.get('conf', '-1')) < 5:
                continue
            box = {'left': origin_x+int(row['left'])//2, 'top': origin_y+int(row['top'])//2,
                   'width': max(1, int(row['width'])//2), 'height': max(1, int(row['height'])//2),
                   'text': text}
            words.append(box)
            groups.setdefault(tuple(row[k] for k in ('block_num', 'par_num', 'line_num')), []).append(box)
        for group in groups.values():
            group.sort(key=lambda word: word['left'])
            left, top = min(word['left'] for word in group), min(word['top'] for word in group)
            lines.append({'text': ' '.join(word['text'] for word in group), 'left': left, 'top': top,
                          'width': max(word['left']+word['width'] for word in group)-left,
                          'height': max(word['top']+word['height'] for word in group)-top})
        frame['text'] = '\n'.join(line['text'] for line in lines)
        frame['tsv'] += '\n# Additional central-panel crop, coordinate origin '
        frame['tsv'] += f'{origin_x},{origin_y}, scale 2\n'+central
    # OCR analysis crops are temporary; the evidence PNG is always the raw
    # screencap. White numbers on the game's purple buttons need inversion.
    lesson = marker(frame, 'LERN-BOOST')
    if lesson:
        prompts = [line for line in lines if lesson['top']+lesson['height'] < line['top'] < .37*height
                   and ('=' in line['text'] or 'WIE VIELE' in folded(line['text']))]
        if prompts:
            prompt_bottom = max(line['top']+line['height'] for line in prompts)
            center_y = prompt_bottom + 32*height/720
            with Image.open(path) as source:
                for index, center_x in enumerate((.275*width, .5*width, .725*width)):
                    crop_box = (int(center_x-.043*width), int(center_y-.03*height),
                                int(center_x+.043*width), int(center_y+.03*height))
                    analysis = source.crop(crop_box).convert('L').point(lambda value: 0 if value > 165 else 255)
                    analysis = analysis.resize((analysis.width*4, analysis.height*4))
                    buffer = io.BytesIO(); analysis.save(buffer, format='PNG')
                    output = subprocess.run(['tesseract', 'stdin', 'stdout', '--psm', '8',
                                             '-c', 'tessedit_char_whitelist=0123456789'],
                                            input=buffer.getvalue(), capture_output=True, timeout=30).stdout.decode().strip()
                    if re.fullmatch(r'\d+', output):
                        words.append({'left': int(center_x-8), 'top': int(center_y-8),
                                      'width': 16, 'height': 16, 'text': output})
    return frame


def race_state(frame):
    state = {}
    for key, caption in [('round', 'RUNDE'), ('place', 'PLATZ')]:
        line = marker(frame, caption)
        value = re.search(caption+r'\s*(\d+)\s*/\s*(\d+)', folded(line['text'])) if line else None
        if not value:
            raise RuntimeError(f'Cannot read the actual race HUD value {caption}')
        state[key] = list(map(int, value.groups()))
    return state


def second_round_in_progress(frame):
    """Count only a readable real HUD before the result overlay appears."""
    if marker(frame, 'geschafft') or marker(frame, 'Noch ein Rennen'):
        return False
    try:
        return race_state(frame)['round'] == [2, 2]
    except RuntimeError:
        # Unreadable frames are retained as evidence but cannot prove a lap.
        return False


def require_second_round(capture_number):
    if capture_number is None:
        raise RuntimeError('No captured race HUD proved Runde 2/2 before the result screen.')


def marker(frame, phrase):
    phrase = folded(phrase)
    return next((line for line in frame['lines'] if phrase in folded(line['text'])), None)


def wait_for_frame(capture, label, predicate, error_message, *, timeout=30,
                   poll_interval=.5, clock=time.monotonic, sleep=time.sleep):
    """Observe a bounded real UI transition after one already-issued input.

    Rendering and panel layout can span several slow emulator frames. Capture
    every observation, but never retry the input or accept a stale HUD alone.
    """
    deadline = clock()+timeout
    last_text = ''
    while clock() < deadline:
        frame = capture(label)
        last_text = frame['text']
        remaining = deadline-clock()
        if remaining >= 0 and predicate(frame):
            return frame
        if remaining <= 0:
            break
        sleep(min(poll_interval, remaining))
    raise RuntimeError(f'{error_message} No matching frame within {timeout}s. '
                       f'Last captured OCR: {last_text!r}')


def race_view_visible(frame):
    return bool(marker(frame, 'RUNDE')) and not any(marker(frame, caption) for caption in
        ('Weiterfahren', 'Kleine Pause', 'geschafft', 'Noch ein Rennen'))


def local_hint_visible(frame):
    if not marker(frame, 'LERN-BOOST') or marker(frame, 'Alle Karts warten'):
        return False
    return any(.38*frame['height'] < line['top'] < .52*frame['height']
               and len(re.findall(r'[A-Za-z]', line['text'])) >= 12
               for line in frame['lines'])


def lesson_closed_or_changed(frame, previous_prompt=None):
    if not (marker(frame, 'SPATER') or marker(frame, 'LERN-BOOST')):
        return race_view_visible(frame) or bool(marker(frame, 'geschafft'))
    next_answer = answer_for(frame)
    return bool(previous_prompt and next_answer and next_answer['prompt'] != previous_prompt)


def restart_visible(frame):
    if not race_view_visible(frame):
        return False
    try:
        return race_state(frame)['round'] == [1, 2]
    except RuntimeError:
        return False


def answer_for(frame):
    """Extract a first-grade maths question and its real on-screen option box."""
    height = frame['height']
    prompts = [line for line in frame['lines'] if .20*height < line['top'] < .37*height
               and any(token in folded(line['text']) for token in (' =', '+', '−', ' WIE VIELE'))]
    for prompt in prompts:
        text = prompt['text'].replace('—', '−').replace('-', '−')
        calculation = re.search(r'(\d+)\s*([+−·xX])\s*(\d+)\s*=', text)
        expected = None
        if calculation:
            a, operator, b = calculation.groups()
            a, b = int(a), int(b)
            expected = a+b if operator == '+' else a-b if operator == '−' else a*b
        elif any(term in folded(text) for term in ('MUSCHELN', 'BLUMEN', 'BUCHER', 'KINDER')):
            numbers = re.findall(r'\b\d+\b', text)
            if len(numbers) == 2:
                expected = sum(map(int, numbers))
        if expected is None:
            continue
        options = [word for word in frame['words']
                   if prompt['top'] + prompt['height'] < word['top'] < .44*height
                   and re.fullmatch(r'\d+', word['text'])]
        right = next((word for word in options if int(word['text']) == expected), None)
        if right:
            return {'prompt': text, 'expected': expected, 'option': right}
    return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', default='emulator-5554')
    parser.add_argument('--package', default='dev.ullmann.lumo.lumo_lernen.neu')
    parser.add_argument('--out', type=Path, default=Path(os.environ.get('LUMO_QA_DIR', 'android-qa-evidence'))/'kart-race')
    parser.add_argument('--timeout', type=int, default=600)
    parser.add_argument('--require-correct', action='store_true')
    parser.add_argument('--restart', action='store_true')
    parser.add_argument('--pause-back', action='store_true')
    parser.add_argument('--check-wrong-hint', action='store_true')
    parser.add_argument('--return-to', choices=['games', 'learn'])
    parser.add_argument('--self-test', type=Path,
                        help='Inspect a supplied PNG only; sends no Android input.')
    args = parser.parse_args()
    if args.self_test:
        frame = read_frame(args.self_test)
        print(json.dumps({'width': frame['width'], 'height': frame['height'],
                          'text': frame['text'], 'math': answer_for(frame)}, ensure_ascii=False))
        return
    args.out.mkdir(parents=True, exist_ok=True)
    android = Android(args.serial, fast_input=False)
    sequence = 0
    second_round_capture = None
    def record(event, **values):
        value = {'time_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                 'event': event, **values}
        with (args.out/'actions.jsonl').open('a') as stream:
            stream.write(json.dumps(value, ensure_ascii=False)+'\n')
        print(json.dumps(value, ensure_ascii=False), flush=True)
    def capture(label):
        nonlocal sequence, second_round_capture
        sequence += 1
        path = args.out/f'{sequence:03d}-{label}.png'
        path.write_bytes(android.adb('exec-out', 'screencap', '-p', binary=True))
        frame = read_frame(path)
        path.with_suffix('.tsv').write_text(frame.pop('tsv'))
        path.with_suffix('.txt').write_text(frame['text'])
        record('capture', image=str(path), width=frame['width'], height=frame['height'])
        if frame['width'] <= frame['height']:
            raise RuntimeError('Kart must finish its actual native landscape rotation first.')
        if second_round_capture is None and second_round_in_progress(frame):
            second_round_capture = sequence
            record('second_round_observed', capture_sequence=sequence,
                   hud=race_state(frame), text=frame['text'])
        return frame
    def wait_frame(label, predicate, error_message):
        started = time.monotonic()
        observed = wait_for_frame(capture, label, predicate, error_message)
        record('transition_observed', transition=label,
               seconds=round(time.monotonic()-started, 2))
        return observed
    def tap_box(box, reason):
        x, y = box['left']+box['width']//2, box['top']+box['height']//2
        record('touch', x=x, y=y, reason=reason)
        android.tap(x, y)
    def tap_phrase(frame, phrase):
        box = marker(frame, phrase)
        if not box and folded(phrase) == 'SPATER':
            lesson = marker(frame, 'LERN-BOOST')
            if lesson:
                # Actual lesson heading anchors the row; this is the source
                # layout's right-hand skip button, not an arbitrary tap.
                box = {'left': int(.795*frame['width'])-5,
                       'top': lesson['top']+lesson['height']//2-5,
                       'width': 10, 'height': 10}
        if not box:
            raise RuntimeError(f'Button absent in actual OCR frame: {phrase}')
        tap_box(box, phrase)
    frame = capture('native-start')
    if marker(frame, 'Weiterfahren'):
        tap_phrase(frame, 'Weiterfahren')
        frame = wait_frame('resumed-start', race_view_visible,
                           'Resume touch did not close the real pause screen.')
    if args.pause_back:
        android.key(4, 'KEY_BACK')
        frame = wait_frame('android-back-pause', lambda frame: bool(marker(frame, 'Weiterfahren')),
                           'Android Back did not open the Godot pause screen.')
        tap_phrase(frame, 'Weiterfahren')
        frame = wait_frame('android-back-resumed', race_view_visible,
                           'Resume touch did not close the real pause screen.')
    deadline = time.monotonic()+args.timeout
    correct = 0
    skipped = 0
    while time.monotonic() < deadline:
        frame = capture('race')
        if marker(frame, 'geschafft') and marker(frame, 'Noch ein Rennen'):
            require_second_round(second_round_capture)
            record('finished', correct_actions=correct, skipped_actions=skipped,
                   second_round_capture_sequence=second_round_capture, text=frame['text'])
            if args.require_correct and correct < 1:
                raise RuntimeError('No actual maths answer was proven; race finish alone is insufficient.')
            break
        if marker(frame, 'SPATER') or marker(frame, 'LERN-BOOST'):
            if correct == 0:
                answer = answer_for(frame)
                if answer:
                    record('math_solution', prompt=answer['prompt'], expected=answer['expected'])
                    # A second actual screenshot proves that the visible lesson remains
                    # waiting while real CPU/wall time passes; no controller alteration.
                    time.sleep(4)
                    waiting = capture('learning-waits')
                    if not (marker(waiting, 'SPATER') or marker(waiting, 'LERN-BOOST')):
                        raise RuntimeError('Lesson disappeared without a touch while waiting.')
                    if not re.search(r'\b[0O]\s*KM\s*/\s*H', folded(waiting['text'])):
                        raise RuntimeError('Visible learning-pause speed is not proven zero by OCR.')
                    record('real_learning_wait', wall_seconds=4, speed_zero=True)
                    if args.check_wrong_hint:
                        wrong = next((word for word in frame['words'] if .32*frame['height'] < word['top'] < .42*frame['height']
                                      and re.fullmatch(r'\d+', word['text']) and int(word['text']) != answer['expected']), None)
                        if not wrong:
                            raise RuntimeError('No wrong option box could be identified safely.')
                        tap_box(wrong, 'intentional wrong answer, inspect local hint')
                        hint = wait_frame('wrong-local-hint', local_hint_visible,
                                          'The local explanation after the wrong answer was not visible.')
                        record('wrong_answer_hint', text=hint['text'])
                    tap_box(answer['option'], 'correct maths answer')
                    wait_frame('answered', lambda frame: lesson_closed_or_changed(frame, answer['prompt']),
                               'Answer touch did not close the real learning pause.')
                    correct += 1
                    continue
            tap_phrase(frame, 'SPATER')
            previous_answer = answer_for(frame)
            wait_frame('lesson-skipped', lambda frame: lesson_closed_or_changed(
                frame, previous_answer['prompt'] if previous_answer else None),
                'Später touch did not close the real learning pause.')
            skipped += 1
            continue
        time.sleep(2)
    else:
        raise RuntimeError('The real two-lap race did not finish before timeout; evidence retained.')
    if args.restart:
        tap_phrase(frame, 'Noch ein Rennen')
        restarted = wait_frame('real-restart', restart_visible,
                               'The real restart did not return to the round-one race HUD.')
        record('restart_verified', text=restarted['text'])
        android.key(4, 'KEY_BACK')
        frame = wait_frame('restart-paused', lambda frame: bool(marker(frame, 'Weiterfahren')),
                           'Android Back after restart did not open the Godot pause screen.')
    if args.return_to:
        if args.restart:
            (args.out/'saved-pause-before-return.json').write_text(json.dumps(race_state(frame), indent=2)+'\n')
        tap_phrase(frame, 'Zum Lernen' if args.return_to == 'learn' else 'Zur Spieleauswahl')
        # Allow native renderer shutdown; only engine PID may stop, never Flutter.
        deadline = time.monotonic()+45
        while time.monotonic() < deadline:
            running = subprocess.run(
                [ADB, '-s', args.serial,
                 'shell', 'pidof', args.package+':lumo_game'], capture_output=True, text=True).stdout.strip()
            if not running:
                break
            time.sleep(.5)
        else:
            raise RuntimeError('Native game process did not stop after the real return button.')
        flutter = android.adb('shell', 'pidof', args.package).strip()
        if not flutter:
            raise RuntimeError('Return killed Flutter as well as the engine.')
        record('returned', destination=args.return_to, flutter_pid=flutter)


if __name__ == '__main__':
    main()
