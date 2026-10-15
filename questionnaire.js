const SECTIONS=[
 {id:'A',name:'CRM',long:'Customer Relationship Management',who:'CRM / account team',qs:[
  [1,'How satisfied were you with the speed of response from our CRM team to your emails, queries or requests?'],
  [2,'Did the CRM team demonstrate clear ownership of your requirement and follow it through until closure?'],
  [3,'How effectively did the CRM team coordinate internally and provide you with clear, consolidated information?'],
  [4,'Were you kept proactively informed about delays, concerns, changes or matters requiring your attention?'],
  [5,'How would you rate the professionalism, clarity and overall communication of the CRM team?']]},
 {id:'B',name:'Merchandising',long:'Order handling and coordination',who:'Merchandising team',qs:[
  [6,'How well did the Merchandising team understand your product, commercial and order requirements?'],
  [7,'How accurate and timely were order details, specifications, confirmations and other information shared with you?'],
  [8,'Did the Merchandising team provide proactive updates on order progress, critical timelines and potential risks?'],
  [9,'How effectively were changes, special requirements and customer instructions communicated and managed?'],
  [10,"How confident are you in the Merchandising team's ability to coordinate your order from confirmation through shipment?"]]},
 {id:'C',name:'Product Development',long:'Design, sampling and technical',who:'Product Development team',qs:[
  [11,'How well did the Product Development team understand and translate your design intent, drawings, specifications and expectations?'],
  [12,'How satisfied were you with the speed of product development, sampling and submission of technical information?'],
  [13,'How accurate were the samples/prototypes in relation to your approved design, dimensions, materials, finish and comfort expectations?'],
  [14,'How effectively did the team respond to development comments, modifications and technical challenges?'],
  [15,"How would you rate U&M's ability to offer practical technical solutions while protecting the original design intent?"]]},
 {id:'D',name:'Quality',long:'Product quality and inspection',who:'Quality team',qs:[
  [16,'How satisfied are you with the overall quality and consistency of products received from U&M Designs?'],
  [17,'How well do finished products conform to approved samples, specifications, workmanship and finish expectations?'],
  [18,'When a quality concern was raised, how quickly and effectively did the Quality team respond and investigate the issue?'],
  [19,'Were corrective actions communicated clearly, and did they give you confidence that the issue would not repeat?'],
  [20,"How would you rate your overall confidence in U&M's quality control and final inspection process?"]]},
 {id:'E',name:'Overall Experience',long:'Relationship and partnership',who:'everyone',qs:[
  [21,'Considering your most recent interaction, how would you rate your overall experience with U&M Designs?'],
  [22,'How confident are you in U&M Designs as a long-term manufacturing partner?'],
  [23,'Would you recommend U&M Designs to another retailer, designer or business partner?']]}
];
const OPEN=[['f1','What is the ONE thing U&M Designs should improve immediately to make working with us easier?'],
 ['f2','What does U&M Designs do particularly well that you would like us to continue?'],
 ['f3','Any specific feedback — positive or negative — about a U&M team member or department?'],
 ['f4','Any other suggestion you would like to share directly with the Managing Director?']];
const SEC=Object.fromEntries(SECTIONS.map(s=>[s.id,s]));
const DEPTS=['A','B','C','D'];
const SCALE_LABELS={1:'Poor',2:'Needs work',3:'Satisfactory',4:'Very good',5:'Excellent'};
/* five faces, drawn inline so they render identically on every device; each still stores 1–5 */
const FACE={
 1:'<path class="f-ln" d="M15 30 Q22 22 29 30"/><circle class="f-dot" cx="16.5" cy="17" r="2"/><circle class="f-dot" cx="27.5" cy="17" r="2"/><path class="f-ln" d="M13 13 l4 2 M31 13 l-4 2"/>',
 2:'<path class="f-ln" d="M15.5 29 Q22 25 28.5 29"/><circle class="f-dot" cx="16.5" cy="17.5" r="2"/><circle class="f-dot" cx="27.5" cy="17.5" r="2"/>',
 3:'<path class="f-ln" d="M15.5 28.5 H28.5"/><circle class="f-dot" cx="16.5" cy="17.5" r="2"/><circle class="f-dot" cx="27.5" cy="17.5" r="2"/>',
 4:'<path class="f-ln" d="M15 27 Q22 33 29 27"/><circle class="f-dot" cx="16.5" cy="17.5" r="2"/><circle class="f-dot" cx="27.5" cy="17.5" r="2"/>',
 5:'<path class="f-ln" d="M14 26 Q22 36 30 26 Z" style="fill:#1F2A44"/><path class="f-ln" d="M13.5 17.5 q3 -3.5 6 0 M24.5 17.5 q3 -3.5 6 0"/>'
};
const faceSvg=v=>`<svg viewBox="0 0 44 44" aria-hidden="true"><circle class="f-bg" cx="22" cy="22" r="20"/>${FACE[v]}</svg>`;

/* ---------- shared helpers ---------- */
const pct=v=>Math.round(v);
const band=v=>v>=70?'good':v>=55?'mid':'bad';
const avg=a=>a.length?a.reduce((x,y)=>x+y,0)/a.length:null;
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const fmtDate=d=>d?new Date(d).toLocaleDateString('en-GB',{day:'numeric',month:'short',year:'numeric'}):'';
const deptNames=ds=>ds.map(d=>SEC[d].name).join(' + ');
function toast(msg){let t=document.getElementById('toast');if(!t){t=document.createElement('div');t.id='toast';t.className='toast';document.body.appendChild(t)}t.textContent=msg;t.classList.add('show');clearTimeout(t._h);t._h=setTimeout(()=>t.classList.remove('show'),2800)}
