import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';
import { normalizePrompt, validateCalculation } from './taskValidation.js';
import { inspectChildSafety, buildLumoSystemPrompt, allowedTopicHints } from './childSafetyPolicy.js';

const port = Number(process.env.PORT || 8787);
const openAiApiKey = process.env.OPENAI_API_KEY || '';
export function resolveModel(configured) {
  const value = String(configured || '').trim();
  return !value || ['gpt-4.1-mini', 'gpt-4o-mini'].includes(value) ? 'gpt-6-luna' : value;
}
const model = resolveModel(process.env.OPENAI_MODEL);
const taskModel = process.env.OPENAI_TASK_MODEL ? resolveModel(process.env.OPENAI_TASK_MODEL) : model;
function modelOptions(selected, tokens) {
  return /^gpt-[56]/.test(selected)
    ? { reasoning_effort: /luna/.test(selected) ? 'none' : 'low', max_completion_tokens: tokens }
    : { temperature: 0.55, max_tokens: tokens };
}
const maxBodyBytes = 16 * 1024;

function json(res, status, payload) {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'access-control-allow-origin': process.env.ALLOWED_ORIGIN || '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'content-type, x-lumo-parent-token',
  });
  res.end(JSON.stringify(payload));
}

function requestPath(req) {
  try {
    return new URL(req.url || '/', 'https://lumo.local').pathname || '/';
  } catch (_) {
    return String(req.url || '/').split('?')[0] || '/';
  }
}

function healthPayload(apiKey, upstreamStatus) {
  return {
    ok: true,
    service: 'lumo-ai-proxy',
    version: '2026-10-02-restart',
    openAiConfigured: Boolean(apiKey),
    upstreamStatus,
    chatModel: model,
    taskModel,
  };
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    let tooLarge = false;
    req.on('data', (chunk) => {
      size += chunk.length;
      if (tooLarge) return;
      if (size > maxBodyBytes) {
        tooLarge = true;
        reject(new Error('body_too_large'));
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      try {
        if (tooLarge) return;
        const raw = Buffer.concat(chunks).toString('utf8');
        const parsed = raw ? JSON.parse(raw) : {};
        if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) throw new Error('invalid_json');
        resolve(parsed);
      } catch (_) {
        reject(new Error('invalid_json'));
      }
    });
    req.on('error', reject);
  });
}

function sanitizeHistory(history) {
  if (!Array.isArray(history)) return [];
  return history
    .filter((item) => item && (item.role === 'user' || item.role === 'assistant'))
    .slice(-8)
    .map((item) => ({
      role: item.role,
      content: String(item.content || '').slice(0, 900),
    }))
    .filter((item) => inspectChildSafety(item.content).allowed);
}

function fallbackReply(message) {
  const safety = inspectChildSafety(message);
  if (!safety.allowed) {
    return {
      reply: `${safety.redirect} Möchtest du lieber Mathe, Deutsch, Lesen oder Natur üben?`,
      blocked: true,
      ruleId: safety.ruleId,
    };
  }
  return {
    reply: 'Ich bin bereit. Frag mich etwas zu Mathe, Deutsch, Lesen, Englisch, Sachunterricht oder einer Geschichte.',
    blocked: false,
    ruleId: null,
  };
}

// Only fixed provider labels may enter logs; never the provider message/body.
const providerDiagnosticLabels = new Set([
  'insufficient_quota', 'rate_limit_exceeded', 'requests', 'tokens',
  'invalid_api_key', 'authentication_error', 'model_not_found',
  'unsupported_parameter', 'unsupported_value', 'invalid_parameter',
  'invalid_request_error', 'server_error',
]);
function providerDiagnosticLabel(value) {
  if (value == null) return 'absent';
  return providerDiagnosticLabels.has(value) ? value : 'other';
}

async function providerError(response) {
  let providerCode, providerType;
  try {
    const detail = (await response.json())?.error;
    providerCode = detail?.code;
    providerType = detail?.type;
  } catch (_) {}
  console.warn(`[lumo-ai-proxy] OpenAI error status=${response.status} code=${providerDiagnosticLabel(providerCode)} type=${providerDiagnosticLabel(providerType)}`);
  const code = response.status === 401 ? 'openai_authentication_failed'
    : [providerCode, providerType].includes('insufficient_quota') ? 'openai_quota_exceeded'
    : response.status === 429 ? 'openai_rate_limited'
    : providerCode === 'model_not_found' ? 'openai_model_unavailable'
    : ['unsupported_parameter', 'unsupported_value', 'invalid_parameter'].includes(providerCode) ? 'openai_configuration_error'
    : 'openai_upstream_error';
  return Object.assign(new Error(code), { status: response.status, publicCode: code });
}

function requestErrorStatus(error) {
  if (error.message === 'invalid_json') return 400;
  if (error.message === 'body_too_large') return 413;
  if (error.status === 429) return 503;
  return 502;
}

async function openAiChat({ message, history, childProfile, apiKey, fetchImpl }) {
  const grade = Math.max(1, Math.min(Number(childProfile?.grade) || 1, 4));
  const profileText = childProfile
    ? `Kindprofil: Klasse ${grade}. Keine privaten Daten erfragen.`
    : 'Kindprofil: unbekannt. Keine privaten Daten erfragen.';
  const payload = {
    model,
    messages: [
      { role: 'system', content: buildLumoSystemPrompt() },
      { role: 'system', content: profileText },
      { role: 'system', content: `Erlaubte Themenhinweise: ${allowedTopicHints.join(', ')}` },
      ...sanitizeHistory(history),
      { role: 'user', content: String(message).slice(0, 1200) },
    ],
    ...modelOptions(model, 1200),
  };
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetchImpl('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    if (!response.ok) {
      throw await providerError(response);
    }
    const data = await response.json();
    const reply = data?.choices?.[0]?.message?.content?.trim();
    if (!reply) throw new Error('empty_model_reply');
    const trimmedReply = reply.length > 800 ? `${reply.slice(0, 800).trimEnd()} ...` : reply;
    const outputSafety = inspectChildSafety(trimmedReply);
    if (!outputSafety.allowed) {
      return {
        reply: `${outputSafety.redirect} Soll ich dir eine leichte Schulfrage stellen?`,
        blocked: true,
        ruleId: outputSafety.ruleId,
      };
    }
    return { reply: trimmedReply, blocked: false, ruleId: null };
  } finally {
    clearTimeout(timeout);
  }
}

async function generateTaskBatch({ subject, grade, units, count, apiKey, fetchImpl, recentPrompts }) {
  const safeCount = Math.max(3, Math.min(Number(count) || 10, 12));
  const safeUnits = Array.isArray(units) ? units.slice(0, 6).map((u) => String(u).slice(0, 80)).filter((u) => inspectChildSafety(u).allowed) : [];
  const unitText = safeUnits.length > 0
    ? `Konzentriere dich auf diese Themen: ${safeUnits.join(', ')}.`
    : 'Mische saubere Standard-Themen für diese Klasse.';
  const payload = {
    model: taskModel,
    response_format: { type: 'json_object' },
    messages: [
      {
        role: 'system',
        content: [
          'Du bist Lumo, ein Lehrer für die Volksschule.',
          'Erzeuge abwechslungsreiche, fachlich richtige und eindeutig lösbare Lernaufgaben für die österreichische Volksschule.',
          'Neue Figuren, Alltagssituationen und Aufgabenformulierungen. Wiederhole keinen Prompt aus der Ausschlussliste.',
          'Für Mathematik: ganzzahlige Rechnungen im Zahlenraum 20/100/1000/10000 für Klasse 1/2/3/4. Mal/Geteilt erst ab Klasse 2.',
          'Jede Mathematik-Aufgabe benötigt calculation: {steps:[{a:Zahl,op:add|subtract|multiply|divide,b:Zahl}]}. Folgeschritte nutzen a:previous. answer ist nur die Ergebniszahl.',
          'Bei Sachaufgaben muss die Geschichte exakt zu allen Rechenschritten passen. Keine ungenannten Mengen oder versteckten Annahmen.',
          'explanation gibt kurze Rechenschritte. hints enthält drei aufeinander aufbauende Hilfen: Verständnisfrage, erster Schritt, Lösungsweg.',
          'Genau eine richtige Antwort. Die richtige Antwort muss in choices enthalten sein.',
          'Keine Politik, Gewalt, Religion oder privaten Daten.',
          'Antworte nur als JSON: {"tasks":[{"prompt":"...","answer":"...","choices":["..."],"explanation":"...","visual":"auto","calculation":{"steps":[]},"hints":["...","...","..."]}]}',
        ].join('\n'),
      },
      {
        role: 'user',
        content: [
          `Subject: ${subject}`,
          `Klasse: ${grade}`,
          `Anzahl: ${safeCount}`,
          unitText,
          `Diese bereits gestellten Aufgaben ausschließen: ${JSON.stringify([...recentPrompts].slice(-30))}`,
          'Mathematik: passende Zahlen, Plus, Minus, Zählen, Verdoppeln, Halbieren.',
          'Deutsch: Reime, Anfangslaut, Endlaut, Artikel, Tunwort, Namenswort, Silben.',
          'Erklärung kurz und kindgerecht.',
          'Visual-Feld: dots, line, sequence, ten_ones, syllables, auto oder emoji.',
        ].join('\n'),
      },
    ],
    ...modelOptions(taskModel, 6000),
  };
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25000);
  try {
    const response = await fetchImpl('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    if (!response.ok) {
      throw await providerError(response);
    }
    const data = await response.json();
    const raw = data?.choices?.[0]?.message?.content?.trim();
    if (!raw) throw new Error('empty_batch_reply');
    const parsed = JSON.parse(raw);
    const list = Array.isArray(parsed?.tasks) ? parsed.tasks : [];
    const cleaned = [];
    const seen = new Set(recentPrompts);
    for (const item of list) {
      if (!item || typeof item !== 'object') continue;
      const prompt = String(item.prompt || '').trim();
      const answer = String(item.answer || '').trim();
      const explanation = String(item.explanation || '').trim();
      const choices = Array.isArray(item.choices)
        ? [...new Set(item.choices.map((c) => String(c || '').trim()).filter(Boolean))].slice(0, 5)
        : [];
      if (!prompt || !answer || choices.length < 2 || seen.has(normalizePrompt(prompt))) continue;
      if (subject === 'Mathematik' && !validateCalculation(item.calculation, answer, grade)) continue;
      if (!choices.includes(answer)) continue;
      if (prompt.length > 220 || answer.length > 60 || choices.some((c) => c.length > 60)) continue;
      if ([prompt, answer, explanation, ...choices].some((text) => !inspectChildSafety(text).allowed)) continue;
      seen.add(normalizePrompt(prompt));
      cleaned.push({
        prompt: prompt.slice(0, 220),
        answer: answer.slice(0, 60),
        choices: choices.map((c) => c.slice(0, 60)),
        explanation: explanation.slice(0, 200),
        visual: 'auto',
      });
      if (cleaned.length >= safeCount) break;
    }
    return cleaned;
  } finally {
    clearTimeout(timeout);
  }
}

export function createLumoServer({ apiKey = openAiApiKey, fetchImpl = fetch } = {}) {
let upstreamStatus = 'not_checked';
const taskHistory = new Map();
const batchInFlight = new Map();
return createServer(async (req, res) => {
  const path = requestPath(req);
  if (req.method === 'OPTIONS') return json(res, 204, {});
  if (req.method === 'GET' && (path === '/' || path === '/health')) {
    return json(res, 200, healthPayload(apiKey, upstreamStatus));
  }
  if (req.method === 'POST' && path === '/tasks') {
    console.log(`[lumo-ai-proxy] /tasks request received at ${new Date().toISOString()}`);
    if (!apiKey) return json(res, 503, { error: 'openai_key_missing', tasks: [] });
    try {
      const body = await readJson(req);
      const subject = String(body.subject || '').trim();
      if (!['Mathematik', 'Deutsch'].includes(subject)) return json(res, 400, { error: 'subject_invalid', tasks: [] });
      const grade = Number(body.grade) || 1;
      if (!Number.isInteger(grade) || grade < 1 || grade > 4) return json(res, 400, { error: 'grade_invalid', tasks: [] });
      const key = `${subject}:${grade}`;
      if (batchInFlight.has(key)) return json(res, 429, { error: 'batch_busy', tasks: [] });
      const recentPrompts = taskHistory.get(key) || [];
      batchInFlight.set(key, true);
      let tasks;
      try { tasks = await generateTaskBatch({
        subject,
        grade,
        units: Array.isArray(body.units) ? body.units : [],
        count: Number(body.count) || 10,
        apiKey, fetchImpl, recentPrompts,
      }); } finally { batchInFlight.delete(key); }
      if (tasks.length === 0) throw new Error('no_valid_tasks');
      taskHistory.set(key, [...recentPrompts, ...tasks.map((t) => normalizePrompt(t.prompt))].slice(-200));
      console.log(`[lumo-ai-proxy] /tasks ok: subject=${subject} returned=${tasks.length}`);
      upstreamStatus = 'ready';
      return json(res, 200, { tasks, count: tasks.length, source: 'openai_batch' });
    } catch (error) {
      console.warn(`[lumo-ai-proxy] /tasks failed: ${String(error?.message || error).slice(0, 80)}`);
      if (error.publicCode) upstreamStatus = error.publicCode;
      return json(res, requestErrorStatus(error), { error: 'batch_generation_failed', reason: error.publicCode || (['invalid_json', 'body_too_large', 'no_valid_tasks'].includes(error.message) ? error.message : 'upstream_unavailable'), tasks: [] });
    }
  }
  if (req.method === 'POST' && path === '/chat') {
    console.log(`[lumo-ai-proxy] /chat request received at ${new Date().toISOString()}`);
    try {
      const body = await readJson(req);
      const message = String(body.message || '').trim();
      if (!message) return json(res, 400, { error: 'empty_message' });
      if (message.length > 1200) return json(res, 400, { error: 'message_too_long' });
      const inputSafety = inspectChildSafety(message);
      if (!inputSafety.allowed) {
        return json(res, 200, {
          reply: `${inputSafety.redirect} Möchtest du eine Deutsch-, Mathe- oder Naturfrage üben?`,
          blocked: true,
          ruleId: inputSafety.ruleId,
          source: 'local_policy',
        });
      }
      if (!apiKey) {
        return json(res, 503, { ...fallbackReply(message), source: 'local_fallback_no_key', error: 'openai_key_missing' });
      }
      const result = await openAiChat({ message, history: body.history, childProfile: body.childProfile, apiKey, fetchImpl });
      upstreamStatus = 'ready';
      console.log(`[lumo-ai-proxy] /chat ok: blocked=${Boolean(result.blocked)} replyLength=${(result.reply || '').length}`);
      return json(res, 200, { ...result, source: 'openai_proxy' });
    } catch (error) {
      console.warn(`[lumo-ai-proxy] /chat failed: ${String(error?.message || error).slice(0, 80)}`);
      if (error.publicCode) upstreamStatus = error.publicCode;
      return json(res, requestErrorStatus(error), {
        error: 'proxy_error',
        reason: error.publicCode || (['invalid_json', 'body_too_large'].includes(error.message) ? error.message : 'upstream_unavailable'),
        reply: 'Ich kann gerade nicht mit dem KI-Server sprechen. Wir können trotzdem Mathe, Deutsch oder Lesen üben.',
        detail: process.env.NODE_ENV === 'development' ? String(error?.message || error) : undefined,
      });
    }
  }
  return json(res, 404, { error: 'not_found', path });
});
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
const server = createLumoServer();
server.listen(port, '0.0.0.0', () => {
  console.log(`Lumo AI proxy listening on 0.0.0.0:${port}`);
});

function shutdown(signal) {
  console.log(`[lumo-ai-proxy] ${signal} received, closing server`);
  server.close((err) => {
    if (err) {
      console.error('[lumo-ai-proxy] server close error', err);
      process.exit(1);
    }
    process.exit(0);
  });
  setTimeout(() => process.exit(0), 10000).unref();
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
}
