#!/usr/bin/env python3
"""Read-only checks for Lumo's shipped JSON questions; no auto-corrections.

This complements audit_content.dart, which checks generated task templates.
Arithmetic is checked only for explicitly recognised, unambiguous prompts.
Unrecognised questions require a separate subject-matter review.
"""
import argparse
from collections import Counter
from fractions import Fraction
import json
from pathlib import Path
import re
import unicodedata


def normalized(value):
    return ' '.join(unicodedata.normalize('NFKC', value).casefold().split())


def arithmetic_answer(prompt):
    match = re.fullmatch(
        r'(?:Wie viel ist|Was ist)\s+(\d+)\s*(\+|[-−]|[×·*]|mal|[:÷/])\s*(\d+)\s*\?',
        prompt.strip(), re.IGNORECASE,
    )
    if not match:
        return None
    left, operator, right = match.groups()
    left, right = int(left), int(right)
    if operator == '+':
        return Fraction(left + right)
    if operator in ('-', '−'):
        return Fraction(left - right)
    if operator in ('×', '·', '*', 'mal'):
        return Fraction(left * right)
    return Fraction(left, right) if right else None


def audit_bundle(path):
    issues = []
    manual_review = []
    histogram = Counter()
    seen = {}
    checked_arithmetic = 0

    def issue(code, row, message):
        issues.append({'code': code, 'row': row, 'message': message})

    try:
        questions = json.loads(path.read_text(encoding='utf-8'))
    except (OSError, UnicodeError, json.JSONDecodeError):
        issue('unreadable_bundle', None, 'Bundle is unreadable or invalid JSON.')
        return {'file': path.name, 'count': 0, 'issues': issues, 'manual_review': []}
    if not isinstance(questions, list) or not questions:
        issue('invalid_bundle', None, 'Expected a non-empty question list.')
        return {'file': path.name, 'count': 0, 'issues': issues, 'manual_review': []}

    for row, question in enumerate(questions, start=1):
        if not isinstance(question, dict):
            issue('invalid_question', row, 'Expected an object.')
            continue
        prompt = question.get('prompt')
        options = question.get('options')
        index = question.get('correctIndex')
        if not isinstance(prompt, str) or not prompt.strip():
            issue('missing_prompt', row, 'A non-empty prompt is required.')
            continue
        if (not isinstance(options, list) or len(options) != 4 or
                any(not isinstance(o, str) or not o.strip() for o in options)):
            issue('invalid_options', row, 'Four non-empty string options are required.')
            continue
        if type(index) is not int or not 0 <= index < len(options):
            issue('invalid_answer_index', row, 'The correct index must be an integer within the options.')
            continue
        histogram[index] += 1
        option_keys = [normalized(o) for o in options]
        if len(set(option_keys)) != len(option_keys):
            issue('duplicate_options', row, 'Options repeat after Unicode, case and whitespace normalization.')
        # Ignore distractor order: repeated visible tasks remain duplicates.
        key = (normalized(prompt), option_keys[index], tuple(sorted(option_keys)))
        if key in seen:
            issue('duplicate_question', row, f'Duplicates row {seen[key]}.')
        else:
            seen[key] = row
        if not isinstance(question.get('hint'), str) or not question['hint'].strip():
            issue('missing_hint', row, 'An age-appropriate hint is required.')

        expected = arithmetic_answer(prompt)
        if expected is None:
            manual_review.append(row)
            continue
        checked_arithmetic += 1
        try:
            answers = [Fraction(o.strip().replace(',', '.')) for o in options]
        except (ValueError, ZeroDivisionError):
            issue('non_numeric_arithmetic_option', row, 'Arithmetic options must be numeric.')
            continue
        if answers[index] != expected:
            issue('wrong_arithmetic_answer', row, 'Stored solution does not equal the independently calculated result.')
        if answers.count(expected) != 1:
            issue('ambiguous_arithmetic_answer', row, 'The calculated result must occur exactly once, including numeric equivalents.')

    if sum(histogram.values()) >= 10 and len(histogram) == 1:
        issue('fixed_answer_position', None, 'Every valid question has the same correct button position; verify/shuffle at presentation time.')
    absent = [name for name in (
        'id', 'grade', 'subject', 'topic', 'competency', 'difficulty',
        'prerequisites', 'explanation', 'curriculumSource',
    ) if any(not isinstance(q, dict) or name not in q for q in questions)]
    return {
        'file': path.name, 'count': len(questions),
        'correct_position_counts': dict(sorted(histogram.items())),
        'arithmetic_checked': checked_arithmetic,
        'manual_review': manual_review,
        'metadata_not_complete': absent, 'issues': issues,
    }


def audit_directory(directory):
    files = sorted(directory.glob('*.json'))
    bundles = [audit_bundle(path) for path in files]
    issues = [{'file': b['file'], **i} for b in bundles for i in b['issues']]
    if not files:
        issues.append({'file': None, 'code': 'missing_bundles', 'row': None,
                       'message': 'No JSON question bundles found.'})
    return {
        'scope': 'Shipped JSON bundles only; generated tasks, language meaning, curriculum and gameplay are separate checks.',
        'bundles': bundles, 'question_count': sum(b['count'] for b in bundles),
        'arithmetic_checked': sum(b.get('arithmetic_checked', 0) for b in bundles),
        'manual_review_count': sum(len(b['manual_review']) for b in bundles),
        'issue_count': len(issues), 'issues': issues,
        'status': 'issues_found' if issues else 'structural_checks_passed',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--json-output', type=Path)
    args = parser.parse_args()
    result = audit_directory(args.root / 'assets' / 'learning_questions')
    if args.json_output:
        args.json_output.parent.mkdir(parents=True, exist_ok=True)
        args.json_output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f"JSON questions: {result['question_count']}; arithmetic independently checked: {result['arithmetic_checked']}; manual review: {result['manual_review_count']}; issues: {result['issue_count']}")
    for issue in result['issues']:
        print(f"{issue['file'] or '<directory>'}:{issue['row'] or '-'} {issue['code']}: {issue['message']}")
    return 1 if result['issues'] else 0


if __name__ == '__main__':
    raise SystemExit(main())
