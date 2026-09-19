// Rebuild original vector artwork and web PNG exports with Node.js and sharp.
// Run from any directory: node app/tool/create_brand_assets.cjs
// Add --cover-only to refresh the store cover without touching launcher icons.
// Add --android-icons-only to refresh only Android launcher icons.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');

const root = path.resolve(__dirname, '../..');
const brand = path.join(root, 'branding');
const release = path.join(root, 'reports/release');
const web = path.join(root, 'app/web');
for (const directory of [brand, release, path.join(web, 'icons')]) {
  fs.mkdirSync(directory, { recursive: true });
}

const tiles = `<g font-family="Arial,sans-serif" font-weight="700" text-anchor="middle">
  <rect x="88" y="88" width="152" height="152" rx="26" fill="#fff8e8"/>
  <text x="164" y="198" font-size="104" fill="#173a67">S</text>
  <rect x="264" y="88" width="152" height="152" rx="26" fill="#fff8e8"/>
  <text x="340" y="198" font-size="104" fill="#173a67">W</text>
  <rect x="88" y="264" width="152" height="152" rx="26" fill="#28734f"/>
  <text x="164" y="374" font-size="104" fill="#ffffff">G</text>
  <rect x="264" y="264" width="152" height="152" rx="26" fill="#e8ad35"/>
  <path d="M339 382V310" stroke="#173a67" stroke-width="12" stroke-linecap="round"/>
  <path d="M339 352C297 354 290 326 299 313C321 313 340 330 339 352Z" fill="#173a67"/>
  <path d="M339 333C374 335 387 311 377 298C354 300 340 312 339 333Z" fill="#173a67"/>
</g>`;
const icon = `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<rect width="512" height="512" rx="92" fill="#173a67"/>${tiles}</svg>`;
// Maskable artwork keeps its entire mark inside the central 80% safe area.
const maskable = `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
<rect width="512" height="512" fill="#173a67"/><g transform="translate(39 39) scale(.8477)">${tiles}</g></svg>`;
const cover = `<svg xmlns="http://www.w3.org/2000/svg" width="1260" height="1000" viewBox="0 0 1260 1000">
<rect width="1260" height="1000" fill="#173a67"/>
<circle cx="1230" cy="80" r="460" fill="#244d79"/>
<circle cx="1190" cy="120" r="360" fill="none" stroke="#e8ad35" stroke-width="3" opacity=".5"/>
<g transform="translate(726 308) scale(.87) rotate(8 256 256)">${tiles}</g>
<g font-family="Arial,sans-serif">
<text x="82" y="125" font-size="26" letter-spacing="5" fill="#e8ad35">FIVE WORD AND LETTER GAMES</text>
<text x="75" y="316" font-size="156" font-weight="700" fill="#fff8e8">Sikhi</text>
<text x="75" y="475" font-size="140" font-weight="700" fill="#fff8e8">Word</text>
<text x="75" y="634" font-size="140" font-weight="700" fill="#fff8e8">Games</text>
<text x="82" y="735" font-size="33" fill="#f7e4bc">Guess words. Find words. Learn meanings.</text>
<path d="M82 774H1178" stroke="#527393" stroke-width="2"/>
<text x="82" y="825" font-size="28" fill="#fff8e8">English · Romanized Punjabi · Gurmukhi</text>
<text x="82" y="875" font-size="23" letter-spacing="2" fill="#e8ad35">BUJHO / KHOJ / WORD QUEST / JODO / LEARN LETTERS</text>
<text x="82" y="932" font-size="30" font-weight="700" fill="#fff8e8">Khalsa Game Studio</text>
<text x="82" y="975" font-size="25" fill="#f7e4bc">khalsagamestudio.com</text>
</g></svg>`;

async function writeAndroidIcons() {
  for (const [density, size] of Object.entries({
    mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192,
  })) {
    const directory = path.join(root, 'app/android/app/src/main/res', `mipmap-${density}`);
    fs.mkdirSync(directory, { recursive: true });
    await sharp(Buffer.from(icon)).resize(size).png().toFile(path.join(directory, 'ic_launcher.png'));
  }
}

async function main() {
  if (process.argv.includes('--android-icons-only')) {
    await writeAndroidIcons();
    console.log('Updated Android launcher icons at all five densities.');
    return;
  }
  if (!process.argv.includes('--cover-only')) {
    await writeAndroidIcons();
    fs.writeFileSync(path.join(brand, 'icon.svg'), icon);
    fs.writeFileSync(path.join(brand, 'icon-maskable.svg'), maskable);
    for (const size of [192, 512]) {
      await sharp(Buffer.from(icon)).resize(size).png().toFile(path.join(web, `icons/Icon-${size}.png`));
      await sharp(Buffer.from(maskable)).resize(size).png().toFile(path.join(web, `icons/Icon-maskable-${size}.png`));
    }
    await sharp(Buffer.from(icon)).resize(64).png().toFile(path.join(web, 'favicon.png'));
  }
  fs.writeFileSync(path.join(brand, 'itch-cover.svg'), cover);
  await sharp(Buffer.from(cover)).resize(630, 500).png().toFile(path.join(release, 'itch-cover-630x500.png'));
  console.log(process.argv.includes('--cover-only')
    ? 'Updated itch.io cover source and PNG.'
    : 'Created original branding sources, Android/web icons and itch.io cover.');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
