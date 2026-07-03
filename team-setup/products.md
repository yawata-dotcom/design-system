# 製品台帳（全社プロダクト一覧と強制状況）

**新しいプロダクト（リポ）を作ったら、必ずこの表に追加し、番人＋ブランチ保護を入れる。**
ここを見れば「強制の外にいる製品」が一目で分かります（＝漏れ防止の見える化）。

| リポ | 種別 | 色/アイコン/フォント番人 | アイコン色番人（静的／実測Playwright） | サイドメニュー/ヘッダー（共通シェル＋骨格一致＋ヘッダー番人） | ブランチ保護 |
|---|---|---|---|---|---|
| `design-system` | 公開・本家 | ✅（自リポも検査） | ✅ 静的（正本）／✅ 実測（正典 shell-demo.html を自己検査） | 正本（shell.css等の出どころ） | ✅ |
| `esecurity-system`（交通誘導警備） | React+mock | ✅ | ✅ 静的／✅ 実測 | ✅ 共通シェル採用済 | ✅ |
| `esupport-jinzai`（人材事業） | 静的(app) | ✅ | ✅ 静的／✅ 実測 | ✅ 共通シェル採用済 | ✅ |
| `portal`（共通ポータル） | 静的 | ✅ | ✅ 静的／－ 実測（選択メニュー/ヘッダー無し＝対象外） | － ヘッダー無しの特殊画面（対象外） | ✅ |
| `esupport-kensetsu`（建設） | React | ✅ | ✅ 静的／✅ 実測 | ✅ 共通シェル採用済（check-shell/appshell/vendored） | ✅ |
| `esupport-honsha`（本社管理） | 静的(mock) | ✅ | ✅ 静的／✅ 実測 | ✅ 共通シェル採用済 | ✅ |

凡例：✅=導入済 ／ ⏳=未（予定） ／ －=対象外（理由を併記）

> **アイコン色番人**（2026-06-22 追加）：アイコンが文脈の正しいトークン色を“実際に”出しているかを守る2本立て。
> ・静的 `tools/check-icon-color.sh`＝`MaterialIcon`の使用／`.ic`が`fill:currentColor`を継がない・固定塗り／アイコンSVGの直書きhex を検出（CIで必須）。
> ・実測（Playwright）＝実画面の computed color で「選択中メニュー=`--fblue`／ヘッダー=`--gray`」を照合（AppShellを持つ製品のみ。portal は対象外）。
>
> **ヘッダー番人**（2026-06-22 追加）：ヘッダーがモック（正典5点＝最終同期/期間/会社/役割セレクタ/ヘルプ）からズレないように守る。
> ・**構造を仕組みで固定**：共有 `<AppShell>` が5点を必ず描く＝Reactは `topbar={{ lastSync, period, company, role, auth? }}` の**必須propsを注入するだけ**（省略は型エラー＝ビルド赤）。`v0.2.0` 以降。
> ・静的 `tools/check-header.sh`＝静的HTMLで5点の存在＋製品独自操作の混入を検査（対象に app/src も追加）。
> ・実測（Playwright）＝実画面に5点が実在するかを照合（`check-icon-color-runtime.mjs` に相乗り。AppShellを持つ製品のみ）。

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
   さらに**実測番人**：design-check.yml に `runtime` ジョブを足す（静的は `file://…/index.html`、Next は `npm ci && build` → `start` → `node tools/check-icon-color-runtime.mjs http://localhost:3000`）。ヘッダー/選択メニューが無い特殊画面（例：portal）は実測対象外。
5. **ブランチ保護を設定**（PR必須＋必須チェック`colors`、実測番人を入れた製品は`runtime`も追加＋`enforce_admins=true`）＝下記コマンド。
6. CLAUDE.md に共通ルール（team-setup/CLAUDE.shared）への参照を追記。
7. **この台帳に1行追加**。

### ブランチ保護コマンド（雛形）
```sh
gh api -X PUT repos/yawata-dotcom/<リポ>/branches/main/protection --input - <<'JSON'
{ "required_status_checks": { "strict": false, "contexts": ["colors", "runtime"] },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null }
JSON
```
