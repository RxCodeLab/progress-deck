// Layout helpers for progress decks assembled from R output images (pptxgenjs, 16:9 wide, 13.333 x 7.5 in).
// Every data graph and table is drawn in R and placed here as a PNG; this library adds only a title, an optional
// short subtitle and an optional source line. The look is deliberately plain: white slides, black text in one font,
// no colour accents, boxes or decorative shapes. Rules: ../SKILL.md.
//
//   const makeDeck = require('deck_lib');            // scripts/deck.sh build puts lib/ on NODE_PATH
//   const D = makeDeck('out.pptx', { title: 'Progress, 2026-11', author: 'Your Name' });
//   await D.loadFigs(['img']);                       // every PNG in these folders, keyed by file name
//   D.titleSlide('Drug A and the course of disease X', 'Progress report, November 2026');
//   D.figSlide({ title: 'Study design', figs: ['design.png'] });
//   await D.write();
const fs = require('fs');
const path = require('path');
const pptxgen = require('pptxgenjs');
const sharp = require('sharp');

const C = { text: '000000', grey: '595959', line: 'BFBFBF', white: 'FFFFFF' };
const FONT = 'Arial';                    // LibreOffice previews use the metric-compatible Liberation Sans
const W = 13.333, H = 7.5, X0 = 0.5, CW = W - 2 * X0;
const SRC_Y = 6.95;                      // the source line sits at the bottom

// CSV as write.csv / readr write it: quoted fields, doubled quotes, newlines inside quotes
function csvRows(file) {
  const txt = fs.readFileSync(file, 'utf8').replace(/^﻿/, '').trim();
  const rows = []; let row = [], f = '', q = false;
  for (let i = 0; i < txt.length; i++) {
    const c = txt[i];
    if (q) { if (c === '"' && txt[i + 1] === '"') { f += '"'; i++; } else if (c === '"') q = false; else f += c; }
    else if (c === '"') q = true;
    else if (c === ',') { row.push(f); f = ''; }
    else if (c === '\n') { row.push(f.replace(/\r$/, '')); rows.push(row); row = []; f = ''; }
    else f += c;
  }
  row.push(f); rows.push(row);
  return rows;
}
function csv(file) { const rows = csvRows(file); const h = rows.shift(); return rows.map(r => Object.fromEntries(h.map((k, i) => [k, r[i]]))); }
const fmtN = n => Number(n).toLocaleString('en-US');

function makeDeck(out, opt = {}) {
  const pres = new pptxgen();
  pres.layout = 'LAYOUT_WIDE';
  pres.title = opt.title || path.basename(out, '.pptx');
  if (opt.author) pres.author = opt.author;
  const font = opt.font || FONT, numbers = opt.slideNumbers !== false;
  const figs = {}; let slideNo = 0;
  const T = (s, t, o) => s.addText(t, Object.assign({ isTextBox: true, margin: 0, fontFace: font, color: C.text, valign: 'top' }, o));

  // R writes PNGs with white margins of its own; trim them. The PNG's own resolution (ragg records it) gives the size
  // it was drawn at, in inches, so a figure is never enlarged past that and its text keeps the point size it was
  // drawn with; opt.dpi is the fallback for PNGs without one.
  async function loadFigs(dirs) {
    for (const dir of [].concat(dirs).filter(d => fs.existsSync(d))) {
      for (const f of fs.readdirSync(dir).filter(n => n.toLowerCase().endsWith('.png'))) {
        if (figs[f]) throw new Error(`figure ${f} is in two folders; rename one`);
        const file = path.join(dir, f), dpi = (await sharp(file).metadata()).density || opt.dpi || 220;
        const { data, info } = await sharp(file).trim().png().toBuffer({ resolveWithObject: true });
        figs[f] = { data: 'image/png;base64,' + data.toString('base64'), w: info.width, h: info.height, nw: info.width / dpi, nh: info.height / dpi };
      }
    }
  }
  const hasFig = name => !!figs[name];

  function newSlide() {
    const s = pres.addSlide(); slideNo++;
    s.background = { color: C.white };
    if (numbers) T(s, String(slideNo), { x: W - 1.0, y: 7.05, w: 0.5, h: 0.25, fontSize: 10, color: C.grey, align: 'right' });
    return s;
  }
  function title(s, t, sub) {
    T(s, t, { x: X0, y: 0.35, w: CW, h: 0.7, fontSize: 28 });
    if (sub) T(s, sub, { x: X0, y: 1.05, w: CW, h: 0.4, fontSize: 16, color: C.grey });
  }
  // full citations only (first author et al., journal, year;volume:pages); long lists shrink and grow upward
  function srcLayout(text) {
    const fz = text.length > 450 ? 8 : 9, lines = Math.ceil(text.length / (1900 / fz)), h = Math.max(lines * fz * 1.25 / 72, 0.3);
    return { fz, h, y: Math.min(SRC_Y, 7.42 - h) };
  }
  function src(s, text) {
    if (!text) return null;
    const t = [].concat(text).join('; '), L = srcLayout(t);
    T(s, t, { x: X0, y: L.y, w: CW - 0.7, h: L.h, fontSize: L.fz, color: C.grey });
    return L.y;
  }
  function cap(s, t, x, y, w) { T(s, t, { x, y, w, h: 0.3, fontSize: 11, color: C.grey }); }
  // fit inside the w x h box, centred horizontally, at most maxScale times the drawn size (default 1: never enlarged)
  function fig(s, name, x, y, w, h, alt, maxScale) {
    const f = figs[name]; if (!f) throw new Error('missing figure ' + name);
    const r = f.w / f.h; let fw = w, fh = w / r;
    if (fh > h) { fh = h; fw = h * r; }
    const cap = (maxScale || opt.maxScale || 1) * f.nw;
    if (fw > cap) { fw = cap; fh = cap / r; }
    const fx = x + (w - fw) / 2;
    s.addImage({ data: f.data, x: fx, y, w: fw, h: fh, altText: alt || name });
    return { x: fx, w: fw, h: fh };
  }

  function titleSlide(t, sub, foot) {
    const s = pres.addSlide(); slideNo++;
    s.background = { color: C.white };
    T(s, t, { x: 1.0, y: 2.4, w: W - 2.0, h: 1.3, fontSize: 36, align: 'center', valign: 'bottom' });
    if (sub) T(s, sub, { x: 1.0, y: 3.85, w: W - 2.0, h: 0.6, fontSize: 18, color: C.grey, align: 'center' });
    if (foot) T(s, foot, { x: 1.0, y: 6.4, w: W - 2.0, h: 0.4, fontSize: 14, color: C.grey, align: 'center' });
    return s;
  }
  function sectionSlide(t) {
    const s = newSlide();
    T(s, t, { x: 1.0, y: 3.0, w: W - 2.0, h: 1.0, fontSize: 32, align: 'center', valign: 'middle' });
    return s;
  }
  // one to three R figures side by side under the title, each fitted into an equal column; labels are optional
  // few-word headings over each figure
  function figSlide(o) {
    const s = newSlide();
    title(s, o.title, o.sub);
    const names = [].concat(o.figs), n = names.length, gap = 0.4, w = (CW - gap * (n - 1)) / n;
    const srcY = o.src ? srcLayout([].concat(o.src).join('; ')).y : SRC_Y;
    const labH = o.labels ? 0.38 : 0;
    const top = o.sub ? 1.6 : 1.3, h = srcY - 0.12 - top - labH;
    names.forEach((nm, i) => {
      const x = X0 + i * (w + gap);
      if (o.labels && o.labels[i]) T(s, o.labels[i], { x, y: top, w, h: 0.32, fontSize: 14 });
      fig(s, nm, x, top + labH, w, h, o.alts ? o.alts[i] : nm, o.maxScale);
    });
    src(s, o.src);
    return s;
  }
  // a long table that comes as a CSV from an R package (e.g. CohortMethod createCmTable1 saved with write.csv),
  // split into up to three columns; headRows rows repeat at the top of each column, and a row whose cells are all
  // empty but the first is a section header. Prefer an R-rendered table PNG (templates/table_grob.R) when it fits
  // on one slide; use this when the package's own long table is the thing to show.
  function csvTable(s, rows, o = {}) {
    const hr = o.headRows || 1, head = rows.slice(0, hr), body = rows.slice(hr);
    const cols = o.columns || (body.length > 60 ? 3 : body.length > 30 ? 2 : 1);
    const per = Math.ceil(body.length / cols), gap = 0.15, w = (CW - gap * (cols - 1)) / cols;
    const nc = rows[0].length, first = o.firstColFrac || 0.43;
    const colW = [w * first].concat(Array(nc - 1).fill(w * (1 - first) / (nc - 1)));
    const cell = (v, k, extra) => ({ text: String(v).trim(), options: Object.assign({ fontSize: o.fontSize || 7.5, color: C.text, align: k === 0 ? 'left' : 'center', valign: 'middle' }, extra) });
    for (let j = 0; j < cols; j++) {
      const part = body.slice(j * per, (j + 1) * per);
      const tr = part.map(r => { const sec = r.slice(1).every(v => !String(v).trim()); return r.map((v, k) => cell(v, k, sec ? { bold: true } : {})); });
      s.addTable(head.map(r => r.map((v, k) => cell(v, k, { bold: true, fontSize: o.headSize || 7 }))).concat(tr),
        { x: X0 + j * (w + gap), y: o.y || 1.4, w, colW, fontFace: font, border: { type: 'solid', pt: 0.5, color: C.line }, margin: 0.01, rowH: o.rowH || 0.13 });
    }
  }

  async function write() {
    await pres.writeFile({ fileName: out });
    console.log('wrote', out, slideNo, 'slides');
  }
  return { pres, newSlide, title, src, cap, fig, hasFig, loadFigs, titleSlide, sectionSlide, figSlide, csvTable, write, C, FONT: font, W, H };
}

module.exports = makeDeck;
Object.assign(module.exports, { csv, csvRows, fmtN, C, FONT, W, H });
