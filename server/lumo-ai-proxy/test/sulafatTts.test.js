import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createLumoServer } from '../src/server.js';
import { synthesizeSulafat, wavFromPcm, validateSpeechRequest, DEFAULT_TTS_MODEL } from '../src/sulafatTts.js';

const pcm = Buffer.alloc(24000, 0x10);
const modelReply = () => new Response(JSON.stringify({
  candidates: [{ content: { parts: [{ inlineData: {
    mimeType: 'audio/pcm;rate=24000', data: pcm.toString('base64'),
  } }] } }],
}), { status: 200, headers: { 'content-type': 'application/json' } });
const fixtureAuthorization = 'Bearer fixture-parent-session-token';
const fixtureParent = async (token) => token === 'fixture-parent-session-token'
  ? { principalId: 'fixture-parent-01', parentVerified: true, speechConsent: true }
  : null;

test('Sulafat calls same speaker for dynamic texts and emits playable WAV', async () => {
  let calls = 0;
  const audio = await synthesizeSulafat({
    text: 'Acht plus fünf?',
    style: 'question',
    apiKey: 'server-only-placeholder',
    fetchImpl: async (url, options) => {
      calls++;
      assert.match(url, /^https:\/\/generativelanguage\.googleapis\.com\//);
      assert.ok(url.includes(DEFAULT_TTS_MODEL));
      assert.equal(options.headers['x-goog-api-key'], 'server-only-placeholder');
      const body = JSON.parse(options.body);
      assert.equal(body.generationConfig.speechConfig.voiceConfig.prebuiltVoiceConfig.voiceName, 'Sulafat');
      assert.equal(body.generationConfig.responseModalities[0], 'AUDIO');
      assert.match(body.contents[0].parts[0].text, /Acht plus fünf\?/);
      return modelReply();
    },
  });
  assert.equal(calls, 1);
  assert.equal(audio.subarray(0, 4).toString(), 'RIFF');
  assert.equal(audio.subarray(8, 12).toString(), 'WAVE');
  assert.equal(audio.readUInt32LE(40), pcm.length);
});

test('compressed, missing-format and wrong-rate audio never masquerade as PCM', async () => {
  for (const mimeType of ['audio/mpeg', '', 'audio/pcm;rate=16000']) {
    await assert.rejects(synthesizeSulafat({
      text: 'Hallo!', apiKey: 'placeholder',
      fetchImpl: async () => new Response(JSON.stringify({
        candidates: [{ content: { parts: [{ inlineData: {
          mimeType, data: pcm.toString('base64'),
        } }] } }],
      })),
    }), /tts_unsupported_audio/);
  }
});

test('status distinguishes configured Sulafat from an unverified provider without spending', async () => {
  let calls = 0;
  const server = createLumoServer({ apiKey: '', ttsEnabled: true,
    ttsApiKey: 'placeholder', authorizeSpeech: fixtureParent,
    fetchImpl: async () => { calls++; return modelReply(); } });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  try {
    const response = await fetch(`http://127.0.0.1:${server.address().port}/speech/status`);
    const status = await response.json();
    assert.equal(status.voice, 'Sulafat');
    assert.equal(status.configured, true);
    assert.equal(status.providerVerified, false);
    assert.equal(status.authorizationConfigured, true);
    assert.equal(status.parentAuthorizationRequired, true);
    assert.equal(status.model, DEFAULT_TTS_MODEL);
    assert.equal(calls, 0);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test('Never synthesize invalid, unsafe or oversized child texts', async () => {
  for (const text of ['', '  ', 'A'.repeat(461), 'Meine Telefonnummer ist 0664 1234567']) {
    assert.equal(validateSpeechRequest({ text }), null);
  }
  assert.equal(validateSpeechRequest({ text: 'Hallo!', style: 'unknown' }), null);
  assert.throws(() => wavFromPcm(Buffer.alloc(3)), /invalid_pcm/);
});

async function withSpeechServer(options, action) {
  const server = createLumoServer({ apiKey: '', ...options });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  try {
    const url = `http://127.0.0.1:${server.address().port}/speech`;
    await action(async (payload, authorization = fixtureAuthorization, extraHeaders = {}) => fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json',
        ...(authorization ? { authorization } : {}), ...extraHeaders },
      body: JSON.stringify(payload),
    }));
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test('server always refuses dynamic speech without explicit deployment', async () => {
  let providerCalls = 0;
  await withSpeechServer({
    ttsApiKey: 'server-only-placeholder',
    ttsEnabled: false,
    fetchImpl: async () => { providerCalls++; return modelReply(); },
  }, async (post) => {
    const response = await post({ text: 'Hallo!' });
    assert.equal(response.status, 503);
    assert.equal((await response.json()).error, 'sulafat_not_configured');
  });
  assert.equal(providerCalls, 0);
});

test('enabled server responds with exclusively Sulafat audio', async () => {
  await withSpeechServer({
    ttsApiKey: 'server-only-placeholder',
    ttsEnabled: true,
    authorizeSpeech: fixtureParent,
    fetchImpl: async () => modelReply(),
  }, async (post) => {
    const resp = await post({ text: 'Schreibe ein A.', style: 'explain' });
    assert.equal(resp.status, 200);
    const data = await resp.json();
    assert.equal(data.voice, 'Sulafat');
    const audio = Buffer.from(data.audioBase64, 'base64');
    assert.equal(audio.subarray(0, 4).toString(), 'RIFF');
  });
});

test('flag and provider key alone cannot enable a billable public endpoint', async () => {
  let calls = 0;
  const server = createLumoServer({
    apiKey: '', ttsApiKey: 'placeholder', ttsEnabled: true,
    fetchImpl: async () => { calls++; return modelReply(); },
  });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  try {
    const base = `http://127.0.0.1:${server.address().port}`;
    const status = await (await fetch(`${base}/speech/status`)).json();
    assert.equal(status.providerConfigured, true);
    assert.equal(status.authorizationConfigured, false);
    assert.equal(status.configured, false);
    const response = await fetch(`${base}/speech`, {
      method: 'POST', headers: { 'content-type': 'application/json',
        authorization: fixtureAuthorization },
      body: JSON.stringify({ text: 'Schreibe ein A.' }),
    });
    assert.equal(response.status, 503);
    assert.equal((await response.json()).error, 'sulafat_authorization_not_configured');
    assert.equal(calls, 0);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});

test('missing, forged and legacy headers never authorize parent speech', async () => {
  let calls = 0;
  await withSpeechServer({
    ttsApiKey: 'placeholder', ttsEnabled: true, authorizeSpeech: fixtureParent,
    fetchImpl: async () => { calls++; return modelReply(); },
  }, async (post) => {
    for (const header of ['', 'Bearer forged-parent-session-token',
      'Basic fixture-parent-session-token', 'Bearer ' + 'x'.repeat(4096)]) {
      const response = await post({ text: 'Schreibe ein A.' }, header);
      assert.equal(response.status, 401);
      assert.equal((await response.json()).error, 'parent_authorization_required');
    }
    const legacy = await post({ text: 'Schreibe ein A.' }, '', {
      'x-lumo-parent-token': 'fixture-parent-session-token',
    });
    assert.equal(legacy.status, 401);
  });
  assert.equal(calls, 0);
});

test('premium status or a verified adult without speech consent is not consent', async () => {
  let calls = 0;
  await withSpeechServer({
    ttsApiKey: 'placeholder', ttsEnabled: true,
    authorizeSpeech: async () => ({
      principalId: 'fixture-parent-01', parentVerified: true,
      premium: true, speechConsent: false,
    }),
    fetchImpl: async () => { calls++; return modelReply(); },
  }, async (post) => {
    const response = await post({ text: 'Schreibe ein A.' });
    assert.equal(response.status, 403);
    assert.equal((await response.json()).error, 'parent_speech_consent_required');
  });
  assert.equal(calls, 0);
});

test('a boolean verifier result or an unverified identity fails closed', async () => {
  for (const identity of [true, { principalId: 'parent', speechConsent: true },
    { principalId: '', parentVerified: true, speechConsent: true }]) {
    let calls = 0;
    await withSpeechServer({
      ttsApiKey: 'placeholder', ttsEnabled: true,
      authorizeSpeech: async () => identity,
      fetchImpl: async () => { calls++; return modelReply(); },
    }, async (post) => {
      assert.equal((await post({ text: 'Schreibe ein A.' })).status, 401);
    });
    assert.equal(calls, 0);
  }
});

test('verifier exceptions do not leak credentials or start synthesis', async () => {
  let calls = 0;
  await withSpeechServer({
    ttsApiKey: 'placeholder', ttsEnabled: true,
    authorizeSpeech: async () => { throw new Error('private-verifier-detail'); },
    fetchImpl: async () => { calls++; return modelReply(); },
  }, async (post) => {
    const response = await post({ text: 'Schreibe ein A.' });
    assert.equal(response.status, 401);
    assert.doesNotMatch(await response.text(), /private-verifier-detail/);
  });
  assert.equal(calls, 0);
});

test('verified parents have distinct budgets and share a bounded process total', async () => {
  let calls = 0;
  await withSpeechServer({
    ttsApiKey: 'placeholder', ttsEnabled: true, ttsPerParentDay: 2, ttsTotalDay: 3,
    authorizeSpeech: async (token) => ({
      principalId: token, parentVerified: true, speechConsent: true,
    }),
    fetchImpl: async () => { calls++; return modelReply(); },
  }, async (post) => {
    const payload = { text: 'Schreibe ein A.' };
    const concurrent = await Promise.all([
      post(payload, 'Bearer fixture-parent-A'),
      post(payload, 'Bearer fixture-parent-A'),
      post(payload, 'Bearer fixture-parent-A'),
    ]);
    assert.deepEqual(concurrent.map((r) => r.status).sort(), [200, 200, 429]);
    assert.equal((await post(payload, 'Bearer fixture-parent-B')).status, 200);
    assert.equal((await post(payload, 'Bearer fixture-parent-B')).status, 429);
  });
  assert.equal(calls, 3);
});
