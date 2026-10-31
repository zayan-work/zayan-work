#!/usr/bin/env bash
# Pulls the generated profile README and its widgets from the DEV//IDENTITY API.
# Widgets are saved next to the README so the profile never depends on the API being awake.
set -euo pipefail

API="${API_BASE_URL:-https://dev-identity-api.onrender.com}"
API="${API%/}"
OUT="${1:-.}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fetch() {
  # Render's free plan can take a minute to wake; retry rather than publish a broken README.
  curl --fail --silent --show-error --location --retry 4 --retry-delay 20 --retry-all-errors \
    --max-time 90 -o "$2" "$API$1"
}

fetch /api/v1/readme/github "$TMP/README.md"
head -n 1 "$TMP/README.md" | grep -q '^# ' || { echo "README did not start with a heading" >&2; exit 1; }

mkdir -p "$TMP/widgets"
for w in identity activity stack; do
  fetch "/api/v1/widgets/$w.svg" "$TMP/widgets/$w.svg"
  head -c 4 "$TMP/widgets/$w.svg" | grep -q '^<svg' || { echo "$w.svg is not an SVG" >&2; exit 1; }
done

# Point the images at the committed copies.
sed -i.bak "s#$API/api/v1/widgets/\([a-z]*\)\.svg#widgets/\1.svg#g" "$TMP/README.md"
rm -f "$TMP/README.md.bak"

mkdir -p "$OUT/widgets"
cp "$TMP/widgets/"*.svg "$OUT/widgets/"
cp "$TMP/README.md" "$OUT/README.md"
