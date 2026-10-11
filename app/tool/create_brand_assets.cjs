// Regenerate the approved S + ਗ identity with Node.js and sharp.
// --icons-only leaves the release cover alone; --cover-only leaves icons alone.
// --android-icons-only refreshes just the five Android launcher densities.
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');

const root = path.resolve(__dirname, '../..');
const brand = path.join(root, 'branding');
const release = path.join(root, 'reports/release');
const web = path.join(root, 'app/web');
const letterforms = require('../../branding/letterforms.json');
const colors = { ink: '#172e33', teal: '#10535d', paper: '#fff7e5', peach: '#edbc93' };

// Font-derived paths keep Gurmukhi intact without installed fonts or raster text.
function letter(key, cx, cy, height, color) {
  const glyph = letterforms[key];
  const [left, bottom, right, top] = glyph.bounds;
  const scale = height / (top - bottom);
  return `<path d="${glyph.path}" fill="${color}" transform="translate(${cx} ${cy}) scale(${scale} ${-scale}) translate(${-(left + right) / 2} ${-(bottom + top) / 2})"/>`;
}

const tiles = `<g transform="rotate(-9 192 218)">
  <rect x="64" y="100" width="228" height="258" rx="25" fill="#0a343b" opacity=".15"/>
  <rect x="64" y="88" width="228" height="258" rx="25" fill="${colors.teal}" stroke="${colors.paper}" stroke-width="6"/>
  <path d="M88 102H270" stroke="#ffffff" stroke-opacity=".22" stroke-width="3" stroke-linecap="round"/>
  ${letter('s', 178, 217, 155, colors.paper)}
</g>
<g transform="rotate(8 333 293)">
  <rect x="217" y="185" width="228" height="258" rx="25" fill="#603d22" opacity=".19"/>
  <rect x="217" y="173" width="228" height="258" rx="25" fill="${colors.peach}" stroke="${colors.paper}" stroke-width="6"/>
  <path d="M240 187H420" stroke="#fff8e8" stroke-opacity=".65" stroke-width="3" stroke-linecap="round"/>
  ${letter('gagga', 331, 298, 153, colors.ink)}
</g>`;

function icon({ square = false, maskable = false } = {}) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512" role="img" aria-label="Sikhi Word Games: S and Gurmukhi ਗ tiles">
<defs><linearGradient id="paper" x2=".7" y2="1"><stop stop-color="#fff9ec"/><stop offset="1" stop-color="#f1e4c9"/></linearGradient></defs>
<rect width="512" height="512" rx="${square || maskable ? 0 : 110}" fill="url(#paper)"/>
${maskable ? `<g transform="translate(56.32 56.32) scale(.78)">${tiles}</g>` : tiles}
</svg>`;
}

const cover = `<svg xmlns="http://www.w3.org/2000/svg" width="1260" height="1000" viewBox="0 0 1260 1000">
<rect width="1260" height="1000" fill="#f8f2e5"/>
<text x="82" y="125" font-family="Arial,sans-serif" font-size="26" letter-spacing="4" fill="${colors.teal}">SIX WORD AND LETTER GAMES</text>
<g transform="translate(710 213) scale(.92)">${tiles}</g>
<g font-family="Georgia,serif" font-weight="700" fill="${colors.ink}">
  <text x="75" y="322" font-size="148">Sikhi</text>
  <text x="75" y="477" font-size="132">Word</text>
  <text x="75" y="632" font-size="132">Games</text>
</g>
<g font-family="Arial,sans-serif">
  <text x="82" y="714" font-size="30" fill="${colors.ink}">Play with letters. Discover new words.</text>
  <path d="M82 758H1178" stroke="#d4c9b2" stroke-width="2"/>
  <text x="82" y="810" font-size="27" fill="${colors.teal}">English · Romanized Punjabi · Gurmukhi</text>
  <text x="82" y="857" font-size="24" fill="${colors.ink}">Guess the Word · Word Search · Word Quest</text>
  <text x="82" y="896" font-size="24" fill="${colors.ink}">Word Bridges · Word Scramble · Learn Letters</text>
  <text x="82" y="960" font-size="28" font-weight="700" fill="${colors.teal}">Khalsa Game Studio</text>
  <text x="1178" y="960" font-size="24" text-anchor="end" fill="${colors.ink}">khalsagamestudio.com</text>
</g></svg>`;

async function writeAndroidIcons() {
  for (const [density, size] of Object.entries({ mdpi: 48, hdpi: 72, xhdpi: 96, xxhdpi: 144, xxxhdpi: 192 })) {
    const directory = path.join(root, 'app/android/app/src/main/res', `mipmap-${density}`);
    fs.mkdirSync(directory, { recursive: true });
    await sharp(Buffer.from(icon())).resize(size).png().toFile(path.join(directory, 'ic_launcher.png'));
  }
}

async function writeIosIcons() {
  const directory = path.join(root, 'app/ios/Runner/Assets.xcassets/AppIcon.appiconset');
  const catalog = JSON.parse(fs.readFileSync(path.join(directory, 'Contents.json'), 'utf8'));
  const filenames = new Set();
  for (const image of catalog.images) {
    if (filenames.has(image.filename)) continue;
    filenames.add(image.filename);
    const size = Math.round(parseFloat(image.size) * parseFloat(image.scale));
    // iOS supplies the corner mask; every export has an opaque square background.
    await sharp(Buffer.from(icon({ square: true }))).resize(size).removeAlpha().png().toFile(path.join(directory, image.filename));
  }
}

async function main() {
  if (process.argv.includes('--android-icons-only')) {
    await writeAndroidIcons();
    return;
  }
  if (!process.argv.includes('--cover-only')) {
    await writeAndroidIcons();
    await writeIosIcons();
    fs.writeFileSync(path.join(brand, 'icon.svg'), icon());
    fs.writeFileSync(path.join(brand, 'icon-maskable.svg'), icon({ maskable: true }));
    for (const size of [192, 512]) {
      await sharp(Buffer.from(icon())).resize(size).png().toFile(path.join(web, `icons/Icon-${size}.png`));
      await sharp(Buffer.from(icon({ maskable: true }))).resize(size).png().toFile(path.join(web, `icons/Icon-maskable-${size}.png`));
    }
    await sharp(Buffer.from(icon())).resize(64).png().toFile(path.join(web, 'favicon.png'));
  }
  if (!process.argv.includes('--icons-only')) {
    fs.mkdirSync(release, { recursive: true });
    fs.writeFileSync(path.join(brand, 'itch-cover.svg'), cover);
    await sharp(Buffer.from(cover)).resize(630, 500).png().toFile(path.join(release, 'itch-cover-630x500.png'));
  }
  console.log('Regenerated approved S + ਗ branding assets.');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
