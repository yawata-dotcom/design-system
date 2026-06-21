#!/bin/sh
# ============================================================
# ヘッダー（共通上バー）中身チェック：appshell-topbar の中に「製品独自の操作」を
# 入れていたら赤で止める。ヘッダーは全製品共通の固定仕様＝各製品の開発者が
# 勝手にボタン/セレクタ/トグルを足せない（中身まで強制）。
# 正本＝ design-system/tools/check-header.sh（更新時はそちらに合わせる）。
#
# 使い方： リポのルートで  sh tools/check-header.sh [対象パス ...]
#   例) sh tools/check-header.sh app
#   ・違反0 → 終了0（合格）／違反あり → 一覧表示して終了1（CIが赤）
#
# ヘッダーに置いてよい（許可）：情報表示の span（会社/事業名・同期日時・対象期間・権限バッジ .plan）・
#   ヘルプ等のアイコン・ログイン/ログアウト（button.tblink）。
# 禁止（製品独自の操作）：<select> / <input> / <textarea> / データ絞り込みトグル
#   （.lead-toggle / .rolesw / .filter*）／ tblink 以外の <button>。
# ＝ 操作系はヘッダーでなく本文（フィルタ帯など）へ置く。
# ============================================================

TARGETS="$@"
[ -z "$TARGETS" ] && TARGETS="."

FILES=$(find $TARGETS -type f -name '*.html' \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/.next/*' -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null)

viol=0
for f in $FILES; do
  # appshell-topbar の中身を抽出（topbar 行〜 </header> もしくは 直後の本文開始まで）
  block=$(awk '
    /appshell-topbar/{inb=1}
    inb{print}
    inb && (/<\/header>/ || /appshell-content/ || /class="wrap"/ || /class="content"/){exit}
  ' "$f" 2>/dev/null)
  [ -z "$block" ] && continue

  # 禁止：<input>/<textarea>／データ絞り込みトグル(lead-toggle)／そして .rolesw 以外の <select>。
  # 許可：共通ヘッダーの「選択枠」＝<span class="rolesw"> 内の <select>（権限/担当者など1つ）。
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "NG: $f  →  $line （ヘッダーに製品独自の操作。本文へ移してください／選択枠は .rolesw のみ）"
    viol=$((viol + 1))
  done <<EOF
$(printf '%s\n' "$block" | grep -nE '<input|<textarea|class="[^"]*lead-toggle'
printf '%s\n' "$block" | grep -n '<select' | grep -v 'rolesw')
EOF
done

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "ヘッダー（共通上バー）に製品独自の操作が $viol 件あります。"
  echo "ヘッダーは全製品共通の固定仕様です。セレクタ・トグル・絞り込み等の操作は本文（フィルタ帯）へ置いてください。"
  exit 1
fi
echo "OK: ヘッダー違反なし（共通上バーに製品独自の操作は入っていない）"
exit 0
