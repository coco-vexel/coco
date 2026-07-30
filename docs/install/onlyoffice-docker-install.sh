#!/usr/bin/env bash
set -euo pipefail

APPLY="${COCO_DOCKER_APPLY:-0}"
if [ "${1:-}" = "--apply" ]; then
  APPLY="1"
  shift
fi
CONTAINER="${1:-onlyoffice-documentserver}"
BASE_URL="${COCO_RELEASE_BASE_URL:-}"
API_BASE_URL="${COCO_API_BASE_URL:-}"
OUT_DIR="${COCO_PLUGIN_OUT_DIR:-$HOME/Downloads/coco-onlyoffice-plugin}"
GUID="{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"
ASC_GUID="asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"
PLUGIN_DIR="$OUT_DIR/$ASC_GUID"
PLUGIN_ROOT="/var/www/onlyoffice/documentserver/sdkjs-plugins"
DEPLOY_PATH="$PLUGIN_ROOT/$ASC_GUID"

if [ -z "$BASE_URL" ]; then
  echo "Missing COCO_RELEASE_BASE_URL. Run this script from the command shown on install.html." >&2
  exit 1
fi
if [ -z "$API_BASE_URL" ]; then
  API_BASE_URL="${BASE_URL%/coco}/api/v1"
fi

# ONLYOFFICE Docker loads plugin files only from sdkjs-plugins inside the
# Document Server container. Build a small local shim instead of trying to
# register the remote /coco/onlyoffice URL directly.
rm -rf "$PLUGIN_DIR"
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
      "url": "index.html?v=ms7btrp5",
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

cat > "$PLUGIN_DIR/coco-runtime-config.js" <<JSON
window.__COCO_RUNTIME_CONFIG__ = {
  "apiBaseUrl": "$API_BASE_URL"
};
JSON

write_remote_loader() {
  file_name="$1"
  # Plugin APIs are served by Document Server next to this shim. Heavy hashed
  # assets stay on the Coco release host, and apiBaseUrl must exist before
  # Vite's module bundle evaluates in the iframe.
  curl -fsSL "$BASE_URL/onlyoffice/$file_name?v=ms7btrp5" \
    | sed -e 's#\(["'\''"]\)\./v1/#\1../v1/#g' \
          -e "s#\([\"']\)\./assets/#\1$BASE_URL/onlyoffice/assets/#g" \
          -e 's#</head>#  <script src="./coco-runtime-config.js"></script></head>#' \
    > "$PLUGIN_DIR/$file_name"
}

write_remote_loader "index.html"
write_remote_loader "settings.html"
write_remote_loader "workflow-editor.html"

echo "Coco ONLYOFFICE Docker plugin package generated:"
echo "  $PLUGIN_DIR"
echo
echo "Deploy this directory to ONLYOFFICE Document Server:"
echo "  $DEPLOY_PATH"
echo
echo "Example:"
echo "  docker cp '$PLUGIN_DIR/.' '$CONTAINER:$DEPLOY_PATH'"
echo "  docker restart '$CONTAINER'"
echo
echo "Remote UI:"
echo "  $BASE_URL/onlyoffice/?v=ms7btrp5"
echo "API:"
echo "  $API_BASE_URL"

if [ "$APPLY" = "1" ]; then
  docker exec "$CONTAINER" sh -lc "rm -rf '$PLUGIN_ROOT/$ASC_GUID' '$PLUGIN_ROOT/$GUID'"
  docker cp "$PLUGIN_DIR/." "$CONTAINER:$DEPLOY_PATH"
  docker restart "$CONTAINER" >/dev/null
  echo
  echo "Applied to container:"
  echo "  $CONTAINER"
fi
