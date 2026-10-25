"""Strict read-only evidence checks for an Android in-place learning update."""
from __future__ import annotations

import json

from kart_tour_evidence import learning_preserved


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


def require_learning_preserved(before: dict, after: dict) -> dict:
    """An empty wallet/profile alone never proves learned work survived."""
    report = learning_preserved(before, after)
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
    return report
