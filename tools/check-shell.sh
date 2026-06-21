#!/bin/sh
# ============================================================
# シェルチェック：シェルの中核クラスを「正典 shell.css 以外」で素で再定義していたら失敗する。
# 全社共通ルール（design-system / RULEBOOK・案A）：サイドメニュー＋ヘッダー＋外殻の見た目は
# design-system/shell.css（各製品はその写し app/src/app/shell.css）だけが持つ。各製品が独自に
# シェルを作り直すと多人数で見た目が崩れるため、再定義を機械検出して止める。
# 正本＝ design-system/tools/check-shell.sh（更新時はそちらに合わせる）。
#
# 使い方： リポのルートで
#   sh tools/check-shell.sh [対象パス ...]
#   例) sh tools/check-shell.sh app/src mock
#   ・違反0 → 終了0（合格）／違反あり → 一覧表示して終了1（CIが赤くなる）
#
# 何を「違反」とするか（誤検知が少ない確実な信号）：
#   シェル中核クラスが、あるルールの“対象（subject）”として定義されている行。
#     NG例)  .side{...}      .topbar:hover{...}      .foo .side{...}      .item.active{...}
#     OK例)  .topbar .mock{...}（topbar の中の子要素を飾るだけ＝再定義ではない）
#   ＝ シェルクラスの直後が { か , か、擬似/連結クラスのみで終わる場合に検出。
#      直後に半角スペース＋別セレクタが続く（＝子孫を飾る）場合は対象外。
# 正典本体（*/shell.css）は常に除外。生成物(.next/dist/build)・node_modules も除外。
# 正当な例外（shell.css に無いレスポンシブ上書き等）は tools/shell-allow.txt に1行＝該当行の一部で追記。
# ============================================================

# シェル中核クラス（shell.css が持つもの）＝ appshell 名前空間 ＋ ランチャー内部(lp*)
CLS="appshell(-[[:alnum:]]+)?|lpcard|lph|lpi|lpnow|lpdiv|lpnote"
# 「シェルクラスが対象（subject）」のパターン： 直前が行頭/空白/区切り、直後は擬似/連結のみ→ { か ,
PATTERN="(^|[[:space:],>+~{}])\.($CLS)([.:][[:alnum:]_()-]+)*[[:space:]]*[{,]"

ALLOW_FILE="tools/shell-allow.txt"

TARGETS="$@"
[ -z "$TARGETS" ] && TARGETS="."

FILES=$(find $TARGETS -type f \( -name '*.css' -o -name '*.html' \) \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/.next/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' \
  -not -name 'shell.css' 2>/dev/null)

allowed() {
  [ -f "$ALLOW_FILE" ] || return 1
  # 許可リストの各行（空行/コメント除く）が、対象行に部分一致したら許可
  while IFS= read -r a; do
    case "$a" in ''|'#'*) continue ;; esac
    case "$1" in *"$a"*) return 0 ;; esac
  done < "$ALLOW_FILE"
  return 1
}

viol=0
for f in $FILES; do
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    body=$(printf '%s' "$line" | sed 's/^[0-9]*://')   # 行番号を除いた本文
    if allowed "$body"; then continue; fi
    echo "NG: $f  →  $line （シェルは shell.css が正・ここで再定義しない）"
    viol=$((viol + 1))
  done <<EOF
$(grep -nE "$PATTERN" "$f" 2>/dev/null)
EOF
done

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "シェル中核クラスの再定義が $viol 件あります。"
  echo "サイドメニュー/ヘッダー/外殻は design-system の shell.css（写し app/src/app/shell.css）だけが持ちます。"
  echo "子要素を飾るだけなら『.topbar .子クラス{…}』のように子孫指定にしてください。"
  echo "正当な例外（レスポンシブ上書き等）は tools/shell-allow.txt に追記。"
  exit 1
fi
echo "OK: シェル再定義の違反なし（shell.css のみがシェルを持つ）"
exit 0
