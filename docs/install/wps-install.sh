#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${COCO_RELEASE_BASE_URL:-${1:-}}"
if [ -z "$BASE_URL" ]; then echo "Missing release base URL." >&2; exit 1; fi
BASE_URL="${BASE_URL%/}"
case "$(uname -s)" in
  Darwin) CANDIDATES=("$HOME/Library/Containers/com.kingsoft.wpsoffice.mac/Data/.kingsoft/wps/jsaddons/publish.xml" "$HOME/.kingsoft/wps/jsaddons/publish.xml") ;;
  Linux) CANDIDATES=("$HOME/.local/share/Kingsoft/wps/jsaddons/publish.xml" "$HOME/.kingsoft/wps/jsaddons/publish.xml") ;;
  *) CANDIDATES=("$HOME/.kingsoft/wps/jsaddons/publish.xml") ;;
esac
PUBLISH_XML=""
for item in "${CANDIDATES[@]}"; do [ -f "$item" ] && PUBLISH_XML="$item" && break; done
[ -n "$PUBLISH_XML" ] || PUBLISH_XML="${CANDIDATES[0]}"
mkdir -p "$(dirname "$PUBLISH_XML")"
[ -f "$PUBLISH_XML" ] || printf '%s
' '<?xml version="1.0" encoding="utf-8"?>' '<jsplugins>' '</jsplugins>' > "$PUBLISH_XML"
TMP_FILE="$(mktemp "${PUBLISH_XML}.tmp.XXXXXX")"
NEXT_FILE="${TMP_FILE}.next"
trap 'rm -f "$TMP_FILE" "$NEXT_FILE"' EXIT
grep -vE '<jspluginonline .*name="(coco-wps|coco-wps-et)"' "$PUBLISH_XML" > "$TMP_FILE" || true
if ! grep -q '<jsplugins' "$TMP_FILE"; then
  printf '%s
' '<?xml version="1.0" encoding="utf-8"?>' '<jsplugins>' '</jsplugins>' > "$TMP_FILE"
elif ! grep -q '</jsplugins>' "$TMP_FILE"; then
  printf '%s
' '</jsplugins>' >> "$TMP_FILE"
fi
awk -v base_url="$BASE_URL" '
  /<\/jsplugins>/ {
    printf "  <jspluginonline name=\"coco-wps\" type=\"wps\" url=\"%s/coco-wps/worker/word/\" debug=\"\" enable=\"enable_dev\" install=\"null\"/>\n", base_url
    printf "  <jspluginonline name=\"coco-wps-et\" type=\"et\" url=\"%s/coco-wps/worker/excel/\" debug=\"\" enable=\"enable_dev\" install=\"null\"/>\n", base_url
  }
  { print }
' "$TMP_FILE" > "$NEXT_FILE"
mv "$NEXT_FILE" "$PUBLISH_XML"
rm -f "$TMP_FILE"
trap - EXIT
echo 'Coco WPS Word + Excel plugins registered.'
