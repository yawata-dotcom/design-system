#!/bin/sh
# ============================================================
# 共通の道具セット 取り込みスクリプト（team-setup）
# 全員が「社長と同じ作業環境」で始めるために、標準のエージェント設定・作業ルール・
# 推奨設定を、自分の Claude Code 環境（~/.claude）へ安全に取り込みます。
#
# 安全設計：
#   ・既存ファイルを上書きする前に必ず .bak バックアップを作る。
#   ・ユーザーの設定(settings.json)・CLAUDE.md は勝手に置き換えない（案内のみ）。
#   ・スキルはライセンス配慮で同梱しないため、導入手順を表示するだけ。
#
# 使い方：  sh team-setup/setup.sh
# ============================================================

# このスクリプトのある場所（team-setup/）
SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEST="${HOME}/.claude"
stamp=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo bak)

echo "==========================================================="
echo " 共通の道具セットを取り込みます"
echo "  取り込み元 : $SRC"
echo "  取り込み先 : $DEST"
echo "==========================================================="

mkdir -p "$DEST/agents"

# 1) 標準エージェント定義 → ~/.claude/agents/
echo ""
echo "[1/4] 標準エージェントを取り込みます"
for f in "$SRC"/agents/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  [ "$base" = "README.md" ] && continue
  target="$DEST/agents/$base"
  if [ -f "$target" ] && ! cmp -s "$f" "$target"; then
    cp "$target" "$target.$stamp.bak"
    echo "  既存をバックアップ: $target.$stamp.bak"
  fi
  cp "$f" "$target"
  echo "  取り込み: agents/$base"
done

# 2) 共通の作業ルール → ~/.claude/CLAUDE.shared.md（既存 CLAUDE.md は触らない）
echo ""
echo "[2/4] 共通の作業ルールを置きます（既存のCLAUDE.mdは上書きしません）"
cp "$SRC/rules/CLAUDE.shared.md" "$DEST/CLAUDE.shared.md"
echo "  置きました: $DEST/CLAUDE.shared.md"
echo "  → 各製品の CLAUDE.md 冒頭から、この共通ルールと公開RULEBOOKを参照してください。"

# 3) 推奨設定（セキュリティ）の案内（settings.json は自動で書き換えない）
echo ""
echo "[3/4] 推奨設定（セキュリティ）"
echo "  ひな形: $SRC/settings.recommended.json"
echo "  内容（鍵・秘密ファイルを読まない等の安全設定）："
sed 's/^/    /' "$SRC/settings.recommended.json"
echo "  → 既存の ~/.claude/settings.json に、上の permissions.deny を取り込んでください。"
echo "    （自動では書き換えません。設定が壊れないよう手で反映してください）"

# 4) スキルの導入案内（ライセンス配慮で同梱なし）
echo ""
echo "[4/4] 標準スキルの導入"
echo "  一覧と入手元: $SRC/skills.manifest.md"
echo "  → まず find-skills を入れ、manifest の11スキルを ~/.claude/skills/ に導入してください。"

echo ""
echo "==========================================================="
echo " 完了。Claude Code を開き直すと、標準エージェントが使えます。"
echo " 最新の標準に追従するには、定期的に  git pull && sh team-setup/setup.sh"
echo "==========================================================="
