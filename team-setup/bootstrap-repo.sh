#!/bin/sh
# ============================================================
# 新プロダクト 一発セットアップ（team-setup）
# 新しいリポを「共通ルールの強制下」に置くため、番人スクリプトとCIひな形を配備する。
# ＝新製品が強制の外に出ないようにするための仕掛け（products.md と対）。
#
# 使い方：  sh team-setup/bootstrap-repo.sh <対象リポのローカルパス>
#   例)     sh team-setup/bootstrap-repo.sh ~/Claude/projects/esupport-new
#
# これがやること：
#   1) 対象リポに tools/ を作り、本家の番人スクリプトを全種コピー
#   2) .github/workflows/design-check.yml のひな形を配備（無ければ）
#   3) 仕上げ手順（検査対象パスの調整・共通シェル・ブランチ保護・台帳追記）を表示
# ※ファイルを置くだけ。push やブランチ保護は行わない（最後は人がPR＋保護設定）。
# ============================================================

SRC=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)        # team-setup/
DSROOT=$(CDPATH= cd -- "$SRC/.." && pwd)                # design-system ルート
TARGET="$1"

if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "使い方: sh team-setup/bootstrap-repo.sh <対象リポのローカルパス>"
  echo "  例)   sh team-setup/bootstrap-repo.sh ~/Claude/projects/esupport-new"
  exit 1
fi

echo "==========================================================="
echo " 新プロダクトを共通ルールの強制下に置きます"
echo "  対象: $TARGET"
echo "==========================================================="

# 1) 番人スクリプトを全種コピー
mkdir -p "$TARGET/tools"
for s in check-colors.sh check-icons.sh check-font.sh check-shell.sh check-header.sh check-vendored.sh check-appshell.sh; do
  if [ -f "$DSROOT/tools/$s" ]; then
    cp "$DSROOT/tools/$s" "$TARGET/tools/$s"; chmod +x "$TARGET/tools/$s"
    echo "  配備: tools/$s"
  fi
done

# 2) CI ひな形（無ければ）
mkdir -p "$TARGET/.github/workflows"
CI="$TARGET/.github/workflows/design-check.yml"
if [ -f "$CI" ]; then
  echo "  既存の design-check.yml はそのまま（上書きしません）"
else
  cat > "$CI" <<'YML'
name: design-check
# 全社共通ルール（design-system / RULEBOOK）に沿っているか機械チェック。
# ▼ 検査対象パスは、この製品の実ファイルに合わせて必ず調整すること（下記は例）。
on:
  push:
  pull_request:

jobs:
  colors:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # --- 静的(HTML/CSS)なら例: app  ／ Reactなら例: app/src に変える ---
      - name: 色チェック（公式17色のみ）
        run: sh tools/check-colors.sh app
      - name: アイコンチェック（Material のみ）
        run: sh tools/check-icons.sh app
      - name: フォントチェック（共通フォントのみ・細く見せる設定禁止）
        run: sh tools/check-font.sh app
      # --- 共通シェル（サイドメニュー/ヘッダー）を使う製品は以下も有効化 ---
      # - name: シェルチェック
      #   run: sh tools/check-shell.sh app
      # - name: ヘッダー中身チェック
      #   run: sh tools/check-header.sh app
      # - name: 共通骨格ファイル一致チェック
      #   run: sh tools/check-vendored.sh app/shell.css app/tokens.css
      # --- React で共通AppShellを使う製品は以下も有効化 ---
      # - name: 正典シェル部品チェック
      #   run: sh tools/check-appshell.sh
YML
  echo "  配備: .github/workflows/design-check.yml（ひな形）"
fi

echo ""
echo "----------------------------------------------"
echo " 仕上げ（人が行う）："
echo "  1) design-check.yml の検査対象パスを実ファイルに合わせる（静的=app / React=app/src 等）"
echo "  2) サイドメニュー/ヘッダーを使うなら shell.css を本家からコピーし、shell/header/vendored(+appshell)を有効化"
echo "  3) CLAUDE.md に team-setup/CLAUDE.shared への参照を追記"
echo "  4) ブランチ保護を設定（PR必須＋必須チェック colors＋enforce_admins）："
echo "       gh api -X PUT repos/yawata-dotcom/<リポ>/branches/main/protection --input - <<'JSON'"
echo "       { \"required_status_checks\": { \"strict\": false, \"contexts\": [\"colors\"] },"
echo "         \"enforce_admins\": true,"
echo "         \"required_pull_request_reviews\": { \"required_approving_review_count\": 0 },"
echo "         \"restrictions\": null }"
echo "       JSON"
echo "  5) team-setup/products.md（製品台帳）に1行追加"
echo "----------------------------------------------"
