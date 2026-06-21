/* =========================================================
   正典シェル React 部品 <AppShell> ／全プロダクト共通
   ---------------------------------------------------------
   ・見た目（外殻/サイドバー/ヘッダー）の唯一の正＝この部品＋ shell.css。
   ・各製品は「使うだけ」：メニュー内容・遷移・認証・ヘッダー中身は props で注入する。
   ・react にのみ依存（next / next-auth は持たない＝どの製品でも使える・壊れにくい）。
   ・出力する DOM は shell-demo.html / shell.css のクラス（appshell 名前空間）に一致させる。
   ・このマークアップを各製品が自前で書き直すのを禁止（import して使う＝真の強制）。
   ・変更できるのは社長のみ。
   ========================================================= */
import * as React from 'react';

/** サイドメニューの1項目 */
export type ShellItem = {
  /** 表示名 */
  title: string;
  /** 行頭アイコン（任意・各製品が <svg className="ic">… 等を渡す） */
  icon?: React.ReactNode;
  /** 遷移先。指定があれば押せる項目、無ければ「近日公開」のグレー項目 */
  href?: string;
  /** 近日公開バッジ等の短いラベル */
  badge?: string;
  /** 選択中（現在地）かどうか */
  active?: boolean;
};

/** サイドメニューの1セクション（見出し＋項目群） */
export type ShellSection = {
  label: string;
  items: ShellItem[];
};

export type AppShellProps = {
  /** ブランド領域（製品名・ロゴ等）。文字列なら <span> で包む */
  brand: React.ReactNode;
  /** 事業ランチャー（任意・ブランド右の□ボタン＋パネル一式を渡す。appshell-launchwrap で包む） */
  launcher?: React.ReactNode;
  /** サイドメニュー */
  sections: ShellSection[];
  /** href のある項目を押したとき（遷移は各製品の流儀＝router 等で行う） */
  onNavigate?: (href: string) => void;
  /** ヘッダー（上バー）の中身。会社名・ユーザー・権限・ログイン等を渡す（外枠 appshell-topbar は本部品が描く） */
  topbar?: React.ReactNode;
  /** メイン領域（各画面の中身） */
  children: React.ReactNode;
};

/**
 * 正典シェル。外殻・サイドバー・ヘッダーの骨格を固定し、中身だけを props で受ける。
 * 見た目は shell.css（と tokens.css）が与える。
 */
export function AppShell({
  brand,
  launcher,
  sections,
  onNavigate,
  topbar,
  children,
}: AppShellProps) {
  return (
    <div className="appshell">
      <nav className="appshell-side" aria-label="メインメニュー">
        <div className="appshell-brand">
          {typeof brand === 'string' ? <span>{brand}</span> : brand}
          {launcher ? <div className="appshell-launchwrap">{launcher}</div> : null}
        </div>

        {sections.map((sec) => (
          <React.Fragment key={sec.label}>
            <div className="appshell-seclabel">{sec.label}</div>
            {sec.items.map((it) =>
              it.href ? (
                <button
                  key={it.title}
                  className={`appshell-item${it.active ? ' active' : ''}`}
                  onClick={onNavigate ? () => onNavigate(it.href!) : undefined}
                >
                  {it.icon}
                  {it.title}
                </button>
              ) : (
                <button
                  key={it.title}
                  className="appshell-item soon"
                  disabled
                  aria-disabled="true"
                  title={it.badge ? `近日公開（${it.badge}）` : undefined}
                >
                  {it.icon}
                  {it.title}
                  {it.badge ? <span className="badge">{it.badge}</span> : null}
                </button>
              )
            )}
          </React.Fragment>
        ))}
      </nav>

      <div className="appshell-main">
        <div className="appshell-topbar">{topbar}</div>
        <div className="appshell-content">{children}</div>
      </div>
    </div>
  );
}

export default AppShell;
