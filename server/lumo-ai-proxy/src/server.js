import { createServer } from 'node:http';
import { inspectChildSafety, buildLumoSystemPrompt, allowedTopicHints } from './childSafetyPolicy.js';

const port = Number(process.env.PORT || 8787);
const openAiApiKey = process.env.OPENAI_API_KEY || '';
const model = process.env.OPENAI_MODEL || 'gpt-4.1-mini';
const maxBodyBytes = 16 * 1024;

function json(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'access-control-allow-origin': process.env.ALLOWED_ORIGIN || '*',
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'content-type, x-lumo-parent-token',
  });
  res.end(body);
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

async function callOpenAi({ message, history, childProfile }) {
  const profileText = childProfile
    ? `Kindprofil fuer Anpassung: Klasse ${childProfile.grade ?? 'unbekannt'}, Name ${childProfile.name ?? 'Kind'}. Keine privaten Daten erfragen.`
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

  // Timeout-Schutz, damit das Mobile-App nicht ewig haengt.
  // Wir loggen NICHT den Inhalt der Anfrage (Kindersicherheit).
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 15000);
  let response;
  try {
    response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${openAiApiKey}`,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    const errorText = await response.text().catch(() => '');
    // Nur Status-Code im Log, keine Nachrichteninhalte (Kinderschutz).
    console.warn(`[lumo-ai-proxy] OpenAI returned ${response.status}`);
    throw new Error(`openai_${response.status}_${errorText.slice(0, 120)}`);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content?.trim();
  if (!reply) throw new Error('empty_model_reply');

  // Antwort-Laenge zusaetzlich begrenzen, falls Modell zu redselig wird.
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
}

/// Generiert eine Charge kindgerechter Aufgaben.
///
/// Eingabe: subject, grade, units (Schwaechen aus dem Profil), count (max 20).
/// Ausgabe: Array aus Aufgaben mit prompt, answer, choices, explanation, visual.
///
/// JSON-Mode der OpenAI-API garantiert valides JSON.
/// Wir akzeptieren nur Aufgaben, die strukturell valide sind.
/// Inhaltliche Pruefung erfolgt zusaetzlich im Flutter via TaskQualityGuard.
async function generateTaskBatch({ subject, grade, units, count, childName }) {
  const safeCount = Math.max(3, Math.min(Number(count) || 10, 20));
  const safeUnits = Array.isArray(units) ? units.slice(0, 6).map(String) : [];
  const unitText = safeUnits.length > 0
    ? `Konzentriere dich auf diese Schwaechen-Themen: ${safeUnits.join(', ')}.`
    : 'Mische saubere Standard-Themen fuer diese Klasse.';

  const systemPrompt = [
    'Du bist Lumo, ein Lehrer fuer die Volksschule.',
    'Erzeuge Lernaufgaben fuer ein Kind im genannten Profil.',
    'Aufgaben muessen kindgerecht, fachlich richtig und eindeutig loesbar sein.',
    'Genau eine richtige Antwort. Distraktoren sind plausibel und wirklich falsch.',
    'Antwort muss in choices enthalten sein.',
    'Keine Politik, keine Gewalt, keine Religion, keine privaten Daten.',
    'Antworte AUSSCHLIESSLICH als JSON: {"tasks":[{"prompt":"...","answer":"...","choices":["..","..",".."],"explanation":"...","visual":"emoji_or_dots"}, ...]}',
  ].join('\n');

  const userPrompt = [
    `Subject: ${subject}`,
    `Klasse: ${grade}`,
    `Anzahl: ${safeCount}`,
    `Kindname: ${childName || 'Kind'}`,
    unitText,
    'Regeln je Subject:',
    '- Mathematik: Zahlen passend zur Klasse, plus/minus/zaehlen/halbieren/verdoppeln.',
    '- Deutsch: Reime, Anfangslaut, Endlaut, Artikel, Tunwort, Namenswort, Silben.',
    'Erklaerung in 1-2 kurzen Saetzen, kindgerecht.',
    'Visual-Feld: einer von {dots, line, sequence, ten_ones, syllables, auto, emoji}.',
    'Antworte NUR mit dem JSON-Objekt, keine Marktdown-Codeblocks.',
  ].join('\n');

  const payload = {
    model,
    response_format: { type: 'json_object' },
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
    temperature: 0.7,
    max_tokens: 1500,
  };

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 25000);
  let response;
  try {
    response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${openAiApiKey}`,
      },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }

  if (!response.ok) {
    console.warn(`[lumo-ai-proxy] OpenAI batch returned ${response.status}`);
    throw new Error(`openai_${response.status}`);
  }

  const data = await response.json();
  const raw = data?.choices?.[0]?.message?.content?.trim();
  if (!raw) throw new Error('empty_batch_reply');

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (_) {
    throw new Error('batch_json_parse_failed');
  }

  const list = Array.isArray(parsed?.tasks) ? parsed.tasks : [];
  const cleaned = [];
  for (const item of list) {
    if (!item || typeof item !== 'object') continue;
    const prompt = String(item.prompt || '').trim();
    const answer = String(item.answer || '').trim();
    const explanation = String(item.explanation || '').trim();
    const choicesRaw = Array.isArray(item.choices) ? item.choices : [];
    const choices = choicesRaw
      .map((c) => String(c || '').trim())
      .filter((c) => c.length > 0)
      .slice(0, 5);
    if (!prompt || !answer || choices.length < 2) continue;
    if (!choices.some((c) => c.toLowerCase() === answer.toLowerCase())) continue;
    // Safety: Prompt + Antwort gegen Filter pruefen
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
}

const server = createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    return json(res, 204, {});
  }

  if (req.method === 'GET' && req.url === '/health') {
    return json(res, 200, {
      ok: true,
      service: 'lumo-ai-proxy',
      openAiConfigured: Boolean(openAiApiKey),
    });
  }

  if (req.method === 'POST' && req.url === '/tasks') {
    console.log(`[lumo-ai-proxy] /tasks request received at ${new Date().toISOString()}`);
    if (!openAiApiKey) {
      return json(res, 503, { error: 'openai_key_missing', tasks: [] });
    }
    try {
      const body = await readJson(req);
      const subject = String(body.subject || '').trim();
      const grade = Number(body.grade) || 1;
      const count = Number(body.count) || 10;
      const units = Array.isArray(body.units) ? body.units : [];
      const childName = String(body.childName || '').slice(0, 60);
      if (!subject) return json(res, 400, { error: 'subject_missing', tasks: [] });
      const tasks = await generateTaskBatch({ subject, grade, units, count, childName });
      console.log(`[lumo-ai-proxy] /tasks ok: subject=${subject} grade=${grade} returned=${tasks.length}`);
      return json(res, 200, {
        tasks,
        count: tasks.length,
        source: 'openai_batch',
      });
    } catch (error) {
      console.warn(`[lumo-ai-proxy] /tasks failed: ${String(error?.message || error).slice(0, 80)}`);
      return json(res, 500, {
        error: 'batch_generation_failed',
        tasks: [],
      });
    }
  }

  if (req.method !== 'POST' || req.url !== '/chat') {
    return json(res, 404, { error: 'not_found' });
  }

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
      // Heinz-Auftrag: bei fehlendem Key explizit 503 statt stiller Fallback,
      // damit der Flutter-Client klar erkennt: Server da, aber nicht voll
      // einsatzbereit. Antwort enthaelt trotzdem freundlichen Text fuer
      // den Fall dass die Mobile App den Body trotz 503 anzeigt.
      const local = fallbackReply(message);
      return json(res, 503, {
        ...local,
        source: 'local_fallback_no_key',
        error: 'openai_key_missing',
      });
    }

    const result = await callOpenAi({
      message,
      history: body.history,
      childProfile: body.childProfile,
    });
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
});

// Auf Render und in Cloud-Containern MUSS der Server explizit auf 0.0.0.0
// lauschen, sonst nimmt der Loadbalancer keine Verbindungen an. Ohne diesen
// Bind-Host kann der externe Health-Check 404/Timeout liefern obwohl der
// Service oben ist.
server.listen(port, '0.0.0.0', () => {
  console.log(`Lumo AI proxy listening on 0.0.0.0:${port}`);
});

// Graceful shutdown fuer Render. Ohne diesen Handler wird der Service hart
// abgebrochen und der naechste Request bekommt 502/504, bis Render den
// Container neu startet. Mit SIGTERM-Handler fahren wir sauber runter.
function shutdown(signal) {
  console.log(`[lumo-ai-proxy] ${signal} received, closing server`);
  server.close((err) => {
    if (err) {
      console.error('[lumo-ai-proxy] server close error', err);
      process.exit(1);
    }
    process.exit(0);
  });
  // Hard-Stop nach 10s falls aktive Requests haengen
  setTimeout(() => process.exit(0), 10000).unref();
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
