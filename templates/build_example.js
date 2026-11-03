// Minimal progress deck from R output images. Run from a folder whose img/ holds the PNGs:
//   Rscript <skill>/templates/design_diagram.R && Rscript <skill>/templates/table_grob.R
//   <skill>/scripts/deck.sh build <skill>/templates/build_example.js
const makeDeck = require('deck_lib');

(async () => {
  const D = makeDeck('example_progress.pptx', { title: 'Example progress deck' });
  await D.loadFigs(['img']);
  D.titleSlide('Drug A and the course of disease X', 'Progress report, November 2026', 'Department, Name');
  D.figSlide({ title: 'Study design', figs: ['demo_design.png'], src: 'Schneeweiss S et al. Ann Intern Med 2019;170:398-406' });
  D.figSlide({ title: 'Cohorts', figs: ['demo_table.png'] });
  await D.write();
})().catch(e => { console.error(e); process.exit(1); });
