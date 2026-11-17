#!/usr/bin/env python3
"""Compare the Dart mirror of the kart fleet with the pinned game source.

Usage: verify_kart_fleet_mirror.py <path to a lumo-godot checkout>
The profile shelf shows karts as unlocked by the same star thresholds the game
uses; a silent drift between both lists would show children wrong rewards.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def dart_fleet() -> list[tuple[str, str, str, int]]:
    text = (ROOT / "lib/domain/games/kart_fleet_catalog.dart").read_text(encoding="utf-8")
    rows = re.findall(r"KartFleetEntry\('([^']+)', '([^']+)', '([^']+)', (\d+)\)", text)
    return [(i, n, r, int(s)) for i, n, r, s in rows]


def godot_fleet(godot: Path) -> list[tuple[str, str, str, int]]:
    text = (godot / "scripts/games/kart_fleet.gd").read_text(encoding="utf-8")
    rows = re.findall(
        r'"id": "([a-z_]+)", "name": "([^"]+)", "role": "([^"]+)", "tag": "[^"]*", "unlock": (\d+)',
        text,
    )
    return sorted(((i, n, r, int(s)) for i, n, r, s in rows), key=lambda row: row[3])


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    dart, godot = dart_fleet(), godot_fleet(Path(sys.argv[1]))
    if not dart or not godot:
        print("FAIL: could not read one of the fleets", len(dart), len(godot))
        return 1
    if sorted(dart) != sorted(godot):
        print("FAIL: kart fleet mirror differs from the game")
        for row in sorted(set(dart) ^ set(godot)):
            print("  ", "only in app " if row in dart else "only in game", row)
        return 1
    missing = [row[0] for row in dart if not (ROOT / f"assets/lumo_design/karts/{row[0]}.webp").is_file()]
    if missing:
        print("FAIL: kart pictures missing:", missing)
        return 1
    print(f"PASS kart fleet mirror: {len(dart)} karts match the game and have pictures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
