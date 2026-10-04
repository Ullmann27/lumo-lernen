"""One-time local repair with exact before/after Git blob guards; no network writes."""
from pathlib import Path
import hashlib

BEFORE = '62394336829476558ffcf8174263ca5ef291ca56'
AFTER = 'a036db4f937a6573925c84e348138755481171e6'


def blob(data):
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()


def repair(path):
    data = path.read_bytes()
    if blob(data) != BEFORE:
        raise ValueError('Kart helper differs from the inspected original; do not overwrite it')
    source = data.decode('utf-8')
    old = "    next_answer = answer_for(frame)\n    return bool(previous_prompt and next_answer and next_answer['prompt'] != previous_prompt)\n"
    new = "    previous = canonical_prompt(previous_prompt) if previous_prompt else None\n    following = prompt_for(frame)\n    return bool(previous and following and following != previous)\n"
    if source.count(old) != 1:
        raise ValueError('Transition source does not match the reviewed repair')
    source = source.replace(old, new)
    start = source.index('def answer_for(frame):')
    end = source.index('    values = ', start)
    old = source[start:end]
    new = '''def lesson_prompts(frame):
    """Read complete task captions inside the measured question area.

    An explicit '= ?' is stronger evidence than a permissive OCR reading with
    the equals sign missing (for example, 7-2=? versus the observed 7-22?).
    Keep all equally explicit readings so disagreement still blocks an answer.
    """
    height = frame['height']
    prompts = [frame['lesson_prompt']] if frame.get('lesson_prompt') else []
    prompt_box = frame.get('prompt_box')
    for line in frame['lines']:
        inside = (prompt_box['top'] <= line.get('top', -1)
                  and line['top']+line['height'] <= prompt_box['top']+prompt_box['height']) if prompt_box else (
                  .20*height < line.get('top', -1) < .37*height)
        if inside and maths_value(line['text']) is not None:
            prompts.append(line)
    recognized = [prompt for prompt in prompts if maths_value(prompt['text']) is not None]
    explicit = [prompt for prompt in recognized
                if re.search(r'=\\s*\\?\\s*$', prompt['text']) or not simple_calculation(prompt['text'])]
    return explicit or recognized


def canonical_prompt(text):
    calculation = simple_calculation(text)
    if calculation:
        left, operator, right = calculation.groups()
        return f"{int(left)}{operator.lower().replace('x', '·')}{int(right)}"
    return ' '.join(folded(text).split()) if maths_value(text) is not None else None


def prompt_for(frame):
    """A changed task can be witnessed even when its answer button is unreadable."""
    identities = {canonical_prompt(prompt['text']) for prompt in lesson_prompts(frame)}
    identities.discard(None)
    return next(iter(identities)) if len(identities) == 1 else None


def answer_for(frame):
    """Extract a first-grade maths question and its real on-screen option box."""
    height = frame['height']
    prompts = lesson_prompts(frame)
'''
    source = source[:start]+source[start:].replace(old, new, 1)
    old = "            tap_phrase(frame, 'SPATER')\n            previous_answer = answer_for(frame)\n            wait_frame('lesson-skipped', lambda frame: lesson_closed_or_changed(\n                frame, previous_answer['prompt'] if previous_answer else None),\n"
    new = "            previous_prompt = prompt_for(frame)\n            tap_phrase(frame, 'SPATER')\n            wait_frame('lesson-skipped', lambda frame: lesson_closed_or_changed(\n                frame, previous_prompt),\n"
    if source.count(old) != 1:
        raise ValueError('Skip source does not match the reviewed repair')
    source = source.replace(old, new)
    updated = source.encode('utf-8')
    if blob(updated) != AFTER:
        raise ValueError('Repair differs from the locally tested exact after-blob')
    path.write_bytes(updated)
    print(f'Exact reviewed Kart helper repair: {BEFORE} -> {AFTER}')


if __name__ == '__main__':
    repair(Path(__file__).with_name('kart_android_race.py'))
