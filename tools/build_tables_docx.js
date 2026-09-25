/* Builds two Word files from the run's CSVs:
 *   report/TABLES_main.docx          Tables 1-3 (main text)
 *   report/TABLES_supplementary.docx eTables 1-9
 * Data comes straight from outputs/tables, so neither can drift from the run. */
const fs=require('fs'), path=require('path'), D=require('docx');
const {Document,Packer,Paragraph,TextRun,AlignmentType,Table,TableRow,TableCell,
       WidthType,ShadingType,BorderStyle,Footer,PageNumber,PageOrientation}=D;
const ROOT=path.resolve(__dirname,'..'), TB=path.join(ROOT,'outputs','tables');
const FONT='Times New Roman';

function csv(f){const t=fs.readFileSync(path.join(TB,f.endsWith('.csv')?f:f+'.csv'),'utf8').replace(/\r/g,'');
 const rows=[];let row=[],cur='',q=false;
 for(let i=0;i<t.length;i++){const c=t[i];
  if(q){if(c==='"'&&t[i+1]==='"'){cur+='"';i++;}else if(c==='"')q=false;else cur+=c;}
  else if(c==='"')q=true;else if(c===','){row.push(cur);cur='';}
  else if(c==='\n'){row.push(cur);rows.push(row);row=[];cur='';}else cur+=c;}
 if(cur.length||row.length){row.push(cur);rows.push(row);}
 return rows.filter(r=>r.length>1||(r[0]||'').trim()!=='');}

const txt=(s,o={})=>new TextRun({text:s,font:FONT,size:20,...o});
const cell=(s,w,head,bold)=>new TableCell({
 width:{size:w,type:WidthType.DXA},
 shading:head?{type:ShadingType.CLEAR,fill:'EDF1F7',color:'auto'}:undefined,
 margins:{top:50,bottom:50,left:100,right:100},
 children:[new Paragraph({spacing:{line:240,before:15,after:15},
   children:[txt(s,{bold:head||bold,size:19})]})]});
function tbl(rows,w){return new Table({columnWidths:w,
 width:{size:w.reduce((a,b)=>a+b,0),type:WidthType.DXA},
 borders:{top:{style:BorderStyle.SINGLE,size:6,color:'404040'},
  bottom:{style:BorderStyle.SINGLE,size:6,color:'404040'},
  left:{style:BorderStyle.NONE},right:{style:BorderStyle.NONE},
  insideHorizontal:{style:BorderStyle.SINGLE,size:2,color:'CCCCCC'},
  insideVertical:{style:BorderStyle.NONE}},
 rows:rows.map((r,i)=>new TableRow({tableHeader:i===0,
  children:r.map((c,j)=>cell(c===''||c==null?'—':String(c),w[j],i===0))}))});}
const cap=(n,t)=>new Paragraph({spacing:{before:360,after:120},
 children:[txt(`${n}. `,{bold:true,size:21}),txt(t,{size:21})]});
const note=s=>new Paragraph({spacing:{before:90,after:260},
 children:[txt(s,{italics:true,size:17,color:'595959'})]});
const head=s=>new Paragraph({spacing:{before:200,after:160},
 children:[txt(s,{bold:true,size:26})]});

const W=9360; // letter, 1in margins
const sec=children=>({properties:{page:{size:{width:12240,height:15840},
   margin:{top:1440,right:1440,bottom:1440,left:1440}}},
  footers:{default:new Footer({children:[new Paragraph({alignment:AlignmentType.CENTER,
    children:[new TextRun({children:[PageNumber.CURRENT],font:FONT,size:18})]})]})},
  children});

/* ---------------- MAIN TABLES ---------------- */
const main=[head('Tables')];

// Table 1 - baseline
{const r=csv('Z_T02_table1_full').slice(1)
   .filter(x=>!/Available|Opening pressure/.test(x[0]))
   .map(x=>[x[0].replace(' (NOT COMPARABLE - see note)',''),x[1],x[2],x[3]]);
 main.push(cap('Table 1','Baseline characteristics of the matched cohort.'));
 main.push(tbl([['Characteristic','IIH (n = 2,138)','Comparator (n = 5,743)','SMD'],...r],[3560,2160,2340,1300]));
 main.push(note('SMD, standardized mean difference; IQR, interquartile range. Matching was on sex, age, body mass index and BMI calendar year. Four covariates exceed |SMD| 0.10 and represent residual imbalance: hypertension, obstructive sleep apnea, polycystic ovary syndrome and pre-index clinical visits. Smoking was not comparably recorded between the two source extracts and was not used as a covariate. Opening pressure was available for 1,585 patients with IIH (74%), mean 29.5 cmH2O (SD 9.7), and was not recorded for comparators. Source: Z_T02.'));}

// Table 2 - primary + sensitivity
{const pv=csv('K_T38_FINAL_results_visits').slice(1), pa=csv('K_T38_FINAL_results_all').slice(1),
       z=csv('Z_T01_complete_sets').slice(1), ag=csv('Z_T07_age18_sensitivity').slice(1),
       l=csv('SAP_T3b_landmark').slice(1), c=csv('SAP_T4_competing_risks').slice(1),
       o=csv('SAP_T6_propensity').slice(1), cm=csv('Z_T04_comorbidity_adjusted').slice(1);
 const rows=[['Analysis','IIH events / n','Comparator events / n','Hazard ratio (95% CI)']];
 rows.push(['Primary analysis',pv[0][1],pv[0][2],pv[0][5]]);
 rows.push(['Codes only, medication criterion removed',pv[1][1],pv[1][2],pv[1][5]]);
 rows.push(['Epilepsy-specific codes only (G40.x / 345.x)',pv[2][1],pv[2][2],pv[2][5]]);
 rows.push(['Opening pressure 25 cmH2O or higher',pv[3][1],pv[3][2],pv[3][5]]);
 rows.push(['All encounter rows counted as contact',pa[0][1],pa[0][2],pa[0][5]]);
 rows.push(['Complete matched sets only',z[1][1],z[1][2],z[1][3]]);
 rows.push(['Age 18 years or older at index',ag[1][1],ag[1][2],ag[1][3]]);
 l.slice(1).forEach(x=>rows.push([x[0].replace('Landmark: events in the first','Landmark: first')
   .replace(' after washout excluded',' excluded'),x[1],x[2],x[3]]));
 rows.push(['Fine-Gray subdistribution hazard','','',c[1][1]]);
 rows.push(['Overlap-weighted','','',o[6][1]]);
 rows.push(['Adjusted for OSA, hypertension and PCOS','','',cm[4][1]]);
 main.push(cap('Table 2','Incident seizure or epilepsy: primary analysis and prespecified sensitivity analyses.'));
 main.push(tbl(rows,[3860,1740,1960,1800]));
 main.push(note('All models are Cox proportional-hazards models with a robust variance clustered by matched set. Primary analysis: incidence 14.46 (95% CI 11.19-18.40) versus 6.72 (5.16-8.60) per 1,000 person-years over 4,563.0 and 9,375.2 person-years; 3-year cumulative incidence 3.83% versus 1.71%, absolute difference 2.12 percentage points; proportional-hazards p = 0.94. Cause-specific hazard ratio for death 0.61 (0.29-1.29). Sources: K_T38, Z_T01, Z_T07, SAP_T3b, SAP_T4, SAP_T6, Z_T04.'));}

// Table 3 - negative controls
{const a=csv('K_T42_negative_controls').slice(1).filter(x=>x[11]!=='not estimable'),
       b=csv('K_T45_negative_controls_v2').slice(1),
       rt=csv('K_T55_negative_outcome_rates').slice(1);
 const rr={};rt.forEach(x=>rr[x[0]]=x[5]);
 const rows=[['Outcome','Baseline prevalence ratio','Post-index HR (95% CI)','Unadjusted rate ratio (95% CI)']];
 a.forEach(x=>rows.push([x[0],x[3],x[11],rr[x[0]]||'']));
 b.forEach(x=>rows.push([x[0],x[5],x[12],rr[x[0]]||'']));
 rows.push(['Seizure or epilepsy (primary outcome)','','2.28 (1.62 to 3.22)',rr['SEIZURE OR EPILEPSY (primary outcome)']||'']);
 main.push(cap('Table 3','Negative-control outcomes: baseline imbalance, post-index association and unadjusted rate ratios.'));
 main.push(tbl(rows,[3260,2100,2200,1800]));
 main.push(note('All 11 negative-control outcomes were more prevalent in the IIH group before the index date (prevalence ratios 1.6-5.0, all p < 0.01); none met the prespecified balance criterion, so the panel does not support a specificity claim. Eight of 11 had post-index confidence intervals excluding 1. On unadjusted rate ratios the primary outcome (2.15) was lower than 6 of the 11 controls. Empirical calibration: r = 0.66, p = 0.026; predicted detection-only hazard ratio at baseline balance 1.04 (95% CI 0.37-2.90), an interval that includes the observed estimate. Sources: K_T42, K_T45, K_T55, K_T48.'));}

/* ---------------- SUPPLEMENTARY ---------------- */
const sup=[head('Supplementary Tables')];
const add=(n,t,rows,w,nt)=>{sup.push(cap(n,t));sup.push(tbl(rows,w));if(nt)sup.push(note(nt));};

add('eTable 1','Seizure and epilepsy code list used for the primary outcome, applied identically to both groups.',
 [['Role','System','Codes'],
  ['Qualifying','ICD-10-CM','G40.x (epilepsy); R56.9 and other R56.x (convulsions)'],
  ['Qualifying','ICD-9-CM','345.x (epilepsy); 780.39 (other convulsions)'],
  ['Qualifying','Legacy','0345x, 07703x variants'],
  ['Excluded','ICD-10-CM / ICD-9-CM','F44.5, 300.11 (psychogenic / conversion)'],
  ['Excluded','ICD-10-CM / ICD-9-CM','R56.1, 780.32, 780.33 (febrile, post-traumatic)'],
  ['Excluded','ICD-10-CM','Z82.0 (family history)'],
  ['Excluded','ICD-10-CM','G43.x (migraine)'],
  ['Excluded','ICD-9-CM','E936, 966 (anticonvulsant adverse effect / poisoning)'],
  ['Excluded','Descriptor match','febrile, non-epileptic, psychogenic, conversion, family history, migraine, poisoning, adverse']],
 [1700,2100,5560],
 'R56.9 "Spells Neurological (HCC)" qualified only when accompanied by indefinite antiseizure medication; this affected one patient. Codes were drawn from the dated diagnosis extract and the problem list; for problem-list entries the onset date was used where present, otherwise the recorded date.');

add('eTable 2','Antiseizure medications counted and excluded.',
 [['Counted (21 agents)','levetiracetam, lamotrigine, carbamazepine, oxcarbazepine, valproate, divalproex, phenytoin, fosphenytoin, lacosamide, zonisamide, perampanel, brivaracetam, felbamate, rufinamide, vigabatrin, tiagabine, primidone, ethosuximide, phenobarbital, eslicarbazepine, cenobamate'],
  ['Not counted: IIH treatments','topiramate, acetazolamide'],
  ['Not counted: analgesics','gabapentin, pregabalin'],
  ['Not counted: procedural sedation','midazolam, lorazepam, diazepam, clonazepam']],
 [2600,6760],
 'A patient qualified on the medication criterion when records spanned 180 days or more, or a single prescription was written for 180 days or more. Topiramate and acetazolamide were excluded because both treat IIH; counting either would generate events in the exposed group by construction.');

{const r=csv('Z_T02_table1_full').slice(1).map(x=>[x[0],x[1],x[2],x[3],x[4],x[5]]);
 add('eTable 3','Baseline characteristics with per-group data availability.',
  [['Characteristic','IIH','Comparator','SMD','Available, IIH','Available, comparator'],...r],
  [2660,1620,1700,900,1240,1240],
  'A variable recorded in only one group cannot be compared between groups. Source: Z_T02.');}

{const r=csv('K_T54_post_index_surveillance').slice(1).map(x=>[x[0],x[3],x[4],x[5],x[6]]);
 add('eTable 4','Post-index healthcare surveillance by encounter setting.',
  [['Setting','IIH, per person-year','Comparator, per person-year','Rate ratio (95% CI)','Note'],...r],
  [1900,1750,1900,1800,2010],
  'Surveillance was higher in the IIH group in every clinician-initiated setting but not in laboratory encounters, the one setting not initiated by a clinician. Source: K_T54.');}

{const r=csv('K_T50_contact_robustness').slice(1).map(x=>[x[0],x[1],x[2],x[3],x[4],x[5],x[6]]);
 add('eTable 5','Response of every outcome to adjustment for six measures of pre-index healthcare contact.',
  [['Contact measure','Controls, median change','Controls, range','Controls moving away from null','Seizure HR','Seizure change','Direction'],...r],
  [1500,1400,1350,1450,1150,1250,1260],
  'All 66 control-by-measure combinations moved toward the null; the seizure estimate moved away from the null under all six measures. Source: K_T50.');}

{const r=csv('K_T52_collider_demonstration').slice(1).map(x=>[x[0],x[1],x[2],x[3]]);
 add('eTable 6','Adjustment for post-index healthcare contact: demonstration of collider bias.',
  [['Outcome','Unadjusted','Adjusted for pre-index contact','Adjusted for post-index contact'],...r],
  [2700,2000,2330,2330],
  'Adjustment for post-index contact produced implausibly protective associations for two negative-control outcomes, indicating collider bias rather than bias removal. Post-index contact was therefore not adjusted for in the primary analysis. Source: K_T52.');}

{const r=csv('SAP_T5_subgroups').slice(1).map(x=>[x[0],x[1],x[2],x[3],x[4],x[5]]);
 add('eTable 7','Subgroup analyses with tests for interaction.',
  [['Subgroup','Level','IIH events','Comparator events','Hazard ratio (95% CI)','p for interaction'],...r],
  [1300,1600,1250,1650,2260,1300],
  'Interaction was tested by a Wald test on the sandwich covariance. No interaction reached significance. The male stratum rests on 20 events in total and is not interpreted. Source: SAP_T5.');}

{const r=csv('Z_T05_confounder_criteria').slice(1).map(x=>[x[0],x[1],x[2],x[3],x[4],x[5]]);
 add('eTable 8','Comorbidities imbalanced after matching, assessed against both confounding criteria.',
  [['Covariate','Prevalence, IIH','Prevalence, comparator','SMD','HR for the outcome (95% CI)','p'],...r],
  [2100,1500,1700,900,2260,900],
  'A covariate can confound only if it is both imbalanced and associated with the outcome. Only obstructive sleep apnea met both criteria. Polycystic ovary syndrome was imbalanced but unassociated with the outcome and therefore cannot confound. Source: Z_T05.');}

{const r=csv('K_T56_evalue').slice(1).map(x=>[x[0],x[1],x[2]]);
 add('eTable 9','E-values for the primary estimate, against the measured surveillance rate ratios.',
  [['Quantity','Value','Relative to the E-value threshold'],...r],
  [3600,1800,3960],
  'An unmeasured mechanism would need to be associated with both IIH status and seizure ascertainment by at least 3.99-fold each, conditional on the measured covariates, to reduce the hazard ratio to unity. Five of the six measured surveillance channels fall below that threshold; emergency department contact (5.74) exceeds it. Source: K_T56.');}

Promise.all([
 Packer.toBuffer(new Document({creator:'Selim Tarabeah',title:'Tables',
  styles:{default:{document:{run:{font:FONT,size:20}}}},sections:[sec(main)]})),
 Packer.toBuffer(new Document({creator:'Selim Tarabeah',title:'Supplementary Tables',
  styles:{default:{document:{run:{font:FONT,size:20}}}},sections:[sec(sup)]})),
]).then(([a,b])=>{
 fs.writeFileSync(path.join(ROOT,'report','TABLES_main.docx'),a);
 fs.writeFileSync(path.join(ROOT,'report','TABLES_supplementary.docx'),b);
 console.log('wrote TABLES_main.docx',(a.length/1024).toFixed(0)+'KB','and TABLES_supplementary.docx',(b.length/1024).toFixed(0)+'KB');
});
