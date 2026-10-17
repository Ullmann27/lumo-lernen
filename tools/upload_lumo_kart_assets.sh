#!/usr/bin/env bash
# Lumo Kart: optional upload of the TEN ORIGINAL locally supplied ZIP packages
# into a DRAFT GitHub Release. This script does not fetch missing archives.
# Run only after reviewing the file set and with authorized gh credentials.
set -euo pipefail

ROOT="${1:-.}"
REPO="Ullmann27/lumo-lernen"
TAG="lumo-kart-visual-references-2026-10-10"
BANDS=()
declare -A EXPECTED=(
  [01]=d6c7597036dc167b897da9a8cfad831efb74f34111ecc57d77a0345ff92f661f
  [02]=06a86a7ca54fdbf86e28aad3fd3a110205ba9177cac17b878217ec7c6da58af5
  [03]=d16687a960831f43dacf549180b425fde63986cae9798751f246f9baa6d3cf62
  [04]=5305815164f5c1457e2a33e8f53376273444616780c829199f95b0fcb108faaf
  [05]=000b65a5f699874f7830772ad9f95562d6633e8daac6a71a83b40dbe799cd1d2
  [06]=2f08b409290e7301ed6bedd2353de9c55d070208eafbdc5b655f9eb35aa65dbc
  [07]=1dafb546e3289a819420cd81aed5bd17966761a43da1855e9b117f06e5ce14f3
  [08]=04ffc2a84bb9ee64b287436bb5bff243227aa0a71f254642caeb0476c89b815d
  [09]=bd15371ceff723fab2eaf92caf8c1b5fbf8365c995bdc4f00eb96967d18aad63
  [10]=cb973b329b0ebce22bb66d6e6677398935904544eb552c68efd372819d7d1e90
)
command -v gh >/dev/null || { echo "gh CLI fehlt" >&2; exit 1; }
command -v sha256sum >/dev/null || { echo "sha256sum fehlt" >&2; exit 1; }
command -v unzip >/dev/null || { echo "unzip fehlt" >&2; exit 1; }
for N in 01 02 03 04 05 06 07 08 09 10; do
  P="$ROOT/Lumo_Kart_4K_Paket_${N}_von_10.zip"
  [[ -f "$P" ]] || { echo "FEHLT: $P" >&2; exit 2; }
  SZ=$(wc -c < "$P")
  [[ "$SZ" -le 50000000 ]] || { echo "Ueber 50 MB: $P" >&2; exit 2; }
  GOT=$(sha256sum "$P" | cut -d' ' -f1)
  [[ "$GOT" == "${EXPECTED[$N]}" ]] || { echo "Falscher SHA256: $P" >&2; exit 2; }
  unzip -tq "$P" >/dev/null || { echo "Defektes ZIP: $P" >&2; exit 2; }
  BANDS+=("$P")
done
echo "OK: alle 10 ZIPs existieren; SHA256, ZIP-Integritaet und 50MB-Grenze bestanden."
echo "Pruefe gh-Zugriff..."
gh auth status
echo "Das Release wird als DRAFT angelegt oder der bestehende DRAFT aktualisiert."
if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  IS_DRAFT=$(gh release view "$TAG" --repo "$REPO" --json isDraft --jq .isDraft)
  [[ "$IS_DRAFT" == true ]] || { echo "Release existiert bereits und ist NICHT draft. Abbruch." >&2; exit 3; }
  gh release upload "$TAG" "${BANDS[@]}" --repo "$REPO" --clobber
else
  gh release create "$TAG" "${BANDS[@]}" --repo "$REPO" --target main --draft --title "Lumo Kart – Visual Reference Sources (10x ZIP)" --notes "32 native image motifs in 95 image files, original and 4K upscaled variants. 2D REFERENCES ONLY; not 3D scenes. See docs/handoffs/2026-10-10-lumo-kart-assets/ for manifest and hashes."
fi
echo "Upload-Auftrag uebergeben. Anschliessend Release-Assets in GitHub unabhaengig pruefen, Groessen und Hashwerte kontrollieren. Ohne echte API-Bestaetigung NICHT 'hochgeladen' melden."
