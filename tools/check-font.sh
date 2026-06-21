#!/bin/sh
# ============================================================
# フォント統一チェック：本文フォントは全社共通の「正」と完全一致のみ許可。
# 「文字を細く見せる設定」(font-smoothing) は禁止＝各製品で文字の見え方がブレない。
# 正本＝ design-system/tools/check-font.sh（更新時はそちらに合わせて各製品へ配布）。
#
# 使い方： リポのルートで  sh tools/check-font.sh [対象パス ...]
#   例) sh tools/check-font.sh app
#   ・違反0 → 終了0（合格）／違反あり → 一覧表示して終了1（CIが赤）
#
# 許可される font-family：
#   ・inherit
#   ・正準スタック： -apple-system,"Hiragino Kaku Gothic ProN","Yu Gothic",sans-serif
#   ・等幅(値に monospace を含む)＝コード表示用のみ例外
# 禁止：
#   ・上記以外の font-family（別フォント・別スタック）
#   ・-webkit-font-smoothing:antialiased ／ -moz-osx-font-smoothing:grayscale（細く見せる設定）
# ============================================================

TARGETS="$@"
[ -z "$TARGETS" ] && TARGETS="."

# 正準スタック（空白を除いた形で比較する）
CANON='font-family:-apple-system,"HiraginoKakuGothicProN","YuGothic",sans-serif'

FILES=$(find $TARGETS -type f \( -name '*.css' -o -name '*.html' \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/.next/*' -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null)

viol=0
for f in $FILES; do
  # 1) font-family 宣言を1件ずつ検査
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    # line = "行番号:font-family:....."  → 空白を除いた値で判定
    val=$(printf '%s' "$line" | sed 's/^[0-9]*://' | tr -d '[:space:]')
    case "$val" in
      font-family:inherit) continue ;;
      "$CANON") continue ;;
      *monospace*) continue ;;
    esac
    echo "NG: $f  →  $line （許可は inherit / 共通フォント / 等幅 のみ）"
    viol=$((viol + 1))
  done <<EOF
$(grep -noE 'font-family:[^;}]*' "$f" 2>/dev/null)
EOF
  # 2) 「文字を細く見せる設定」は禁止
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "NG: $f  →  $line （文字を細く見せる設定は禁止＝共通の標準描画に統一）"
    viol=$((viol + 1))
  done <<EOF
$(grep -noE '\-webkit-font-smoothing:[[:space:]]*antialiased|\-moz-osx-font-smoothing:[[:space:]]*grayscale' "$f" 2>/dev/null)
EOF
done

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "フォント違反が $viol 件あります。"
  echo '本文フォントは共通の正のみ： -apple-system,"Hiragino Kaku Gothic ProN","Yu Gothic",sans-serif'
  echo "他フォントや「細く見せる設定」は使わないでください（等幅はコード表示のみ可）。"
  exit 1
fi
echo "OK: フォント違反なし（共通フォントに統一）"
exit 0
