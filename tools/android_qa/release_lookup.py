"""Resolve an existing unpublished release through the paginated GitHub list.

The releases/tags endpoint can return 404 for drafts whose tag has not been
published. Resolve the tag uniquely from the list, then read the release by ID.
"""
import json
import re
import subprocess

PAGE_SIZE = 100


def _get(endpoint):
    return json.loads(subprocess.check_output(['gh', 'api', endpoint], text=True))


def resolve_draft(repository, tag):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repository):
        raise ValueError('Invalid GitHub repository')
    if not isinstance(tag, str) or not tag:
        raise ValueError('Release tag must not be empty')
    matches = []
    page = 1
    while True:
        releases = _get(f'repos/{repository}/releases?per_page={PAGE_SIZE}&page={page}')
        if not isinstance(releases, list):
            raise ValueError('GitHub release list is not an array')
        matches.extend(release for release in releases if release.get('tag_name') == tag)
        if len(releases) < PAGE_SIZE:
            break
        page += 1
    if not matches:
        raise ValueError(f'Existing draft release not found: {tag}')
    if len(matches) != 1:
        raise ValueError(f'Ambiguous release tag: {tag}')
    listed = matches[0]
    if listed.get('draft') is not True:
        raise ValueError('The requested release is already published; an existing draft is required')
    release_id = listed.get('id')
    if type(release_id) is not int or release_id <= 0:
        raise ValueError('Draft release has no valid GitHub ID')
    # Fetch fresh assets and reject a release published/retagged since listing.
    release = _get(f'repos/{repository}/releases/{release_id}')
    if (release.get('id') != release_id or release.get('tag_name') != tag
            or release.get('draft') is not True):
        raise ValueError('Resolved release is no longer the requested unpublished draft')
    return release
