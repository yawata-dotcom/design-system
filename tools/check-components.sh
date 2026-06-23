#!/bin/sh
# 公式部品ガード（2026-06-23〜）
# 目的：公式部品に「置換済み」の“独自版クラス”を、マークアップ（class= / className=）で
#       使ったら CI を赤で止める。＝公式部品の同種を独自に作り直す逸脱を機械的に防ぐ。
# 使い方：sh tools/check-components.sh <ファイル|ディレクトリ> ...
#   ・ディレクトリは再帰で .html / .tsx / .jsx を対象
#   ・検査するのは「使用（class 属性の値）」のみ。CSS 定義(.x{})は対象外（描画されないため）。
# 禁止クラス：公式部品に統一済みのもの（左=独自版 / 右=公式の置換先）。
#   新しい逸脱を見つけたら、ここに「独自版:公式置換先」を1語追記する。
set -u

DENY="btn-p:.btn btn-s:.btn.ghost btn-primary:.btn btnp:.btn cmp:.tbl2 mkv:.kv mnote2:.callout mapnote:.callout schip:.chip-c alrow:.timeline otabs:.utabs crumbs:.crumb"

if [ "$#" -eq 0 ]; then
  echo "usage: sh tools/check-components.sh <file|dir> ..." >&2
  exit 2
fi

# 対象ファイル収集
FILES=$(for p in "$@"; do
  if [ -d "$p" ]; then
    find "$p" -type f \( -name '*.html' -o -name '*.tsx' -o -name '*.jsx' \)
  elif [ -f "$p" ]; then
    echo "$p"
  fi
done)

if [ -z "$FILES" ]; then
  echo "OK: 対象ファイルなし"
  exit 0
fi

ng=0
for pair in $DENY; do
  tok=${pair%%:*}
  repl=${pair#*:}
  # class="..." / className="..." の中で tok が独立したクラスとして出現する場合のみ一致
  # （前後は 引用符 か 空白 で区切られている＝部分一致や別クラスへの誤検出を防ぐ）
  hits=$(grep -nEH "(class|className)=\"([^\"]* )?${tok}( [^\"]*)?\"" $FILES 2>/dev/null)
  if [ -n "$hits" ]; then
    echo "NG: 独自版クラス \"${tok}\" は使用禁止 → 公式 ${repl} を使ってください"
    echo "$hits" | sed 's/^/    /'
    ng=1
  fi
done

echo "----------------------------------------------"
if [ "$ng" -eq 0 ]; then
  echo "OK: 置換済みの独自版クラスの使用なし（UIは公式部品に統一）"
  exit 0
else
  echo "公式部品に置換済みの“独自版クラス”が使われています。"
  echo "見本帳（gallery）の公式部品に置き換えてください（材料＝色/アイコン/フォントは別番人で強制済み）。"
  exit 1
fi
