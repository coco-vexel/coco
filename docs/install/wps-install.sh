#!/usr/bin/env bash
set -euo pipefail

ENTRY_URL="${COCO_WPS_ENTRY_URL:-}"
PLUGIN_NAME="${COCO_WPS_PLUGIN_NAME:-coco-wps}"

if [ -z "$ENTRY_URL" ]; then
  echo "Missing COCO_WPS_ENTRY_URL. Run this script from the command shown on install.html." >&2
  exit 1
fi

candidate_paths() {
  case "$(uname -s)" in
    Darwin)
      printf '%s\n' \
        "$HOME/Library/Containers/com.kingsoft.wpsoffice.mac/Data/.kingsoft/wps/jsaddons/publish.xml" \
        "$HOME/.kingsoft/wps/jsaddons/publish.xml"
      ;;
    Linux)
      printf '%s\n' \
        "$HOME/.local/share/Kingsoft/wps/jsaddons/publish.xml" \
        "$HOME/.kingsoft/wps/jsaddons/publish.xml"
      ;;
    *)
      printf '%s\n' "$HOME/.kingsoft/wps/jsaddons/publish.xml"
      ;;
  esac
}

PUBLISH_XML=""
while IFS= read -r path; do
  if [ -f "$path" ]; then
    PUBLISH_XML="$path"
    break
  fi
done < <(candidate_paths)

if [ -z "$PUBLISH_XML" ]; then
  PUBLISH_XML="$(candidate_paths | head -n 1)"
  mkdir -p "$(dirname "$PUBLISH_XML")"
  cat > "$PUBLISH_XML" <<XML
<?xml version="1.0" encoding="utf-8"?>
<jsplugins>
</jsplugins>
XML
fi

ENTRY="  <jspluginonline name=\"$PLUGIN_NAME\" type=\"wps\" url=\"$ENTRY_URL\" debug=\"\" enable=\"enable_dev\" install=\"null\"/>"
TMP_FILE="$(mktemp)"

grep -v "<jspluginonline .*name=\"$PLUGIN_NAME\"" "$PUBLISH_XML" > "$TMP_FILE" || true
if grep -q "</jsplugins>" "$TMP_FILE"; then
  sed "s#</jsplugins>#$ENTRY\n</jsplugins>#" "$TMP_FILE" > "$TMP_FILE.next"
else
  {
    cat "$TMP_FILE"
    echo "$ENTRY"
    echo "</jsplugins>"
  } > "$TMP_FILE.next"
fi
cat "$TMP_FILE.next" > "$PUBLISH_XML"
rm -f "$TMP_FILE.next"
rm -f "$TMP_FILE"

echo "Coco WPS plugin registered:"
echo "  $ENTRY_URL"
echo "publish.xml:"
echo "  $PUBLISH_XML"
echo "Restart WPS Writer, then open the Coco entry from the ribbon."
