#!/bin/sh
# ============================================================
# 色チェック：公式カラートークン(17値)以外の「直書きhex」を検出して失敗する。
# 全社共通ルール（design-system / RULEBOOK §色）：色は tokens.css の var(--token) だけ。
#
# 使い方： リポのルートで
#   sh tools/check-colors.sh [対象パス ...]
#   例) sh tools/check-colors.sh mock/index.html mock/staff-portal.html
#       sh tools/check-colors.sh app
#   ・対象パス省略時はカレント配下すべて（*.css / *.html）
#   ・違反0 → 終了0（合格）／違反あり → 一覧表示して終了1（CIが赤くなる）
#
# 正当な例外（第三者ブランド色など）は tools/color-allow.txt に1行1hex（#付き可）で追記。
# 影・スクリム用の rgba(0,0,0,*) / rgba(255,255,255,*) は色ではないので対象外（hexのみ検査）。
# 生成物(.next/dist/build)・node_modules・tokens.css定義そのものは常に除外。
# ============================================================

# 公式17トークンの実hex（小文字・#なし）。#fff と #ffffff の両表記を許可。
ALLOW=" 285ac8 1b49b8 dce8ff ebf3ff 00b9b9 e3f6f4 e1dcdc f7f5f5 fff ffffff 6e6b6b 323232 00963c cdebd7 dc1e32 fad2d7 be8c14 fff0d2 "

# 例外ファイル（あれば取り込む）
ALLOW_FILE="tools/color-allow.txt"
if [ -f "$ALLOW_FILE" ]; then
  EXTRA=$(grep -oiE '#?[0-9a-f]{3}([0-9a-f]{3})?' "$ALLOW_FILE" 2>/dev/null | sed 's/^#//' | tr 'A-F' 'a-f' | tr '\n' ' ')
  ALLOW="$ALLOW $EXTRA "
fi

# 対象パス（引数があればそれ、無ければ ".")
TARGETS="$@"
[ -z "$TARGETS" ] && TARGETS="."

FILES=$(find $TARGETS -type f \( -name '*.css' -o -name '*.html' \) \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/.next/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  -not -name 'tokens.css' 2>/dev/null)

viol=0
for f in $FILES; do
  hits=$(grep -oiE '#[0-9a-f]{3}([0-9a-f]{3})?([0-9a-f]{2})?\b' "$f" 2>/dev/null | tr 'A-F' 'a-f' | sort -u)
  for h in $hits; do
    hex=$(printf '%s' "$h" | sed 's/^#//')
    case "$ALLOW" in
      *" $hex "*) : ;;                               # 公式 or 例外 → OK
      *) echo "NG: $f  →  #$hex （公式17色以外の直書き）"; viol=$((viol + 1)) ;;
    esac
  done
done

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "公式17色以外の直書き色が $viol 件あります。"
  echo "tokens.css の var(--token) を使ってください（直書きhex禁止）。"
  echo "第三者ブランド色など正当な例外は tools/color-allow.txt に追記。"
  exit 1
fi
echo "OK: 直書き色の違反なし（公式17色＋例外のみ）"
exit 0
