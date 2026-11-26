#!/usr/bin/env python3
"""Wählt die echten Aufnahmen für das Video aus und legt sie verkleinert unter build/cap/ ab.

Aufruf: prepare_assets.py <flutter-aufnahmen> <godot-aufnahmen>
Die Aufnahmen entstehen mit capture/flutter_captures.sh und capture/godot_captures.sh.
Es wird nichts retuschiert: nur zugeschnitten (Seitenverhältnis) und verkleinert.
"""
import json
import sys
from pathlib import Path
from PIL import Image

F, G = Path(sys.argv[1]), Path(sys.argv[2])
OUT = Path(__file__).parent / 'build' / 'cap'
OUT.mkdir(parents=True, exist_ok=True)
A = '__fold_aussen_1080x2340.png'

# Ziel: (Quelle, Art). Arten: phone = Hochformat-Handy, land = 16:9, port = 9:16.
SHOTS = {
    # Lern-App (Flutter)
    'app_home': (F / 'tour/phone_home.png', 'phone'),
    'app_learn': (F / 'tour/phone_learn.png', 'phone'),
    'app_task': (F / 'lesson/phone.png', 'phone'),
    'app_tests': (F / 'tour/phone_tests.png', 'phone'),
    'app_games': (F / 'hub/phone.png', 'phone'),
    'nh_1_tipp': (F / f'nachhilfe/14_hinweis_37_25{A}', 'phone'),
    'nh_2_anders': (F / f'nachhilfe/12_minus_62_25_muenzen{A}', 'phone'),
    'nh_3_zeigt': (F / f'nachhilfe/07_plus_37_25_zahlenstrahl{A}', 'phone'),
    'nh_4_gemeinsam': (F / f'nachhilfe/06_plus_37_25_gemeinsam_zehner_voll{A}', 'phone'),
    'nh_5_pruefen': (F / f'nachhilfe/13_pruefen_allein{A}', 'phone'),
    'nh_b1': (F / f'nachhilfe/05_plus_37_25_stangen_unterwegs{A}', 'phone'),
    'nh_b2': (F / f'nachhilfe/11_mal_6x7_teller{A}', 'phone'),
    'nh_b3': (F / f'nachhilfe/01_mal_6x7_lumo_zeigt_fuenf_reihen{A}', 'phone'),
    'nh_b4': (F / f'nachhilfe/02_mal_6x7_gemeinsam_kind_tippt{A}', 'phone'),
    'nh_b5': (F / f'nachhilfe/10_plus_8_5_eierkarton{A}', 'phone'),
    'verst_wechsel': (F / f'a5/mathe_methodenwechsel{A}', 'phone'),
    'verst_eltern': (F / f'a5/eltern_spaeter_bestaetigt{A}', 'phone'),
    'logic_sudoku': (F / 'logic/sudoku-initial.png', 'phone'),
    'logic_sudoku_ok': (F / 'logic/sudoku-success.png', 'phone'),
    'logic_words': (F / 'logic/words-initial.png', 'phone'),
    'logic_maths': (F / 'logic/maths-initial.png', 'phone'),
    'logic_hub': (F / 'logic/hub-fold-cover-large.png', 'phone'),
    'eltern_1': (F / f'a3/eltern_1_oben{A}', 'phone'),
    'eltern_2': (F / f'a3/eltern_2_ueberblick{A}', 'phone'),
    'eltern_3': (F / f'a3/eltern_3_lernplan{A}', 'phone'),
    'eltern_ha1': (F / f'a3/hausaufgabe_2_kind_hilfe{A}', 'phone'),
    'eltern_ha2': (F / f'a3/hausaufgabe_3_geschafft{A}', 'phone'),
    'hub_land': (F / 'hub/tablet-landscape.png', 'land-top'),
    'hub_port': (F / 'hub/phone.png', 'port-top'),
}
# Spiele (Godot): Auswahl in capture/godot_auswahl.json als {ziel: [datei, art]}.
for _name, (_file, _kind) in json.loads((Path(__file__).parent / 'capture' / 'godot_auswahl.json').read_text()).items():
    SHOTS[_name] = (G / _file, _kind)

SIZE = {'phone': (720, 1560), 'land': (1600, 924), 'port': (900, 1576)}


def fit(im, kind):
    top = kind.endswith('-top')
    w, h = SIZE[kind.replace('-top', '')]
    scale = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * scale), round(im.height * scale)), Image.LANCZOS)
    x = (im.width - w) // 2
    y = 0 if (top or kind == 'phone') else (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


missing = []
for name, (src, kind) in SHOTS.items():
    if not src.exists():
        missing.append(f'{name}: {src}')
        continue
    fit(Image.open(src).convert('RGB'), kind).save(OUT / f'{name}.jpg', quality=92)
print(f'{len(SHOTS) - len(missing)} Bilder nach {OUT}')
if missing:
    print('FEHLT:\n  ' + '\n  '.join(missing))
    sys.exit(1)
