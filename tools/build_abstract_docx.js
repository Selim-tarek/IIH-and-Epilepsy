/* Standalone abstract file. Extracted from the same source markdown as the
 * manuscript, so the two cannot diverge. The abstract remains in the
 * manuscript as well. */
const fs=require('fs'),path=require('path'),D=require('docx');
const {Document,Packer,Paragraph,TextRun,HeadingLevel,AlignmentType,Footer,PageNumber}=D;
const ROOT=path.resolve(__dirname,'..'),FONT='Times New Roman';
const unesc=t=>t.replace(/\\([.|'\[\]()*_~#+-])/g,'$1');
function runs(t,base={}){t=unesc(t);const out=[];const re=/(\*\*[^*]+\*\*|\*[^*]+\*)/g;
 let last=0,m;const push=(s,o)=>{if(s)out.push(new TextRun({text:s,font:FONT,size:24,...base,...o}));};
 while((m=re.exec(t))!==null){push(t.slice(last,m.index),{});const k=m[0];
  if(k.startsWith('**'))push(k.slice(2,-2),{bold:true});else push(k.slice(1,-1),{italics:true});
  last=m.index+k.length;}
 push(t.slice(last),{});return out.length?out:[new TextRun({text:'',font:FONT,size:24})];}

const md=fs.readFileSync(path.join(ROOT,'report','MANUSCRIPT_corrected_source.md'),'utf8')
  .replace(/\r/g,'');
const title=(md.match(/^\*\*(.+?)\*\*/s)||[])[1]||'Manuscript';
const a=md.indexOf('# ABSTRACT'), b=md.indexOf('# 1 \\| INTRODUCTION');
if(a<0||b<0) throw new Error('could not locate the abstract in the source markdown');
const lines=md.slice(a,b).split('\n');

const ch=[new Paragraph({spacing:{after:260},
  children:[new TextRun({text:title.replace(/\s+/g,' '),bold:true,font:FONT,size:28})]})];
let i=0;
while(i<lines.length){const t=lines[i].trim();
 if(t===''){i++;continue;}
 if(t.startsWith('# ')){ch.push(new Paragraph({heading:HeadingLevel.HEADING_1,
   spacing:{before:260,after:160},children:runs(t.slice(2),{bold:true,size:26})}));i++;continue;}
 if(t.startsWith('•')){ch.push(new Paragraph({spacing:{line:360,after:90},
   indent:{left:360,hanging:220},children:runs(t.replace(/^•\s*/,'•  '))}));i++;continue;}
 const buf=[];
 while(i<lines.length&&lines[i].trim()!==''&&!lines[i].trim().startsWith('#')
   &&!lines[i].trim().startsWith('•')){buf.push(lines[i].trim());i++;}
 ch.push(new Paragraph({spacing:{line:480,after:0},children:runs(buf.join(' '))}));
 ch.push(new Paragraph({spacing:{after:120},children:[]}));}

// Objective through Significance. Keywords are not part of the abstract word count.
const kwIdx=md.indexOf('*Keywords:');
const abEnd=kwIdx>0?kwIdx:md.indexOf('# KEY POINTS');
const words=md.slice(md.indexOf('Objective:'),abEnd)
  .replace(/^#.*$/gm,'').replace(/\\([.|'\[\]()*_~#+-])/g,'$1').replace(/\*\*|\*/g,'')
  .split(/\s+/).filter(Boolean).length;
ch.push(new Paragraph({spacing:{before:300},children:[new TextRun({
 text:`Abstract word count (Objective through Significance): ${words}`,
 italics:true,font:FONT,size:18,color:'595959'})]}));

Packer.toBuffer(new Document({creator:'Selim Tarabeah',title:'Abstract',
 styles:{default:{document:{run:{font:FONT,size:24}}}},
 sections:[{properties:{page:{size:{width:12240,height:15840},
   margin:{top:1440,right:1440,bottom:1440,left:1440}}},
  footers:{default:new Footer({children:[new Paragraph({alignment:AlignmentType.CENTER,
   children:[new TextRun({children:[PageNumber.CURRENT],font:FONT,size:20})]})]})},
  children:ch}]})).then(buf=>{
 fs.writeFileSync(path.join(ROOT,'report','ABSTRACT.docx'),buf);
 console.log('wrote ABSTRACT.docx',(buf.length/1024).toFixed(0)+'KB · abstract words:',words);});
