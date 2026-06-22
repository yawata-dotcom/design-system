// ============================================================
// アイコン色チェック（実測版・ヘッドレスブラウザ）：RULEBOOK §6
//   実際に描画された画面の computed color を測り、
//     ・選択中メニューのアイコン色 == --fblue（青）
//     ・ヘッダーのアイコン色       == --gray（グレー）
//   を照合する。静的番人 check-icon-color.sh が捕らえきれない
//   「実際の表示色のズレ」（MaterialIcon等で currentColor が継がれない等）を最終的に止める。
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
} catch (e) {
  console.error('NG: ページ読込/描画に失敗:', e.message);
  fail++;
}
await browser.close();

if (fail > 0) {
  console.error('----------------------------------------------');
  console.error(`実測アイコン色のちがいが ${fail} 件あります（RULEBOOK §6）。`);
  console.error('選択中メニュー=--fblue／ヘッダー=--gray を fill:currentColor で継いでください（MaterialIcon は使わない）。');
  process.exit(1);
}
console.log('OK: 実測アイコン色 合格（選択中=青／ヘッダー=グレー）');
