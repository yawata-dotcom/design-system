#!/bin/sh
# ============================================================
# アイコン色チェック：アイコンが「文脈の正しいトークン色」を継ぐ作法から外れていないか検出する。
#   ※ 色の“値”が公式か＝check-colors／アイコンの“種類”が md か＝check-icons とは「別の観点」。
#     ここは「currentColor を壊して塗りを固定していないか」を機械で止める。
#     （2台目=建設で、選択中メニュー＝青のはずが濃グレー #323232 で出た事故の再発防止。
#      原因は vibes の MaterialIcon が塗りを #323232 に固定し currentColor を継がなかったこと。
#      #323232 は公式トークンなので check-colors を、md なので check-icons を、それぞれ素通りした。）
#
# 全社共通ルール（design-system / RULEBOOK §6）：
#   アイコンは fill:currentColor で文字色（トークン）を継ぐ。塗りを固定する vibes の MaterialIcon は使わない。
#   react-icons/md を直接 <Icon className="ic">（またはインラインSVG）で描く。
# 正本＝ design-system/tools/check-icon-color.sh（更新時はそちらに合わせる）。
#
# 使い方： リポのルートで
#   sh tools/check-icon-color.sh [対象パス ...]
#   例) sh tools/check-icon-color.sh mock app/src
#   ・違反0 → 終了0（合格）／違反あり → 一覧表示して終了1（CIが赤くなる）
#
# 検出する3点：
#   (a) vibes の MaterialIcon でアイコンを描いている（塗りを固定し currentColor を壊す）。
#       ＝ <MaterialIcon … /> の使用、または @freee_jp/vibes から MaterialIcon を import。
#   (b) アイコン基底 .ic が「fill:currentColor」を持たない／.ic に固定塗り(fill:#hex や fill:var(--token))を当てている。
#   (c) アイコンSVG（class=ic / 事業切替ランチャー）に fill="#hex"（直書き）がある。
#       → トークン色は fill="var(--token)" で。正当な例外は tools/icon-color-allow.txt に1行1hex。
# ※ チャート/アバター/イラスト等「アイコンでないSVG」の fill="#公式hex" は対象外（.ic とランチャーに限定して誤検知を防ぐ）。
# 生成物(.next/dist/build)・node_modules は常に除外。
# ============================================================

TARGETS="$@"
[ -z "$TARGETS" ] && TARGETS="."

# (c)用の例外hex（既定は無し。第三者ブランド等の正当な例外だけ tools/icon-color-allow.txt に追記）
ALLOW=" "
ALLOW_FILE="tools/icon-color-allow.txt"
if [ -f "$ALLOW_FILE" ]; then
  EXTRA=$(grep -oiE '#?[0-9a-f]{3}([0-9a-f]{3})?' "$ALLOW_FILE" 2>/dev/null | sed 's/^#//' | tr 'A-F' 'a-f' | tr '\n' ' ')
  ALLOW="$ALLOW $EXTRA "
fi

FILES=$(find $TARGETS -type f \( -name '*.css' -o -name '*.html' -o -name '*.js' -o -name '*.tsx' -o -name '*.ts' \) \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  -not -path '*/.next/*' \
  -not -path '*/dist/*' \
  -not -path '*/build/*' 2>/dev/null)

# アイコン文脈（このクラスを持つ行＝アイコン/ランチャー。チャート/アバターは含めない）
ICCTX='appshell-launcher|class="[^"]*\bic\b|className="[^"]*\bic\b'

viol=0
ic_usage=0   # className="ic" を実際に使っているか
ic_base=0    # .ic{ fill:currentColor } の基底定義があるか

for f in $FILES; do
  # (a) MaterialIcon の使用
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "NG(a): $f:$line"
    echo "       vibes の MaterialIcon は塗りを #323232 に固定し currentColor を壊す。react-icons/md を <Icon className=\"ic\"> で直接描く。"
    viol=$((viol + 1))
  done <<EOF
$(grep -noE '<MaterialIcon[ />]' "$f" 2>/dev/null)
$(grep -noiE "import[^;]*\bMaterialIcon\b[^;]*@freee_jp/vibes" "$f" 2>/dev/null)
EOF

  # (b1) .ic に固定塗り（fill:#hex / fill:var(...)）＝ currentColor を上書きしてしまう
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    echo "NG(b): $f:$line"
    echo "       アイコン基底 .ic に固定塗りを当てている。.ic は fill:currentColor だけにして文字色（トークン）を継ぐ。"
    viol=$((viol + 1))
  done <<EOF
$(grep -noiE '\.ic\b[^{}]*\{[^{}]*fill[[:space:]]*:[[:space:]]*(#[0-9a-f]|var\()' "$f" 2>/dev/null)
EOF

  # 集計：アイコンclassの使用 / .ic基底(fill:currentColor) の有無
  grep -qiE 'class(Name)?="[^"]*\bic\b' "$f" 2>/dev/null && ic_usage=1
  grep -qiE '\.ic\b[^{}]*\{[^{}]*fill[[:space:]]*:[[:space:]]*currentColor' "$f" 2>/dev/null && ic_base=1

  # (c) アイコン/ランチャーSVGの直書きhex（例外リストに無いもの）
  while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    hexes=$(printf '%s\n' "$ln" | grep -oiE 'fill="#[0-9a-f]{3,8}"' | grep -oiE '[0-9a-f]{3,8}' | tr 'A-F' 'a-f')
    bad=0
    for h in $hexes; do
      case "$ALLOW" in
        *" $h "*) : ;;
        *) bad=1 ;;
      esac
    done
    [ "$bad" -eq 1 ] || continue
    echo "NG(c): $f → アイコン/ランチャーSVGに直書きhex。fill=\"var(--token)\" を使う（正当な例外は tools/icon-color-allow.txt）。"
    printf '       %s\n' "$ln" | cut -c1-180
    viol=$((viol + 1))
  done <<EOF
$(grep -niE 'fill="#' "$f" 2>/dev/null | grep -iE "$ICCTX")
EOF
done

# (b2) className="ic" を使っているのに .ic{ fill:currentColor } の基底が（対象パス内に）無い
if [ "$ic_usage" -eq 1 ] && [ "$ic_base" -eq 0 ]; then
  echo "NG(b): className=\"ic\" を使っていますが、.ic{ fill:currentColor } の基底定義が対象パス内に見つかりません。"
  echo "       theme/styles に  .ic{ width:1.15em;height:1.15em;fill:currentColor;stroke:none;flex-shrink:0;vertical-align:-0.18em; }  を置いてください。"
  viol=$((viol + 1))
fi

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "アイコン色の作法ちがいが $viol 件あります（RULEBOOK §6）。"
  echo "アイコンは fill:currentColor で文字色（トークン）を継ぐ。塗りを固定する MaterialIcon は使わない。"
  echo "正典：shell-demo.html の .ic{fill:currentColor} ＋ react-icons/md を <Icon className=\"ic\"> で直接描画。"
  exit 1
fi
echo "OK: アイコン色の作法ちがいなし（MaterialIcon不使用・.ic は currentColor・直書きhexなし）"
exit 0
