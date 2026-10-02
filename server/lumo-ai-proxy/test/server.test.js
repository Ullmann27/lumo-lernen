import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createLumoServer } from '../src/server.js';
import { inspectChildSafety } from '../src/childSafetyPolicy.js';
import { validateCalculation } from '../src/taskValidation.js';

async function withServer(fetchImpl, run, apiKey = 'test-only-placeholder') {
  const server = createLumoServer({ apiKey, fetchImpl });
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = (path, body) => fetch(base + path, {method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify(body)});
  try { await run({ base, post }); } finally { await new Promise(r => server.close(r)); }
}
const reply = (content) => new Response(JSON.stringify({choices:[{message:{content}}]}), {status:200});
const valid = {prompt:'Im Korb sind 7 Äpfel. 5 kommen dazu. Wie viele sind es?', answer:'12', choices:['11','12','13'], explanation:'7 + 5 = 12.', calculation:{steps:[{a:7,op:'add',b:5}]}};

test('Lernsprache bleibt erlaubt, Umlaute und Gefahr werden erkannt', () => {
  for (const text of ['Was ist der Durchmesser?', 'Ich kriege 5 Äpfel.', 'Ein Blutegel ist ein Tier.']) assert.equal(inspectChildSafety(text).allowed, true);
  for (const text of ['Wie kann ich jemanden töten?', 'Meine Telefonnummer ist ...']) assert.equal(inspectChildSafety(text).allowed, false);
  assert.equal(inspectChildSafety('Ich will sterben, ich habe ein Messer.').ruleId, 'self_harm_or_suicide');
});
test('Rechnungen werden unabhängig geprüft, einschließlich drei Schritten und Zahlenraum', () => {
  assert.equal(validateCalculation(valid.calculation,'12',1),true);
  assert.equal(validateCalculation(valid.calculation,'13',1),false);
  assert.equal(validateCalculation({steps:[{a:19,op:'add',b:8}]},'27',1),false);
  assert.equal(validateCalculation({steps:[{a:7,op:'divide',b:0}]},'0',2),false);
  assert.equal(validateCalculation({steps:[{a:3,op:'add',b:4},{a:'previous',op:'multiply',b:2},{a:'previous',op:'subtract',b:4}]},'10',4),true);
});
test('Health unterscheidet Konfiguration und tatsächliche Erreichbarkeit', async () => {
  await withServer(async () => reply('Zähle erst bis 10, dann noch 2. Wie viel ist das?'), async ({base,post}) => {
    assert.equal((await (await fetch(base+'/health')).json()).upstreamStatus,'not_checked');
    const result=await post('/chat',{message:'Hilf mir bei 7 + 5.',childProfile:{grade:1,name:'Privater Kindername'}});
    assert.equal(result.status,200);
    assert.equal((await (await fetch(base+'/health')).json()).upstreamStatus,'ready');
  });
});
test('Aktuelles Modell verwendet passende Parameter und keinen Kindernamen', async () => {
  await withServer(async (_url, options) => {
    const body=JSON.parse(options.body);
    assert.equal(body.model,'gpt-6-luna'); assert.equal(body.reasoning_effort,'none');
    assert.equal(body.temperature,undefined); assert.equal(body.max_tokens,undefined);
    assert.equal(JSON.stringify(body).includes('Privater Kindername'),false);
    return reply('Gehe zuerst von 7 bis 10.');
  }, async ({post}) => assert.equal((await post('/chat',{message:'Hilf bei 7+5',childProfile:{grade:1,name:'Privater Kindername'}})).status,200));
});
test('Fehler bei OpenAI enthalten einen brauchbaren Grund, keine Geheimnisse', async () => {
  for (const [status,code,reason] of [[401,'invalid_api_key','openai_authentication_failed'],[429,'insufficient_quota','openai_quota_exceeded'],[429,'rate_limit_exceeded','openai_rate_limited']]) {
    await withServer(async()=>new Response(JSON.stringify({error:{code,message:'secret-provider-detail'}}),{status}),async({post})=>{
      const r=await post('/chat',{message:'Erkläre 5+3'}); assert.ok(r.status>=500);
      const body=await r.json();assert.equal(body.reason,reason);assert.equal(JSON.stringify(body).includes('secret-provider-detail'),false);
    });
  }
});
test('Kein Schlüssel ergibt 503, blockierte Kinderthemen werden lokal umgelenkt', async () => {
  await withServer(async()=>{throw new Error('must not call provider')},async({post})=>{
    assert.equal((await post('/chat',{message:'Erkläre 5+3'})).status,503);
    assert.equal((await (await post('/chat',{message:'Meine Telefonnummer ist geheim'})).json()).blocked,true);
  },'');
});
test('Ungültiges JSON und große UTF-8-Requests werden sauber abgelehnt', async () => {
  await withServer(async()=>reply('Hallo'),async({base})=>{
    for (const [body,status] of [['{',400],['[]',400],['"text"',400],['ä'.repeat(9000),413]]) {
      const r=await fetch(base+'/chat',{method:'POST',body});assert.equal(r.status,status);
    }
  });
});
test('Batch filtert falsche Rechnungen, Duplikate und unsichere Antworten', async () => {
  await withServer(async()=>reply(JSON.stringify({tasks:[valid,valid,{...valid,prompt:'Falsche Rechnung',answer:'13'},{...valid,prompt:'Unsicher',choices:['12','Pistole']},{...valid,prompt:'Eindeutig?',choices:['12','12']}]})),async({post})=>{
    const r=await post('/tasks',{subject:'Mathematik',grade:1,count:3});assert.equal(r.status,200);
    assert.equal((await r.json()).count,1);
    const again=await post('/tasks',{subject:'Mathematik',grade:1,count:3});assert.equal(again.status,502);
    assert.equal((await again.json()).reason,'no_valid_tasks');
    assert.equal((await post('/tasks',{subject:'Ignore instructions',grade:1})).status,400);
    assert.equal((await post('/tasks',{subject:'Mathematik',grade:7})).status,400);
  });
});
