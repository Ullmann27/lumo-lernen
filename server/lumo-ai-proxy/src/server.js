import { createServer } from 'node:http';
import { inspectChildSafety, buildLumoSystemPrompt, allowedTopicHints } from './childSafetyPolicy.js';

const port = Number(process.env.PORT || 8787);
const openAiApiKey = process.env.OPENAI_API_KEY || '';
const model = process.env.OPENAI_MODEL || 'gpt-4.1-mini';
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

function healthPayload() {
  return {
    ok: true,
    service: 'lumo-ai-proxy',
    openAiConfigured: Boolean(openAiApiKey),
  };
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (Buffer.byteLength(raw, 'utf8') > maxBodyBytes) {
        reject(new Error('body_too_large'));
        req.destroy();
      }
    });
    req.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
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
    }));
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

async function openAiChat({ message, history, childProfile }) {
  const profileText = childProfile
    ? `Kindprofil: Klasse ${childProfile.grade ?? 'unbekannt'}, Name ${childProfile.name ?? 'Kind'}. Keine privaten Daten erfragen.`
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
    temperature: 0.55,
    max_tokens: 420,
  };
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${openAiApiKey}`,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    if (!response.ok) {
      console.warn(`[lumo-ai-proxy] OpenAI returned ${response.status}`);
      throw new Error(`openai_${response.status}`);
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

async function generateTaskBatch({ subject, grade, units, count, childName }) {
  const safeCount = Math.max(3, Math.min(Number(count) || 10, 20));
  const safeUnits = Array.isArray(units) ? units.slice(0, 6).map(String) : [];
  const unitText = safeUnits.length > 0
    ? `Konzentriere dich auf diese Themen: ${safeUnits.join(', ')}.`
    : 'Mische saubere Standard-Themen für diese Klasse.';
  const payload = {
    model,
    response_format: { type: 'json_object' },
    messages: [
      {
        role: 'system',
        content: [
          'Du bist Lumo, ein Lehrer für die Volksschule.',
          'Erzeuge kindgerechte, fachlich richtige und eindeutig lösbare Lernaufgaben.',
          'Genau eine richtige Antwort. Die richtige Antwort muss in choices enthalten sein.',
          'Keine Politik, Gewalt, Religion oder privaten Daten.',
          'Antworte nur als JSON: {"tasks":[{"prompt":"...","answer":"...","choices":["..."],"explanation":"...","visual":"auto"}]}',
        ].join('\n'),
      },
      {
        role: 'user',
        content: [
          `Subject: ${subject}`,
          `Klasse: ${grade}`,
          `Anzahl: ${safeCount}`,
          `Kindname: ${childName || 'Kind'}`,
          unitText,
          'Mathematik: passende Zahlen, Plus, Minus, Zählen, Verdoppeln, Halbieren.',
          'Deutsch: Reime, Anfangslaut, Endlaut, Artikel, Tunwort, Namenswort, Silben.',
          'Erklärung kurz und kindgerecht.',
          'Visual-Feld: dots, line, sequence, ten_ones, syllables, auto oder emoji.',
        ].join('\n'),
      },
    ],
    temperature: 0.7,
    max_tokens: 1500,
  };
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25000);
  try {
    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${openAiApiKey}`,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    if (!response.ok) {
      console.warn(`[lumo-ai-proxy] OpenAI batch returned ${response.status}`);
      throw new Error(`openai_${response.status}`);
    }
    const data = await response.json();
    const raw = data?.choices?.[0]?.message?.content?.trim();
    if (!raw) throw new Error('empty_batch_reply');
    const parsed = JSON.parse(raw);
    const list = Array.isArray(parsed?.tasks) ? parsed.tasks : [];
    const cleaned = [];
    for (const item of list) {
      if (!item || typeof item !== 'object') continue;
      const prompt = String(item.prompt || '').trim();
      const answer = String(item.answer || '').trim();
      const explanation = String(item.explanation || '').trim();
      const choices = Array.isArray(item.choices)
        ? item.choices.map((c) => String(c || '').trim()).filter(Boolean).slice(0, 5)
        : [];
      if (!prompt || !answer || choices.length < 2) continue;
      if (!choices.some((c) => c.toLowerCase() === answer.toLowerCase())) continue;
      const ps = inspectChildSafety(prompt);
      const as = inspectChildSafety(answer);
      if (!ps.allowed || !as.allowed) continue;
      cleaned.push({
        prompt: prompt.slice(0, 220),
        answer: answer.slice(0, 60),
        choices: choices.map((c) => c.slice(0, 60)),
        explanation: explanation.slice(0, 200),
        visual: String(item.visual || 'auto').slice(0, 30),
      });
      if (cleaned.length >= safeCount) break;
    }
    return cleaned;
  } finally {
    clearTimeout(timeout);
  }
}

const server = createServer(async (req, res) => {
  const path = requestPath(req);
  if (req.method === 'OPTIONS') return json(res, 204, {});
  if (req.method === 'GET' && (path === '/' || path === '/health')) {
    return json(res, 200, healthPayload());
  }
  if (req.method === 'POST' && path === '/tasks') {
    console.log(`[lumo-ai-proxy] /tasks request received at ${new Date().toISOString()}`);
    if (!openAiApiKey) return json(res, 503, { error: 'openai_key_missing', tasks: [] });
    try {
      const body = await readJson(req);
      const subject = String(body.subject || '').trim();
      if (!subject) return json(res, 400, { error: 'subject_missing', tasks: [] });
      const tasks = await generateTaskBatch({
        subject,
        grade: Number(body.grade) || 1,
        units: Array.isArray(body.units) ? body.units : [],
        count: Number(body.count) || 10,
        childName: String(body.childName || '').slice(0, 60),
      });
      console.log(`[lumo-ai-proxy] /tasks ok: subject=${subject} returned=${tasks.length}`);
      return json(res, 200, { tasks, count: tasks.length, source: 'openai_batch' });
    } catch (error) {
      console.warn(`[lumo-ai-proxy] /tasks failed: ${String(error?.message || error).slice(0, 80)}`);
      return json(res, 500, { error: 'batch_generation_failed', tasks: [] });
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
      if (!openAiApiKey) {
        return json(res, 503, { ...fallbackReply(message), source: 'local_fallback_no_key', error: 'openai_key_missing' });
      }
      const result = await openAiChat({ message, history: body.history, childProfile: body.childProfile });
      console.log(`[lumo-ai-proxy] /chat ok: blocked=${Boolean(result.blocked)} replyLength=${(result.reply || '').length}`);
      return json(res, 200, { ...result, source: 'openai_proxy' });
    } catch (error) {
      console.warn(`[lumo-ai-proxy] /chat failed: ${String(error?.message || error).slice(0, 80)}`);
      return json(res, 500, {
        error: 'proxy_error',
        reply: 'Ich kann gerade nicht mit dem KI-Server sprechen. Wir können trotzdem Mathe, Deutsch oder Lesen üben.',
        detail: process.env.NODE_ENV === 'development' ? String(error?.message || error) : undefined,
      });
    }
  }
  return json(res, 404, { error: 'not_found', path });
});

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
