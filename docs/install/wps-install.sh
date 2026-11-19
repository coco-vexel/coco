#!/usr/bin/env bash
set -euo pipefail

source_copy=""
if [ "${1:-}" = "--prepare" ]; then
  [ -f "${2:-}" ] || { echo "请选择从 WPS 目录复制出的 publish.xml。" >&2; exit 1; }
  source_copy="$2"
  shift 2
fi
base="${COCO_RELEASE_BASE_URL:-${1:-}}"
[ -n "$base" ] || { echo "缺少 Coco 发布地址。" >&2; exit 1; }
base="${base%/}"
platform="$(uname -s)"
case "$platform" in
  Darwin) candidates=("$HOME/Library/Containers/com.kingsoft.wpsoffice.mac/Data/.kingsoft/wps/jsaddons/publish.xml" "$HOME/.kingsoft/wps/jsaddons/publish.xml") ;;
  Linux) candidates=("$HOME/.local/share/Kingsoft/wps/jsaddons/publish.xml" "$HOME/.kingsoft/wps/jsaddons/publish.xml") ;;
  *) candidates=("$HOME/.kingsoft/wps/jsaddons/publish.xml") ;;
esac
target="${candidates[0]}"
for file in "${candidates[@]}"; do
  if [ -f "$file" ]; then target="$file"; break; fi
done
dir="$(dirname "$target")"

manual_help() {
  printf '无法访问 WPS 配置目录：%s\n' "$dir" >&2
  if [ "$platform" = Darwin ]; then
    printf '在访达中按 ⇧⌘G 打开上述目录，将现有 publish.xml 复制到可访问的文件夹，然后运行：\n  bash %q --prepare "/副本所在目录/publish.xml" %q\n' "$0" "$base" >&2
  fi
}

work="$(mktemp -d "${TMPDIR:-/tmp}/coco-wps.XXXXXX")"
pending=""
cleanup() {
  [ -z "$pending" ] || rm -f "$pending"
  [ -z "$work" ] || rm -rf "$work"
}
trap cleanup EXIT
snapshot="$work/original.xml"
output="$work/publish.xml"
existing=false
if [ -n "$source_copy" ] || [ -f "$target" ]; then
  if ! cat "${source_copy:-$target}" > "$snapshot"; then manual_help; exit 1; fi
  existing=true
else
  # Confirm directory access before treating a missing registry as a new installation.
  if ! mkdir -p "$dir" || ! ls -a "$dir" >/dev/null; then manual_help; exit 1; fi
fi
input="$snapshot"
if [ ! -s "$snapshot" ]; then
  input="$work/empty.xml"
  printf '%s\n' '<jsplugins>' '</jsplugins>' > "$input"
fi

if command -v xsltproc >/dev/null; then
  # Identity transform preserves other plugins, attributes and comments, including compact XML.
  cat > "$work/register.xsl" <<'XSL'
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="utf-8" indent="yes"/>
  <xsl:strip-space elements="jsplugins"/>
  <xsl:param name="base"/>
  <xsl:template match="/">
    <xsl:if test="not(jsplugins)"><xsl:message terminate="yes">配置文件的根元素必须为 jsplugins。</xsl:message></xsl:if>
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="@*|node()">
    <xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy>
  </xsl:template>
  <xsl:template match="/jsplugins/jspluginonline[@name='coco-wps' or @name='coco-wps-et']"/>
  <xsl:template match="/jsplugins">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
      <jspluginonline name="coco-wps" type="wps" url="{$base}/coco-wps/worker/word/" debug="" enable="enable_dev" install="null"/>
      <jspluginonline name="coco-wps-et" type="et" url="{$base}/coco-wps/worker/excel/" debug="" enable="enable_dev" install="null"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
XSL
  if LC_ALL=C grep -aq '<!DOCTYPE' "$input"; then echo "无法合并带 DOCTYPE 的 WPS 配置。" >&2; exit 1; fi
  xsltproc --nonet --novalid --nowrite --stringparam base "$base" "$work/register.xsl" "$input" > "$output"
else
  # Minimal Linux installs may have only awk. Accept the usual one-tag-per-line
  # registry and stop on other layouts instead of deleting unrelated entries.
  awk -v base="$base" '
    /^[[:space:]]*<jsplugins([[:space:]][^<>]*)?>[[:space:]]*$/ { roots++ }
    /^[[:space:]]*<jspluginonline[[:space:]][^<>]*\/>[[:space:]]*$/ {
      if ($0 ~ /[[:space:]]name="(coco-wps|coco-wps-et)"/) next
    }
    /[[:space:]]name=["\047](coco-wps|coco-wps-et)["\047]/ { exit 2 }
    /^[[:space:]]*<\/jsplugins>[[:space:]]*$/ {
      ends++
      gsub(/&/, "\\&amp;", base)
      gsub(/"/, "\\&quot;", base)
      gsub(/</, "\\&lt;", base)
      printf "  <jspluginonline name=\"coco-wps\" type=\"wps\" url=\"%s/coco-wps/worker/word/\" debug=\"\" enable=\"enable_dev\" install=\"null\"/>\n", base
      printf "  <jspluginonline name=\"coco-wps-et\" type=\"et\" url=\"%s/coco-wps/worker/excel/\" debug=\"\" enable=\"enable_dev\" install=\"null\"/>\n", base
    }
    { print }
    END { if (roots != 1 || ends != 1) exit 1 }
  ' "$input" > "$output" || { echo "请使用 xsltproc 合并此格式的 WPS 配置。" >&2; exit 1; }
fi

keep_copy() {
  rm -f "$snapshot" "$work/empty.xml" "$work/register.xsl"
  printf '已生成合并后的配置：%s\n' "$output"
  printf '退出 WPS，在文件管理器中将这个 publish.xml 复制到 %s，再启动 WPS。\n' "$dir"
  work=""
}
if [ -n "$source_copy" ]; then keep_copy; exit 0; fi
if ! pending="$(mktemp "$dir/publish.xml.tmp.XXXXXX")"; then
  echo "无法在 WPS 目录创建临时文件，插件尚未注册。" >&2
  keep_copy
  exit 1
fi
cat "$output" > "$pending"
if { "$existing" && ! cmp -s "$target" "$snapshot"; } || { ! "$existing" && [ -e "$target" ]; }; then
  echo "安装期间 publish.xml 已更改，请重新运行。" >&2
  exit 1
fi
if ! mv -f "$pending" "$target"; then
  echo "无法更新 WPS 配置，插件尚未注册。" >&2
  keep_copy
  exit 1
fi
pending=""
printf '已注册 Coco WPS 文字和表格插件。请完全退出并重新打开 WPS。\n'
