/* Corrected Epilepsia manuscript: prose from /tmp/user_ms_corrected.md,
 * then Tables 1-3 and Figures 1-3 appended at the end, as Epilepsia requires. */
const fs=require('fs'),path=require('path'),D=require('docx');
const {Document,Packer,Paragraph,TextRun,HeadingLevel,AlignmentType,Table,TableRow,
 TableCell,WidthType,ShadingType,BorderStyle,Footer,PageNumber,ImageRun,PageBreak}=D;
const ROOT=path.resolve(__dirname,'..'),TB=path.join(ROOT,'outputs','tables'),
      FG=path.join(ROOT,'outputs','figures_publication'),FONT='Times New Roman';

function csv(f){const t=fs.readFileSync(path.join(TB,f.endsWith('.csv')?f:f+'.csv'),'utf8').replace(/\r/g,'');
 const rows=[];let row=[],cur='',q=false;
 for(let i=0;i<t.length;i++){const c=t[i];
  if(q){if(c==='"'&&t[i+1]==='"'){cur+='"';i++;}else if(c==='"')q=false;else cur+=c;}
  else if(c==='"')q=true;else if(c===','){row.push(cur);cur='';}
  else if(c==='\n'){row.push(cur);rows.push(row);row=[];cur='';}else cur+=c;}
 if(cur.length||row.length){row.push(cur);rows.push(row);}
 return rows.filter(r=>r.length>1||(r[0]||'').trim()!=='');}

// pandoc escapes punctuation with backslashes (1\. , 1 \| METHODS, O\'Shea).
// Strip those before rendering or they appear literally in Word.
const unesc=t=>t.replace(/\\([.|'\[\]()*_~#+-])/g,'$1');
function runs(t,base={}){t=unesc(t);const out=[];const re=/(\*\*[^*]+\*\*|\*[^*]+\*|\[AUTHOR DECISION REQUIRED\]|\[END AUTHOR DECISION\])/g;
 let last=0,m;const push=(s,o)=>{if(s)out.push(new TextRun({text:s,font:FONT,size:24,...base,...o}));};
 while((m=re.exec(t))!==null){push(t.slice(last,m.index),{});const k=m[0];
  if(k.startsWith('**'))push(k.slice(2,-2),{bold:true});
  else if(k.startsWith('['))push(k,{bold:true,color:'B03A00'});
  else push(k.slice(1,-1),{italics:true});
  last=m.index+k.length;}
 push(t.slice(last),{});
 return out.length?out:[new TextRun({text:'',font:FONT,size:24})];}

const body=t=>new Paragraph({spacing:{line:480,after:0},children:runs(t)});
const cell=(s,w,h)=>new TableCell({width:{size:w,type:WidthType.DXA},
 shading:h?{type:ShadingType.CLEAR,fill:'EDF1F7',color:'auto'}:undefined,
 margins:{top:50,bottom:50,left:100,right:100},
 children:[new Paragraph({spacing:{line:240,before:15,after:15},
  children:[new TextRun({text:s,font:FONT,size:19,bold:h})]})]});
const tbl=(rows,w)=>new Table({columnWidths:w,width:{size:w.reduce((a,b)=>a+b,0),type:WidthType.DXA},
 borders:{top:{style:BorderStyle.SINGLE,size:6,color:'404040'},
  bottom:{style:BorderStyle.SINGLE,size:6,color:'404040'},
  left:{style:BorderStyle.NONE},right:{style:BorderStyle.NONE},
  insideHorizontal:{style:BorderStyle.SINGLE,size:2,color:'CCCCCC'},
  insideVertical:{style:BorderStyle.NONE}},
 rows:rows.map((r,i)=>new TableRow({tableHeader:i===0,
  children:r.map((c,j)=>cell(c===''||c==null?'—':String(c),w[j],i===0))}))});
const cap=(n,t)=>new Paragraph({spacing:{before:360,after:120},
 children:[new TextRun({text:n+'. ',bold:true,font:FONT,size:21}),
           new TextRun({text:t,font:FONT,size:21})]});
const note=s=>new Paragraph({spacing:{before:90,after:240},
 children:[new TextRun({text:s,italics:true,font:FONT,size:17,color:'595959'})]});

/* ---- prose ---- */
const md=fs.readFileSync('/tmp/user_ms_corrected.md','utf8').replace(/\r/g,'').split('\n');
const ch=[];let i=0;
while(i<md.length){const t=md[i].trim();
 if(t===''){i++;continue;}
 if(t.startsWith('## ')){ch.push(new Paragraph({heading:HeadingLevel.HEADING_2,
   spacing:{before:300,after:150},children:runs(t.slice(3),{bold:true,size:26})}));i++;continue;}
 if(t.startsWith('# ')){ch.push(new Paragraph({heading:HeadingLevel.HEADING_1,
   spacing:{before:360,after:180},children:runs(t.slice(2),{bold:true,size:28})}));i++;continue;}
 if(t.startsWith('•')||t.startsWith('- ')){ch.push(new Paragraph({spacing:{line:360,after:80},
   indent:{left:360,hanging:220},children:runs(t.replace(/^[-•]\s*/,'•  '))}));i++;continue;}
 if(/^\d+\\?\./.test(t)&&t.length<200){ch.push(new Paragraph({spacing:{line:300,after:40},
   children:runs(t)}));i++;continue;}
 const buf=[];
 while(i<md.length&&md[i].trim()!==''&&!md[i].trim().startsWith('#')
   &&!md[i].trim().startsWith('•')&&!md[i].trim().startsWith('- ')){buf.push(md[i].trim());i++;}
 ch.push(body(buf.join(' ')));ch.push(new Paragraph({spacing:{after:120},children:[]}));}

/* ---- tables ---- */
ch.push(new Paragraph({children:[new PageBreak()]}));
ch.push(new Paragraph({heading:HeadingLevel.HEADING_1,spacing:{after:200},
 children:[new TextRun({text:'TABLES',bold:true,font:FONT,size:28})]}));

{const r=csv('Z_T02_table1_full').slice(1).filter(x=>!/Opening pressure/.test(x[0]))
  .map(x=>[x[0].replace(' (NOT COMPARABLE - see note)','').replace('apnoea','apnea'),x[1],x[2],x[3]]);
 ch.push(cap('Table 1','Baseline characteristics of the matched cohort.'));
 ch.push(tbl([['Characteristic','IIH (n = 2,138)','Comparator (n = 5,743)','SMD'],...r],[3560,2160,2340,1300]));
 ch.push(note('SMD, standardized mean difference. Four covariates exceed |SMD| 0.10 and represent residual imbalance: hypertension, obstructive sleep apnea, polycystic ovary syndrome and pre-index clinical visits. Smoking was not comparably recorded between the two source extracts and was not used as a covariate. Opening pressure was available for 1,585 patients with IIH (74%), mean 29.5 cmH2O (SD 9.7), and was not recorded for comparators.'));}

{const pv=csv('K_T38_FINAL_results_visits').slice(1),pa=csv('K_T38_FINAL_results_all').slice(1),
  z=csv('Z_T01_complete_sets').slice(1),ag=csv('Z_T07_age18_sensitivity').slice(1),
  l=csv('SAP_T3b_landmark').slice(1),c=csv('SAP_T4_competing_risks').slice(1),
  o=csv('SAP_T6_propensity').slice(1),cm=csv('Z_T04_comorbidity_adjusted').slice(1);
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
 ch.push(cap('Table 2','Incident seizure or epilepsy: primary analysis and prespecified sensitivity analyses.'));
 ch.push(tbl(rows,[3860,1740,1960,1800]));
 ch.push(note('All models are Cox proportional-hazards models with a robust variance clustered by matched set. Primary analysis: 14.46 (95% CI 11.19-18.40) versus 6.72 (5.16-8.60) per 1,000 person-years over 4,563.0 and 9,375.2 person-years; 3-year cumulative incidence 3.83% versus 1.71%, absolute difference 2.12 percentage points; proportional-hazards p = 0.94. Cause-specific hazard ratio for death 0.61 (0.29-1.29).'));}

{const a=csv('K_T42_negative_controls').slice(1).filter(x=>x[11]!=='not estimable'),
  b=csv('K_T45_negative_controls_v2').slice(1),rt=csv('K_T55_negative_outcome_rates').slice(1);
 const rr={};rt.forEach(x=>rr[x[0]]=x[5]);
 const rows=[['Outcome','Baseline prevalence ratio','Post-index HR (95% CI)','Unadjusted rate ratio (95% CI)']];
 a.forEach(x=>rows.push([x[0],x[3],x[11],rr[x[0]]||'']));
 b.forEach(x=>rows.push([x[0],x[5],x[12],rr[x[0]]||'']));
 rows.push(['Seizure or epilepsy (primary outcome)','','2.28 (1.62 to 3.22)',rr['SEIZURE OR EPILEPSY (primary outcome)']||'']);
 ch.push(cap('Table 3','Negative-control outcomes: baseline imbalance, post-index association and unadjusted rate ratios.'));
 ch.push(tbl(rows,[3260,2100,2200,1800]));
 ch.push(note('All 11 negative-control outcomes were more prevalent in the IIH group before the index date (prevalence ratios 1.6-5.0, all p < 0.01); none met the prespecified balance criterion. Eight of 11 had post-index confidence intervals excluding 1. On unadjusted rate ratios the primary outcome (2.15) was lower than 6 of the 11 controls. Empirical calibration: r = 0.66, p = 0.026; predicted detection-only hazard ratio at baseline balance 1.04 (95% CI 0.37-2.90).'));}

/* ---- figures ---- */
ch.push(new Paragraph({children:[new PageBreak()]}));
ch.push(new Paragraph({heading:HeadingLevel.HEADING_1,spacing:{after:200},
 children:[new TextRun({text:'FIGURES',bold:true,font:FONT,size:28})]}));
const figs=[
 ['Figure_1_cumulative_incidence','Figure 1','Cumulative incidence of incident seizure or epilepsy after the 180-day washout, by cohort. Estimated with the Aalen-Johansen method treating death as a competing event; shaded bands are 95% confidence intervals. Three-year cumulative incidence was 3.83% in the IIH group and 1.71% among comparators (absolute difference 2.12 percentage points; HR 2.28, 95% CI 1.62-3.22).',540],
 ['Figure_2_forest_specifications','Figure 2','Hazard ratio for incident seizure or epilepsy across outcome definitions, cohort restrictions, follow-up landmarks and analytic models. Points are hazard ratios and horizontal lines 95% confidence intervals, on a logarithmic scale; the diamond marks the primary analysis and the dashed line its point estimate. Point estimates range from 1.93 to 2.79 and every confidence interval excludes 1.',620],
 ['Figure_3A_calibration','Figure 3A','Empirical calibration across 11 negative-control outcomes. Each orange point is one negative control, plotted by its baseline prevalence ratio and its post-index hazard ratio; the line is the fitted relationship (r = 0.66, p = 0.026) and the shaded band its 95% prediction interval. The open circle is the predicted detection-attributable hazard ratio at baseline balance, 1.04 (95% CI 0.37-2.90). The diamond is the observed seizure estimate, which lies inside that interval.',540],
 ['Figure_3B_contact_direction','Figure 3B','Direction of movement of each outcome under adjustment for six independent measures of pre-index healthcare contact. Circles show the median change across the 11 negative-control outcomes; diamonds show the seizure outcome. All 66 control-by-measure combinations moved toward the null, whereas the seizure estimate moved away from the null under all six measures.',540]];
for(const [f,n,legend,wpx] of figs){
 const buf=fs.readFileSync(path.join(FG,f+'.png'));
 // 600-dpi source; place at the given display width, preserving aspect.
 const mm={'Figure_1_cumulative_incidence':[140,100],'Figure_2_forest_specifications':[180,115],
           'Figure_3A_calibration':[140,105],'Figure_3B_contact_direction':[140,100]}[f];
 const wpt=Math.min(468,mm[0]/25.4*72), hpt=wpt*(mm[1]/mm[0]);
 ch.push(new Paragraph({spacing:{before:300,after:100},alignment:AlignmentType.CENTER,
  children:[new ImageRun({data:buf,type:'png',transformation:{width:Math.round(wpt),height:Math.round(hpt)}})]}));
 ch.push(new Paragraph({spacing:{after:240},children:[
  new TextRun({text:n+'. ',bold:true,font:FONT,size:21}),
  new TextRun({text:legend,font:FONT,size:21})]}));}

const doc=new Document({creator:'Selim Tarabeah',
 title:'Incident Seizures and Epilepsy Following Idiopathic Intracranial Hypertension',
 styles:{default:{document:{run:{font:FONT,size:24}}}},
 sections:[{properties:{page:{size:{width:12240,height:15840},
   margin:{top:1440,right:1440,bottom:1440,left:1440}},
   lineNumbers:{countBy:1,restart:'continuous'}},
  footers:{default:new Footer({children:[new Paragraph({alignment:AlignmentType.CENTER,
    children:[new TextRun({children:[PageNumber.CURRENT],font:FONT,size:20})]})]})},
  children:ch}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync(path.join(ROOT,'report','MANUSCRIPT_corrected.docx'),b);
 console.log('wrote MANUSCRIPT_corrected.docx',(b.length/1024).toFixed(0)+'KB');});
