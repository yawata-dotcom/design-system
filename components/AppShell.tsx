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

/** ヘッダーの役割（権限）セレクタ＝.rolesw の <select> に注入する値 */
export type ShellRole = {
  /** 選択肢（例: ['管理者'] / ['① 統括管理者','② 受入支援担当', …]） */
  options: string[];
  /** 現在値（任意） */
  value?: string;
  /** 変更時（任意・指定すると制御コンポーネント、未指定なら表示のみ） */
  onChange?: (value: string) => void;
  /** スクリーンリーダー用ラベル（既定 '権限'） */
  ariaLabel?: string;
};

/**
 * ヘッダー（共通上バー）の中身＝正典シェル(shell-demo.html)の固定5点セット。
 * 各製品は「値」を注入するだけ。枠・並び・アイコン・「最終同期」ラベルは本部品が必ず描く
 * ＝省略・改変できない（構造のズレを仕組みで防ぐ）。
 */
export type ShellTopbar = {
  /** 最終同期の値（例 '2026-06-05 14:21'）。ラベル「最終同期 」は本部品が付ける（.sync で左寄せ） */
  lastSync: React.ReactNode;
  /** 対象期間（例 '2026-04-01 〜 2027-03-31'） */
  period: React.ReactNode;
  /** 会社名／事業名（例 '株式会社○○'） */
  company: React.ReactNode;
  /** 役割（権限）セレクタ */
  role: ShellRole;
  /** 認証スロット（ログイン/ログアウト・メール等。任意。next-auth 等の依存は本部品に持たせない＝各製品が要素を渡す） */
  auth?: React.ReactNode;
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
  /** ヘッダー（上バー）の固定5点セット（最終同期/期間/会社/役割/ヘルプ）＋認証スロット。値を注入するだけ。 */
  topbar: ShellTopbar;
  /** メイン領域（各画面の中身） */
  children: React.ReactNode;
};

/* 正典シェル(shell-demo.html)のヘッダー公式アイコン（Material Design Icons）を内蔵。
   react-icons 等に依存させない＝どの製品でも壊れずに同じ形が出る。 */
const IC_SYNC =
  'M17.65 6.35A7.958 7.958 0 0012 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08A5.99 5.99 0 0112 18c-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z';
const IC_PERIOD =
  'M20 3h-1V1h-2v2H7V1H5v2H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 18H4V8h16v13z';
const IC_COMPANY =
  'M20 6h-4V4c0-1.11-.89-2-2-2h-4c-1.11 0-2 .89-2 2v2H4c-1.11 0-1.99.89-1.99 2L2 19c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V8c0-1.11-.89-2-2-2zm-6 0h-4V4h4v2z';
const IC_ROLE =
  'M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z';
const IC_HELP =
  'M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 17h-2v-2h2v2zm2.07-7.75l-.9.92C13.45 12.9 13 13.5 13 15h-2v-.5c0-1.1.45-2.1 1.17-2.83l1.24-1.26c.37-.36.59-.86.59-1.41 0-1.1-.9-2-2-2s-2 .9-2 2H8c0-2.21 1.79-4 4-4s4 1.79 4 4c0 .88-.36 1.68-.93 2.25z';

function TopIcon({ d }: { d: string }) {
  return (
    <svg className="ic" viewBox="0 0 24 24" aria-hidden="true">
      <path d={d} />
    </svg>
  );
}

/** ヘッダー（上バー）：固定5点セットを必ず描く。各製品は値（topbar props）を注入するだけ。 */
function Topbar({ lastSync, period, company, role, auth }: ShellTopbar) {
  return (
    <div className="appshell-topbar">
      <span className="sync">
        <TopIcon d={IC_SYNC} />最終同期 {lastSync}
      </span>
      <span>
        <TopIcon d={IC_PERIOD} />{period}
      </span>
      <span>
        <TopIcon d={IC_COMPANY} />{company}
      </span>
      <span className="rolesw">
        <TopIcon d={IC_ROLE} />
        <select
          aria-label={role.ariaLabel ?? '権限'}
          {...(role.onChange
            ? { value: role.value, onChange: (e: React.ChangeEvent<HTMLSelectElement>) => role.onChange!(e.target.value) }
            : { defaultValue: role.value })}
        >
          {role.options.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
      </span>
      {auth ? <span className="authslot">{auth}</span> : null}
      <span>
        <TopIcon d={IC_HELP} />
      </span>
    </div>
  );
}

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
        <Topbar {...topbar} />
        <div className="appshell-content">{children}</div>
      </div>
    </div>
  );
}

export default AppShell;
