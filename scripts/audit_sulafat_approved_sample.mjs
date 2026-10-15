#!/usr/bin/env node
// Adult-authorized, one-shot provider audit. NOT an app speech route,
// parent-session issuer, production deployment or automatic CI generation.
// Run with the approved HTTPS credential injected into curl's environment.
// Never place an API key in this script, an argument, a file or a log.
import { spawn, execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdir, open, readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import {
  synthesizeSulafat,
  validatePcmWav,
  DEFAULT_TTS_MODEL,
  SULAFAT_VOICE,
  SULAFAT_PROFILE,
} from '../server/lumo-ai-proxy/src/sulafatTts.js';

const approvedText = 'Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues! Von sieben bis zehn fehlen drei. Von den fünf bleiben dann zwei übrig. Zehn plus zwei ist zwölf.';
const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${DEFAULT_TTS_MODEL}:generateContent`;
const outputArg = process.argv.indexOf('--output-dir');
if (!process.argv.includes('--execute-approved-once') || outputArg < 0 ||
    !process.argv[outputArg + 1]) {
  console.error('No request sent. Requires --execute-approved-once --output-dir PATH and explicit user approval.');
  process.exit(2);
}
const outputDir = resolve(process.argv[outputArg + 1]);
await mkdir(outputDir, { recursive: true });
// A persistent exclusive marker also protects failed/timed-out requests from
// an accidental second billable attempt. Never remove it to force a retry.
const marker = await open(resolve(outputDir, 'ONE-APPROVED-ATTEMPT'), 'wx');
await marker.close();

let providerAttempts = 0;
let providerStatus = null;
let providerMime = null;
let usage = null;
let receivedModelVersion = null;
const startedAt = new Date().toISOString();
const sourceCommit = execFileSync('git', ['rev-parse', 'HEAD'], {
  cwd: resolve(import.meta.dirname, '..'), encoding: 'utf8',
}).trim();
const sourceHash = createHash('sha256').update(await readFile(
  resolve(import.meta.dirname, '../server/lumo-ai-proxy/src/sulafatTts.js'),
)).digest('hex');

async function credentialInjectedCurl(url, options) {
  if (url !== endpoint || options.method !== 'POST' || providerAttempts !== 0) {
    throw new Error('audit_scope_violation');
  }
  const request = JSON.parse(options.body);
  if (request.generationConfig?.speechConfig?.voiceConfig?.prebuiltVoiceConfig?.voiceName !== 'Sulafat' ||
      request.generationConfig?.responseModalities?.[0] !== 'AUDIO' ||
      !request.contents?.[0]?.parts?.[0]?.text?.endsWith(`${approvedText}\n[ENDE]`)) {
    throw new Error('audit_scope_violation');
  }
  // Only non-secret request fields are saved. The existing synthesizeSulafat
  // function's placeholder header is NOT sent; the secure HTTPS proxy supplies
  // the user's approved x-goog-api-key directly to the exact Google host.
  await writeFile(resolve(outputDir, 'approved-request.json'),
    `${JSON.stringify(request, null, 2)}\n`);
  providerAttempts++;
  const raw = await new Promise((resolveResponse, reject) => {
    const child = spawn('curl', [
      '--silent', '--show-error', '--proto', '=https',
      '--connect-timeout', '12', '--max-time', '28',
      '--request', 'POST', '--header', 'Content-Type: application/json',
      '--data-binary', '@-', '--write-out', '\n%{http_code}', url,
    ], { stdio: ['pipe', 'pipe', 'pipe'], signal: options.signal });
    const chunks = [];
    let length = 0;
    child.stdout.on('data', chunk => {
      length += chunk.length;
      if (length > 12_000_000) {
        child.kill();
        reject(new Error('audit_response_too_large'));
      } else {
        chunks.push(chunk);
      }
    });
    // Provider/proxy error text is deliberately not logged or persisted.
    child.stderr.resume();
    child.on('error', () => reject(new Error('audit_transport_failed')));
    child.on('close', code => code === 0
      ? resolveResponse(Buffer.concat(chunks).toString('utf8'))
      : reject(new Error('audit_transport_failed')));
    child.stdin.on('error', () => {});
    child.stdin.end(options.body);
  });
  const split = raw.lastIndexOf('\n');
  providerStatus = Number(raw.slice(split + 1));
  if (!Number.isInteger(providerStatus) || providerStatus < 100 || providerStatus > 599) {
    throw new Error('audit_invalid_status');
  }
  const payload = JSON.parse(raw.slice(0, split));
  providerMime = payload.candidates?.[0]?.content?.parts
    ?.find(part => part.inlineData?.data)?.inlineData?.mimeType ?? null;
  const totals = payload.usageMetadata;
  if (totals) {
    usage = Object.fromEntries(['promptTokenCount', 'candidatesTokenCount',
      'totalTokenCount'].filter(key => Number.isInteger(totals[key]))
      .map(key => [key, totals[key]]));
  }
  receivedModelVersion = typeof payload.modelVersion === 'string'
    ? payload.modelVersion : null;
  return new Response(JSON.stringify(payload), {
    status: providerStatus, headers: { 'content-type': 'application/json' },
  });
}

const baseManifest = () => ({
  started_at: startedAt,
  completed_at: new Date().toISOString(),
  endpoint,
  source_commit: sourceCommit,
  synthesis_source_sha256: sourceHash,
  requested_model: DEFAULT_TTS_MODEL,
  received_model_version: receivedModelVersion,
  requested_voice: SULAFAT_VOICE,
  profile: SULAFAT_PROFILE,
  approved_text: approvedText,
  provider_attempts: providerAttempts,
  provider_http_status: providerStatus,
  provider_audio_mime: providerMime,
  provider_usage: usage,
  credential_value_saved: false,
  child_data_sent: false,
  production_server_changed: false,
  android_playback_tested: false,
  parent_session_flow_tested: false,
});

try {
  const audio = validatePcmWav(await synthesizeSulafat({
    text: approvedText,
    style: 'warm',
    // This is not a credential. The approved secret is injected into curl only.
    apiKey: 'secure-proxy-injected-credential',
    fetchImpl: credentialInjectedCurl,
  }));
  let dataBytes = 0;
  for (let offset = 12; offset + 8 <= audio.length;) {
    const size = audio.readUInt32LE(offset + 4);
    if (audio.toString('ascii', offset, offset + 4) === 'data') dataBytes += size;
    offset += 8 + size + size % 2;
  }
  const filename = 'Lumo-Sulafat-echter-Gemini-API-Hoertest.wav';
  await writeFile(resolve(outputDir, filename), audio);
  const manifest = {
    ...baseManifest(), outcome: 'audio_received_and_structurally_validated',
    audio_file: filename, audio_bytes: audio.length,
    audio_sha256: createHash('sha256').update(audio).digest('hex'),
    sample_rate_hz: 24000, channels: 1, bits_per_sample: 16,
    audio_duration_seconds: dataBytes / 48000,
  };
  await writeFile(resolve(outputDir, 'live-api-manifest.json'),
    `${JSON.stringify(manifest, null, 2)}\n`);
  console.log(JSON.stringify(manifest, null, 2));
} catch (error) {
  const permitted = new Set(['tts_not_configured', 'tts_bad_request',
    'tts_provider_unavailable', 'tts_invalid_provider_response',
    'tts_invalid_pcm', 'tts_invalid_wav', 'tts_unsupported_audio',
    'audit_scope_violation', 'audit_transport_failed', 'audit_response_too_large',
    'audit_invalid_status']);
  const manifest = {
    ...baseManifest(), outcome: 'not_verified',
    error_code: permitted.has(error?.message) ? error.message : 'audit_failed',
  };
  await writeFile(resolve(outputDir, 'live-api-manifest.json'),
    `${JSON.stringify(manifest, null, 2)}\n`);
  console.error(JSON.stringify(manifest, null, 2));
  process.exitCode = 1;
}
