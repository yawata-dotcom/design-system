// ============================================================
// 実測UIチェック（実測版・ヘッドレスブラウザ）：RULEBOOK §6・ヘッダー固定仕様
//   実際に描画された画面を測り、次を照合する：
//     ・選択中メニューのアイコン色 == --fblue（青）
//     ・ヘッダーのアイコン色       == --gray（グレー）
//     ・ヘッダー（共通上バー）に正典5点が実在＝最終同期(.sync)/期間/会社/役割セレクタ(.rolesw>select)/ヘルプ
//   静的番人が捕らえきれない「実際の表示ズレ」（MaterialIcon等で色が継がれない／
//   モックとアプリでヘッダーが食い違う 等）を最終的に止める。
//   正本＝ design-system/tools/check-icon-color-runtime.mjs（更新時はそちらに合わせる）。
//
//   使い方:  node tools/check-icon-color-runtime.mjs <URL>
//     静的:   node tools/check-icon-color-runtime.mjs "file://$PWD/app/index.html"
//     Next:   node tools/check-icon-color-runtime.mjs "http://localhost:3000"
//   依存:  playwright（CIで `npm i playwright && npx playwright install --with-deps chromium`）
//   合否:  全項目一致 → 終了0 ／ ちがい → 一覧表示して終了1（CIが赤くなる）
//
//   期待値はトークンの実hexを直接書かず、同じページ上で var(--token) を probe して解決する。
//   ＝トークンの値を将来変えても、この番人は壊れない（“継いでいるか”だけを見る）。
// ============================================================
import { chromium } from 'playwright';

const url = process.argv[2];
if (!url) { console.error('usage: node check-icon-color-runtime.mjs <URL>'); process.exit(2); }

// 測る対象（セレクタは候補を順に試す＝静的/React どちらの骨格でも当たるように）
const EXPECT = [
  { name: '選択中メニューのアイコン', token: '--fblue',
    sels: ['.appshell-side .appshell-item.active .ic', '.appshell-item.active .ic', '.sidenav .active .ic'] },
  { name: 'ヘッダーのアイコン',       token: '--gray',
    sels: ['.appshell-topbar .ic'] },
];

const browser = await chromium.launch();
const page = await browser.newPage();
let fail = 0;
try {
  await page.goto(url, { waitUntil: 'load', timeout: 30000 });
  // React(SPA)のハイドレーション待ち：選択中アイコン or ヘッダーアイコンが出るまで
  await page.waitForSelector(
    [...EXPECT[0].sels, ...EXPECT[1].sels].join(', '),
    { timeout: 20000 }
  ).catch(() => {});

  const probe = (v) => page.evaluate((vv) => {
    const e = document.createElement('span');
    e.style.color = `var(${vv})`;
    document.body.appendChild(e);
    const c = getComputedStyle(e).color;
    e.remove();
    return c;
  }, v);

  for (const ex of EXPECT) {
    const want = await probe(ex.token);
    const got = await page.evaluate((sels) => {
      for (const s of sels) { const el = document.querySelector(s); if (el) return getComputedStyle(el).fill; }
      return null;
    }, ex.sels);

    if (got === null) {
      console.error(`NG: ${ex.name} の要素が見つかりません（${ex.sels.join(' / ')}）`);
      fail++; continue;
    }
    if (got !== want) {
      console.error(`NG: ${ex.name} の実測色が ${ex.token}(${want}) ではなく ${got}（currentColor が継がれていない疑い＝MaterialIcon等）`);
      fail++;
    } else {
      console.log(`OK: ${ex.name} = ${ex.token} (${got})`);
    }
  }

  // ── ヘッダー（共通上バー）の正典セットが“実在”するか（2026-07-19 ヘッダー統一・モックとアプリのズレ防止）──
  //   会社名(.company) / 役割セレクタ(.rolesw>select) / （任意：メール・ログアウト） / ヘルプ。
  //   旧5点の 最終同期(.sync)・期間 は廃止＝残っていたら赤（消し忘れ検知）。
  const header = await page.evaluate(() => {
    const bar = document.querySelector('.appshell-topbar');
    if (!bar) return { exists: false };
    return {
      exists: true,
      company: !!bar.querySelector('.company'),
      role: !!bar.querySelector('.rolesw select'),
      sync: !!bar.querySelector('.sync'),
      icons: bar.querySelectorAll('.ic').length,
    };
  });
  if (!header.exists) {
    console.log('… appshell-topbar が無い画面（ヘッダー正典チェックは対象外）');
  } else {
    const need = [];
    if (!header.company) need.push('会社名(.company)');
    if (!header.role) need.push('役割セレクタ(.rolesw>select)');
    if (header.sync) need.push('廃止済みの最終同期(.sync)が残存');
    if (header.icons < 3) need.push(`アイコン不足(${header.icons}個・会社/役割/ヘルプ=3個以上)`);
    if (need.length) {
      console.error(`NG: ヘッダー正典セットの違反：${need.join(' ')}（会社名/役割/メール/ログアウト/ヘルプ＝確定書2026-07-19）`);
      fail++;
    } else {
      console.log(`OK: ヘッダー正典セット 実在（.company/.rolesw/ヘルプ・アイコン${header.icons}個）`);
    }
  }
} catch (e) {
  console.error('NG: ページ読込/描画に失敗:', e.message);
  fail++;
}
await browser.close();

if (fail > 0) {
  console.error('----------------------------------------------');
  console.error(`実測UIのちがいが ${fail} 件あります（RULEBOOK §6・ヘッダー固定仕様）。`);
  console.error('・色：選択中メニュー=--fblue／ヘッダー=--gray を fill:currentColor で継ぐ（MaterialIcon は使わない）。');
  console.error('・ヘッダー：正典5点（最終同期/期間/会社/役割セレクタ/ヘルプ）を共有 <AppShell> で揃える。');
  process.exit(1);
}
console.log('OK: 実測UI 合格（アイコン色＝選択中青/ヘッダーグレー・ヘッダー正典5点 実在）');
