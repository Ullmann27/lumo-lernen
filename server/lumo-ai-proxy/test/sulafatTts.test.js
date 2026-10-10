import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createLumoServer } from '../src/server.js';
import { synthesizeSulafat, wavFromPcm, validateSpeechRequest } from '../src/sulafatTts.js';

const pcm = Buffer.alloc(24000, 0x10);
const modelReply = () => new Response(JSON.stringify({
  candidates: [{ content: { parts: [{ inlineData: {
    mimeType: 'audio/pcm;rate=24000', data: pcm.toString('base64'),
  } }] } }],
}), { status: 200, headers: { 'content-type': 'application/json' } });

test('Sulafat calls same speaker for dynamic texts and emits playable WAV', async () => {
  let calls = 0;
  const audio = await synthesizeSulafat({
    text: 'Acht plus fünf?',
    style: 'question',
    apiKey: 'server-only-placeholder',
    fetchImpl: async (url, options) => {
      calls++;
      assert.match(url, /^https:\/\/generativelanguage\.googleapis\.com\//);
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
    await action(async (payload) => fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
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
