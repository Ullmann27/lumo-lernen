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


def simple_calculation(text):
    # OCR can omit "= ?". Accept only a complete arithmetic prompt, never
    # a sentence that merely mentions a calculation in an explanation.
    text = text.replace('—', '−').replace('-', '−')
    return re.fullmatch(r'\s*(\d+)\s*([+−·xX])\s*(\d+)\s*(?:=\s*)?\??\s*', text)


def maths_value(text):
    calculation = simple_calculation(text)
    if calculation:
        a, operator, b = calculation.groups()
        a, b = int(a), int(b)
        return a+b if operator == '+' else a-b if operator == '−' else a*b
    # These are the four actual addition-story formats in KartQuestions.
    # Full matching excludes explanations and unrelated pairs of numbers.
    caption = ' '.join(folded(text).split())
    stories = (
        r'LUMO SAMMELT (\d+) MUSCHELN\. (\d+) KOMMEN DAZU\. WIE VIELE SIND ES\?',
        r'IM GARTEN STEHEN (\d+) BLUMEN\. LUMO PFLANZT (\d+) DAZU\. WIE VIELE WACHSEN JETZT\?',
        r'AUF DEM FEST SIND (\d+) KINDER\. (\d+) KOMMEN NOCH\. WIE VIELE FEIERN ZUSAMMEN\?',
        r'IM REGAL LIEGEN (\d+) (?:BUCHER|BIICHER)\. (\d+) NEUE KOMMEN DAZU\. WIE VIELE SIND ES JETZT\?',
    )
    for pattern in stories:
        match = re.fullmatch(pattern, caption)
        if match:
            return sum(map(int, match.groups()))
    return None


def colour_regions(source, rectangle, palette):
    """Connected visible UI pixels, with measured bounds rather than tap guesses."""
    left, top, right, bottom = map(int, rectangle)
    left, top = max(0, left), max(0, top)
    right, bottom = min(source.width, right), min(source.height, bottom)
    pixels = source.load()
    matches = set()
    for y in range(top, bottom):
        for x in range(left, right):
            r, g, b = pixels[x, y]
            if palette == 'cream':
                hit = r > 240 and g > 230 and b > 210 and r >= g >= b
            elif palette == 'teal':
                hit = 20 < r < 85 and 65 < g < 145 and 80 < b < 165 and min(g, b)-r > 25 and abs(b-g) < 45
            else:
                hit = 65 < r < 145 and 45 < g < 130 and 115 < b < 210 and b-r > 25 and b-g > 30
            if hit:
                matches.add((x, y))
    regions = []
    while matches:
        seed = matches.pop()
        stack = [seed]
        xs, ys = [seed[0]], [seed[1]]
        while stack:
            x, y = stack.pop()
            for point in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
                if point in matches:
                    matches.remove(point)
                    stack.append(point)
                    xs.append(point[0]); ys.append(point[1])
        if len(xs) >= 100:
            regions.append({'left': min(xs), 'top': min(ys),
                            'width': max(xs)-min(xs)+1, 'height': max(ys)-min(ys)+1})
    return regions


def bounds(box):
    return box['left'], box['top'], box['left']+box['width'], box['top']+box['height']


def light_panel(source, anchor, search):
    candidates = [box for box in colour_regions(source, search, 'cream')
                  if box['left'] <= anchor['left'] and box['top'] <= anchor['top']
                  and box['left']+box['width'] >= anchor['left']+anchor['width']
                  and box['top']+box['height'] >= anchor['top']+anchor['height']]
    return max(candidates, key=lambda box: box['width']*box['height']) if candidates else None


def ocr_region(source, box, frame, label, *, contrast='dark', psm=6,
               min_confidence=20, numbers=False):
    from PIL import ImageOps
    left, top, right, bottom = bounds(box)
    if right <= left or bottom <= top:
        return [], []
    crop = source.crop((left, top, right, bottom)).convert('L')
    crop = crop.point(lambda value: (0 if value > 160 else 255)
                      if contrast == 'light' else (255 if value > 160 else 0))
    crop = ImageOps.expand(crop.resize((crop.width*4, crop.height*4)), 20, 'white')
    buffer = io.BytesIO(); crop.save(buffer, format='PNG')
    command = ['tesseract', 'stdin', 'stdout', '--psm', str(psm)]
    if numbers:
        command += ['-c', 'tessedit_char_whitelist=0123456789']
    output = subprocess.run(command+['tsv'], input=buffer.getvalue(), capture_output=True,
                            check=True, timeout=30).stdout.decode()
    frame['tsv'] += f'\n# {label} OCR, origin {left},{top}, scale 4, padding 20\n'+output
    words, groups = [], {}
    for row in csv.DictReader(io.StringIO(output), delimiter='\t'):
        text = row.get('text', '').strip()
        if not text or float(row.get('conf', '-1')) < min_confidence:
            continue
        if numbers and not re.fullmatch(r'\d+', text):
            continue
        word = {'left': left+(int(row['left'])-20)//4, 'top': top+(int(row['top'])-20)//4,
                'width': max(1, int(row['width'])//4), 'height': max(1, int(row['height'])//4), 'text': text}
        if not (left <= word['left'] < right and top <= word['top'] < bottom):
            continue
        words.append(word)
        groups.setdefault(tuple(row[k] for k in ('block_num', 'par_num', 'line_num')), []).append(word)
    lines = []
    for group in groups.values():
        group.sort(key=lambda word: word['left'])
        lines.append(combined_line(group))
    return words, lines


def combined_line(items):
    left, top = min(item['left'] for item in items), min(item['top'] for item in items)
    return {'text': ' '.join(item['text'] for item in items), 'left': left, 'top': top,
            'width': max(item['left']+item['width'] for item in items)-left,
            'height': max(item['top']+item['height'] for item in items)-top}


def analyse_lesson(source, heading, frame):
    panel = light_panel(source, heading, (max(0, heading['left']-.1*source.width),
                                        max(0, heading['top']-.075*source.height),
                                        .95*source.width, .8*source.height))
    if not panel:
        return
    frame['lesson_panel'] = panel
    teal = [box for box in colour_regions(source, bounds(panel), 'teal')
            if box['left'] >= heading['left']+heading['width']
            and 1.3 < box['width']/box['height'] < 4.5
            and abs(box['top']+box['height']/2-heading['top']-heading['height']/2) < heading['height']
            and box['width'] >= .05*source.width and box['height'] >= .025*source.height]
    if len(teal) == 1:
        box = teal[0]
        x_pad, y_pad = max(1, round(box['width']*.045)), max(1, round(box['height']*.11))
        inside = {'left': box['left']+x_pad, 'top': box['top']+y_pad,
                  'width': box['width']-2*x_pad, 'height': box['height']-2*y_pad}
        words, lines = ocr_region(source, inside, frame, 'Isolated teal button',
                                  contrast='light', psm=7, min_confidence=60)
        for line in lines:
            if action_marker({'lines': [line]}, 'SPATER'):
                frame['lines'].append(line)
                frame['words'].extend(words)
    purple = sorted([box for box in colour_regions(source, bounds(panel), 'purple')
                     if box['width'] > .1*source.width and box['height'] > .025*source.height
                     and box['width']/box['height'] > 2.5], key=lambda box: box['left'])
    if len(purple) != 3 or max(box['top'] for box in purple)-min(box['top'] for box in purple) > 3:
        return
    frame['answer_buttons'] = purple
    row_top = min(box['top'] for box in purple)
    row_bottom = max(box['top']+box['height'] for box in purple)
    question_box = {'left': panel['left']+8, 'top': heading['top']+heading['height']+1,
                    'width': panel['width']-16, 'height': row_top-heading['top']-heading['height']-4}
    frame['prompt_box'] = question_box
    # Retain lower-confidence connecting words; maths_value still requires a
    # complete known task sentence before any numbers can become an answer.
    _, prompt_lines = ocr_region(source, question_box, frame, 'Complete lesson prompt', min_confidence=5)
    if prompt_lines:
        prompt = combined_line(sorted(prompt_lines, key=lambda line: (line['top'], line['left'])))
        frame['lesson_prompt'] = prompt
        frame['lines'].append(prompt)
    # Two bounded views of the same complete measured row avoid clipping a
    # multiline task's options or relying on weak individual-digit OCR.
    option_words = []
    for top_fraction, height_fraction in ((.15, .75), (.2, .65)):
        answer_box = {'left': purple[0]['left'], 'top': row_top+round((row_bottom-row_top)*top_fraction),
                      'width': purple[-1]['left']+purple[-1]['width']-purple[0]['left'],
                      'height': round((row_bottom-row_top)*height_fraction)}
        words, _ = ocr_region(source, answer_box, frame, 'Measured answer row',
                              contrast='light', min_confidence=60, numbers=True)
        option_words.extend(words)
    frame['option_words'] = []
    for box in purple:
        observed = [word for word in option_words
                    if box['left'] <= word['left'] < box['left']+box['width']
                    and box['top'] <= word['top'] < box['top']+box['height']]
        if observed and len({int(word['text']) for word in observed}) == 1:
            frame['option_words'].append(observed[0])
    frame['words'].extend(frame['option_words'])
    hint_box = {'left': panel['left']+8, 'top': row_bottom+2,
                'width': panel['width']-16, 'height': panel['top']+panel['height']-row_bottom-6}
    _, hint_lines = ocr_region(source, hint_box, frame, 'Hint below measured answer row')
    if hint_lines:
        frame['lesson_hint'] = combined_line(sorted(hint_lines, key=lambda line: (line['top'], line['left'])))
        frame['lines'].append(frame['lesson_hint'])


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
    # Derived OCR never changes the raw screenshot. UI colour boundaries keep
    # world geometry out of the HUD, lesson, and button analysis crops.
    with Image.open(path) as source:
        source = source.convert('RGB')
        hud = marker(frame, 'RUNDE')
        if hud:
            panel = light_panel(source, hud, (0, max(0, hud['top']-40), width,
                                             min(height, hud['top']+hud['height']+40)))
            if panel:
                _, hud_lines = ocr_region(source, panel, frame, 'HUD', contrast='dark', min_confidence=45)
                frame['hud_panel'], frame['hud_lines'] = panel, hud_lines
                lines.extend(hud_lines)
        lesson = marker(frame, 'LERN-BOOST')
        if lesson:
            analyse_lesson(source, lesson, frame)
    frame['text'] = '\n'.join(line['text'] for line in lines)
    return frame


def race_state(frame):
    state = {}
    for key, caption in [('round', 'RUNDE'), ('place', 'PLATZ')]:
        # Prefer the measured HUD and include actual base OCR within its bounds.
        # A malformed early caption must not hide a readable later crop; two
        # different readable values cannot prove a saved/restored race state.
        panel = frame.get('hud_panel')
        lines = list(frame.get('hud_lines', []))
        for line in frame['lines']:
            if not panel or ('top' in line and panel['top'] <= line['top']
                             and line['top']+line['height'] <= panel['top']+panel['height']):
                lines.append(line)
        values = {tuple(map(int, match.groups())) for line in lines
                  for match in re.finditer(r'\b'+caption+r'\s*(\d+)\s*/\s*(\d+)\b', folded(line['text']))}
        if len(values) != 1 or any(current < 1 or current > total for current, total in values):
            raise RuntimeError(f'Cannot read the actual race HUD value {caption}')
        state[key] = list(next(iter(values)))
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


def action_marker(frame, phrase):
    """Match an entire actual button caption, never a sentence mentioning it."""
    wanted = ' '.join(folded(phrase).split())
    for line in frame['lines']:
        caption = ' '.join(folded(line['text']).split())
        if caption == wanted:
            return line
        if wanted in ('ZUR SPIELEAUSWAHL', 'ZUM LERNEN') and re.fullmatch(
                re.escape(wanted)+r'\s*[·•:\-–—]\s*RENNEN BEHALTEN', caption):
            return line
        if wanted == 'SPATER' and re.fullmatch(r'SPATER\s*[›»>]+', caption):
            return line
    return None


def lightweight_pause_visible(frame):
    return bool(action_marker(frame, 'Leichte Grafik: an') and action_marker(frame, 'Weiterfahren'))


def lesson_visible(frame):
    return bool(marker(frame, 'LERN-BOOST') or action_marker(frame, 'SPATER'))


def wait_for_frame(capture, label, predicate, error_message, *, timeout=90,
                   poll_interval=.5, clock=time.monotonic, sleep=time.sleep):
    """Observe a bounded real UI transition after one already-issued input.

    Rendering, ADB capture and full OCR can span several slow emulator frames.
    The bounded budget includes all this processing. Capture every observation,
    but never retry the input or accept a stale HUD alone or after the deadline.
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
    if not marker(frame, 'LERN-BOOST'):
        return False
    hint, panel, buttons = frame.get('lesson_hint'), frame.get('lesson_panel'), frame.get('answer_buttons')
    if not hint or not panel or not buttons:
        return False
    if hint['top'] < max(box['top']+box['height'] for box in buttons):
        return False
    if hint['top']+hint['height'] > panel['top']+panel['height']:
        return False
    caption = folded(hint['text'])
    return len(re.findall(r'[A-Za-z]', hint['text'])) >= 12 and not any(
        initial in caption for initial in ('ALLE KARTS', 'NIMM DIR ZEIT', 'DANACH GEHT DEIN RENNEN'))


def lesson_closed_or_changed(frame, previous_prompt=None):
    if not lesson_visible(frame):
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
    prompts = [frame['lesson_prompt']] if frame.get('lesson_prompt') else []
    prompt_box = frame.get('prompt_box')
    for line in frame['lines']:
        inside = (prompt_box['top'] <= line.get('top', -1)
                  and line['top']+line['height'] <= prompt_box['top']+prompt_box['height']) if prompt_box else (
                  .20*height < line['top'] < .37*height)
        if inside and maths_value(line['text']) is not None:
            prompts.append(line)
    values = {maths_value(prompt['text']) for prompt in prompts if maths_value(prompt['text']) is not None}
    if len(values) != 1:
        return None
    for prompt in prompts:
        text = prompt['text'].replace('—', '−').replace('-', '−')
        expected = maths_value(text)
        if expected is None:
            continue
        options = (frame['option_words'] if 'option_words' in frame else
                   [word for word in frame['words']
                    if prompt['top'] + prompt['height'] < word['top'] < .44*height
                    and re.fullmatch(r'\d+', word['text'])])
        right = next((word for word in options if int(word['text']) == expected), None)
        if right:
            return {'prompt': text, 'expected': expected, 'option': right, 'options': options}
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
    parser.add_argument('--lightweight', action='store_true',
                        help='Enable the real Leichte Grafik setting in the observed Back pause.')
    parser.add_argument('--check-wrong-hint', action='store_true')
    parser.add_argument('--return-to', choices=['games', 'learn'])
    parser.add_argument('--self-test', type=Path,
                        help='Inspect a supplied PNG only; sends no Android input.')
    args = parser.parse_args()
    if args.lightweight and not args.pause_back:
        parser.error('--lightweight requires --pause-back to inspect the actual settings panel')
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
        box = action_marker(frame, phrase)
        if not box:
            raise RuntimeError(f'Button absent in actual OCR frame: {phrase}')
        tap_box(box, phrase)
    frame = capture('native-start')
    if action_marker(frame, 'Weiterfahren'):
        tap_phrase(frame, 'Weiterfahren')
        frame = wait_frame('resumed-start', race_view_visible,
                           'Resume touch did not close the real pause screen.')
    if args.pause_back:
        android.key(4, 'KEY_BACK')
        frame = wait_frame('android-back-pause', lambda frame: bool(action_marker(frame, 'Weiterfahren')),
                           'Android Back did not open the Godot pause screen.')
        if args.lightweight:
            changed = False
            if action_marker(frame, 'Leichte Grafik: aus'):
                tap_phrase(frame, 'Leichte Grafik: aus')
                changed = True
                frame = wait_frame('lightweight-setting-reloaded', lightweight_pause_visible,
                                   'The real lightweight setting did not reload the saved pause with Leichte Grafik: an.')
            elif not lightweight_pause_visible(frame):
                raise RuntimeError('The actual lightweight setting and resume button were not visible.')
            record('lightweight_setting_verified', changed=changed, text=frame['text'])
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
        if lesson_visible(frame):
            answer = answer_for(frame)
            if answer:
                record('math_solution', prompt=answer['prompt'], expected=answer['expected'])
                if correct == 0:
                    # A second actual screenshot proves that the visible lesson remains
                    # waiting while real CPU/wall time passes; no controller alteration.
                    time.sleep(4)
                    waiting = capture('learning-waits')
                    if not lesson_visible(waiting):
                        raise RuntimeError('Lesson disappeared without a touch while waiting.')
                    if not re.search(r'\b[0O]\s*KM\s*/\s*H', folded(waiting['text'])):
                        raise RuntimeError('Visible learning-pause speed is not proven zero by OCR.')
                    record('real_learning_wait', wall_seconds=4, speed_zero=True)
                    if args.check_wrong_hint:
                        wrong = next((word for word in answer['options']
                                      if int(word['text']) != answer['expected']), None)
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
        frame = wait_frame('restart-paused', lambda frame: bool(action_marker(frame, 'Weiterfahren')),
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
