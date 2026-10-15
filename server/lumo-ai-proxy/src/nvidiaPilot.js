// NVIDIA Nemotron 3 Ultra pilot. Server-side only. No secret or provider URL
// is accepted from an Android device or from a user-supplied request body.
import { inspectChildSafety, buildLumoSystemPrompt } from './childSafetyPolicy.js';

export const NVIDIA_PILOT_ENDPOINT = 'https://integrate.api.nvidia.com/v1/chat/completions';
export const NVIDIA_PILOT_MODEL = 'nvidia/nemotron-3-ultra-550b-a55b';

const allowedContexts = new Set([
  'companion', 'learning_tutor', 'math_coach',
  'reading_buddy', 'writing_helper', 'science_explorer',
]);

const personalData = /(?:[\w.+-]+@[\w.-]+\.[a-z]{2,}|(?:\+?\d[\d\s()/.-]{7,}\d)|(?:\b(?:mein(?:e)?\s+adresse|ich\s+wohne\s+in|meine\s+schule|mein\s+passwort|meine\s+telefonnummer)\b))/iu;

export function normalizeNvidiaPilotInput(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) return null;
  if (typeof input.message !== 'string') return null;
  const message = input.message.trim();
  if (!message || message.length > 800 || personalData.test(message) ||
      !inspectChildSafety(message).allowed) return null;
  if (!allowedContexts.has(input.context)) return null;
  const grade = input.grade == null ? 1 : input.grade;
  if (!Number.isInteger(grade) || grade < 1 || grade > 4) return null;
  // No names, profile identifiers, raw history, learning records or free-form
  // extras are sent to NVIDIA. Adult consent is verified separately by server.
  return { message, context: input.context, grade };
}

export function nvidiaPilotStatus({ enabled, apiKey, authorize }) {
  return {
    enabled: Boolean(enabled),
    providerConfigured: Boolean(apiKey),
    authorizationConfigured: typeof authorize === 'function',
    readyForAuthorizedPilot: Boolean(enabled && apiKey && typeof authorize === 'function'),
    model: NVIDIA_PILOT_MODEL,
    providerVerified: false,
    requiresVerifiedParentConsent: true,
  };
}

function promptForContext(context) {
  switch (context) {
    case 'learning_tutor':
    case 'math_coach':
      return 'Du bist Lumo als Mathe-/Lern-Nachhilfelehrer. Gib nur einen kleinen Denkschritt und eine Rückfrage, niemals die fertige Lösung einer laufenden Aufgabe.';
    case 'reading_buddy':
      return 'Du bist Lumo als Lesebegleiter. Erkläre höchstens ein unbekanntes Wort und stelle eine sanfte Verständnisfrage.';
    case 'writing_helper':
      return 'Du bist Lumo beim Schreiben. Gib einen kurzen Verbesserungshinweis, keine fertige Hausaufgabe.';
    case 'science_explorer':
      return 'Du bist Lumo und erklärst einen ungefährlichen Naturzusammenhang für Kinder.';
    default:
      return 'Du bist Lumo, der freundliche Lernfuchs. Begleite das Kind ruhig, motivierend und ohne unnötig lange Antworten.';
  }
}

export async function callNvidiaPilot({ input, apiKey, fetchImpl = fetch, timeoutMs = 18000 }) {
  const normalized = normalizeNvidiaPilotInput(input);
  if (!normalized) throw Object.assign(new Error('nvidia_invalid_input'), { code: 'nvidia_invalid_input' });
  if (!apiKey) throw Object.assign(new Error('nvidia_unconfigured'), { code: 'nvidia_unconfigured' });
  const { message, context, grade } = normalized;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  timer.unref?.();
  try {
    const response = await fetchImpl(NVIDIA_PILOT_ENDPOINT, {
      method: 'POST',
      headers: {
        authorization: 'Bearer ' + apiKey,
        accept: 'application/json',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: NVIDIA_PILOT_MODEL,
        messages: [
          { role: 'system', content: buildLumoSystemPrompt() + '\n' +
            promptForContext(context) + '\nKind ist in der ' + grade +
            '. Volksschulklasse. Keine privaten Daten erfragen. ' +
            'Keine Aussagen zu Preisen, Kontoständen oder Geräteaktionen. ' +
            'Antworte auf Deutsch in höchstens drei kurzen Sätzen.' },
          { role: 'user', content: message },
        ],
        stream: false,
        reasoning_effort: 'none',
        max_tokens: 320,
        temperature: 0.4,
      }),
      signal: controller.signal,
    });
    if (!response.ok) {
      const code = response.status === 429 ? 'nvidia_rate_limited'
        : response.status === 401 || response.status === 403 ? 'nvidia_auth_failed'
        : 'nvidia_upstream_unavailable';
      throw Object.assign(new Error(code), { code });
    }
    const data = await response.json();
    const raw = data?.choices?.[0]?.message?.content;
    if (typeof raw !== 'string' || !raw.trim() || /<\/?think\b/i.test(raw)) {
      throw Object.assign(new Error('nvidia_invalid_reply'), { code: 'nvidia_invalid_reply' });
    }
    const reply = raw.trim().slice(0, 600);
    const output = inspectChildSafety(reply);
    if (!output.allowed || personalData.test(reply)) {
      return {
        reply: output.allowed
          ? 'Lass uns lieber gemeinsam eine neue Lernfrage anschauen.'
          : output.redirect + ' Möchtest du lieber etwas lernen?',
        blocked: true,
        ruleId: output.ruleId || 'personal_data',
      };
    }
    return { reply, blocked: false, ruleId: null };
  } finally {
    clearTimeout(timer);
  }
}
