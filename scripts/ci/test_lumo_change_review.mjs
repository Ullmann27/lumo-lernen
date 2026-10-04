import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const workflow = fs.readFileSync(path.join(root, '.github/workflows/lumo-change-review.yml'), 'utf8');
// Extract this workflow's two literal JavaScript blocks; fail if their layout changes.
const blocks = workflow.split(/\n          script: \|\n/).slice(1).map(part => {
  const lines = [];
  for (const line of part.split('\n')) {
    if (line.trim() && !line.startsWith('            ')) break;
    lines.push(line.slice(12));
  }
  return lines.join('\n');
});
assert.equal(blocks.length, 2, 'Expected coordination and report JavaScript blocks');
const AsyncFunction = Object.getPrototypeOf(async function(){}).constructor;
const inspect = new AsyncFunction('github','context','core', blocks[0]);
const report = new AsyncFunction('github','context','core', blocks[1]);
let passed = 0;
function fixture({latest={}, siblings=[], files={}, comments=[]}={}) {
  const outputs={}, texts=[], writes=[];
  const pr={number:156,head:{sha:'abc123'},base:{ref:'main'},state:'open'};
  const context={payload:{pull_request:pr},repo:{owner:'Ullmann27',repo:'lumo-lernen'},sha:'manualsha',serverUrl:'https://github.com',runId:42};
  const summary={};
  for(const n of ['addHeading','addRaw','addCodeBlock']) summary[n]=s=>{texts.push(s);return summary;};
  summary.write=async()=>{};
  const core={setOutput:(k,v)=>outputs[k]=v,summary,info:s=>texts.push(s)};
  const listFiles=()=>{}, list=()=>{}, listComments=()=>{};
  const github={rest:{pulls:{get:async()=>({data:{...pr,...latest}}),listFiles,list},issues:{listComments,
    createComment:async p=>writes.push({op:'create',...p}),updateComment:async p=>writes.push({op:'update',...p})}},
    paginate:async(fn,p)=>fn===listFiles?(files[p.pull_number]||[]):fn===list?siblings:fn===listComments?comments:assert.fail('unexpected API call')};
  return {outputs,texts,writes,context,core,github};
}
async function test(name, cb){ await cb();passed++; console.log('PASS '+name); }
await test('fresh head remains candidate', async()=>{const f=fixture();await inspect(f.github,f.context,f.core);assert.equal(f.outputs.fresh,'true');assert.equal(f.outputs.head,'abc123');});
await test('changed head never judged current',async()=>{const f=fixture({latest:{head:{sha:'new'}}});await inspect(f.github,f.context,f.core);assert.equal(f.outputs.fresh,'false');});
await test('closed PR never judged current',async()=>{const f=fixture({latest:{state:'closed'}});await inspect(f.github,f.context,f.core);assert.equal(f.outputs.fresh,'false');});
await test('manual run records actual event SHA',async()=>{const f=fixture();delete f.context.payload.pull_request;await inspect(f.github,f.context,f.core);assert.equal(f.outputs.head,'manualsha');assert.match(f.texts.join(' '),/No PR overlap/);});
await test('overlapping paths reported without a fake conflict verdict',async()=>{const f=fixture({siblings:[{number:156},{number:165,head:{sha:'sibling'}}],files:{156:[{filename:'lib/home.dart'}],165:[{filename:'lib/home.dart'},{filename:'lib/other.dart'}]}});await inspect(f.github,f.context,f.core);const data=JSON.parse(f.texts.find(s=>s.startsWith('{')));assert.deepEqual(data.overlaps,[{pr:165,head:'sibling',files:['lib/home.dart']}]);assert.match(f.texts.join(' '),/warnings, not proof/);});
await test('stale result cannot post a comment',async()=>{const f=fixture({latest:{head:{sha:'different'}}});process.env.VERIFY_RESULT='success';await report(f.github,f.context,f.core);assert.equal(f.writes.length,0);});
await test('closed PR cannot receive a success verdict',async()=>{const f=fixture({latest:{state:'closed'}});process.env.VERIFY_RESULT='success';await report(f.github,f.context,f.core);assert.equal(f.writes.length,0);});
await test('failure clearly reported, without an agent mention',async()=>{const f=fixture();process.env.VERIFY_RESULT='failure';await report(f.github,f.context,f.core);assert.match(f.writes[0].body,/FEHLER: PRUEFUNG NICHT BESTANDEN/);assert.doesNotMatch(f.writes[0].body,/@copilot|@claude/);});
await test('skipped is not presented as success',async()=>{const f=fixture();process.env.VERIFY_RESULT='skipped';await report(f.github,f.context,f.core);assert.match(f.writes[0].body,/NICHT VOLLSTAENDIG GEPRUEFT/);});
await test('success explicitly excludes APK approval',async()=>{const f=fixture();process.env.VERIFY_RESULT='success';await report(f.github,f.context,f.core);assert.match(f.writes[0].body,/TECHNISCHE PRUEFUNG BESTANDEN/);assert.match(f.writes[0].body,/KEINE APK-/);assert.match(f.writes[0].body,/abc123/);});
await test('own bot comment updated rather than duplicated',async()=>{const f=fixture({comments:[{id:7,user:{login:'github-actions[bot]'},body:'<!-- lumo-change-review-v1 -->'}]});await report(f.github,f.context,f.core);assert.equal(f.writes[0].op,'update');assert.equal(f.writes[0].comment_id,7);});
await test('user supplied marker cannot cause user-comment overwrite',async()=>{const f=fixture({comments:[{id:7,user:{login:'Ullmann27'},body:'<!-- lumo-change-review-v1 -->'}]});await report(f.github,f.context,f.core);assert.equal(f.writes[0].op,'create');});
console.log(`${passed} JS metadata/report fixture tests passed.`);
