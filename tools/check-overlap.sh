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
#
# 【先に開いたPRを通す（2026-11-10 社長「はい、直して」）】
#   赤にするのは「自分より番号が若い（＝先に開いた）PR」と重なる時だけ。
#   自分の方が先なら緑のまま「後から来た #N と重なる」と知らせるだけ。
#   ＝重なっている PR のうち、いちばん古い1本はいつでも通れる（両方赤のお見合いをなくす）。
#   経緯＝2026-11-10 台帳 daicho#1127・#1128・#1129 が同じファイルで互いを赤にし、全部止まった。
#   ⚠ 古い PR を閉じて開き直すと、閉じていた間に緑になった新しい側も緑のまま残る
#     （番人は相手の判定をやり直さない）。開き直したら、新しい側の番人を
#     gh run rerun で1回やり直す（赤に戻る＝正しい）。
# ============================================================

# 先着の判定：相手(other)が自分(this)より先に開いた PR なら 0（＝こちらが待つ側＝赤）
other_is_earlier() {
  [ "$2" -lt "$1" ]
}

# --- 自己テスト（オフライン）------------------------------------------------
if [ "$1" = "--self-test" ]; then
  ta=$(mktemp); tb=$(mktemp)
  printf 'src/a.tsx\nsrc/b.tsx\n' | sort > "$ta"
  printf 'src/b.tsx\nsrc/c.tsx\n' | sort > "$tb"
  common=$(comm -12 "$ta" "$tb"); rm -f "$ta" "$tb"
  if [ "$common" != "src/b.tsx" ]; then echo "self-test FAIL: [$common]"; exit 1; fi
  # 先着の判定（自分 1128・相手 1127 ＝相手が先＝待つ／自分 1127・相手 1128 ＝自分が先＝通す）
  if ! other_is_earlier 1128 1127; then echo "self-test FAIL: 先着（相手が先）"; exit 1; fi
  if other_is_earlier 1127 1128; then echo "self-test FAIL: 先着（自分が先）"; exit 1; fi
  if other_is_earlier 1127 1127; then echo "self-test FAIL: 先着（同じ番号）"; exit 1; fi
  echo "self-test OK"; exit 0
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
    if other_is_earlier "$PR" "$o"; then
      echo "NG: 先に開いている PR #$o と同じファイルを編集しています："
      printf '%s\n' "$common" | sed 's/^/    - /'
      viol=$((viol + 1))
    else
      echo "注意: 後から開いた PR #$o と同じファイルを触っています（こちらが先＝このPRは通します・#$o は待ちます）："
      printf '%s\n' "$common" | sed 's/^/    - /'
    fi
  fi
done
rm -f "$curfile"

if [ "$viol" -gt 0 ]; then
  echo "----------------------------------------------"
  echo "先に開いているPRと同じファイルを触っています（同時マージ防止のため停止・先に開いた方が通ります）。"
  echo "対応：先に相手のPRをマージ → このブランチで  git pull --rebase origin main  → 出し直してください。"
  exit 1
fi
echo "OK: 先に開いているPRとのファイルの重なりはありません。"
exit 0
