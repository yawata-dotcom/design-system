#!/bin/sh
# ============================================================
# ヘッダー（共通上バー）中身チェック：appshell-topbar の中に「製品独自の操作」や
# 廃止済み要素が残っていたら赤で止める。ヘッダーは全製品共通の固定仕様。
# 正本＝ design-system/tools/check-header.sh（更新時はそちらに合わせる）。
# 正典セット（2026-07-19 社長確定・ヘッダー統一_壁打ち確定_20260719）＝
#   会社名(.company) / 役割セレクタ(.rolesw>select) / メール / ログアウト(button.appshell-logout) / ヘルプ
#   （未SSO製品はメール・ログアウトを省略可。役割未整備は「準備中」disabled）。
# 旧5点の「最終同期」「期間」は廃止＝残っていたら赤（消し忘れ検知）。
#
# 使い方： リポのルートで  sh tools/check-header.sh [対象パス ...]
#   例) sh tools/check-header.sh app
#   ・違反0 → 終了0（合格）／違反あり → 一覧表示して終了1（CIが赤）
#
# ヘッダーに置いてよい（許可）：会社名・メールの span／役割セレクタ(.rolesw内のselect1つ)／
#   ヘルプ等のアイコン／ログアウト(button.appshell-logout)／スマホ用ハンバーガー(button.appshell-burger)。
# 禁止（製品独自の操作）：<input> / <textarea> / データ絞り込みトグル
#   （.lead-toggle / .filter*）／ .rolesw 以外の <select>／ 許可2種以外の <button>。
# ＝ 操作系はヘッダーでなく本文（フィルタ帯など）へ置く。
# ============================================================

TARGETS="$@"
[ -z "$TARGETS" ] && TARGETS="."

FILES=$(find $TARGETS -type f -name '*.html' \
  -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/.next/*' -not -path '*/dist/*' -not -path '*/build/*' 2>/dev/null)

viol=0
for f in $FILES; do
  # appshell-topbar の中身を抽出（実マークアップの class="…appshell-topbar" 行〜 </header> もしくは 直後の本文開始まで）
  # ※ <style> 内のCSSセレクタ（.appshell-topbar …）やコード見本（&lt;エスケープ）に反応しないよう class=" で限定
  block=$(awk '
    /class="[^"]*appshell-topbar/{inb=1}
    inb{print}
    inb && (/<\/header>/ || /appshell-content/ || /class="wrap"/ || /class="content"/){exit}
  ' "$f" 2>/dev/null)
  [ -z "$block" ] && continue

  # 禁止：<input>/<textarea>／絞り込みトグル(lead-toggle)／.rolesw以外の<select>／許可外の<button>。
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "NG: $f  →  $line （ヘッダーに製品独自の操作。本文へ移してください／選択枠は .rolesw のみ・ボタンは appshell-logout / appshell-burger のみ）"
    viol=$((viol + 1))
  done <<EOF
$(printf '%s\n' "$block" | grep -nE '<input|<textarea|class="[^"]*lead-toggle'
printf '%s\n' "$block" | grep -n '<select' | grep -v 'rolesw'
printf '%s\n' "$block" | grep -n '<button' | grep -vE 'appshell-logout|appshell-burger')
EOF

  # ── 廃止済み要素の消し忘れ検知（2026-07-19 ヘッダー統一）──
  if printf '%s' "$block" | grep -q '最終同期'; then
    echo "NG: $f  →  廃止済みの「最終同期」がヘッダーに残っています（2026-07-19社長決定で削除）"
    viol=$((viol + 1))
  fi
  if printf '%s' "$block" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}[^<]*〜'; then
    echo "NG: $f  →  廃止済みの「期間（日付範囲）」がヘッダーに残っています（2026-07-19社長決定で削除）"
    viol=$((viol + 1))
  fi

  # ── 必須要素の存在チェック（モックとアプリでヘッダーがズレる事故の防止）──
  # 会社名(.company)・役割セレクタ(.rolesw>select)・span3個以上（会社名/役割/ヘルプ）。
  # ※ React実装は構造を共有 <AppShell> が固定（topbar propsが型＝ビルドで強制）＋実測番人で担保。
  miss=""
  printf '%s' "$block" | grep -q 'class="[^"]*\bcompany\b' || miss="$miss 会社名(.company)"
  { printf '%s' "$block" | grep -q 'class="[^"]*\brolesw\b' && printf '%s' "$block" | grep -q '<select'; } \
    || miss="$miss 役割セレクタ(.rolesw>select)"
  spans=$(printf '%s' "$block" | grep -o '<span' | wc -l | tr -d ' ')
  [ "${spans:-0}" -ge 3 ] || miss="$miss 必須3点未満(spanが${spans}個)"
  if [ -n "$miss" ]; then
    echo "NG: $f  →  ヘッダーに必須要素が欠けています：$miss"
    echo "    正典セット＝会社名(.company)／役割セレクタ(.rolesw>select)／メール／ログアウト(.appshell-logout)／ヘルプ。共有 <AppShell> に合わせてください。"
    viol=$((viol + 1))
  fi
done

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "ヘッダー（共通上バー）の違反が $viol 件あります。"
  echo "ヘッダーは全製品共通の固定仕様（正典セット＝会社名/役割セレクタ/メール/ログアウト/ヘルプ・2026-07-19確定）です。"
  echo "操作系の追加は本文へ／欠け・消し忘れは共有 <AppShell> と確定書に合わせてください。"
  exit 1
fi
echo "OK: ヘッダー違反なし（共通上バーは正典セット・製品独自の操作なし・廃止要素の残存なし）"
exit 0
