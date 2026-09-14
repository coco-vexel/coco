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
TMP_FILE="$(mktemp)"
grep -vE '<jspluginonline .*name="(coco-wps|coco-wps-et)"' "$PUBLISH_XML" > "$TMP_FILE" || true
sed "s#</jsplugins>#  </jsplugins>#  <jspluginonline name="coco-wps" type="wps" url="$BASE_URL/coco-wps/worker/word/" debug="" enable="enable_dev" install="null"/>\n  <jspluginonline name="coco-wps-et" type="et" url="$BASE_URL/coco-wps/worker/excel/" debug="" enable="enable_dev" install="null"/>\n</jsplugins>#" "$TMP_FILE" > "$PUBLISH_XML"
rm -f "$TMP_FILE"
echo 'Coco WPS Word + Excel plugins registered.'
