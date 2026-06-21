#!/bin/sh
# ============================================================
# アイコンチェック：freee公式 Material Design Icons 以外の混入を検出して失敗する。
# 全社共通ルール（design-system / RULEBOOK §6）：アイコンは Material（react-icons の md／
# design-system/icons の公式SVG）だけ。絵文字・他セット・自作SVGは禁止。
# 正本＝ design-system/tools/check-icons.sh（更新時はそちらに合わせる）。
#
# 使い方： リポのルートで
#   sh tools/check-icons.sh [対象パス ...]
#   例) sh tools/check-icons.sh mock app/src
#   ・違反0 → 終了0（合格）／違反あり → 一覧表示して終了1（CIが赤くなる）
#
# 検出するもの（誤検知が少なく確実な信号）：
#   1) react-icons の md 以外のセット（fa/lu/hi/bi…）の取り込み
#   2) 他のアイコンライブラリ（lucide / heroicons / fontawesome / feather / mui-icons / tabler 等）
#   3) Lucide系スプライトの痕跡（<symbol id="i-…"> 内の <polyline> / <line>。Materialは塗りpath/circle）
# ※ 手書きSVGパスの真贋や絵文字の用途までは機械判定が難しいため、RULEBOOK §6＋見本帳＋レビューで補う。
# 生成物(.next/dist/build)・node_modules は常に除外。
# ============================================================

TARGETS="$@"
[ -z "$TARGETS" ] && TARGETS="."

FILES=$(find $TARGETS -type f \( -name '*.css' -o -name '*.html' -o -name '*.js' -o -name '*.tsx' -o -name '*.ts' \) \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/.next/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' 2>/dev/null)

viol=0
for f in $FILES; do
  # 1) react-icons の md 以外
  while IFS= read -r line; do
    [ -n "$line" ] && { echo "NG: $f  →  $line （react-icons は md だけ可）"; viol=$((viol + 1)); }
  done <<EOF
$(grep -noiE "react-icons/(ai|bi|bs|cg|di|fa|fc|fi|gi|go|gr|hi|im|io|io5|ri|si|ti|vsc|wi)\b" "$f" 2>/dev/null)
EOF
  # 2) 他のアイコンライブラリ
  while IFS= read -r line; do
    [ -n "$line" ] && { echo "NG: $f  →  $line （他アイコンライブラリ禁止・Materialのみ）"; viol=$((viol + 1)); }
  done <<EOF
$(grep -noiE "lucide-react|lucide\.|@heroicons|@fortawesome|react-feather|feather-icons|bootstrap-icons|@mui/icons-material|@tabler/icons" "$f" 2>/dev/null)
EOF
  # 3) Lucide系スプライト痕跡（symbol内の polyline/line）
  while IFS= read -r line; do
    [ -n "$line" ] && { echo "NG: $f  →  $line （アイコンに polyline/line＝Lucide系の疑い・Materialは塗りpath）"; viol=$((viol + 1)); }
  done <<EOF
$(grep -noE "<symbol[^>]*>.*<(polyline|line)" "$f" 2>/dev/null)
EOF
done

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "Material以外のアイコンの疑いが $viol 件あります。"
  echo "アイコンは react-icons の md／design-system/icons の公式SVG だけを使ってください（RULEBOOK §6）。"
  echo "見本帳：https://yawata-dotcom.github.io/design-system/gallery.html"
  exit 1
fi
echo "OK: アイコン違反なし（Material のみ）"
exit 0
