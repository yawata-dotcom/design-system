# 標準スキル一覧（manifest）

全社で使う「標準スキル」はこの11個です。**これ以外を勝手に足さない**（足したい時は社長に相談＝PRで追加）。
ライセンス配慮のため実体はこのリポに同梱しません。各自が同じ公開元から `~/.claude/skills/`（または
プロジェクトの `.claude/skills/`）へ導入してください。迷ったら `find-skills` スキルが探索・導入を助けます。

| スキル | 用途（いつ使う） | ライセンス/出所 |
|---|---|---|
| `frontend-design` | 高品質なUI/画面・コンポーネントを作る | Anthropic（LICENSE.txt） |
| `ui-ux-pro-max` | UI/UXの設計知（スタイル/配色/フォント/UX指針） | 公開スキル |
| `web-design-guidelines` | UIコードをWeb設計指針で点検 | Vercel |
| `accessibility` | アクセシビリティ(WCAG2.2)の監査・改善 | MIT |
| `fixing-accessibility` | ARIA/キーボード/コントラスト等の修正 | 公開スキル |
| `performance` | 表示速度・読み込みの最適化 | MIT |
| `design-tokens` | デザイントークン（CSS変数/Tailwind）生成 | 公開スキル |
| `brand-guidelines` | ブランド配色・タイポの適用 | Anthropic（LICENSE.txt） |
| `kpi-dashboard-design` | KPIダッシュボードの設計 | 公開スキル |
| `chart-visualization` | グラフ・データ可視化 | 公開スキル |
| `find-skills` | 必要なスキルを探して入れる（入口） | 公開スキル |

## 導入の考え方
1. まず `find-skills` を入れる（これがあれば他を探して導入できる）。
2. 上の表のスキルを `~/.claude/skills/<名前>/` に置く（各スキルは自己完結フォルダ）。
3. 導入後、Claude Code を開けば自動で認識されます。

> 注意：ここに無いスキル・外部の素性不明なスキルは使わない（情報漏えい・品質ブレ防止）。
> 標準を増やす判断は社長のみ＝この manifest を PR で更新してから使う。
