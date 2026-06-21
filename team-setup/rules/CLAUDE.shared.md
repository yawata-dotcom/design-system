# 全社共通の作業ルール（共有テンプレート）

これは全製品で共通の「進め方・絶対ルール」です。各製品の `CLAUDE.md` の冒頭から
これを参照してください（食い違ったら**公開RULEBOOKが優先**・変更は社長のみ）。

## 唯一の正＝公開RULEBOOK（作業前に必ず最新を読む）
- デザイン/UI/操作/アイコン/色/フォント/サイドメニュー・ヘッダーの最新ルールは
  **design-system の RULEBOOK が唯一の正**。
  - RULEBOOK：`https://raw.githubusercontent.com/yawata-dotcom/design-system/main/RULEBOOK.md`
  - 見本帳：`https://yawata-dotcom.github.io/design-system/gallery.html`
  - 色トークン：`https://raw.githubusercontent.com/yawata-dotcom/design-system/main/tokens.css`
  - 技術方針：`https://raw.githubusercontent.com/yawata-dotcom/design-system/main/TECH-POLICY.md`

## 守ること（要点）
1. **色は公式17トークンのみ**（直書きhex禁止）。
2. **アイコンは Material のみ**（`react-icons/md`・design-system/icons の公式SVG。絵文字・他セット・自作SVG禁止）。
3. **フォントは共通の正のみ**：`-apple-system,"Hiragino Kaku Gothic ProN","Yu Gothic",sans-serif`。
   「文字を細く見せる設定」(font-smoothing)は使わない。等幅はコード表示のみ。
4. **サイドメニュー・ヘッダーは共通骨格(shell.css)をそのまま使う**。
   各製品で骨格CSSを書き換えない（コピーは本家とビット一致が必須）。
   ヘッダーに製品独自の操作（セレクタ/トグル/絞り込み）を足さない＝本文へ。
5. **UIは見本帳の標準部品から作る**。無い部品は勝手に作らず社長に相談。

## 進め方
- 認識合わせ → 番号付きで1問ずつ確認 → 方針提示 → 1機能ずつ実装 → 出力前チェック → 動作確認依頼。
- **直push禁止**。ブランチ→PR→CI(番人)緑→マージで反映（mainは保護・管理者も例外なし）。
- 出力/反映の前に必ずバグチェック（最大5回・正確さ最優先）。
- **複数PC/複数人で並行作業するときは `team-setup/parallel-work.md` に従う**（作業前pull／タスクごとに別ブランチ／同じブランチを2台で共有しない／同一プロダクトは担当画面を分ける）。

## セキュリティ（厳守）
- 鍵・パスワード・トークンをコードに書かない／commitしない。`.env` は読まない/出さない。
- 実個人情報をリポに入れない（開発はダミー/マスクデータ）。
- **素性不明のAI・スキル・外部連携(MCP)を使わない**。使う道具は `team-setup` の標準のみ。
- 外部にデータ・命令を渡す設計にしない（プロンプトインジェクション注意）。

## CI（番人）で自動チェックされること
色 / アイコン / フォント / サイドメニュー・ヘッダー骨格 / ヘッダー中身 / 共通骨格ファイルの一致。
＝**どの道具で作っても、ルールに合わない成果物はマージできません。**
