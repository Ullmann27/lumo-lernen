from __future__ import annotations
import hashlib, json, platform, stat, zipfile
from datetime import datetime, timezone
from pathlib import Path
from PIL import Image

ROOT = Path('/dev/shm/lumo-village-6b-retry-original-review-909ddb52fe7b')
ORIGINALS = ROOT / 'originals'
ARCHIVE = ROOT / 'archive'
ARCHIVE.mkdir(exist_ok=True)
PREFIX = 'docs/evidence/village-6b-cleanup-originals-43634531860'
QA = '3cae9c407a6eef1970e24bc9a61516b13fe0af52'
QA_TREE = '16dbaa5024c0bba79c9ab8a9d23b9025a0c2f5d7'
APK = '6b3047b7979dfb86d837e74a21b0fd890e4f9e66'
NATIVE = '84789d0c2c6fb4b6ecd2897ce1951b89f958b604'
BASE = '8a45f0028cb46be3d050c7d9cad5d4513423ce25'

def load(path):
    return json.loads(path.read_text())

def blob(data):
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()

def record(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(), 'git_blob': blob(data)}

def write(name, value):
    p = ARCHIVE / name
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + '\n')
    return p

replay = load(ROOT / 'replay/independent-reader-result.json')
manifest = load(ROOT / 'artifact-manifest.json')
c4 = load(ORIGINALS / 'c4/c4-result.json')
village = load(ORIGINALS / 'village/village-result.json')
main = load(ORIGINALS / 'main/tour-result.json')
village_journal = load(ORIGINALS / 'village/returned-flutter-observation.json')
pixel_comparison = load(ROOT / 'replay/first-return-original-pixel-comparison.json')
before = load(ROOT / 'replay/original-files-before.json')
reader_before = load(ROOT / 'replay/reader-source-before.json')['files']

# Archive immutable originals as bytes; do not rerun readers or touch source files.
current = {}
for p in sorted(ORIGINALS.rglob('*')):
    if p.is_file():
        rel = p.relative_to(ORIGINALS).as_posix()
        current[rel] = {**record(p), 'mode': stat.S_IMODE(p.stat().st_mode)}
assert len(current) == 2875
for rel, row in before.items():
    assert current[rel]['sha256'] == row['sha256'] and current[rel]['bytes'] == row['bytes']
    assert current[rel]['mode'] == row['mode']
assert set(current) == set(before)
reader_current = {}
for rel, row in reader_before.items():
    p = ROOT / 'reader' / rel
    reader_current[rel] = {**record(p), 'mode': stat.S_IMODE(p.stat().st_mode)}
    assert all(reader_current[rel][k] == row[k] for k in ('bytes', 'sha256', 'git_blob', 'mode'))

non_png = [rel for rel in current if not rel.lower().endswith('.png')]
zip_path = ARCHIVE / 'original-non-png-files.zip'
with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for rel in non_png:
        info = zipfile.ZipInfo(rel, date_time=(2026, 11, 14, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = (stat.S_IFREG | 0o444) << 16
        info.create_system = 3
        z.writestr(info, (ORIGINALS / rel).read_bytes())
with zipfile.ZipFile(zip_path) as z:
    assert z.testzip() is None and z.namelist() == non_png
    for rel in non_png:
        b = z.read(rel)
        assert len(b) == current[rel]['bytes'] and hashlib.sha256(b).hexdigest() == current[rel]['sha256']
non_png_record = {**record(zip_path), 'file_count': len(non_png), 'expanded_bytes': sum(current[p]['bytes'] for p in non_png), 'all_member_crc_and_original_bytes_verified': True}
write('original-non-png-archive-manifest.json', {'scope': 'Derived lossless container of every non-PNG original; contents unchanged, ZIP container newly composed.', 'archive': non_png_record, 'files': {p: current[p] for p in non_png}})

manual = {
 'c4/initial-015.png': 'Empty native 7 by 6 board; Back, Pause and seven column controls visible.',
 'c4/child-first-confirmed-004.png': 'First child and bot pair visible in column 4; zero-based columns [3,3].',
 'c4/pause-first-confirmed-001.png': 'Native pause controls visible; the same two counters remain behind the overlay.',
 'c4/child-second-confirmed-003.png': 'Two cyan child counters and two yellow bot counters visible; zero-based columns [3,3,2,3].',
 'c4/pause-before-return-confirmed-001.png': 'Native pause with the same four counters behind the overlay.',
 'c4/reopened-009.png': 'Reopened native board shows the same four counters and seven column controls; new PID and token are established by original state/process files.',
 'c4/return-first-flutter.png': 'Early stale native pause frame with Bitte kurz warten; this is not visual proof of Flutter, despite the original filename.',
 'c4/return-first-to-games-00-frame.png': 'Later true Flutter pause: Spiel pausiert, Fortsetzen, Zur Spieleauswahl and Neu starten are visible.',
 'c4/return-first-to-games-01-frame.png': 'Second original target frame is byte-identical to the first target frame; the actual subsequent touch is journaled separately.',
 'c4/return-first-games-001-frame.png': 'Actual Flutter games screen with the 4. Gewinnt portal and selected Spielen tab visible after the target touch.',
 'c4/return-final-flutter.png': 'Actual Flutter pause card after the second native return.',
 'c4/return-final-games-001-frame.png': 'Actual Flutter games screen after the final Zur Spieleauswahl touch; 4. Gewinnt portal and Spielen tab visible.',
 'village/village-ready-10.png': 'Actual landscape village HUD with Spiele, LUMO DORFWELT, two residents, nine plots and Nächster Tag. The large HUD occupies most of this original frame; this is not a whole-village visual-composition acceptance.',
 'village/returned-flutter-observations/attempt-1/returned-flutter-frame.png': 'Rejected first village return capture still shows the native village HUD; retained unchanged.',
 'village/returned-flutter-frame.png': 'Accepted later actual Flutter Spielewelt with Dorfwirtschaft tile and selected Spielen tab.',
 'main/21_race_driving_late_2.png': 'Actual API35 kart frame: green kart with fox, road, minimap and driving controls; HUD shows lap 1/2, position 6/6 and 177 km/h. This static frame proves no real-world speed, completed race or FPS.',
}
selected = set(manual)
selected.update('c4/' + row['frame'] for row in replay['all_board_observations'])
selected.update({
 'c4/return-first-games-000-frame.png',
 'c4/return-final-to-games-00-frame.png',
 'c4/return-final-to-games-01-frame.png',
 'c4/return-final-games-000-frame.png',
 'village/returned-flutter-observations/attempt-2/returned-flutter-frame.png',
})
images = []
for rel in sorted(selected):
    p = ORIGINALS / rel
    with Image.open(p) as im:
        dimensions = list(im.size)
        assert im.format == 'PNG'
    images.append({'path': rel, **current[rel], 'pixels': dimensions, 'personally_viewed': rel in manual, 'visual_finding': manual.get(rel), 'also_checked_by_original_board_reader': any('c4/' + r['frame'] == rel for r in replay['all_board_observations'])})
write('selected-original-images.json', images)

first_touch = load(ORIGINALS / 'c4/return-first-to-games-flutter-touch.json')
last_touch = load(ORIGINALS / 'c4/return-final-to-games-flutter-touch.json')
first_games = load(ORIGINALS / 'c4/return-first-games-flutter-ready.json')
last_games = load(ORIGINALS / 'c4/return-final-games-flutter-ready.json')
visual = {
 'scope': 'Independent visual review of existing unmodified PNG originals; no generated or replacement images and no new device, engine or test run.',
 'first_return_order': {
   'early_stale_frame': {'path': 'c4/return-first-flutter.png', **current['c4/return-first-flutter.png']},
   'later_flutter_pause_target_frames': first_touch,
   'actual_target_touch': load(ORIGINALS / 'c4' / first_touch['command_original'].replace('.stdout', '.json')),
   'subsequent_games_frames': first_games,
   'monotonic_clock_scope': 'Values are original probe monotonic timestamps, not fabricated UTC event times.',
 },
 'final_return_order': {'flutter_pause_target_frames': last_touch, 'actual_target_touch': load(ORIGINALS / 'c4' / last_touch['command_original'].replace('.stdout', '.json')), 'subsequent_games_frames': last_games},
 'village_return_order': village_journal,
 'provisional_review_correction': {
   'initial_error': 'The reviewer provisionally misclassified the later first-return target frames as native while assessing the genuine early stale frame.',
   'corrected_finding': 'The later b90d1e9c target originals show a true Flutter pause card and are followed by the actual Spielewelt frame 5310fb1a. The earlier ba51f3f5 frame alone is stale.',
   'evidence': pixel_comparison,
   'communication': 'The provisional additional blocker was explicitly withdrawn to Root and Android QA before any source change. Root independently opened ba51, b90 and 5310 originals and confirmed the pixel relationship.',
   'no_image_replacement_or_source_patch': True,
 },
 'images': images,
 'limits': ['An original reader PASS is not by itself a manual visual finding.', 'Only selected existing images were personally viewed; remaining board observations were checked by the unchanged full reader.', 'The rejected/early stale originals are preserved with their actual ordering.', 'No C4 win or reward occurred; no complete two-lap race, physical-device, API37 or FPS claim.'],
}
write('visual-review.json', visual)

# Save exact original event excerpts, with source path and 1-based line numbers.
events = []
for rel in ['village/commands/0082-village-final-all-buffer-logcat.stdout', 'c4/commands/0462-final-all-buffer-logcat.stdout']:
    for number, line in enumerate((ORIGINALS / rel).read_text().splitlines(), 1):
        village_event = rel.startswith('village/') and '  6686 ' in line and ('[VillageHostReady]' in line or '[LumoHost] return: games' in line)
        c4_warning = rel.startswith('c4/') and ('  7129 ' in line or '  8289 ' in line) and 'SurfaceSyncGroup' in line and 'Failed to receive transaction ready' in line
        if village_event or c4_warning:
            events.append({'original_path': rel, 'line': number, 'text': line})
write('original-event-excerpts.json', {'events': events, 'scope': 'Exact selected original lines. Surface synchronization warnings are preserved; no warning-free claim.'})

limits = replay['limits'] + [
 'Complete original ZIP remains locally and under the source GitHub artifact; this Git checkpoint stores its complete hash inventory, every non-PNG original in a verified compact container, and selected original PNGs, not all 393 PNGs.',
 'A fresh APK download or local signature verification was not performed. Original diagnostic identity and before/after source/APK receipts are cross-bound to exact QA3cae and APK6b.',
 'The snapshot source area is a small exact-blob materialization, not a Git checkout. No raw Git-index-preservation result is claimed.',
 'No observed nonempty mailbox poll in this successful run had an already-absent native PID. Therefore this run does not reproduce the old timing window or prove a particular causal explanation for it.',
 'First early C4 return PNG is stale native; later target and games originals supply the visual Flutter-return proof. The provisional misclassification of those later frames is transparently corrected.',
]
result = {
 'schema': 1, 'status': 'PASS_SEPARATE_UNCHANGED_APK_DIAGNOSTIC_WITH_EXPLICIT_VISUAL_QUALIFICATIONS',
 'diagnostic': {'run': 43634531860, 'attempt': 1, 'android_job': 132568698911, 'contract_job': 132568308161, 'qa_source': QA, 'qa_tree': QA_TREE, 'qa_blob_files': 5010},
 'product': {'apk_source': APK, 'native_source': NATIVE, 'apk_sha256': village['identity']['apk_sha256'], 'pck_sha256': village['identity']['godot_pck_sha256'], 'version_code': 2020, 'version_name': '0.13.8'},
 'artifact': {k:v for k,v in manifest.items() if k != 'files'},
 'observer_sources': {'expected_count': 79, 'before_after_equal': True, 'independently_matched_to_full_untruncated_qa_tree': True, 'local_exact_qa_files': 12, 'separate_unchanged_zip_utility_files': 1},
 'main_original': {'status': main['status'], 'steps': len(main['steps']), 'all_steps_true': all(x.get('ok') is True for x in main['steps']), 'mandatory_steps_independently_checked': 18, 'fatal_crashes': main['fatal_crashes'], 'not_tested': main['not_tested']},
 'village': {'original_reader': replay['village_original_reader'], 'native_ready_marker': village['native']['marker'], 'return_observation_count': len(village_journal['attempts']), 'rejected_return_observations': sum(x['status']=='REJECTED' for x in village_journal['attempts']), 'actual_accepted_return_sha256': village['returned']['frame']['sha256'], 'native_return_ack_in_original_log': next(x for x in events if '[LumoHost] return: games' in x['text'])},
 'c4': {'original_reader': replay['c4_original_reader'], 'cleanup_rounds': replay['actual_cleanup_rounds'], 'reopen': replay['actual_reopen'], 'visual_qualification': 'See visual-review.json: stale early first-return PNG, followed by true Flutter pause and Spielewelt originals; both returns complete.'},
 'local_replay': {'elapsed_seconds': replay['elapsed_seconds'], 'runtime': replay['runtime'], 'full_readers_unchanged': True, 'original_c4_result_exactly_reproduced': True, 'new_device_engine_or_capture_runs': 0},
 'preservation': {'original_files': len(current), 'all_original_bytes_and_modes_unchanged_after_replay_and_views': True, 'reader_files': len(reader_current), 'all_reader_bytes_and_modes_unchanged': True},
 'archival': {'branch': 'evidence/lumo-village-6b-diagnostic-originals-20261114', 'parent': BASE, 'prefix': PREFIX, 'base_blob_files_preserved': 5170, 'non_png_archive': non_png_record, 'selected_png_paths': len(images), 'selected_unique_png_blobs': len({x['git_blob'] for x in images}), 'parent_owned_joblog': load(ROOT/'metadata/parent-joblog-reference.json')},
 'seven_job_acceptance': False, 'publication_approval': False, 'limits': limits,
}
write('manifest.json', result)
write('final-preservation-snapshot.json', {'originals': current, 'readers': reader_current, 'all_match_pre_replay_bytes_and_modes': True})
write('evidence-tree-contract.json', {'parent': BASE, 'parent_tree': '5ab6c0811d43b16eed166b3a651f3134aa34050e', 'base_files': 5170, 'allowed_new_prefix': PREFIX+'/', 'allowed_changed_or_deleted_paths': [], 'actual_tree_comparison': 'Must be completed against full GitHub tree before commit/reference update; final counts are recorded in the commit message and readback proof.'})

plan = []
def add(relative, path):
    plan.append({'relative_path': relative, 'local_path': str(path), **record(path)})
for p in sorted(ARCHIVE.rglob('*')):
    if p.is_file(): add(p.relative_to(ARCHIVE).as_posix(),p)
add('original-artifact-index.json', ROOT/'artifact-manifest.json')
for sub in ['metadata', 'replay', 'reader']:
    for p in sorted((ROOT/sub).rglob('*')):
        if p.is_file() and p.suffix not in ['.pyc']:
            add(sub+'/'+p.relative_to(ROOT/sub).as_posix(),p)
for rel in selected: add('originals/'+rel,ORIGINALS/rel)
direct = {p.relative_to(ORIGINALS).as_posix() for p in ORIGINALS.iterdir() if p.is_file()}
direct.update({'main/tour-result.json','village/village-result.json','village/returned-flutter-observation.json','village/returned-flutter-ui-2.xml','village/returned-flutter-visible-2-ocr.json','village/village-return-surface-readiness.json','c4/c4-result.json'})
for part in ['return-first','return-final']:
    direct.update('c4/'+p.name for p in (ORIGINALS/'c4').glob(part+'*.json'))
    direct.update('c4/'+p.name for p in (ORIGINALS/'c4').glob(part+'*.xml'))
for cleanup in replay['actual_cleanup_rounds']:
    for poll in cleanup['polls']:
        for key in ['pid_original','activity_original','find_original']:
            name=poll[key]
            for suffix in ['.stdout','.stderr','.json']:direct.add('c4/'+name.removesuffix('.stdout')+suffix)
for touch in [first_touch,last_touch]:
    for suffix in ['.stdout','.stderr','.json']:direct.add('c4/'+touch['command_original'].removesuffix('.stdout')+suffix)
for rel in sorted(direct): add('originals/'+rel, ORIGINALS/rel)
joblog = load(ROOT/'metadata/parent-joblog-reference.json')
plan.append({'relative_path':'originals/parent-owned-android-job-132568698911.original.log','bytes':joblog['size'],'git_blob':joblog['sha'],'reuse_blob':True,'provenance':joblog})
assert len({x['relative_path'] for x in plan}) == len(plan)
write('upload-plan.json',plan)
print(json.dumps({'non_png_archive':non_png_record,'selected_pngs':len(images),'selected_unique_pngs':len({x['git_blob'] for x in images}),'evidence_paths_before_readme':len(plan),'evidence_bytes_before_readme':sum(x['bytes'] for x in plan),'main_steps':len(main['steps']),'all_main_steps_true':all(x.get('ok') is True for x in main['steps']),'village_return_observations':len(village_journal['attempts'])},indent=2))
