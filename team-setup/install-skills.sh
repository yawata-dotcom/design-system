#!/bin/sh
# ============================================================
# 標準スキル 1コマンド自動導入（team-setup）
# skills-lock.json に記録された「正確な出所」をもとに、公式の Skills CLI
# （npx skills）で 11個の標準スキルをまとめて導入します。
#
# 使い方：
#   sh team-setup/install-skills.sh            … 実際に導入する
#   sh team-setup/install-skills.sh --dry-run  … 実行されるコマンドを表示するだけ
#
# 前提：Node.js（npx）が必要。導入は公式ツール `npx skills add <出所>@<名前> -g -y` を使う。
#       -g=ユーザー全体に導入 / -y=確認を省略。スキル本体はここには同梱せず、毎回正規の出所から取得。
# ============================================================

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
LOCK="$SRC/skills-lock.json"
DRY=0
[ "$1" = "--dry-run" ] && DRY=1

if [ ! -f "$LOCK" ]; then
  echo "NG: $LOCK が見つかりません"; exit 1
fi

# skills-lock.json から「出所@スキル名」の一覧を作る（python3 で安全に解析）
PKGS=$(python3 - "$LOCK" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
for name,info in d.get("skills",{}).items():
    src=info.get("source","")
    if src:
        print(f"{src}@{name}")
PY
)

if [ -z "$PKGS" ]; then
  echo "NG: skills-lock.json からスキルを読み取れませんでした"; exit 1
fi

echo "==========================================================="
echo " 標準スキルを導入します（公式 Skills CLI 経由）"
echo "==========================================================="

if [ "$DRY" -eq 0 ] && ! command -v npx >/dev/null 2>&1; then
  echo "NG: npx（Node.js）が見つかりません。Node.js を入れてから再実行してください。"
  echo "    入れずに中身だけ見る場合： sh team-setup/install-skills.sh --dry-run"
  exit 1
fi

n=0
for pkg in $PKGS; do
  n=$((n+1))
  echo ""
  echo "[$n] $pkg"
  if [ "$DRY" -eq 1 ]; then
    echo "    （dry-run）npx skills add \"$pkg\" -g -y"
  else
    npx skills add "$pkg" -g -y || echo "    ※ $pkg の導入に失敗。手動確認： https://skills.sh/ で名前を検索"
  fi
done

echo ""
echo "==========================================================="
echo " 完了（$n 件）。Claude Code を開き直すとスキルが使えます。"
echo " 更新確認は  npx skills check  /  更新は  npx skills update"
echo "==========================================================="
