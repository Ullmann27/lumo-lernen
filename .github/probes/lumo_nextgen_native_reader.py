"""Read a complete native phrase on one current frame; never issue input."""
from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path
import re
import time
import unicodedata


# Keep the historical native_text attempt count, OCR budget and retry delay.
ATTEMPTS, FRAME_SECONDS, RETRY_SECONDS = 10, 225, 2


def _words(text):
    plain = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return re.findall(r"[a-z0-9]+", plain.lower())


def _contains(words, wanted):
    return any(words[i:i + len(wanted)] == wanted for i in range(len(words) - len(wanted) + 1))


def adjacent_phrase(lines, label, pixels):
    """One full line or two consecutive, aligned lines of one OCR variant.

    Callers supply only the rows of one captured PNG. No skipped OCR rows,
    word reordering, cross-variant joins or partial expected text are accepted.
    """
    wanted, variants, matches = _words(label), {}, []
    if not wanted:
        raise ValueError("Expected phrase must contain words")
    for row in lines:
        box, text, variant = row.get("bounds"), row.get("text"), row.get("variant")
        if not (isinstance(text, str) and isinstance(variant, str) and variant and
                isinstance(box, (list, tuple)) and len(box) == 4 and
                all(type(n) in (int, float) and math.isfinite(n) for n in box) and
                0 <= box[0] < box[2] <= pixels[0] and 0 <= box[1] < box[3] <= pixels[1]):
            continue
        if row not in variants.setdefault(variant, []):
            variants[variant].append(row)

    def record(variant, rows):
        matches.append({"variant": variant, "rows": rows,
                        "text": " ".join(row["text"] for row in rows),
                        "bounds": [min(row["bounds"][0] for row in rows),
                                   min(row["bounds"][1] for row in rows),
                                   max(row["bounds"][2] for row in rows),
                                   max(row["bounds"][3] for row in rows)]})

    for variant, rows in variants.items():
        rows.sort(key=lambda row: (row["bounds"][1], row["bounds"][0]))
        for row in rows:
            if _contains(_words(row["text"]), wanted):
                record(variant, [row])
        for first, second in zip(rows, rows[1:]):
            left, right = _words(first["text"]), _words(second["text"])
            if _contains(left, wanted) or _contains(right, wanted) or not _contains(left + right, wanted):
                continue
            a, b = first["bounds"], second["bounds"]
            heights = (a[3] - a[1], b[3] - b[1])
            overlap = min(a[2], b[2]) - max(a[0], b[0])
            if (0 <= b[1] - a[3] <= 1.5 * max(heights) and
                    min(heights) >= .5 * max(heights) and
                    overlap >= .5 * min(a[2] - a[0], b[2] - b[0])):
                record(variant, [first, second])
    if not matches:
        return None
    # OCR masks may observe the same words with slightly different rectangles.
    # A separate occurrence elsewhere is not interchangeable with this heading.
    selected = min(matches, key=lambda match: (len(match["rows"]), match["variant"], match["bounds"]))
    a = selected["bounds"]
    for match in matches:
        b = match["bounds"]
        intersection = max(0, min(a[2], b[2]) - max(a[0], b[0])) * max(0, min(a[3], b[3]) - max(a[1], b[1]))
        smaller = min((a[2] - a[0]) * (a[3] - a[1]), (b[2] - b[0]) * (b[3] - b[1]))
        if intersection < .75 * smaller:
            raise RuntimeError("Ambiguous distinct native phrase regions: " + label)
    return selected


def _digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def see_wrapped_text(reader, out: Path, label: str, tag: str):
    """Reuse current capture/OCR with the existing budgets; observe, never tap."""
    evidence = {"status": "WAITING", "label": label, "attempt_limit": ATTEMPTS,
                "frame_budget_seconds": FRAME_SECONDS, "retry_seconds": RETRY_SECONDS,
                "frames": [], "input_issued": False}
    journal = out / (tag + "-wrapped-read.json")
    try:
        for attempt in range(ATTEMPTS):
            deadline = time.monotonic() + FRAME_SECONDS
            name = f"{tag}-{attempt}"
            shot = reader.capture(out, name, timeout=FRAME_SECONDS)
            source = out / shot["file"]
            before = _digest(source)
            if before != shot["sha256"]:
                raise RuntimeError("Captured native phrase screenshot hash mismatch")
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise TimeoutError("Current native phrase frame deadline exceeded")
            lines = reader.image_lines(out, name, reader.normalized(label),
                                       source_path=source, timeout=remaining)
            if _digest(source) != before:
                raise RuntimeError("Current native phrase screenshot changed during OCR")
            if time.monotonic() >= deadline:
                raise TimeoutError("Current native phrase frame deadline exceeded")
            match = adjacent_phrase(lines, label, (shot["width"], shot["height"]))
            evidence["frames"].append({"capture": shot, "source_sha256": before, "match": match})
            if match is not None:
                evidence["status"] = "READ"
                return
            time.sleep(RETRY_SECONDS)
        raise RuntimeError("Current native screenshot lacks complete adjacent phrase: " + label)
    except Exception as error:
        evidence.update(status="FAIL", error=str(error))
        raise
    finally:
        journal.write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n")
