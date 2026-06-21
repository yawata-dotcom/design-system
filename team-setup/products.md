# 製品台帳（全社プロダクト一覧と強制状況）

**新しいプロダクト（リポ）を作ったら、必ずこの表に追加し、番人＋ブランチ保護を入れる。**
ここを見れば「強制の外にいる製品」が一目で分かります（＝漏れ防止の見える化）。

| リポ | 種別 | 色/アイコン/フォント番人 | サイドメニュー/ヘッダー（共通シェル＋骨格一致＋ヘッダー番人） | ブランチ保護 |
|---|---|---|---|---|
| `design-system` | 公開・本家 | ✅（自リポも検査） | 正本（shell.css等の出どころ） | ✅ |
| `esecurity-system`（交通誘導警備） | React+mock | ✅ | ✅ 共通シェル採用済 | ✅ |
| `esupport-jinzai`（人材事業） | 静的(app) | ✅ | ✅ 共通シェル採用済 | ✅ |
| `portal`（共通ポータル） | 静的 | ✅ | － ヘッダー無しの特殊画面（対象外） | ✅ |
| `esupport-kensetsu`（建設） | React | ✅ | ✅ 共通シェル採用済（check-shell/appshell/vendored） | ✅ |

凡例：✅=導入済 ／ ⏳=未（予定） ／ －=対象外（理由を併記）

## 強制の効き方（大前提）
ロックは**パソコンではなくGitHubのリポ単位**で効く。どのPC・どの道具で書いても、
リポに番人＋ブランチ保護が入っていれば、ルール違反の成果物はマージできない。
＝**新しいリポを作ったら、その瞬間にこの仕組みを入れない限り「強制の外」になる。** だから下記を必須にする。

## 新プロダクトを作る時の必須手順（チェックリスト）
1. リポを作る（`yawata-dotcom/<名前>`）。
2. **`sh team-setup/bootstrap-repo.sh <そのリポのローカルパス>`** を実行（番人スクリプト＋CIひな形を配備）。
3. design-check.yml の検査対象パスを、その製品の実ファイルに合わせる（静的 or React）。
4. 共通シェル（サイドメニュー/ヘッダー）を使う製品は、shell.css を本家からコピー（vendored）し、
   `check-shell`/`check-header`/`check-vendored`（Reactは `check-appshell`）も有効化する。
5. **ブランチ保護を設定**（PR必須＋必須チェック`colors`＋`enforce_admins=true`）＝下記コマンド。
6. CLAUDE.md に共通ルール（team-setup/CLAUDE.shared）への参照を追記。
7. **この台帳に1行追加**。

### ブランチ保護コマンド（雛形）
```sh
gh api -X PUT repos/yawata-dotcom/<リポ>/branches/main/protection --input - <<'JSON'
{ "required_status_checks": { "strict": false, "contexts": ["colors"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null }
JSON
```
