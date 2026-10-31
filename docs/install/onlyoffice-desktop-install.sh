#!/usr/bin/env bash
set -euo pipefail
BASE_URL="${COCO_RELEASE_BASE_URL:-${1:-}}"
[ -n "$BASE_URL" ] || { echo 'Missing release base URL.' >&2; exit 1; }
BASE_URL="${BASE_URL%/}"
API_BASE_URL="${COCO_DESKTOP_API_BASE_URL:-${2:-}}"
is_allowed_url() {
  case "$1" in
    https://*|http://localhost|http://localhost/*|http://localhost:*|http://127.0.0.1|http://127.0.0.1/*|http://127.0.0.1:*) return 0 ;;
    *) return 1 ;;
  esac
}
is_allowed_url "$BASE_URL" || { echo 'ONLYOFFICE Desktop requires HTTPS, except localhost development URLs.' >&2; exit 1; }
if [ -n "$API_BASE_URL" ]; then
  API_BASE_URL="${API_BASE_URL%/}"
  is_allowed_url "$API_BASE_URL" || { echo 'API base URL must use HTTPS, except localhost.' >&2; exit 1; }
fi
case "$(uname -s)" in
  Darwin) ROOT="$HOME/Library/Application Support/ONLYOFFICE/DesktopEditors/data/sdkjs-plugins" ;;
  Linux) ROOT="$HOME/.local/share/ONLYOFFICE/DesktopEditors/data/sdkjs-plugins" ;;
  *) echo 'Unsupported platform.' >&2; exit 1 ;;
esac
install_plugin() {
  local label="$1" raw="$2" asc="$3" config="$4" dir="$ROOT/$raw"
  rm -rf "$ROOT/$raw" "$ROOT/$asc"
  mkdir -p "$dir/resources/light"
  curl -fsSL "$BASE_URL/onlyoffice/$config" -o "$dir/config.json"
  curl -fsSL "$BASE_URL/onlyoffice/resources/light/icon.png" -o "$dir/resources/light/icon.png"
  curl -fsSL "$BASE_URL/onlyoffice/resources/light/icon@2x.png" -o "$dir/resources/light/icon@2x.png"
  if [ -n "$API_BASE_URL" ]; then
    printf 'window.__COCO_RUNTIME_CONFIG__ = {"apiBaseUrl":"%s"};
' "$API_BASE_URL" > "$dir/coco-runtime-config.js"
  fi
  for page in index.html excel.html settings.html workflow-editor.html; do
    curl -fsSL "$BASE_URL/onlyoffice/$page?v=online-2026.10.31.1" | sed       -e 's#"[.]/v1/#"../v1/#g'       -e "s#\"[.]/assets/#\"$BASE_URL/onlyoffice/assets/#g"       > "$dir/$page"
    if [ -n "$API_BASE_URL" ]; then
      sed -i.bak 's#</head>#  <script src="./coco-runtime-config.js"></script></head>#' "$dir/$page"
      rm -f "$dir/$page.bak"
    fi
  done
  echo "  $label: $dir"
}
mkdir -p "$ROOT"
install_plugin Word '{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}' 'asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}' config.json
install_plugin Excel '{A9551FA7-1158-4A6E-9DE0-9A36684B7934}' 'asc.{A9551FA7-1158-4A6E-9DE0-9A36684B7934}' config.excel.json
echo 'Coco ONLYOFFICE Word + Excel plugins installed. Restart ONLYOFFICE Desktop Editors.'
