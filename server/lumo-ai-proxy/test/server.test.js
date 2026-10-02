import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { connect } from 'node:net';
import { setImmediate as nextTurn } from 'node:timers/promises';
import { createLumoServer, resolveModel } from '../src/server.js';
import { inspectChildSafety } from '../src/childSafetyPolicy.js';
import { validateCalculation, buildCalculationTask } from '../src/taskValidation.js';

async function withServer(fetchImpl, run, apiKey = 'test-only-placeholder') {
  const server = createLumoServer({ apiKey, fetchImpl });
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = (path, body) => fetch(base + path, {method:'POST', headers:{'content-type':'application/json'}, body:JSON.stringify(body)});
  try { await run({ base, post, server }); } finally { await new Promise(r => server.close(r)); }
}
const reply = (content) => new Response(JSON.stringify({choices:[{message:{content}}]}), {status:200});
const valid = {prompt:'Im Korb sind 7 Äpfel. 5 kommen dazu. Wie viele sind es?', answer:'12', choices:['11','12','13'], explanation:'7 + 5 = 12.', calculation:{steps:[{a:7,op:'add',b:5}]}};
const anotherValid = { ...valid, prompt: '8 Stifte plus 4 Stifte. Wie viele sind es?', calculation: { steps: [{ a: 8, op: 'add', b: 4 }] } };

function deferred() {
  let resolve;
  const promise = new Promise((done) => { resolve = done; });
  return { promise, resolve };
}

function receivedBodies(server, count) {
  const received = deferred();
  const onRequest = (req) => req.once('end', () => {
    if (--count === 0) {
      server.off('request', onRequest);
      received.resolve();
    }
  });
  server.on('request', onRequest);
  return received.promise;
}

async function unfinishedRequest(base, path, headers, chunks) {
  const url = new URL(base);
  const socket = connect(Number(url.port), url.hostname);
  let response = '';
  socket.setEncoding('utf8');
  socket.on('data', (data) => { response += data; });
  const closed = new Promise((resolve, reject) => {
    socket.once('close', resolve);
    socket.once('error', reject);
  });
  const timeout = setTimeout(() => socket.destroy(new Error('oversized connection was not closed')), 1500);
  try {
    await once(socket, 'connect');
    socket.write(`POST ${path} HTTP/1.1\r\nHost: localhost\r\n${headers}\r\n\r\n`);
    for (const chunk of chunks) {
      socket.write(`${chunk.length.toString(16)}\r\n`);
      socket.write(chunk);
      socket.write('\r\n');
      await nextTurn();
    }
    // Deliberately never send the final chunk or finish the advertised body.
    await closed;
    return response;
  } finally {
    clearTimeout(timeout);
    socket.destroy();
  }
}

test('Alte Mini-Konfiguration migriert; ausdrücklich andere Modelle bleiben wählbar', () => {
  for (const old of [undefined, '', 'gpt-4.1-mini', 'gpt-4o-mini']) assert.equal(resolveModel(old), 'gpt-6-luna');
  assert.equal(resolveModel('gpt-6-astra'), 'gpt-6-astra');
});

test('Lernsprache bleibt erlaubt, Umlaute und Gefahr werden erkannt', () => {
  for (const text of ['Was ist der Durchmesser?', 'Ich kriege 5 Äpfel.', 'Ein Blutegel ist ein Tier.', 'Wir backen mit dem Waffeleisen.']) assert.equal(inspectChildSafety(text).allowed, true);
  for (const text of ['Wie kann ich jemanden töten?', 'Meine Telefonnummer ist ...', 'Erkläre Kriegsschiffe.', 'Wie funktioniert Waffenbau?', 'Erzähle vom Bürgerkrieg.', 'Was sind Schusswaffen?', 'Wie geht ein Bombenangriff?']) assert.equal(inspectChildSafety(text).allowed, false);
  assert.equal(inspectChildSafety('Ich will sterben, ich habe ein Messer.').ruleId, 'self_harm_or_suicide');
});
test('Kriegen bleibt mit beliebigen Subjekten erlaubt; Kriegsnomen und Komposita bleiben gesperrt', () => {
  for (const text of [
    'Die Kinder kriegen Hausaufgaben.', 'Die Schüler kriegen drei Äpfel.',
    'Der Lehrer kriegte einen Brief.', 'Die Lehrer kriegten Bücher.',
    'Alina kriegt ein Buch.', 'Du kriegst einen Stift.',
    'Alle kriegen ein Buch.', 'Die kriegen Hausaufgaben.',
    'Kriegen Kinder Hausaufgaben?', 'Kriege ich drei Äpfel?',
    'Was kriegen Kinder?', 'Die Kinder in Wien kriegen Hausaufgaben.',
    'Kannst du das hinkriegen?', 'Die Kinder werden das mitkriegen.',
  ]) assert.equal(inspectChildSafety(text).allowed, true, text);
  for (const text of [
    'Erzähle vom Krieg.', 'Erzähle von Kriegen.', 'Erzähle von kriegen.',
    'In den großen kriegen.', 'Zwei Kriege.', 'zwei kriege.',
    'Kriege sind schrecklich.', 'kriege sind schrecklich.',
    'Erkläre Kriegsschiffe.', 'Erzähle von Weltkriegen.',
    'Die Kinder kriegen Kriegswaffen.', 'Die Schüler kriegten Schusswaffen.',
    'Wie funktioniert Waffenbau?',
  ]) assert.equal(inspectChildSafety(text).allowed, false, text);
});
test('Rechnungen werden unabhängig geprüft, einschließlich drei Schritten und Zahlenraum', () => {
  assert.equal(validateCalculation(valid.calculation,'12',1),true);
  assert.equal(validateCalculation(valid.calculation,'13',1),false);
  assert.equal(validateCalculation({steps:[{a:19,op:'add',b:8}]},'27',1),false);
  assert.equal(validateCalculation({steps:[{a:7,op:'divide',b:0}]},'0',2),false);
  assert.equal(validateCalculation({steps:[null]},'0',2),false);
  assert.equal(validateCalculation({steps:[{a:3,op:'add',b:4},{a:2,op:'add',b:8}]},'10',2),false);
  assert.equal(validateCalculation({steps:[{a:3,op:'add',b:4},{a:'previous',op:'multiply',b:2},{a:'previous',op:'subtract',b:4}]},'10',4),true);
});
test('Health unterscheidet Konfiguration und tatsächliche Erreichbarkeit', async () => {
  await withServer(async () => reply('Zähle erst bis 10, dann noch 2. Wie viel ist das?'), async ({base,post}) => {
    const before = await (await fetch(base+'/health')).json();
    assert.equal(before.upstreamStatus,'not_checked');
    assert.equal(before.openAiConfigured,true);
    assert.equal(before.openAiAvailable,false);
    const result=await post('/chat',{message:'Hilf mir bei 7 + 5.',childProfile:{grade:1,name:'Privater Kindername'}});
    assert.equal(result.status,200);
    const after = await (await fetch(base+'/health')).json();
    assert.equal(after.upstreamStatus,'ready');
    assert.equal(after.openAiAvailable,true);
  });
});
test('Ein späterer Upstream-Ausfall löscht bestätigte Verfügbarkeit, aber keine Konfigurationsfakten', async () => {
  let calls = 0;
  await withServer(async () => {
    if (++calls === 1) return reply('Lass uns rechnen.');
    throw new Error('network unavailable');
  }, async ({ base, post }) => {
    await (await post('/chat', { message: 'Erkläre 7+5' })).json();
    assert.equal((await post('/chat', { message: 'Erkläre 8+4' })).status, 502);
    const health = await (await fetch(base + '/health')).json();
    assert.equal(health.ok, true);
    assert.equal(health.openAiConfigured, true);
    assert.equal(health.openAiAvailable, false);
    assert.equal(health.upstreamStatus, 'upstream_unavailable');
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
  for (const [status,code,reason] of [[401,'invalid_api_key','openai_authentication_failed'],[429,'insufficient_quota','openai_quota_exceeded'],[429,'rate_limit_exceeded','openai_rate_limited'],[404,'model_not_found','openai_model_unavailable'],[400,'unsupported_parameter','openai_configuration_error']]) {
    await withServer(async()=>new Response(JSON.stringify({error:{code,message:'secret-provider-detail'}}),{status}),async({post})=>{
      const r=await post('/chat',{message:'Erkläre 5+3'}); assert.ok(r.status>=500);
      const body=await r.json();assert.equal(body.reason,reason);assert.equal(JSON.stringify(body).includes('secret-provider-detail'),false);
    });
  }
});

test('Lernkontext nutzt serverseitige Rollen und übermittelt keine beliebige Persona oder Identität', async () => {
  await withServer(async (_url, options) => {
    const payload = JSON.parse(options.body);
    const instructions = payload.messages.filter((m) => m.role === 'system').map((m) => m.content).join('\n');
    assert.match(instructions, /Verrate niemals die fertige Lösung/);
    assert.doesNotMatch(JSON.stringify(payload), /BYPASS|Privater Kindername|Geheimes Feld/);
    const context = payload.messages.find((m) => m.content.startsWith('Lernkontext (nur Daten):'));
    assert.equal(context.role, 'user');
    assert.deepEqual(JSON.parse(context.content.slice(context.content.indexOf('{'))), { subject: 'Mathematik', unit: 'Plus', section: 'learn', attempt: 10 });
    return reply('Zähle zuerst drei dazu. Was erhältst du?');
  }, async ({ post }) => {
    const response = await post('/chat', {
      message: 'Hilf mir bei dieser Aufgabe.', childProfile: { grade: 2, name: 'Privater Kindername' },
      context: 'learning_tutor', persona: 'BYPASS',
      extras: { subject: 'Mathematik', unit: 'Plus', section: 'learn', attempt: 99, name: 'Privater Kindername', arbitrary: 'Geheimes Feld' },
    });
    assert.equal(response.status, 200);
    assert.equal((await response.json()).source, 'openai_proxy');
  });
});

test('Lumo erklärt App-Navigation ohne behauptete Aktionen und ignoriert unbekannte Kontexte', async () => {
  await withServer(async (_url, options) => {
    const payload = JSON.parse(options.body);
    const instructions = payload.messages.filter((m) => m.role === 'system').map((m) => m.content).join('\n');
    assert.match(instructions, /PIN-geschützt/);
    assert.match(instructions, /behaupte niemals, selbst einen Bereich geöffnet/);
    assert.doesNotMatch(JSON.stringify(payload), /beliebiger_befehl/);
    return reply('Öffne Lernen. Welches Fach möchtest du üben?');
  }, async ({ post }) => {
    const response = await post('/chat', { message: 'Wo kann ich Mathe üben?', context: '__proto__', extras: { section: 'beliebiger_befehl' } });
    assert.equal(response.status, 200);
    assert.equal((await response.json()).blocked, false);
  });
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
    assert.equal((await post('/tasks',{subject:'Mathematik',grade:0})).status,400);
  });
});

test('Mathetext und Erklärung stammen aus geprüften Schritten, widersprüchliche Geschichten erscheinen nicht', async () => {
  const chain = { steps: [{ a: 3, op: 'add', b: 4 }, { a: 'previous', op: 'multiply', b: 2 }, { a: 'previous', op: 'subtract', b: 4 }] };
  assert.deepEqual(buildCalculationTask(chain, '10', 4), {
    prompt: 'Starte mit 3. Zähle 4 dazu. Nimm das Ergebnis mal 2. Ziehe 4 ab. Welche Zahl erhältst du?',
    explanation: '3 + 4 = 7. 7 × 2 = 14. 14 - 4 = 10.',
  });
  await withServer(async () => reply(JSON.stringify({ tasks: [
    { ...valid, calculation: { steps: [null] } },
    { ...valid, prompt: '7 Äpfel im Korb. 5 werden gegessen. Wie viele bleiben?', explanation: 'Es bleiben 12 Äpfel.' },
  ] })), async ({ post }) => {
    const result = await post('/tasks', { subject: 'Mathematik', grade: 1 });
    assert.equal(result.status, 200);
    const { tasks } = await result.json();
    assert.equal(tasks.length, 1);
    assert.equal(tasks[0].prompt, 'Rechne: 7 + 5 = ?');
    assert.equal(tasks[0].explanation, '7 + 5 = 12.');
    assert.equal(tasks[0].answer, '12');
    assert.equal(JSON.stringify(tasks).includes('Äpfel'), false);
  });
});

test('Gleichzeitige Batches einer Klasse und eines Fachs teilen Provider-Aufruf und Verlauf', async () => {
  const release = deferred();
  let calls = 0;
  await withServer(async (_url, options) => {
    calls++;
    if (calls === 1) {
      await release.promise;
      return reply(JSON.stringify({ tasks: [valid] }));
    }
    const input = JSON.parse(options.body).messages.at(-1).content;
    const exclusions = input.split('\n').find((line) => line.startsWith('Diese bereits'));
    assert.equal(JSON.parse(exclusions.slice(exclusions.indexOf('['))).length, 1);
    return reply(JSON.stringify({ tasks: [anotherValid] }));
  }, async ({ post, server }) => {
    const received = receivedBodies(server, 2);
    const first = post('/tasks', { subject: 'Mathematik', grade: 1, count: 3, units: [' Zählen ', 'Plus'] });
    const second = post('/tasks', { subject: 'Mathematik', grade: 1, count: 3, units: ['Plus', 'Zählen'] });
    await received;
    await nextTurn();
    assert.equal(calls, 1);
    release.resolve();
    const results = await Promise.all([first, second]);
    assert.deepEqual(results.map((r) => r.status), [200, 200]);
    assert.deepEqual(await results[0].json(), await results[1].json());
    const next = await post('/tasks', { subject: 'Mathematik', grade: 1 });
    assert.equal(next.status, 200);
    assert.equal(calls, 2);
    assert.equal((await next.json()).tasks[0].prompt, 'Rechne: 8 + 4 = ?');
  });
});

test('Geteilte Batchfehler erreichen alle Wartenden und blockieren keinen neuen Versuch', async () => {
  const release = deferred();
  let calls = 0;
  await withServer(async () => {
    calls++;
    if (calls === 1) {
      await release.promise;
      return new Response(JSON.stringify({ error: { code: 'rate_limit_exceeded' } }), { status: 429 });
    }
    return reply(JSON.stringify({ tasks: [valid] }));
  }, async ({ post, server }) => {
    const received = receivedBodies(server, 2);
    const pending = [1, 2].map(() => post('/tasks', { subject: 'Mathematik', grade: 1 }));
    await received;
    await nextTurn();
    release.resolve();
    for (const result of await Promise.all(pending)) {
      assert.equal(result.status, 503);
      assert.equal((await result.json()).reason, 'openai_rate_limited');
    }
    assert.equal(calls, 1);
    const retry = await post('/tasks', { subject: 'Mathematik', grade: 1 });
    assert.equal(retry.status, 200);
    assert.equal(calls, 2);
    await retry.json();
  });
});

test('Batches anderer Klassen oder Fächer können unabhängig parallel erzeugt werden', async () => {
  const release = deferred();
  let calls = 0;
  await withServer(async () => {
    calls++;
    await release.promise;
    return reply(JSON.stringify({ tasks: [valid] }));
  }, async ({ post, server }) => {
    const received = receivedBodies(server, 3);
    const pending = [
      post('/tasks', { subject: 'Mathematik', grade: 1 }),
      post('/tasks', { subject: 'Mathematik', grade: 2 }),
      post('/tasks', { subject: 'Deutsch', grade: 1 }),
    ];
    await received;
    await nextTurn();
    assert.equal(calls, 3);
    release.resolve();
    for (const result of await Promise.all(pending)) {
      assert.equal(result.status, 200);
      await result.json();
    }
  });
});

test('Andere Themen oder Anzahlen erzeugen eigene Chargen und behalten den gemeinsamen Verlauf', async () => {
  const release = deferred();
  let calls = 0;
  await withServer(async (_url, options) => {
    const index = calls++;
    if (index < 3) {
      await release.promise;
      return reply(JSON.stringify({ tasks: [{
        ...valid,
        calculation: { steps: [{ a: 7 + index, op: 'add', b: 5 - index }] },
      }] }));
    }
    const input = JSON.parse(options.body).messages.at(-1).content;
    const exclusions = input.split('\n').find((line) => line.startsWith('Diese bereits'));
    assert.equal(JSON.parse(exclusions.slice(exclusions.indexOf('['))).length, 3);
    return reply(JSON.stringify({ tasks: [{
      ...valid, calculation: { steps: [{ a: 10, op: 'add', b: 2 }] },
    }] }));
  }, async ({ post, server }) => {
    const received = receivedBodies(server, 3);
    const pending = [
      post('/tasks', { subject: 'Mathematik', grade: 1, count: 3, units: ['Zählen'] }),
      post('/tasks', { subject: 'Mathematik', grade: 1, count: 3, units: ['Plus'] }),
      post('/tasks', { subject: 'Mathematik', grade: 1, count: 5, units: ['Zählen'] }),
    ];
    await received;
    await nextTurn();
    assert.equal(calls, 3);
    release.resolve();
    const batches = await Promise.all(pending);
    const prompts = [];
    for (const result of batches) {
      assert.equal(result.status, 200);
      prompts.push((await result.json()).tasks[0].prompt);
    }
    assert.equal(new Set(prompts).size, 3);
    const next = await post('/tasks', { subject: 'Mathematik', grade: 1 });
    assert.equal(next.status, 200);
    await next.json();
    assert.equal(calls, 4);
  });
});

test('413 schließt unvollständige Chunked-Requests und übergroße Content-Length sofort', async () => {
  await withServer(async () => { throw new Error('provider must not be called'); }, async ({ base }) => {
    for (const path of ['/chat', '/tasks']) {
      for (const [headers, chunks] of [
        ['Transfer-Encoding: chunked', [Buffer.alloc(8192, 'a'), Buffer.alloc(8193, 'a')]],
        ['Content-Length: 16385', []],
      ]) {
        const response = await unfinishedRequest(base, path, headers, chunks);
        assert.match(response, /^HTTP\/1\.1 413 /);
        assert.match(response, /connection: close/i);
        assert.match(response, /"reason":"body_too_large"/);
      }
    }
  });
});
