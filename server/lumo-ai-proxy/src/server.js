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
      reply: `${safety.redirect} Moechtest du lieber Mathe, Deutsch, Lesen oder Natur ueben?`,
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

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${openAiApiKey}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorText = await response.text().catch(() => '');
    throw new Error(`openai_${response.status}_${errorText.slice(0, 120)}`);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content?.trim();
  if (!reply) throw new Error('empty_model_reply');

  const outputSafety = inspectChildSafety(reply);
  if (!outputSafety.allowed) {
    return {
      reply: `${outputSafety.redirect} Soll ich dir eine leichte Schulfrage stellen?`,
      blocked: true,
      ruleId: outputSafety.ruleId,
    };
  }

  return { reply, blocked: false, ruleId: null };
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

  if (req.method !== 'POST' || req.url !== '/chat') {
    return json(res, 404, { error: 'not_found' });
  }

  try {
    const body = await readJson(req);
    const message = String(body.message || '').trim();
    if (!message) return json(res, 400, { error: 'empty_message' });
    if (message.length > 1200) return json(res, 400, { error: 'message_too_long' });

    const inputSafety = inspectChildSafety(message);
    if (!inputSafety.allowed) {
      return json(res, 200, {
        reply: `${inputSafety.redirect} Moechtest du eine Deutsch-, Mathe- oder Naturfrage ueben?`,
        blocked: true,
        ruleId: inputSafety.ruleId,
        source: 'local_policy',
      });
    }

    if (!openAiApiKey) {
      const local = fallbackReply(message);
      return json(res, 200, { ...local, source: 'local_fallback_no_key' });
    }

    const result = await callOpenAi({
      message,
      history: body.history,
      childProfile: body.childProfile,
    });
    return json(res, 200, { ...result, source: 'openai_proxy' });
  } catch (error) {
    return json(res, 500, {
      error: 'proxy_error',
      reply: 'Ich kann gerade nicht mit dem KI-Server sprechen. Wir koennen trotzdem Mathe, Deutsch oder Lesen ueben.',
      detail: process.env.NODE_ENV === 'development' ? String(error?.message || error) : undefined,
    });
  }
});

server.listen(port, () => {
  console.log(`Lumo AI proxy listening on http://localhost:${port}`);
});
