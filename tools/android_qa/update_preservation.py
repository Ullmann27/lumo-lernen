"""Strict read-only evidence checks for an Android in-place learning update."""
from __future__ import annotations

import json
import re

from kart_tour_evidence import learning_preserved

_LOCAL_STUDENT_KEY = 'flutter.lumo_learning_local_student_id_v1'
_SKILLS_PREFIX = 'flutter.lumo_progress_skills::'
_LEGACY_SKILL_FIELDS = frozenset({
    'skillId', 'subject', 'unit', 'correct', 'wrong', 'hintCount',
    'currentStreak', 'currentMisses', 'difficulty', 'lastSeen',
})
_EVIDENCE_FIELDS = frozenset({
    'version', 'correct', 'wrong', 'correctStreak', 'wrongStreak',
})


def _strict_object(raw: str) -> dict:
    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError('Duplicate saved JSON key')
            result[key] = value
        return result

    def invalid_constant(_):
        raise ValueError('Non-finite saved JSON number')

    if type(raw) is not str:
        raise ValueError('Saved JSON must be a string')
    value = json.loads(raw, object_pairs_hook=unique_object,
                       parse_constant=invalid_constant)
    if type(value) is not dict:
        raise ValueError('Saved JSON must be an object')
    return value


def _legacy_evidence(record: dict, skill_id: str) -> dict:
    if type(record) is not dict or set(record) != _LEGACY_SKILL_FIELDS:
        raise ValueError('Unsupported 2017 skill schema')
    for key in ('skillId', 'subject', 'unit', 'lastSeen'):
        if type(record[key]) is not str or not record[key].strip():
            raise ValueError('Invalid legacy skill identity')
    if record['skillId'] != skill_id:
        raise ValueError('Skill map identity differs from its record')
    for key, minimum, maximum in (
        ('correct', 0, 10000), ('wrong', 0, 10000), ('hintCount', 0, 10000),
        ('currentStreak', 0, 1000), ('currentMisses', 0, 1000),
        ('difficulty', 1, 5),
    ):
        if type(record[key]) is not int or not minimum <= record[key] <= maximum:
            raise ValueError('Invalid legacy skill count')
    evidence = dict(version=1, correct=0, wrong=0, correctStreak=0, wrongStreak=0)
    if record['hintCount'] == 0:
        evidence.update(
            correct=record['correct'], wrong=record['wrong'],
            correctStreak=0 if record['currentMisses'] > 0 else min(
                record['currentStreak'], record['correct']),
            wrongStreak=0 if record['currentStreak'] > 0 else min(
                record['currentMisses'], record['wrong']),
        )
    return evidence


def _approved_migration_view(before: dict, after: dict,
                             versions: tuple[int, int]) -> tuple[dict, list[dict]]:
    """Validate the one reviewed additive migration; never edit source evidence.

    Only the existing primary local namespace can migrate during this proof.
    Foreign child records, all old fields and unrelated protected values remain
    subject to the original exact-byte preservation check.
    """
    if (type(versions) is not tuple or len(versions) != 2 or
            any(type(value) is not int for value in versions) or
            versions != (2017, 2018)):
        raise RuntimeError('Independent evidence migration is approved only for 2017 to 2018')
    owner = before.get(_LOCAL_STUDENT_KEY)
    if (type(owner) is not str or not re.fullmatch(r'local-[a-f0-9]{32}', owner) or
            after.get(_LOCAL_STUDENT_KEY) != owner):
        raise RuntimeError('The existing primary learning owner must be preserved')
    key = _SKILLS_PREFIX + owner
    old_skill_keys = {name for name in before if name.startswith('flutter.lumo_progress_skills')}
    new_skill_keys = {name for name in after if name.startswith('flutter.lumo_progress_skills')}
    if old_skill_keys != new_skill_keys:
        raise RuntimeError('The existing child skill namespaces must be preserved')
    if key not in before or key not in after:
        raise RuntimeError('The existing primary skill map must be preserved')
    if before[key] == after[key]:
        return after, []
    try:
        old, new = _strict_object(before[key]), _strict_object(after[key])
        if not old or set(old) != set(new):
            raise ValueError('Skill map membership changed')
        migrated = []
        for skill_id, original in old.items():
            expected = _legacy_evidence(original, skill_id)
            updated = new[skill_id]
            if (type(updated) is not dict or
                    set(updated) != _LEGACY_SKILL_FIELDS | {'independentEvidence'}):
                raise ValueError('Only independentEvidence may be added')
            for field, value in original.items():
                if type(updated[field]) is not type(value) or updated[field] != value:
                    raise ValueError('Existing skill field changed')
            evidence = updated['independentEvidence']
            if (type(evidence) is not dict or set(evidence) != _EVIDENCE_FIELDS or
                    any(type(value) is not int for value in evidence.values()) or
                    evidence != expected):
                raise ValueError('Independent evidence differs from the reviewed legacy conversion')
            migrated.append({'preference_key': key, 'skill_id': skill_id,
                             'added_independent_evidence': evidence})
    except (ValueError, TypeError, KeyError) as error:
        raise RuntimeError('Unsupported change to saved 2017 learning history') from error
    # The unmodified strict gate now checks every other byte. This local view is
    # created only after exact schema, identity, type and derived-value checks.
    comparison = dict(after)
    comparison[key] = before[key]
    return comparison, migrated


def require_in_place_update(before: dict, after: dict, expected_version: int) -> dict:
    try:
        old_code = int(before['versionCode'].split()[0])
        new_code = int(after['versionCode'].split()[0])
        if (not before['userId'] or not before['firstInstallTime'] or
                before['userId'] != after['userId'] or
                before['firstInstallTime'] != after['firstInstallTime'] or
                new_code != expected_version or new_code <= old_code):
            raise ValueError('installation identity or version changed incorrectly')
    except (KeyError, ValueError, TypeError, IndexError, AttributeError) as error:
        raise RuntimeError('Not the expected in-place Android update') from error
    return {'before_version': old_code, 'after_version': new_code,
            'userId': before['userId'], 'firstInstallTime': before['firstInstallTime']}


def require_learning_preserved(before: dict, after: dict, *,
                               migration_versions: tuple[int, int] | None = None) -> dict:
    """An empty wallet/profile alone never proves learned work survived."""
    comparison, migrated = (after, []) if migration_versions is None else (
        _approved_migration_view(before, after, migration_versions))
    report = learning_preserved(before, comparison)
    correct = 0
    try:
        for key, raw in before.items():
            if key.startswith('flutter.lumo_progress_skills'):
                for record in json.loads(raw).values():
                    value = record['correct']
                    if type(value) is not int or value < 0:
                        raise ValueError('Invalid correct-answer count')
                    correct += value
        wallet = json.loads(before['flutter.lumo_reward_wallet_v1'])
        if (correct < 1 or type(wallet['stars']) is not int or wallet['stars'] < 1 or
                type(wallet['xp']) is not int or wallet['xp'] < 1):
            raise ValueError('No actually earned learning progress and reward')
    except (KeyError, ValueError, TypeError, AttributeError) as error:
        raise RuntimeError('Meaningful saved learning and reward required') from error
    report.update(correct_answers_preserved=correct,
                  earned_stars=wallet['stars'], earned_xp=wallet['xp'])
    if migration_versions is not None:
        report['approved_migration'] = {
            'from_version': 2017, 'to_version': 2018,
            'kind': 'independentEvidence-v1', 'records': migrated,
            'existing_fields_preserved': True,
        }
    return report


def require_post_update_learning_preserved(before: dict, after_update: dict,
                                          current: dict, *,
                                          migration_versions: tuple[int, int] | None = None) -> dict:
    """Keep all later snapshots exact and retain the initial history proof."""
    if migration_versions is None:
        # Existing release probes retain their exact contract and report shape.
        return require_learning_preserved(before, current)
    exact = require_learning_preserved(after_update, current)
    history = require_learning_preserved(
        before, current, migration_versions=migration_versions)
    return {**history, 'after_update_exact': exact, 'baseline_history': history}
