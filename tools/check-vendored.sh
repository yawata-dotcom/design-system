#!/bin/sh
# ============================================================
# 共通骨格ファイル一致チェック：各製品が持つ shell.css / tokens.css のコピーが、
# 本家(design-system main)とビット単位で完全一致かを毎回照合。1文字でも違えば赤。
# ＝サイドメニュー/ヘッダーの共通骨格を、製品ごとに勝手に書き換えられない（中身まで強制）。
# 正本＝ design-system/tools/check-vendored.sh（更新時はそちらに合わせて各製品へ配布）。
#
# 使い方： リポのルートで  sh tools/check-vendored.sh <ローカルパス> [<ローカルパス> ...]
#   各ファイルの「ファイル名」が本家のファイル名（shell.css / tokens.css）と一致している前提。
#   例) sh tools/check-vendored.sh app/shell.css app/tokens.css
#
# 仕様：本家 raw を取得して diff。
#   ・不一致 → 終了1（赤）＝改ざん/ズレは止める。
#   ・取得失敗(ネット不通など) → 警告のみで終了0＝インフラ起因では止めない。
#   ・変更したい時は design-system 側を直し、各製品は tools/sync-shell.sh 等で同期する。
# ============================================================

BASE="https://raw.githubusercontent.com/yawata-dotcom/design-system/main"

viol=0
for local in "$@"; do
  name=$(basename "$local")
  if [ ! -f "$local" ]; then
    echo "NG: $local が見つかりません（共通骨格のコピーが必要です）"
    viol=$((viol + 1)); continue
  fi
  tmp=$(mktemp 2>/dev/null) || tmp="/tmp/check-vendored-$$.tmp"
  if ! curl -fsSL "$BASE/$name" -o "$tmp" 2>/dev/null; then
    echo "WARN: 本家 $name を取得できませんでした（ネット不通?）。照合をスキップします。"
    rm -f "$tmp"; continue
  fi
  if diff -q "$tmp" "$local" >/dev/null 2>&1; then
    echo "OK: $local は本家と一致"
  else
    echo "NG: $local が本家($name)と違います"
    echo "    共通骨格は本家(design-system)と完全一致のみ。変更は design-system 側で行い、tools/sync-shell.sh 等で同期してください。"
    viol=$((viol + 1))
  fi
  rm -f "$tmp"
done

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "共通骨格ファイルの不一致/欠落が $viol 件あります。"
  echo "shell.css / tokens.css は本家(design-system)と完全一致が必須です。"
  exit 1
fi
echo "OK: 共通骨格ファイルは本家と完全一致"
exit 0
