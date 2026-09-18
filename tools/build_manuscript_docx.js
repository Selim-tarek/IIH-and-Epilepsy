/* Build a submission-ready Word manuscript from report/MANUSCRIPT.md.
 * The markdown stays the single source of truth for prose; the four data
 * tables are injected from the CSVs written by the final run, so the Word
 * file cannot drift from the analysis. */
const fs = require('fs');
const path = require('path');
const D = require('docx');
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, ShadingType, BorderStyle,
  PageOrientation, PageBreak, PageNumber, Footer, LevelFormat, convertInchesToTwip,
} = D;

const ROOT = path.resolve(__dirname, '..');
const TB   = path.join(ROOT, 'outputs', 'tables');
const FONT = 'Times New Roman';
const CONTENT_W = 9360;                      // 12240 - 2*1440

/* ---------- CSV ---------- */
function csv(file) {
  const txt = fs.readFileSync(path.join(TB, file.endsWith('.csv') ? file : file + '.csv'), 'utf8').replace(/\r/g, '');
  const rows = [];
  let row = [], cur = '', q = false;
  for (let i = 0; i < txt.length; i++) {
    const c = txt[i];
    if (q) {
      if (c === '"' && txt[i + 1] === '"') { cur += '"'; i++; }
      else if (c === '"') q = false;
      else cur += c;
    } else if (c === '"') q = true;
    else if (c === ',') { row.push(cur); cur = ''; }
    else if (c === '\n') { row.push(cur); rows.push(row); row = []; cur = ''; }
    else cur += c;
  }
  if (cur.length || row.length) { row.push(cur); rows.push(row); }
  return rows.filter(r => r.length > 1 || (r[0] || '').trim() !== '');
}

/* ---------- inline markdown ---------- */
function runs(text, base = {}) {
  const out = [];
  const re = /(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`|«[^»]*»)/g;
  let last = 0, m;
  const push = (t, o) => { if (t) out.push(new TextRun({ text: t, font: FONT, size: 24, ...base, ...o })); };
  while ((m = re.exec(text)) !== null) {
    push(text.slice(last, m.index), {});
    const tok = m[0];
    if (tok.startsWith('**')) push(tok.slice(2, -2), { bold: true });
    else if (tok.startsWith('`')) push(tok.slice(1, -1), { font: 'Consolas', size: 20 });
    else if (tok.startsWith('«')) push(tok, { italics: true, color: '8B5E00' });
    else push(tok.slice(1, -1), { italics: true });
    last = m.index + tok.length;
  }
  push(text.slice(last), {});
  return out.length ? out : [new TextRun({ text: '', font: FONT, size: 24 })];
}

const body = (text, opts = {}) => new Paragraph({
  children: runs(text), spacing: { line: 480, after: 0 },
  alignment: AlignmentType.LEFT, ...opts,
});

/* ---------- tables ---------- */
function cell(text, { head = false, w, bold = false } = {}) {
  return new TableCell({
    width: { size: w, type: WidthType.DXA },
    shading: head ? { type: ShadingType.CLEAR, fill: 'E8EDF4', color: 'auto' } : undefined,
    margins: { top: 60, bottom: 60, left: 108, right: 108 },
    children: [new Paragraph({
      spacing: { line: 240, before: 20, after: 20 },
      children: [new TextRun({ text, font: FONT, size: 20, bold: head || bold })],
    })],
  });
}

function dataTable(rows, widths, { headerRow = true } = {}) {
  return new Table({
    columnWidths: widths,
    width: { size: widths.reduce((a, b) => a + b, 0), type: WidthType.DXA },
    borders: {
      top:    { style: BorderStyle.SINGLE, size: 6, color: '404040' },
      bottom: { style: BorderStyle.SINGLE, size: 6, color: '404040' },
      left:   { style: BorderStyle.NONE }, right: { style: BorderStyle.NONE },
      insideHorizontal: { style: BorderStyle.SINGLE, size: 2, color: 'C8C8C8' },
      insideVertical:   { style: BorderStyle.NONE },
    },
    rows: rows.map((r, i) => new TableRow({
      tableHeader: headerRow && i === 0,
      children: r.map((c, j) => cell(c, { head: headerRow && i === 0, w: widths[j] })),
    })),
  });
}

const caption = (n, t) => new Paragraph({
  spacing: { before: 320, after: 120, line: 240 },
  children: [new TextRun({ text: `Table ${n}. `, bold: true, font: FONT, size: 22 }),
             new TextRun({ text: t, font: FONT, size: 22 })],
});
const source = s => new Paragraph({
  spacing: { before: 80, after: 240, line: 240 },
  children: [new TextRun({ text: s, italics: true, font: FONT, size: 18, color: '595959' })],
});

/* ---------- the four data tables ---------- */
function table1() {
  const r = csv('SAP_T1_baseline').slice(1);
  return [caption(1, 'Baseline characteristics of the matched cohort.'),
    dataTable([['Characteristic', 'IIH (n = 2,138)', 'Comparator (n = 5,743)', 'SMD'],
               ...r.map(x => [x[0], x[1], x[2], x[3]])],
              [3660, 2100, 2300, 1300]),
    source('Source: SAP_T1_baseline. SMD, standardised mean difference. Recorded smoking is not comparable between the source extracts and was not used as a covariate.')];
}
function table2() {
  const p = csv('K_T38_FINAL_results_visits').slice(1);
  const z = csv('Z_T01_complete_sets').slice(1);
  const l = csv('SAP_T3b_landmark').slice(1);
  const c = csv('SAP_T4_competing_risks').slice(1);
  const o = csv('SAP_T6_propensity').slice(1);
  const all = csv('K_T38_FINAL_results_all').slice(1);
  const rows = [['Analysis', 'IIH events/n', 'Comparator events/n', 'Hazard ratio (95% CI)']];
  rows.push(['Primary', p[0][1], p[0][2], p[0][5]]);
  rows.push(['Codes only, medication channel removed', p[1][1], p[1][2], p[1][5]]);
  rows.push(['Epilepsy-specific codes only (G40/345)', p[2][1], p[2][2], p[2][5]]);
  rows.push(['Restricted to opening pressure ≥25 cmH₂O', p[3][1], p[3][2], p[3][5]]);
  rows.push(['All encounter rows counted as contact', all[0][1], all[0][2], all[0][5]]);
  rows.push(['Complete matched sets only', z[1][1], z[1][2], z[1][3]]);
  l.slice(1).forEach(x => rows.push([x[0].replace('Landmark: events in the first', 'Landmark, first')
      .replace(' after washout excluded', ' excluded'), String(x[1]), String(x[2]), x[3]]));
  rows.push(['Fine–Gray subdistribution hazard', '—', '—', c[1][1]]);
  rows.push(['Overlap-weighted', '—', '—', o[6][1]]);
  return [caption(2, 'Primary outcome and sensitivity analyses: incident seizure or epilepsy after the 180-day washout.'),
    dataTable(rows, [3960, 1700, 1900, 1800]),
    source('Sources: K_T38, Z_T01, SAP_T3b, SAP_T4, SAP_T6. Primary three-year cumulative incidence 3.83% vs 1.71%; risk difference 2.12 percentage points; proportional hazards p = 0.94.')];
}
function table3() {
  const r = csv('K_T54_post_index_surveillance').slice(1)
    .filter(x => x[3] !== 'not available');
  return [caption(3, 'Post-index healthcare surveillance, by encounter setting.'),
    dataTable([['Setting', 'IIH, per person-year', 'Comparator, per person-year', 'Rate ratio (95% CI)'],
               ...r.map(x => [x[0], x[3], x[4], x[5]])],
              [2760, 2200, 2400, 2000]),
    source('Source: K_T54. Neurology, ophthalmology, imaging and EEG rates are not estimable: the encounter extract carries no specialty field, the radiology extract covers comparators only, and EEG is recorded for IIH patients only.')];
}
function table4() {
  const a = csv('K_T42_negative_controls').slice(1);
  const b = csv('K_T45_negative_controls_v2').slice(1);
  const rt = csv('K_T55_negative_outcome_rates').slice(1);
  const rr = {}; rt.forEach(x => { rr[x[0]] = x[5]; });
  const rows = [['Negative-control outcome', 'Baseline prevalence ratio', 'Post-index HR (95% CI)', 'Unadjusted rate ratio']];
  a.filter(x => x[11] !== 'not estimable').forEach(x => rows.push([x[0], x[3], x[11], rr[x[0]] || '—']));
  b.forEach(x => rows.push([x[0], x[5], x[12], rr[x[0]] || '—']));
  rows.push(['Seizure or epilepsy (primary outcome)', '—', '2.28 (1.62 to 3.22)',
             rr['SEIZURE OR EPILEPSY (primary outcome)'] || '—']);
  return [caption(4, 'Negative-control outcomes: baseline imbalance, post-index effect and unadjusted rate ratios.'),
    dataTable(rows, [3260, 2100, 2200, 1800]),
    source('Sources: K_T42, K_T45, K_T55. All eleven controls failed the pre-specified baseline-balance criterion, so the panel cannot support a specificity claim. On unadjusted rate ratios the primary outcome ranks eighth of twelve.')];
}

/* ---------- markdown → docx ---------- */
const md = fs.readFileSync(path.join(ROOT, 'report', 'MANUSCRIPT.md'), 'utf8')
  .replace(/\r/g, '').split('\n');

const children = [];
let i = 0, inNote = false, noteLines = [];
const flushNote = () => {
  if (!noteLines.length) return;
  children.push(new Paragraph({
    spacing: { before: 200, after: 200, line: 300 },
    shading: { type: ShadingType.CLEAR, fill: 'FFF6E5', color: 'auto' },
    border: { left: { style: BorderStyle.SINGLE, size: 18, color: 'C8952B', space: 8 } },
    children: [new TextRun({ text: 'TO BE REMOVED BEFORE SUBMISSION — ', bold: true, font: FONT, size: 20, color: '8B5E00' }),
               ...runs(noteLines.join(' '), { size: 20, color: '6B4A00' })],
  }));
  noteLines = [];
};

while (i < md.length) {
  const line = md[i];
  const t = line.trim();

  if (t.startsWith('> ')) { inNote = true; noteLines.push(t.slice(2)); i++; continue; }
  if (inNote && t === '') { flushNote(); inNote = false; i++; continue; }

  if (t === '---') { i++; continue; }
  if (t === '') { i++; continue; }

  /* markdown table */
  if (t.startsWith('|')) {
    const blk = [];
    while (i < md.length && md[i].trim().startsWith('|')) { blk.push(md[i].trim()); i++; }
    const parsed = blk.filter(r => !/^\|[\s:|-]+\|$/.test(r))
      .map(r => r.slice(1, -1).split('|').map(c => c.trim().replace(/\*\*/g, '')));
    const n = parsed[0].length;
    const w = n === 2 ? [6360, 3000]
            : n === 3 ? [4360, 2500, 2500]
            : Array(n).fill(Math.floor(CONTENT_W / n));
    if (w.reduce((a, b) => a + b, 0) !== CONTENT_W) w[0] += CONTENT_W - w.reduce((a, b) => a + b, 0);
    children.push(dataTable(parsed, w));
    children.push(new Paragraph({ spacing: { after: 160 }, children: [] }));
    continue;
  }

  if (t.startsWith('#### ')) { children.push(new Paragraph({ heading: HeadingLevel.HEADING_4, spacing: { before: 240, after: 120 }, children: runs(t.slice(5), { bold: true, size: 24 }) })); i++; continue; }
  if (t.startsWith('### '))  { children.push(new Paragraph({ heading: HeadingLevel.HEADING_3, spacing: { before: 280, after: 140 }, children: runs(t.slice(4), { bold: true, size: 24 }) })); i++; continue; }
  if (t.startsWith('## '))   { children.push(new Paragraph({ heading: HeadingLevel.HEADING_2, pageBreakBefore: /^## (Introduction|Methods|Results|Discussion|Tables)/.test(t), spacing: { before: 360, after: 180 }, children: runs(t.slice(3), { bold: true, size: 28 }) })); i++; continue; }
  if (t.startsWith('# '))    { children.push(new Paragraph({ heading: HeadingLevel.TITLE, alignment: AlignmentType.LEFT, spacing: { after: 240 }, children: runs(t.slice(2), { bold: true, size: 34 }) })); i++; continue; }

  /* the Tables section: replace callouts with real tables */
  if (/^\*\*Table \d\.\*\*/.test(t)) {
    const n = Number(t.match(/^\*\*Table (\d)\./)[1]);
    ({ 1: table1, 2: table2, 3: table3, 4: table4 }[n])().forEach(e => children.push(e));
    i++; continue;
  }

  if (t.startsWith('- ')) {
    children.push(new Paragraph({ bullet: { level: 0 }, spacing: { line: 360, after: 60 }, children: runs(t.slice(2)) }));
    i++; continue;
  }
  if (/^\d+\.\s/.test(t)) {
    children.push(new Paragraph({ numbering: { reference: 'nums', level: 0 }, spacing: { line: 360, after: 60 }, children: runs(t.replace(/^\d+\.\s/, '')) }));
    i++; continue;
  }
  if (t.startsWith('*') && t.endsWith('*') && !t.startsWith('**')) {
    children.push(new Paragraph({ spacing: { before: 200, line: 300 }, children: runs(t, { italics: true, size: 20, color: '595959' }) }));
    i++; continue;
  }

  /* paragraph: join wrapped lines */
  const buf = [];
  while (i < md.length && md[i].trim() !== '' && !md[i].trim().startsWith('#')
         && !md[i].trim().startsWith('|') && !md[i].trim().startsWith('- ')
         && !md[i].trim().startsWith('> ') && md[i].trim() !== '---'
         && !/^\*\*Table \d\.\*\*/.test(md[i].trim())) { buf.push(md[i].trim()); i++; }
  children.push(body(buf.join(' ')));
  children.push(new Paragraph({ spacing: { after: 120 }, children: [] }));
}
flushNote();

const doc = new Document({
  creator: 'Selim Tarabeah', title: 'Incident Seizures and Epilepsy After Idiopathic Intracranial Hypertension',
  numbering: { config: [{ reference: 'nums', levels: [{ level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.START }] }] },
  styles: { default: { document: { run: { font: FONT, size: 24 } } } },
  sections: [{
    properties: {
      page: { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } },
      lineNumbers: { countBy: 1, restart: 'continuous' },
    },
    footers: { default: new Footer({ children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 20 })],
    })] }) },
    children,
  }],
});

Packer.toBuffer(doc).then(b => {
  const out = path.join(ROOT, 'report', 'MANUSCRIPT.docx');
  fs.writeFileSync(out, b);
  console.log('wrote', out, (b.length / 1024).toFixed(0) + ' KB');
});
