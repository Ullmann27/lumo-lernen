import { inspectChildSafety } from './childSafetyPolicy.js';

// Lumo's ONLY dynamic speaking voice. The original preview was produced
// with the Google Gemini prebuilt voice named "Sulafat".
// Gemini returns 24kHz 16-bit mono PCM for preview TTS models.
export const SULAFAT_VOICE = 'Sulafat';
export const DEFAULT_TTS_MODEL = 'gemini-3.1-flash-tts-preview';
const validStyles = new Set(['warm', 'greeting', 'explain', 'celebrate', 'comfort', 'question']);
const promptFor = {
  warm: 'warm, freundlich und natürlich',
  greeting: 'herzlich, aufmerksam und leicht fröhlich',
  explain: 'verständlich, klar und geduldig',
  celebrate: 'fröhlich, stolz und lebendig ohne Schreien',
  comfort: 'ruhig, zuversichtlich und tröstend',
  question: 'neugierig und ermutigend',
};

export function validateSpeechRequest(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
  const text = typeof body.text === 'string' ? body.text.trim() : '';
  const style = typeof body.style === 'string' ? body.style : 'warm';
  if (!text || text.length > 460 || /[\u0000-\u0008\u000B\u000C\u000E-\u001F]/u.test(text)) return null;
  if (!validStyles.has(style)) return null;
  if (!inspectChildSafety(text).allowed) return null;
  return { text, style };
}

export function wavFromPcm(pcm, sampleRate = 24000) {
  if (!Buffer.isBuffer(pcm) || pcm.length < 100 || pcm.length > 4_000_000 || pcm.length % 2) {
    throw new Error('tts_invalid_pcm');
  }
  const header = Buffer.alloc(44);
  header.write('RIFF', 0, 'ascii');
  header.writeUInt32LE(36 + pcm.length, 4);
  header.write('WAVEfmt ', 8, 'ascii');
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20); // PCM
  header.writeUInt16LE(1, 22); // mono
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(sampleRate * 2, 28);
  header.writeUInt16LE(2, 32);
  header.writeUInt16LE(16, 34);
  header.write('data', 36, 'ascii');
  header.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([header, pcm]);
}

export async function synthesizeSulafat({ text, style = 'warm', apiKey, model = DEFAULT_TTS_MODEL, fetchImpl = fetch }) {
  if (!apiKey) throw new Error('tts_not_configured');
  const verified = validateSpeechRequest({ text, style });
  if (!verified) throw new Error('tts_bad_request');

  const abort = new AbortController();
  const timeout = setTimeout(() => abort.abort(), 20000);
  try {
    const response = await fetchImpl(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-goog-api-key': apiKey },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{
            text: `Sprich auf Deutsch, ${promptFor[verified.style]}. Behalte die sanfte, wiedererkennbare Sulafat-Stimme. Lies AUSSCHLIESSLICH den Text zwischen den Markierungen vor, ohne Einleitung oder Zusätze.\n[ANFANG]\n${verified.text}\n[ENDE]`,
          }] }],
          generationConfig: {
            responseModalities: ['AUDIO'],
            speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: SULAFAT_VOICE } } },
          },
        }),
        signal: abort.signal,
      },
    );
    if (!response.ok) throw new Error('tts_provider_unavailable');
    const payload = await response.json();
    const part = payload?.candidates?.[0]?.content?.parts?.find((item) => item?.inlineData?.data);
    if (!part || !part.inlineData.data || part.inlineData.data.length > 6_000_000) {
      throw new Error('tts_invalid_provider_response');
    }
    const mime = String(part.inlineData.mimeType || '').toLowerCase();
    const audio = Buffer.from(part.inlineData.data, 'base64');
    if (audio.length < 100) throw new Error('tts_invalid_provider_response');
    if (audio.subarray(0, 4).toString('ascii') === 'RIFF' &&
        audio.subarray(8, 12).toString('ascii') === 'WAVE') return audio;
    if (mime && !mime.includes('pcm') && !mime.includes('l16') && !mime.includes('audio')) {
      throw new Error('tts_unsupported_audio');
    }
    return wavFromPcm(audio);
  } finally {
    clearTimeout(timeout);
  }
}
