// Copies Atlas's legal documents from the web repo into the app, so the
// app shows them natively (no web page) with the exact same text.
//
//   node --experimental-strip-types tool/sync_legal.mjs [path/to/atlas]
//
// The web keeps them as typed data in src/features/legal/content/*.ts;
// this writes assets/legal/<doc>.<lang>.json from those files unchanged.
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const web = resolve(process.argv[2] ?? join(here, '../../atlas'));
const content = join(web, 'src/features/legal/content');
const out = join(here, '../assets/legal');
mkdirSync(out, { recursive: true });

const docs = [
  ['privacy', 'privacy-policy', 'PRIVACY_POLICY'],
  ['terms', 'terms', 'TERMS'],
];
for (const [id, file, constant] of docs) {
  const shapes = {};
  for (const lang of ['ar', 'en']) {
    const mod = await import(pathToFileURL(join(content, `${file}.${lang}.ts`)).href);
    const doc = mod[`${constant}_${lang.toUpperCase()}`] ?? Object.values(mod)[0];
    if (!doc?.sections?.length) throw new Error(`${file}.${lang}: no sections`);
    shapes[lang] = doc.sections.map((s) => s.id).join(',');
    writeFileSync(join(out, `${id}.${lang}.json`), JSON.stringify(doc, null, 1) + '\n');
    console.log(`${id}.${lang}.json: ${doc.sections.length} sections, updated ${doc.lastUpdated}`);
  }
  if (shapes.ar !== shapes.en) throw new Error(`${id}: Arabic and English sections differ`);
}
