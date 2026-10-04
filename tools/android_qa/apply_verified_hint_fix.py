"""One-time local repair; exact source hashes prevent unrelated changes."""
from pathlib import Path
import hashlib

BEFORE = 'a036db4f937a6573925c84e348138755481171e6'
AFTER = 'c4192dd84fac9c5111055d0894842c105499b5b8'


def blob(data):
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()


def repair(path):
    data = path.read_bytes()
    if blob(data) != BEFORE:
        raise ValueError('Refuse to overwrite an unreviewed Kart helper')
    source = data.decode('utf-8')
    replacements = [
        ('def main():\n', '''def require_learning_evidence(correct, wrong_hint_observed, *, require_correct, check_wrong_hint):
    if require_correct and correct < 1:
        raise RuntimeError('No actual maths answer was proven; race finish alone is insufficient.')
    if check_wrong_hint and not wrong_hint_observed:
        raise RuntimeError('No actual wrong-answer/local-hint interaction was proven during this race.')


def wrong_option_for(answer):
    return next((word for word in answer['options']
                 if int(word['text']) != answer['expected']), None)


def main():
'''),
        ('    correct = 0\n    skipped = 0\n',
         '    correct = 0\n    skipped = 0\n    wrong_hint_observed = False\n'),
        ("            if args.require_correct and correct < 1:\n                raise RuntimeError('No actual maths answer was proven; race finish alone is insufficient.')\n",
         '            require_learning_evidence(correct, wrong_hint_observed,\n                                      require_correct=args.require_correct,\n                                      check_wrong_hint=args.check_wrong_hint)\n'),
        ('''                    if args.check_wrong_hint:
                        wrong = next((word for word in answer['options']
                                      if int(word['text']) != answer['expected']), None)
                        if not wrong:
                            raise RuntimeError('No wrong option box could be identified safely.')
                        tap_box(wrong, 'intentional wrong answer, inspect local hint')
                        hint = wait_frame('wrong-local-hint', local_hint_visible,
                                          'The local explanation after the wrong answer was not visible.')
                        record('wrong_answer_hint', text=hint['text'])
''', '''                if args.check_wrong_hint and not wrong_hint_observed:
                    # A safe correct answer may be visible before any wrong
                    # option is readable. Keep driving/answering, but require
                    # this independent wrong-answer/hint check before success.
                    wrong = wrong_option_for(answer)
                    if wrong:
                        tap_box(wrong, 'intentional wrong answer, inspect local hint')
                        hint = wait_frame('wrong-local-hint', local_hint_visible,
                                          'The local explanation after the wrong answer was not visible.')
                        record('wrong_answer_hint', text=hint['text'])
                        wrong_hint_observed = True
                    else:
                        record('deferred_wrong_hint', reason='No safely read wrong option in this question',
                               prompt=answer['prompt'], expected=answer['expected'])
'''),
    ]
    for old, new in replacements:
        if source.count(old) != 1:
            raise ValueError('Source does not exactly match the reviewed repair')
        source = source.replace(old, new)
    result = source.encode('utf-8')
    if blob(result) != AFTER:
        raise ValueError('Result differs from the locally tested exact after-blob')
    path.write_bytes(result)
    print(f'Exact tested learning-evidence repair: {BEFORE} -> {AFTER}')


if __name__ == '__main__':
    repair(Path(__file__).with_name('kart_android_race.py'))
