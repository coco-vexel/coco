#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${COCO_RELEASE_BASE_URL:-}"
API_BASE_URL="${COCO_DESKTOP_API_BASE_URL:-}"
GUID="{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"
ASC_GUID="asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"

if [ -z "$BASE_URL" ]; then
  echo "Missing COCO_RELEASE_BASE_URL. Run this script from the command shown on install.html." >&2
  exit 1
fi
case "$BASE_URL" in
  https://*) ;;
  http://localhost:*|http://localhost/*|http://127.0.0.1:*|http://127.0.0.1/*|http://[::1]:*|http://[::1]/*) ;;
  *) echo "ONLYOFFICE Desktop requires an HTTPS release BaseUrl, except localhost HTTP for local development. Open the HTTPS install page or set COCO_RELEASE_BASE_URL=https://... ." >&2; exit 1 ;;
esac
if [ -n "$API_BASE_URL" ]; then
  case "$API_BASE_URL" in
    https://*) ;;
    http://localhost:*|http://localhost/*|http://127.0.0.1:*|http://127.0.0.1/*|http://[::1]:*|http://[::1]/*) ;;
    *) echo "ONLYOFFICE Desktop requires an HTTPS API base URL, except localhost HTTP for local development. Set COCO_DESKTOP_API_BASE_URL=https://.../api/v1 ." >&2; exit 1 ;;
  esac
fi

case "$(uname -s)" in
  Darwin)
    PLUGIN_ROOT="$HOME/Library/Application Support/ONLYOFFICE/DesktopEditors/data/sdkjs-plugins"
    ;;
  Linux)
    PLUGIN_ROOT="$HOME/.local/share/ONLYOFFICE/DesktopEditors/data/sdkjs-plugins"
    ;;
  *)
    PLUGIN_ROOT="$HOME/.local/share/ONLYOFFICE/DesktopEditors/data/sdkjs-plugins"
    ;;
esac

PLUGIN_DIR="$PLUGIN_ROOT/$GUID"
rm -rf "$PLUGIN_ROOT/$ASC_GUID" "$PLUGIN_ROOT/$GUID"
mkdir -p "$PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR/resources/light"
curl -fsSL "$BASE_URL/onlyoffice/resources/light/icon.png" -o "$PLUGIN_DIR/resources/light/icon.png"
curl -fsSL "$BASE_URL/onlyoffice/resources/light/icon@2x.png" -o "$PLUGIN_DIR/resources/light/icon@2x.png"

cat > "$PLUGIN_DIR/config.json" <<JSON
{
  "name": "Coco",
  "nameLocale": { "zh": "Coco 助手", "en": "Coco" },
  "guid": "$ASC_GUID",
  "version": "0.0.1",
  "minVersion": "7.0.0",
  "variations": [
    {
      "description": "Coco 文档智能助手",
      "descriptionLocale": { "zh": "Coco 文档智能助手" },
      "url": "index.html?v=ms7gwg7x",
      "icons": [
        "resources/light/icon.png",
        "resources/light/icon@2x.png"
      ],
      "isViewer": true,
      "EditorsSupport": ["word", "cell", "slide"],
      "isVisual": true,
      "isModal": false,
      "isInsideMode": true,
      "initDataType": "none",
      "initData": "",
      "isUpdateOften": false,
      "buttons": [],
      "size": [320, 600],
      "events": []
    }
  ]
}
JSON

if [ -n "$API_BASE_URL" ]; then
cat > "$PLUGIN_DIR/coco-runtime-config.js" <<JSON
window.__COCO_RUNTIME_CONFIG__ = {
  "apiBaseUrl": "$API_BASE_URL"
};
JSON
fi

write_remote_loader() {
  file_name="$1"
  html="$(curl -fsSL "$BASE_URL/onlyoffice/$file_name?v=ms7gwg7x" \
    | sed -e 's#\(["'\''"]\)\./v1/#\1../v1/#g' \
          -e "s#\([\"']\)\./assets/#\1$BASE_URL/onlyoffice/assets/#g" \
    | sed -E "s#(src=[\"'][^\"']*/onlyoffice/assets/[^\"']+\.js)([\"'])#\1?v=ms7gwg7x\2#g" \
    | sed -E "s#(href=[\"'][^\"']*/onlyoffice/assets/[^\"']+\.css)([\"'])#\1?v=ms7gwg7x\2#g")"
  if [ -n "$API_BASE_URL" ]; then
    html="$(printf '%s' "$html" | sed -e 's#</head>#  <script src="./coco-runtime-config.js"></script></head>#')"
  fi
  printf '%s' "$html" > "$PLUGIN_DIR/$file_name"
}

write_remote_loader "index.html"
write_remote_loader "settings.html"
write_remote_loader "workflow-editor.html"

echo "Coco ONLYOFFICE Desktop local shell installed:"
echo "  $PLUGIN_DIR"
echo "Remote UI:"
echo "  $BASE_URL/onlyoffice/?v=ms7gwg7x"
if [ -n "$API_BASE_URL" ]; then
  echo "API:"
  echo "  $API_BASE_URL"
fi
echo "Fully quit and restart ONLYOFFICE Desktop Editors."
