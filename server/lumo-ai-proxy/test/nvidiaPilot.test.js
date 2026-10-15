import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { createLumoServer } from '../src/server.js';
import {
  NVIDIA_PILOT_ENDPOINT,
  NVIDIA_PILOT_MODEL,
  normalizeNvidiaPilotInput,
} from '../src/nvidiaPilot.js';

const message = { message: 'Kannst du mir bei 7 + 5 helfen?', grade: 1, context: 'math_coach' };
const ok = (text = 'Zähle erst bis zehn. Wie viel fehlt dir dann?') =>
  new Response(JSON.stringify({ choices: [{ message: { content: text } }] }),
    { status: 200, headers: { 'content-type': 'application/json' } });

async function serverCase(options, fn) {
  const server = createLumoServer({ apiKey: '', ...options });
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');
  const base = 'http://127.0.0.1:' + server.address().port;
  const post = (body, token = '') => fetch(base + '/nvidia/pilot/chat', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(token ? { authorization: 'Bearer ' + token } : {}),
    },
    body: JSON.stringify(body),
  });
  try { await fn({ base, post }); }
  finally { await new Promise(resolve => server.close(resolve)); }
}

test('Pilot request accepts only allowed contexts and no private data/history', () => {
  assert.deepEqual(normalizeNvidiaPilotInput(message), message);
  for (const input of [
    { ...message, context: 'parent_advisor' },
    { ...message, grade: 5 },
    { ...message, grade: '1' },
    { ...message, message: 'Bitte hilf mir, meine Mail ist Kind@schule.at' },
    { ...message, message: 'Meine Telefonnummer 0676 12345678' },
    { ...message, message: 'ich wohne in der Hauptstraße' },
    { ...message, message: ' ' },
    { ...message, message: 'X'.repeat(801) },
  ]) assert.equal(normalizeNvidiaPilotInput(input), null);
});

test('Default pilot disabled: no key, no verifier and no outgoing NVIDIA call', async () => {
  let calls = 0;
  await serverCase({
    fetchImpl: async () => { calls++; throw new Error('must never call'); },
  }, async ({ base, post }) => {
    const status = await (await fetch(base + '/nvidia/pilot/status')).json();
    assert.equal(status.enabled, false);
    assert.equal(status.readyForAuthorizedPilot, false);
    assert.equal(status.providerVerified, false);
    const attempt = await post(message, 'opaque-test-token');
    assert.equal(attempt.status, 503);
    assert.equal((await attempt.json()).error, 'nvidia_pilot_unavailable');
    assert.equal(calls, 0);
  });
});

test('Even with a key and flag, missing verified-parent adapter fails closed', async () => {
  let calls = 0;
  await serverCase({
    nvidiaEnabled: true,
    nvidiaApiKey: 'mock-nvidia-key',
    fetchImpl: async () => { calls++; throw new Error('must not call'); },
  }, async ({ post }) => {
    assert.equal((await post(message, 'any')).status, 503);
    assert.equal(calls, 0);
  });
});

test('Invalid token, unverified identity and absent independent NVIDIA consent block upstream', async () => {
  let calls = 0;
  await serverCase({
    nvidiaEnabled: true, nvidiaApiKey: 'mock-nvidia-key',
    authorizeNvidiaPilot: token => token === 'valid-consent'
      ? { parentVerified: true, principalId: 'parent-1', nvidiaConsent: true }
      : token === 'without-consent'
        ? { parentVerified: true, principalId: 'parent-1', nvidiaConsent: false }
        : { parentVerified: false, principalId: 'parent-1', nvidiaConsent: true },
    fetchImpl: async () => { calls++; return ok(); },
  }, async ({ post }) => {
    assert.equal((await post(message)).status, 401);
    assert.equal((await post(message, 'unauthorized')).status, 401);
    const noConsent = await post(message, 'without-consent');
    assert.equal(noConsent.status, 403);
    assert.equal((await noConsent.json()).error, 'parent_nvidia_consent_required');
    assert.equal(calls, 0);
  });
});

test('Authorized tutoring and chat invoke exact NVIDIA endpoint, no identifiers and no raw history', async () => {
  const payloads = [];
  await serverCase({
    nvidiaEnabled: true, nvidiaApiKey: 'mock-nvidia-key',
    authorizeNvidiaPilot: () =>
      ({ parentVerified: true, principalId: 'not-an-api-payload', nvidiaConsent: true }),
    fetchImpl: async (url, options) => {
      assert.equal(url, NVIDIA_PILOT_ENDPOINT);
      assert.equal(options.headers.authorization, 'Bearer mock-nvidia-key');
      const payload = JSON.parse(options.body);
      payloads.push(payload);
      assert.equal(payload.model, NVIDIA_PILOT_MODEL);
      assert.equal(payload.stream, false);
      assert.equal(payload.reasoning_effort, 'none');
      assert.equal(payload.messages.length, 2);
      assert.equal(payload.messages[1].role, 'user');
      assert.equal(payload.messages[1].content, message.message);
      assert.doesNotMatch(JSON.stringify(payload), /not-an-api-payload|Privater Kindername|raw history/i);
      return ok();
    },
  }, async ({ post, base }) => {
    const health = await (await fetch(base + '/health')).json();
    assert.equal(health.nvidiaPilot.readyForAuthorizedPilot, true);
    assert.equal(health.nvidiaPilot.providerVerified, false);
    for (const context of ['math_coach', 'companion']) {
      const response = await post({
        ...message, context,
        childProfile: { name: 'Privater Kindername', id: 'test-ident' },
        history: [{ role: 'user', content: 'raw history' }],
      }, 'adult-token');
      assert.equal(response.status, 200);
      const body = await response.json();
      assert.equal(body.source, 'nvidia_nemotron_pilot');
      assert.equal(body.reply, 'Zähle erst bis zehn. Wie viel fehlt dir dann?');
    }
    assert.equal(payloads.length, 2);
  });
});

test('Unsafe questions and reasoning traces cannot leave or reach child', async () => {
  let calls = 0;
  await serverCase({
    nvidiaEnabled: true, nvidiaApiKey: 'mock-nvidia-key',
    authorizeNvidiaPilot: () =>
      ({ parentVerified: true, principalId: 'p', nvidiaConsent: true }),
    fetchImpl: async () => { calls++; return ok('<think>provider reasoning</think>fake'); },
  }, async ({ post }) => {
    const invalid = await post({ ...message, message: 'Meine Adresse ist ganz geheim.' }, 'adult-token');
    assert.equal(invalid.status, 400);
    assert.equal(calls, 0);
    const reject = await post(message, 'adult-token');
    assert.equal(reject.status, 502);
    const raw = await reject.json();
    assert.equal(raw.error, 'nvidia_invalid_reply');
    assert.doesNotMatch(JSON.stringify(raw), /provider reasoning|mock-nvidia-key/i);
  });
});

test('Quota exceeded before new upstream invocation and OpenAI routes stay unchanged', async () => {
  let nvidiaCalls = 0;
  await serverCase({
    nvidiaEnabled: true, nvidiaApiKey: 'mock-nvidia-key',
    nvidiaPerParentDay: 1, nvidiaTotalDay: 1,
    authorizeNvidiaPilot: () =>
      ({ parentVerified: true, principalId: 'p', nvidiaConsent: true }),
    fetchImpl: async (url) => {
      if (url === NVIDIA_PILOT_ENDPOINT) nvidiaCalls++;
      return ok();
    },
  }, async ({ post, base }) => {
    assert.equal((await post(message, 'parent-token')).status, 200);
    const second = await post(message, 'parent-token');
    assert.equal(second.status, 429);
    assert.equal((await second.json()).error, 'nvidia_pilot_budget_exceeded');
    assert.equal(nvidiaCalls, 1);
    const oldChat = await fetch(base + '/chat', {
      method: 'POST', headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ message: message.message }),
    });
    assert.equal(oldChat.status, 503);
    assert.equal((await oldChat.json()).source, 'local_fallback_no_key');
  });
});
