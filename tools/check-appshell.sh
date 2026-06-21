#!/bin/sh
# ============================================================
# 正典シェル部品チェック（案A P3／React）：
#   「サイドメニュー＋ヘッダー＋外殻は、共有部品 <AppShell> を import して使う」を強制する。
#   各製品が自前でシェル骨格を書き直すのを禁止＝真の強制。
#   正本＝ design-system/tools/check-appshell.sh（更新時はそちらに合わせる）。
#
# 使い方： リポのルートで
#   sh tools/check-appshell.sh
#   ・違反0 → 終了0（合格）／違反あり → 一覧表示して終了1（CIが赤くなる）
#
# 検査する3点：
#   (1) app/package.json が @yawata-dotcom/design-system に依存し、git のタグ/コミットで
#       ピン留めされている（再現可能・勝手に流入しない）。例: github:org/repo#appshell-v1
#   (2) app/src のどこかで共有 <AppShell> を import している。
#   (3) app/src の .tsx が「シェル骨格」クラス(appshell / appshell-side / appshell-main /
#       appshell-content / appshell-brand / appshell-seclabel / appshell-item / appshell-topbar)を
#       自前 className に書いていない（骨格は共有部品が描く。ランチャー等の中身スロットは許可）。
# ============================================================

PKG="@yawata-dotcom/design-system"
PJSON="app/package.json"
SRC="app/src"
viol=0

# (1) 依存＋ピン留め
if [ ! -f "$PJSON" ]; then
  echo "NG: $PJSON が見つかりません"; viol=$((viol + 1))
else
  dep=$(grep -oE "\"$PKG\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$PJSON")
  if [ -z "$dep" ]; then
    echo "NG: $PJSON が $PKG に依存していません（共有部品を使ってください）"; viol=$((viol + 1))
  else
    val=$(printf '%s' "$dep" | sed -E "s/.*:[[:space:]]*\"([^\"]*)\"/\1/")
    case "$val" in
      */archive/refs/tags/*.tar.gz|*github:*\#*|*git+*\#*|*\.git\#*)
        echo "OK(1): 依存はタグ/コミットでピン留め済み → $val" ;;
      *)
        echo "NG: $PKG の依存がタグ/コミットでピン留めされていません（例 .../archive/refs/tags/v0.1.0.tar.gz もしくは github:org/repo#tag）→ 現在: $val"
        viol=$((viol + 1)) ;;
    esac
  fi
fi

# (2) 共有 <AppShell> の import
if grep -rqE "from[[:space:]]+['\"]$PKG(/AppShell)?['\"]" "$SRC" 2>/dev/null; then
  echo "OK(2): 共有 <AppShell> を import している"
else
  echo "NG: $SRC で共有 <AppShell>（$PKG）を import していません"; viol=$((viol + 1))
fi

# (3) シェル骨格クラスの自前記述を禁止（中身スロット launcher/launchwrap/launchpanel は許可）
#   骨格クラス（決して中身スロットにならない）＝下の具体名のみを検出。launcher系は対象外なので誤検知なし。
SKELETON='appshell-side|appshell-main|appshell-content|appshell-brand|appshell-seclabel|appshell-item|appshell-topbar'
while IFS= read -r line; do
  [ -n "$line" ] || continue
  echo "NG: $line （シェル骨格は共有 <AppShell> が描く。自前 className 禁止）"
  viol=$((viol + 1))
done <<EOF
$(grep -rnoE "className=[\"'\`][^\"'\`]*($SKELETON)[^\"'\`]*[\"'\`]" "$SRC" --include='*.tsx' --include='*.ts' 2>/dev/null)
$(grep -rnoE "className=[\"'\`]appshell[\"'\`]" "$SRC" --include='*.tsx' --include='*.ts' 2>/dev/null)
EOF

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "正典シェル部品ルール違反が $viol 件あります。"
  echo "サイドメニュー/ヘッダー/外殻は共有 <AppShell>（$PKG）を import して使ってください（自前で作り直さない）。"
  exit 1
fi
echo "OK: 正典シェル部品ルール 合格（共有 <AppShell> を import・ピン留め・骨格の自前記述なし）"
exit 0
