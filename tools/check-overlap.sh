#!/bin/sh
# ============================================================
# 重なりチェック：このPRが「他の開いているPR」と同じファイルを触っていたら赤で止める。
#   ＝同じ画面（ファイル）を2つのPRが同時にマージするのを実質的に禁止する。
#   人ではなく"ファイルの重なり"で判定するので、同じGitHubアカウント1人で2台でも効く。
#   正本＝ design-system/tools/check-overlap.sh（更新時はそちらに合わせて各製品へ配布）。
#
# 使い方（CI / pull_request イベント時）：
#   sh tools/check-overlap.sh <このPR番号>
#   ・GH_TOKEN（GitHub Actions の GITHUB_TOKEN）が必要。
#   ・PR番号が無い（push 等）→ skip して終了0。
# 自己テスト（gh 不要・積集合ロジックの確認）：
#   sh tools/check-overlap.sh --self-test
#
# 重なりがあったら：先に相手のPRをマージ→このブランチで
#   git pull --rebase origin main → 出し直す（重なりが消えれば緑になる）。
# ============================================================

# --- 自己テスト（オフライン）------------------------------------------------
if [ "$1" = "--self-test" ]; then
  ta=$(mktemp); tb=$(mktemp)
  printf 'src/a.tsx\nsrc/b.tsx\n' | sort > "$ta"
  printf 'src/b.tsx\nsrc/c.tsx\n' | sort > "$tb"
  common=$(comm -12 "$ta" "$tb"); rm -f "$ta" "$tb"
  if [ "$common" = "src/b.tsx" ]; then echo "self-test OK"; exit 0; fi
  echo "self-test FAIL: [$common]"; exit 1
fi

PR="$1"
if [ -z "$PR" ]; then
  echo "OK(skip): PR番号がありません（push 等）。重なりチェックは pull_request のみ。"
  exit 0
fi

REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)}"
if [ -z "$REPO" ]; then
  echo "WARN: リポジトリを特定できません。重なりチェックをスキップします。"
  exit 0
fi

# このPRの変更ファイル
curfile=$(mktemp)
gh api "repos/$REPO/pulls/$PR/files" --paginate -q '.[].filename' 2>/dev/null | sort -u > "$curfile"
if [ ! -s "$curfile" ]; then
  echo "OK(skip): このPRの変更ファイルを取得できませんでした。"
  rm -f "$curfile"; exit 0
fi

# 他の開いているPR
others=$(gh pr list --repo "$REPO" --state open --json number -q '.[].number' 2>/dev/null)

viol=0
for o in $others; do
  [ "$o" = "$PR" ] && continue
  ofile=$(mktemp)
  gh api "repos/$REPO/pulls/$o/files" --paginate -q '.[].filename' 2>/dev/null | sort -u > "$ofile"
  common=$(comm -12 "$curfile" "$ofile")
  rm -f "$ofile"
  if [ -n "$common" ]; then
    echo "NG: 開いているPR #$o と同じファイルを編集しています："
    printf '%s\n' "$common" | sed 's/^/    - /'
    viol=$((viol + 1))
  fi
done
rm -f "$curfile"

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "他の開いているPRと同じファイルを触っています（同時マージ防止のため停止）。"
  echo "対応：先に相手のPRをマージ → このブランチで  git pull --rebase origin main  → 出し直してください。"
  exit 1
fi
echo "OK: 他の開いているPRとファイルの重なりはありません。"
exit 0
