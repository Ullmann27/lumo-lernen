"""Read-only contracts for actual Android C4 observations.

The production Dart engine remains the only game authority. This module checks
its original mailbox, persisted round, native geometry and touch acknowledgments;
it never chooses a bot move, awards a result or changes application data.
"""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import re
import xml.etree.ElementTree as ET

from PIL import Image
from native_surface_readiness import inspect_surface


WORKFLOW = '.github/workflows/lumo-connect-four-2020.yml'
BRANCH = 'integration/lumo-c4-connections-20261114'
QUALITY_BRANCH = 'work/lumo-play-quality-20261114'
ALLOWED_BRANCHES = frozenset((BRANCH, QUALITY_BRANCH,
                             'integration/lumo-agent-execution-20261114',
                             'integration/lumo-live-connections-20261114'))
ACCEPTED_BRANCHES = ALLOWED_BRANCHES
CANDIDATE = 'lumo-connect-four-2020-candidate'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
ROUND_PREFIX = 'flutter.lumo.connect_four.round.v1.'
PORTAL = 'Lumo 4 Gewinnt. Vier in einer Reihe · gegen Lumo oder zu zweit Spielen'
LEARNING_PREFIXES = (
    'flutter.lumo_progress', 'flutter.lumo_writing_progress', 'flutter.lumo_journal',
    'flutter.lumo_story_library', 'flutter.lumo_reading_sessions', 'flutter.lumo_attempt_log',
    'flutter.lumo_reward_wallet', 'flutter.lumo_school', 'flutter.lumo_learning',
    'flutter.lumo_legacy',
)
STATE_KEYS = ('token', 'owner', 'roundId', 'revision', 'recordRevision', 'ack',
              'rejected', 'paused', 'canDrop', 'turn', 'phase', 'twoPlayers',
              'level', 'columns', 'board', 'winningLine', 'rewarded')


def demand(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def integer(value, minimum=0, maximum=1_000_000_000) -> bool:
    return type(value) is int and minimum <= value <= maximum


def sha256(path: Path) -> str:
    with path.open('rb') as source:
        return hashlib.file_digest(source, 'sha256').hexdigest()


def artifact_binding(run: dict, artifacts: dict, jobs: dict, *, source: str,
                     run_id: int, attempt: int, artifact_id: int, digest: str,
                     native: str, version_name: str) -> dict:
    demand(bool(re.fullmatch('[a-f0-9]{40}', source)), 'Invalid exact host source')
    demand(bool(re.fullmatch('[a-f0-9]{40}', native)), 'Invalid exact configured native source')
    demand(bool(re.fullmatch(r'[0-9]+(?:\.[0-9]+){2}', version_name)), 'Invalid configured version name')
    demand(all(integer(v, 1, 2**63-1) for v in (run_id, attempt, artifact_id)), 'Invalid run/artifact identity')
    # upload-artifact exposes the hexadecimal digest; the original REST
    # artifact object prefixes the same bytes with "sha256:".
    if isinstance(digest, str) and re.fullmatch('[a-f0-9]{64}', digest):
        digest = 'sha256:' + digest
    demand(bool(re.fullmatch('sha256:[a-f0-9]{64}', digest)), 'Missing original upload digest')
    demand(run.get('id') == run_id and run.get('run_attempt') == attempt,
           'Candidate run or attempt differs')
    demand(run.get('head_sha') == source and run.get('head_branch') in ALLOWED_BRANCHES
           and run.get('event') == 'pull_request' and run.get('path') == WORKFLOW,
           'Candidate source/event/workflow differs')
    demand(run.get('repository', {}).get('full_name') == 'Ullmann27/lumo-lernen',
           'Candidate repository differs')
    rows = [row for row in artifacts.get('artifacts', []) if row.get('name') == CANDIDATE]
    demand(len(rows) == 1, 'Exactly one current C4 candidate artifact is required')
    row = rows[0]
    demand(row.get('id') == artifact_id and row.get('digest') == digest
           and row.get('expired') is False and integer(row.get('size_in_bytes'), 1),
           'Candidate artifact identity/digest/availability differs')
    bound_run = row.get('workflow_run', {})
    demand(bound_run.get('id') == run_id and bound_run.get('head_sha') == source,
           'Artifact belongs to another source/run')
    for name in ('android-host-compile', 'connect-four-runtime', 'verify-and-build'):
        found = [job for job in jobs.get('jobs', []) if job.get('name') == name]
        demand(len(found) == 1 and found[0].get('run_id') == run_id
               and found[0].get('head_sha') == source
               and found[0].get('run_attempt') == attempt
               and found[0].get('conclusion') == 'success',
               'Required current source job did not succeed: ' + name)
    return {'host_source': source, 'native_source': native, 'versionCode': 2020,
            'versionName': version_name, 'workflow': WORKFLOW, 'run_id': run_id,
            'run_attempt': attempt, 'candidate_artifact_id': artifact_id,
            'candidate_artifact_digest': digest}


def preferences(raw: str) -> dict:
    tree = ET.fromstring(raw)
    demand(tree.tag == 'map', 'Original SharedPreferences map is missing')
    names = [node.get('name') for node in tree]
    demand(len(names) == len(set(names)) and all(names), 'Duplicate/unnamed preference entry')
    return {node.get('name'): node.text if node.tag == 'string' else node.get('value') for node in tree}


def owner_from_preferences(prefs: dict) -> str:
    selected = (prefs.get('flutter.lumo_school_active_student_v1') or '').strip()
    owner_id = selected or (prefs.get('flutter.lumo_learning_local_student_id_v1') or '').strip()
    demand(bool(owner_id) and len(owner_id) <= 512, 'Actual active learning owner is missing')
    return hashlib.sha256(owner_id.encode('utf-8')).hexdigest()


def persisted_round(prefs: dict, state: dict) -> dict:
    demand(owner_from_preferences(prefs) == state['owner'], 'C4 belongs to a different child')
    raw = prefs.get(ROUND_PREFIX + state['owner'])
    demand(isinstance(raw, str), 'Original persisted Dart round is missing')
    record = json.loads(raw)
    demand(isinstance(record, dict) and record.get('schema') == 1, 'Invalid stored round schema')
    for source, stored in (('roundId', 'id'), ('owner', 'owner'), ('columns', 'columns'),
                           ('recordRevision', 'revision'), ('twoPlayers', 'twoPlayers'),
                           ('level', 'level'), ('rewarded', 'rewarded')):
        demand(state[source] == record.get(stored), 'Mailbox differs from durable Dart round: ' + source)
    return record


def validate_state(state: dict) -> None:
    demand(isinstance(state, dict) and state.get('schema') == 1
           and state.get('game') == 'connect_four', 'Wrong C4 mailbox schema/game')
    for key, length in (('token', 32), ('roundId', 32), ('owner', 64)):
        demand(isinstance(state.get(key), str) and bool(re.fullmatch('[a-f0-9]{%d}' % length, state[key])),
               'Invalid C4 identity: ' + key)
    for key in ('revision', 'recordRevision', 'ack', 'rejected'):
        demand(integer(state.get(key), 1 if key.endswith('evision') else 0), 'Invalid counter: ' + key)
    for key in ('paused', 'exit', 'canDrop', 'twoPlayers', 'rewarded'):
        demand(type(state.get(key)) is bool, 'Invalid actual boolean: ' + key)
    demand(state.get('error') is None and state.get('exit') is False,
           'C4 controller reports an error or closed state')
    demand(state.get('phase') in ('playing', 'won', 'draw')
           and integer(state.get('turn'), 1, 2)
           and state.get('level') in ('leicht', 'mittel', 'schlau'), 'Invalid C4 phase/turn/level')
    history, board = state.get('columns'), state.get('board')
    demand(isinstance(history, list) and len(history) <= 42
           and all(integer(c, 0, 6) for c in history), 'Invalid authoritative history')
    demand(isinstance(board, list) and len(board) == 42
           and all(integer(c, 0, 2) for c in board), 'Invalid authoritative board')
    # Only replay persisted gravity/history for consistency; no bot/win/reward logic.
    expected, heights = [0] * 42, [0] * 7
    for index, column in enumerate(history):
        demand(heights[column] < 6, 'History exceeds a real column')
        expected[(5 - heights[column]) * 7 + column] = index % 2 + 1
        heights[column] += 1
    demand(board == expected, 'Rendered board disagrees with persisted drop history')
    demand(isinstance(state.get('winningLine'), list), 'Missing authoritative winning-line field')
    demand(isinstance(state.get('validColumns'), list)
           and state['validColumns'] == [c for c in range(7) if heights[c] < 6],
           'Actual available columns disagree with the persisted board')


def vector(value, length: int, label: str) -> list[float]:
    demand(isinstance(value, list) and len(value) == length
           and all(type(v) in (int, float) and math.isfinite(v) for v in value),
           'Invalid original geometry: ' + label)
    return [float(v) for v in value]


def device_density(raw: str) -> float:
    override = re.findall(r'(?m)^Override density:\s*(\d+)\s*$', raw)
    physical = re.findall(r'(?m)^Physical density:\s*(\d+)\s*$', raw)
    values = override or physical
    demand(len(values) == 1 and int(values[0]) > 0, 'Actual Android density is ambiguous')
    return min(4, max(.75, int(values[0]) / 160))


def rectangle(value, label: str) -> list[float]:
    x, y, w, h = vector(value, 4, label)
    demand(x >= 0 and y >= 0 and w > 0 and h > 0, 'Invalid rectangle: ' + label)
    return [x, y, w, h]


def validate_layout(layout: dict, state: dict, pixels: tuple[int, int], pid: int,
                    observed_density: float) -> dict:
    validate_state(state)
    demand(layout.get('schema') == 1 and layout.get('game') == 'connect_four'
           and layout.get('settled') is True and layout.get('ui_visible') is True
           and layout.get('pending') == 0 and layout.get('pid') == pid
           and integer(pid, 1) and integer(layout.get('layout_sequence'), 1)
           and integer(layout.get('ticks_msec'), 1), 'No current settled native C4 layout')
    demand(layout.get('observation_source') == 'android_window_insets',
           'Actual Android window observation is required')
    for key in STATE_KEYS:
        demand(layout.get(key) == state.get(key), 'Layout/mailbox revision differs: ' + key)
    density = layout.get('density')
    demand(type(density) in (int, float) and math.isfinite(density)
           and .75 <= density <= 4 and abs(density - observed_density) < .01,
           'Layout differs from the actual Android density')
    window = vector(layout.get('window_px'), 2, 'window_px')
    android = layout.get('android_observation', {})
    decor = vector(android.get('decor_size'), 2, 'decor_size')
    view = vector(android.get('view_size'), 2, 'view_size')
    render = rectangle(android.get('render_rect'), 'render_rect')
    demand(decor == list(pixels) and min(window) > 0 and min(view) > 0
           and max(abs(a-b) for a, b in zip(window, view)) <= 1,
           'Native window/decor differs from current original screenshot')
    rx, ry, rw, rh = render
    demand(rx + rw <= pixels[0] + .1 and ry + rh <= pixels[1] + .1,
           'Actual render rectangle exceeds decor screenshot')
    sx, sy = rw / window[0], rh / window[1]
    demand(abs(sx - 1) < .01 and abs(sy - 1) < .01, 'Unexpected Android pixel scaling')
    safe = rectangle(layout.get('safe_rect'), 'safe_rect')
    demand(safe[0] + safe[2] <= window[0] + .1
           and safe[1] + safe[3] <= window[1] + .1, 'Safe area exceeds native window')
    buttons = layout.get('buttons')
    demand(isinstance(buttons, list) and len(buttons) == 15
           and all(isinstance(b, dict) for b in buttons), 'Missing original C4 control roster')
    ids = [b.get('id') for b in buttons]
    demand(len(set(ids)) == len(ids) and set(ids) == {
        'back', 'pause', 'resume', 'restart', 'mode',
        *('column_' + str(i) for i in range(7)), 'level_leicht', 'level_mittel', 'level_schlau'},
        'Ambiguous or incomplete real control identities')
    return {'offset': [rx, ry], 'scale': [sx, sy], 'safe': safe, 'density': density}


def touch_target(layout: dict, state: dict, pixels: tuple[int, int], pid: int,
                 density: float, control: str) -> dict:
    mapping = validate_layout(layout, state, pixels, pid, density)
    rows = [row for row in layout['buttons'] if row['id'] == control]
    demand(len(rows) == 1, 'No unique actual C4 target')
    row = rows[0]
    demand(row.get('visible') is True and row.get('enabled') is True
           and row.get('clipped') is False, 'Target is hidden, disabled or clipped')
    rect = rectangle(row.get('rect_px'), control)
    hit = rectangle(row.get('hit_rect_px'), control + ' hit')
    demand(max(abs(a-b) for a, b in zip(rect, hit)) < .1,
           'Actual hit region does not contain the complete control')
    x, y, w, h = hit
    ax, ay, aw, ah = mapping['safe']
    demand(x >= ax - .1 and y >= ay - .1 and x + w <= ax + aw + .1
           and y + h <= ay + ah + .1, 'Target intersects the observed unsafe area')
    demand(min(w, h) / density >= 47.99, 'Actual target is smaller than 48dp')
    ox, oy = mapping['offset']; sx, sy = mapping['scale']
    bounds = [ox + x*sx, oy + y*sy, ox + (x+w)*sx, oy + (y+h)*sy]
    demand(0 <= bounds[0] < bounds[2] <= pixels[0]
           and 0 <= bounds[1] < bounds[3] <= pixels[1], 'Target exceeds screenshot')
    expected = {'back': 'Zurück', 'pause': 'Pause', 'resume': 'Fortsetzen'}
    if control.startswith('column_'):
        expected[control] = str(int(control[7:]) + 1) + ' ↓'
    demand(control in expected and row.get('text') == expected[control],
           'Actual target caption differs from the published C4 control')
    return {'id': control, 'text': row['text'], 'bounds': bounds,
            'point': [round((bounds[0]+bounds[2])/2), round((bounds[1]+bounds[3])/2)],
            'size_dp': [w / density, h / density]}


def stable_target(first: dict, second: dict) -> dict:
    demand(first['state'] == second['state'], 'Authoritative state changed before touch')
    for key in ('pid', 'density', 'pixels'):
        demand(first[key] == second[key], 'Current surface identity changed before touch')
    demand(first['target']['id'] == second['target']['id']
           and max(abs(a-b) for a, b in zip(first['target']['bounds'], second['target']['bounds'])) <= 2,
           'Actual target moved between the two observations')
    demand(second['lifecycle']['stamp'] > first['lifecycle']['stamp'],
           'No actual continuing visible Activity heartbeat')
    return second['target']


def acknowledged(before: dict, after: dict, request: dict, action: str) -> None:
    validate_state(before); validate_state(after)
    for key in ('owner', 'roundId', 'token', 'twoPlayers', 'level'):
        demand(before[key] == after[key], 'Unexpected C4 session/round change: ' + key)
    demand(request.get('action') == action and request.get('token') == before['token']
           and request.get('roundId') == before['roundId']
           and request.get('revision') == before['revision']
           and integer(request.get('sequence'), 1)
           and request['sequence'] == before['ack'] + 1 == after['ack']
           and after['revision'] > before['revision']
           and after['rejected'] == before['rejected'],
           'Touch lacks the matching positive Dart acknowledgment')
    if action == 'drop':
        column = request.get('column')
        demand(integer(column, 0, 6) and before['canDrop'] and not before['paused']
               and not before['twoPlayers'] and before['turn'] == 1,
               'Drop was not a permitted actual child turn')
        demand(after['columns'][:len(before['columns'])] == before['columns']
               and len(after['columns']) == len(before['columns']) + 2
               and after['columns'][len(before['columns'])] == column
               and after['recordRevision'] == before['recordRevision'] + 2
               and after['turn'] == 1 and after['canDrop'] and not after['paused'],
               'Actual child drop and subsequent Dart bot response are missing')
    elif action in ('pause', 'resume'):
        demand(after['columns'] == before['columns'] and after['board'] == before['board']
               and after['recordRevision'] == before['recordRevision']
               and after['paused'] is (action == 'pause'),
               'Pause/resume changed the durable board or missed its actual state')
    else:
        raise ValueError('Unsupported transition contract')


def paused_unchanged(first: dict, second: dict, elapsed: float) -> None:
    demand(elapsed >= 1 and first['state']['paused'] is True
           and first['state'] == second['state'], 'Actual pause did not hold the same state')
    demand(second['lifecycle']['stamp'] > first['lifecycle']['stamp'],
           'Paused native Activity heartbeat stopped')


def reopened(previous: dict, current: dict) -> None:
    validate_state(previous); validate_state(current)
    demand(previous['token'] != current['token'], 'Reopen reused the closed private session')
    for key in ('owner', 'roundId', 'columns', 'board', 'recordRevision', 'twoPlayers',
                'level', 'phase', 'rewarded', 'winningLine'):
        demand(previous[key] == current[key], 'Reopen changed the persisted round: ' + key)


def board_pixels(path: Path, layout: dict, state: dict, pid: int, density: float) -> dict:
    with Image.open(path) as original:
        demand(original.format == 'PNG', 'Original screenshot is not PNG')
        original.load()
        image = original.convert('RGB')
    mapping = validate_layout(layout, state, image.size, pid, density)
    if state['paused']:
        return {'sha256':sha256(path), 'pixels':list(image.size), 'occupied_cells':[],
                'scope':'Pause overlay is visible; this frame does not prove covered disc pixels'}
    cells = layout.get('cells')
    demand(isinstance(cells, list) and len(cells) == 42, 'Missing native projected board cells')
    identities = [(c.get('row'), c.get('column')) for c in cells if isinstance(c, dict)]
    demand(len(identities) == 42 and set(identities) == {(r,c) for r in range(6) for c in range(7)},
           'Projected board cells are duplicated or incomplete')
    observations = []
    ox, oy = mapping['offset']; sx, sy = mapping['scale']
    for cell in cells:
        piece = state['board'][cell['row']*7 + cell['column']]
        demand(cell.get('piece') == piece, 'Pixel geometry belongs to a different board')
        quad = cell.get('disc_quad')
        demand(isinstance(quad, list) and len(quad) == 4, 'Missing actual projected disc corners')
        points = [vector(point, 2, 'disc_quad') for point in quad]
        cx = ox + sum(p[0] for p in points) / 4 * sx
        cy = oy + sum(p[1] for p in points) / 4 * sy
        radius = min(max(p[0] for p in points)-min(p[0] for p in points),
                     max(p[1] for p in points)-min(p[1] for p in points)) * .15
        demand(radius >= 1 and radius <= cx < image.width-radius
               and radius <= cy < image.height-radius, 'Projected disc has no visible interior')
        if piece == 0:
            continue
        box = (math.floor(cx-radius), math.floor(cy-radius), math.ceil(cx+radius), math.ceil(cy+radius))
        sampled = list(image.crop(box).getdata())
        cyan = sum(g > r*1.15 and b > r*1.15 and max(r,g,b) > 70 for r,g,b in sampled)
        gold = sum(r > b*1.15 and g > b*1.1 and max(r,g,b) > 70 for r,g,b in sampled)
        matching = cyan if piece == 1 else gold
        demand(matching / len(sampled) >= .45, 'Original pixels do not show the acknowledged C4 disc')
        observations.append({'row':cell['row'], 'column':cell['column'], 'piece':piece,
                             'sample_box':list(box), 'matching_pixels':matching,
                             'sampled_pixels':len(sampled)})
    demand(len(observations) == len(state['columns']), 'Missing actual occupied-cell pixel evidence')
    return {'sha256':sha256(path), 'pixels':list(image.size), 'occupied_cells':observations,
            'scope':'Projected visible cyan/gold disc interiors; no FPS or visual-style approval'}


def learning_unchanged(before: dict, after: dict) -> None:
    for key in ('flutter.lumo_active_profile',):
        first, last = json.loads(before.get(key, '{}')), json.loads(after.get(key, '{}'))
        demand(first and all(first.get(k) == last.get(k) for k in ('id','name','age','grade','createdAt')),
               'Active child profile changed')
    selected = {k:v for k,v in before.items() if k.startswith(LEARNING_PREFIXES)}
    demand(selected and all(after.get(k) == v for k,v in selected.items()),
           'Actual previous learning/rewards/ownership changed during C4')


def flutter_control(nodes: list, label: str, pixels: tuple[int, int], density: float) -> dict:
    found = []
    for node in nodes:
        values = (node.get('text', ''), node.get('content-desc', ''))
        if not any(label == value or label in value.split('\n') for value in values):
            continue
        if (node.get('package') != PACKAGE or node.get('enabled') != 'true'
                or node.get('clickable') != 'true'):
            continue
        raw = node.get('bounds', '')
        if not re.fullmatch(r'\[\d+,\d+\]\[\d+,\d+\]', raw):
            continue
        x0, y0, x1, y1 = map(int, re.findall(r'\d+', raw))
        if (0 <= x0 < x1 <= pixels[0] and 0 <= y0 < y1 <= pixels[1]
                and min(x1-x0, y1-y0) / density >= 47.99):
            found.append({'label':label, 'bounds':[x0,y0,x1,y1],
                          'point':[(x0+x1)//2,(y0+y1)//2]})
    demand(len(found) == 1, 'No unique complete enabled Flutter control: ' + label)
    return found[0]


def safe_member(root: Path, relative: str) -> Path:
    demand(isinstance(relative, str) and relative and '\\' not in relative,
           'Invalid evidence path')
    name = Path(relative)
    demand(not name.is_absolute() and relative == name.as_posix()
           and all(p not in ('..','.') for p in name.parts),
           'Evidence path escapes its source')
    current = root
    for part in name.parts:
        current = current / part
        demand(not current.is_symlink(), 'Evidence cannot use a symlink')
    demand(current.is_file(), 'Original evidence member is missing: ' + relative)
    return current


def verify_inventory(root: Path, inventory: list[dict]) -> None:
    demand(isinstance(inventory, list) and all(isinstance(row, dict) for row in inventory),
           'Missing original evidence inventory')
    names = [row.get('path') for row in inventory]
    demand(len(names) == len(set(names)) and names, 'Duplicate/empty original evidence inventory')
    for row in inventory:
        member = safe_member(root, row['path'])
        demand(member.stat().st_size == row.get('bytes') and sha256(member) == row.get('sha256'),
               'Original evidence bytes changed: ' + row['path'])
    actual = set()
    for member in root.rglob('*'):
        demand(not member.is_symlink(), 'Evidence cannot contain symlinks')
        if member.is_file() and member != root / 'c4-result.json':
            actual.add(member.relative_to(root).as_posix())
    demand(set(names) == actual, 'Evidence inventory does not cover the complete original directory')


def runtime_errors(text: str) -> list[dict]:
    return [{'line':number, 'text':line} for number,line in enumerate(text.splitlines(),1)
            if any(token in line for token in ('FATAL EXCEPTION','Fatal signal','am_anr:',
                   'SCRIPT ERROR:', 'Parse Error:', 'GL_MAX_FRAGMENT_UNIFORM_VECTORS'))
            or re.search(r'(?i)\bgodot\b.*\bERROR:', line)]


def read_original(root: Path, name: str, *, empty_ok=False, command=None) -> str:
    path = safe_member(root, name)
    raw = path.read_text(encoding='utf-8')
    demand(empty_ok or bool(raw), 'Original reply is empty: ' + name)
    if name.endswith('.stdout'):
        metadata = json.loads(safe_member(root, name[:-7]+'.json').read_text())
        stderr = safe_member(root, name[:-7]+'.stderr')
        demand(metadata.get('returncode') == 0 and not stderr.read_bytes(),
               'Original read/dispatch did not succeed: ' + name)
        demand(metadata.get('stdout_bytes') == path.stat().st_size
               and metadata.get('stdout_sha256') == sha256(path)
               and metadata.get('stderr_bytes') == 0
               and metadata.get('stderr_sha256') == hashlib.sha256(b'').hexdigest(),
               'Original command identity differs')
        if command is not None:
            demand(metadata.get('command') == command, 'Original command reads another source: ' + name)
    return raw


def checked_observation(root: Path, name: str) -> dict:
    demand(bool(re.fullmatch(r'[a-z0-9-]+', name)), 'Invalid original observation id')
    item = json.loads(safe_member(root, 'observations/' + name + '.json').read_text())
    demand(item.get('id') == name, 'Original observation id differs')
    raw = item['raw']
    mailbox = f'/data/user/0/{PACKAGE}/files/lumo_connect_four_session_v1/{item["state"]["token"]}'
    for key in ('state','layout','lifecycle'):
        source = (f'/data/user/0/{PACKAGE}/files/connect_four_layout_v1.json' if key == 'layout'
                  else mailbox + '/' + key + '.json')
        demand(json.loads(read_original(root, raw[key], command=['adb','exec-out','cat',source])) == item[key],
               'Observation differs from original ' + key)
    for key in ('state','layout'):
        demand(json.loads(read_original(root, raw[key+'_after'])) == item[key], 'Frame crosses a state change')
    demand(int(read_original(root, raw['native_pid'], command=['adb','shell','pidof',PACKAGE+':lumo_game'])) == item['pid']
           and int(read_original(root, raw['host_pid'], command=['adb','shell','pidof',PACKAGE])) == item['host_pid']
           and item['pid'] != item['host_pid'], 'Real process identity differs')
    activity = read_original(root, raw['activity'])
    resumed = [line for line in activity.splitlines() if 'mResumedActivity' in line or 'topResumedActivity' in line]
    demand(resumed and all('ConnectFourGameActivity' in line for line in resumed), 'Actual C4 foreground missing')
    demand('ConnectFourAuthorityService' in read_original(root, raw['authority']), 'Real Binder authority missing')
    now = int(read_original(root, raw['clock'], command=['adb','shell','date','+%s%3N']))
    demand(now == item['device_clock_ms'] and item['lifecycle']['active'] is True
           and 0 <= now - item['lifecycle']['stamp'] < 2500, 'Actual lifecycle observation is stale')
    persisted_round(preferences(read_original(root, raw['preferences'])), item['state'])
    demand(device_density(read_original(root, raw['density'], command=['adb','shell','wm','density']))
           == item['density'], 'Original device density differs')
    frame = safe_member(root, item['frame'])
    demand(sha256(frame) == item['frame_sha256'], 'Current original screenshot differs')
    surface = inspect_surface(frame, orientation='responsive')
    demand(surface['acceptable_for_target_sampling'] and surface == item['surface'],
           'Original C4 surface was incomplete')
    result = board_pixels(frame, item['layout'], item['state'], item['pid'], item['density'])
    demand(result == item['visual'] and result['pixels'] == item['pixels'], 'Original pixel replay differs')
    if 'target' in item:
        demand(touch_target(item['layout'], item['state'], tuple(item['pixels']), item['pid'], item['density'],
                            item['target']['id']) == item['target'], 'Observed real target differs')
    return item


def checked_dispatch(root: Path, touch: dict) -> None:
    x, y = map(str, touch['target']['point'])
    reply = read_original(root, touch['command_original'], empty_ok=True,
                          command=['adb','shell','input','swipe',x,y,x,y,'120'])
    demand(not reply.strip(), 'Actual touch dispatch returned unexpected output')


def checked_native_touch(root: Path, name: str, observations: dict, before: dict, control: str) -> None:
    touch = json.loads(safe_member(root, name).read_text())
    first, second = observations[touch['first']], observations[touch['second']]
    demand(second['id'] == before['id'] and stable_target(first, second) == touch['target']
           and touch['target']['id'] == control, 'Actual two-frame control differs from the touch')
    checked_dispatch(root, touch)


def checked_flutter_touch(root: Path, name: str, label: str) -> None:
    touch = json.loads(safe_member(root, name).read_text())
    for frame in (touch['first'], touch['second']):
        screenshot = safe_member(root, frame['capture']['file'])
        demand(sha256(screenshot) == frame['capture']['sha256'], 'Original Flutter target frame changed')
        with Image.open(screenshot) as image:
            image.load()
            demand(image.format == 'PNG', 'Flutter target frame is not an original PNG')
            pixels = image.size
        density = device_density(read_original(root, frame['density'], command=['adb','shell','wm','density']))
        ui = ET.fromstring(safe_member(root, frame['ui']).read_text())
        demand(ui.tag == 'hierarchy', 'Original Flutter hierarchy is missing')
        target = flutter_control(list(ui.iter('node')), label, pixels, density)
        demand(target == touch['target'], 'Actual Flutter target differs between original frames')
    demand(touch['first']['ui'] != touch['second']['ui']
           and touch['first']['capture']['file'] != touch['second']['capture']['file']
           and touch['second']['observed_monotonic'] > touch['first']['observed_monotonic'],
           'The actual Flutter touch lacks two distinct current observations')
    checked_dispatch(root, touch)


def verify_report(root: Path, binding: dict, identity: dict) -> dict:
    report = json.loads(safe_member(root, 'c4-result.json').read_text())
    demand(report.get('schema') == 1 and report.get('status') == 'PASS'
           and report.get('binding') == binding and report.get('identity') == identity,
           'C4 report is missing, failed or bound to a different candidate')
    verify_inventory(root, report['originals'])
    observations = {name:checked_observation(root, name) for name in report['observations']}
    demand(len(observations) == len(report['observations']), 'Duplicate C4 observations')
    initial = observations[report['initial']]
    demand(initial['state']['columns'] == [] and initial['state']['twoPlayers'] is False,
           'No untouched actual initial single-player round')
    checked_flutter_touch(root, report['entry_touch'], PORTAL)
    transitions = report['transitions']
    demand([step.get('action') for step in transitions] == ['drop','pause','resume','drop','pause','pause'],
           'Required child/bot/pause/resume sequence is incomplete')
    previous = initial
    route = report['reopen']
    closed, opened = observations[route['closed']], observations[route['opened']]
    for index, step in enumerate(transitions):
        before, after = observations[step['before']], observations[step['after']]
        if index == 5:
            previous = opened
        demand(before['state'] == previous['state'] and before['pid'] == previous['pid']
               and before['host_pid'] == initial['host_pid'], 'C4 transition chain changed authority or round')
        request = json.loads(read_original(root, step['request']))
        acknowledged(before['state'], after['state'], request, step['action'])
        expected_control = {'drop':'column_' + str(request.get('column')),
                            'pause':'pause','resume':'resume'}[step['action']]
        checked_native_touch(root, step['touch'], observations, before, expected_control)
        previous = after
    hold = report['pause_hold']
    demand(hold['first'] == transitions[1]['after']
           and observations[hold['second']]['state'] == observations[hold['first']]['state'],
           'Pause hold belongs to another transition')
    demand(hold['elapsed'] == observations[hold['second']]['observed_monotonic']
           - observations[hold['first']]['observed_monotonic'], 'Pause elapsed time differs')
    paused_unchanged(observations[hold['first']], observations[hold['second']], hold['elapsed'])
    reopened(closed['state'], opened['state'])
    demand(closed['pid'] != opened['pid'], 'Actual native process did not change on reopen')
    demand(len(closed['state']['columns']) == 4 and opened['host_pid'] == initial['host_pid'],
           'Reopen did not preserve both actual child/bot pairs and the Flutter authority')
    checked_flutter_touch(root, route['touch'], PORTAL)
    demand(len(report['returns']) == 2, 'Both actual Flutter returns are mandatory')
    demand(report['returns'][0]['before'] == closed['id'], 'Reopen does not follow the actual first return')
    for index, returned in enumerate(report['returns']):
        before = observations[returned['before']]
        demand(before['state']['paused'], 'Return bypassed the proved pause')
        expected = observations[transitions[4 if index == 0 else 5]['after']]
        demand(before['state'] == expected['state'] and before['pid'] == expected['pid'],
               'Return belongs to a different C4 sequence')
        checked_native_touch(root, returned['touch'], observations, before, 'back')
        # pidof correctly returns 1 after process exit; retain that original
        # failure status as positive absence only for this one known command.
        pid_path = safe_member(root, returned['native_exit'])
        pid_meta = json.loads(safe_member(root, returned['native_exit'][:-7]+'.json').read_text())
        pid_stderr = safe_member(root, returned['native_exit'][:-7]+'.stderr')
        demand(not pid_path.read_bytes() and not pid_stderr.read_bytes()
               and pid_meta['returncode'] == 1
               and pid_meta['command'] == ['adb','shell','pidof',PACKAGE+':lumo_game'],
               'Native process absence is not actually observed')
        demand(not read_original(root, returned['closed_mailbox'], empty_ok=True).strip(),
               'Old private C4 mailbox is still live')
        activity = read_original(root, returned['activity'])
        resumed = [line for line in activity.splitlines() if 'mResumedActivity' in line or 'topResumedActivity' in line]
        demand(resumed and all('MainActivity' in line and PACKAGE in line for line in resumed),
               'Actual Flutter foreground is missing')
        demand(persisted_round(preferences(read_original(root, returned['preferences'])), before['state'])
               == returned['round'], 'Actual returned round differs')
        ui = ET.fromstring(safe_member(root, returned['returned_ui']).read_text())
        labels = '\n'.join(node.get('text','')+'\n'+node.get('content-desc','') for node in ui.iter('node'))
        demand('Spiel pausiert' in labels and 'Fortsetzen' in labels, 'Actual paused Flutter UI missing')
        frame = safe_member(root, returned['frame']['file'])
        demand(sha256(frame) == returned['frame']['sha256'], 'Returned original Flutter frame differs')
        with Image.open(frame) as png:
            png.load()
            demand(png.format == 'PNG' and png.width > 100 and png.height > 100, 'Invalid return PNG')
        checked_flutter_touch(root, returned['to_games_touch'], 'Zur Spieleauswahl')
    learning_unchanged(preferences(read_original(root, report['preferences_before'])),
                       preferences(read_original(root, report['preferences_after'])))
    errors = runtime_errors(read_original(root, report['original_logcat']))
    demand(not errors and report.get('fatal_entries') == [], 'Original Android/engine failure remains')
    demand(read_original(root, report['android_sdk_original']).strip() == '35', 'Wrong actual Android API')
    return {'status':'PASS','versionCode':2020,'binding':binding,
            'actual_child_drops':2, 'actual_bot_responses':2,
            'same_round_reopened':True,'native_returns':2,'api':35,
            'original_files':len(report['originals']), 'observations':len(observations),
            'scope':'C4 candidate device test only; no release, physical ARM64, API37 or FPS acceptance'}
