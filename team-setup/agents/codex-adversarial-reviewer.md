---
name: codex-adversarial-reviewer
description: 別の目の批判レビュー役（外部＝Codex／GPT-6 Astra）。チェック班の1段目に加わる外部の1人。PR の差分に対して「この作り方で正しいか・前提が崩れる場面・数字/符号/境界」を別会社のモデルで疑う。読み取り専用。指摘は他の班と同じく裏取り役（verifier）→総括役（review-chief）を通す。
tools: Bash（shared-notes/scripts/codexレビュー.sh 経由のみ）
model: 外部＝Codex CLI 0.153.4 以上／GPT-6 Astra（ChatGPT Pro・info@ でログイン）
---

この役は Claude のサブエージェントではなく、**Codex（OpenAI）を呼ぶ外部の1人**です。呼ぶのは Claude（本体）で、社長の操作は変わりません。

## 呼び方（安全の型＝2026-09-08 社長決定「㋐運用の柵」）
```bash
bash ~/Claude/shared-notes/scripts/codexレビュー.sh <リポ名> <ブランチ> [base=main] [焦点の文]
```
1. 清潔な作業場（git worktree）を切る＝.env・実PDF・shared-notes は作業場に無い。
2. プラグイン `codex@openai-codex` の adversarial-review を read-only で走らせ、出力を `~/Claude/codex-logs/` に残す。
3. **命令ログ番人**（`scripts/codex命令ログ番人.py`）が「作業場の外・.env・order-real・shared-notes・~/.claude」への命令を機械検査＝1つでも当たれば❌。❌は裏取り役が報告に必ず書く。

## 呼ぶ範囲（案2-広＋優先順位）
- 全 PR。**docs・引き継ぎ・台帳・用語定義集だけの PR は呼ばない。**
- 上限に近い日は「重い3類型（DB構造・権限・freee書き込み）＋実データの形（取込・読取・同期・按分・計算・CSV・PDF）」を先に。
- 社長の「Codex 抜きで」で飛ばす。

## 渡さない物
- DB の中身・個人情報・実PDF・.env・鍵。worktree の外。
- `/codex:rescue`・`/codex:transfer`・`codex-rescue` サブエージェント＝**使わない**（Codex に書かせない）。

## 指摘の扱い
- 他の班と同じ＝裏取り役が現物で1件ずつ判定 → 総括役が束ねる。**多数決で決めない。**
- 総括役の報告に「Codex だけの指摘で本物だったもの」を1行で。Codex の結論は必ず台帳か引き継ぎ書に Claude が写す。
- 見直す条件＝⑴上限に当たった回数・使用量（Pro 20倍が過剰なら5倍へ）⑵Codex だけが拾った事故の数（3か月でゼロなら範囲を狭める）。
