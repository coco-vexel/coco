#!/usr/bin/env bash
set -euo pipefail
if [ -n "${COCO_RELEASE_BASE_URL:-}" ]; then
  BASE_URL="$COCO_RELEASE_BASE_URL"
  CONTAINER="${COCO_ONLYOFFICE_CONTAINER:-${1:-onlyoffice-documentserver}}"
else
  BASE_URL="${1:-}"
  CONTAINER="${COCO_ONLYOFFICE_CONTAINER:-${2:-onlyoffice-documentserver}}"
fi
[ -n "$BASE_URL" ] || { echo 'Missing release base URL.' >&2; exit 1; }
BASE_URL="${BASE_URL%/}"
RELEASE_ROOT="${BASE_URL%/coco}"
API_BASE_URL="${COCO_DESKTOP_API_BASE_URL:-$RELEASE_ROOT/api/v1}"
API_BASE_URL="${API_BASE_URL%/}"
APPLY="${COCO_DOCKER_APPLY:-0}"
is_allowed_url() {
  case "$1" in
    https://*|http://localhost|http://localhost/*|http://localhost:*|http://127.0.0.1|http://127.0.0.1/*|http://127.0.0.1:*) return 0 ;;
    *) return 1 ;;
  esac
}
is_allowed_url "$BASE_URL" || { echo 'ONLYOFFICE Docker requires HTTPS, except localhost development URLs.' >&2; exit 1; }
is_allowed_url "$API_BASE_URL" || { echo 'API base URL must use HTTPS, except localhost.' >&2; exit 1; }
OUT_DIR="${COCO_ONLYOFFICE_OUT_DIR:-$PWD/coco-onlyoffice-plugins}"
ROOT='/var/www/onlyoffice/documentserver/sdkjs-plugins'
rm -rf "$OUT_DIR" && mkdir -p "$OUT_DIR"
build_plugin() {
  local label="$1" raw="$2" asc="$3" config="$4" dir="$OUT_DIR/$asc"
  mkdir -p "$dir/resources/light"
  curl -fsSL "$BASE_URL/onlyoffice/$config" -o "$dir/config.json"
  curl -fsSL "$BASE_URL/onlyoffice/resources/light/icon.png" -o "$dir/resources/light/icon.png"
  curl -fsSL "$BASE_URL/onlyoffice/resources/light/icon@2x.png" -o "$dir/resources/light/icon@2x.png"
  printf 'window.__COCO_RUNTIME_CONFIG__ = {"apiBaseUrl":"%s"};
' "$API_BASE_URL" > "$dir/coco-runtime-config.js"
  for page in index.html excel.html settings.html workflow-editor.html; do
    curl -fsSL "$BASE_URL/onlyoffice/$page?v=online-2026.10.31.1" | sed -e 's#"[.]/v1/#"../v1/#g' -e "s#\"[.]/assets/#\"$BASE_URL/onlyoffice/assets/#g" -e 's#</head>#  <script src="./coco-runtime-config.js"></script></head>#' > "$dir/$page"
  done
  echo "  $label: $dir"
}
build_plugin Word '{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}' 'asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}' config.json
build_plugin Excel '{A9551FA7-1158-4A6E-9DE0-9A36684B7934}' 'asc.{A9551FA7-1158-4A6E-9DE0-9A36684B7934}' config.excel.json
if [ "$APPLY" = '1' ]; then
  for spec in '{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}|asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}' '{A9551FA7-1158-4A6E-9DE0-9A36684B7934}|asc.{A9551FA7-1158-4A6E-9DE0-9A36684B7934}'; do
    raw="${spec%%|*}"
    asc="${spec#*|}"
    docker exec "$CONTAINER" sh -lc "rm -rf '$ROOT/$raw' '$ROOT/$asc'"
    docker cp "$OUT_DIR/$asc/." "$CONTAINER:$ROOT/$asc"
  done
  docker restart "$CONTAINER" >/dev/null
  echo "Coco ONLYOFFICE Word + Excel plugins applied to $CONTAINER."
else
  echo "Packages generated at $OUT_DIR. Set COCO_DOCKER_APPLY=1 to apply them."
fi
