# Lumo AI Proxy

Der Server ist über `LumoAiProxyClient` mit der Flutter-App verbunden. Der OpenAI-Schlüssel liegt ausschließlich in Render, nie in der APK. Die KI wird im Elternbereich freigegeben; lokale Aufgaben und Hinweise funktionieren ohne KI.

## Start und Modell

```bash
cd server/lumo-ai-proxy
export OPENAI_API_KEY="<Schlüssel nur lokal setzen>"
export OPENAI_MODEL="gpt-6-luna"
npm start
```

Standard ist GPT-6 Luna für kurze Lernhinweise und Aufgabenchargen. Frühere Konfigurationen `gpt-4.1-mini` und `gpt-4o-mini` werden beim Serverstart auf Luna migriert; andere ausdrücklich konfigurierte Modelle bleiben wählbar. `OPENAI_TASK_MODEL` erlaubt ein separates Aufgabenmodell. Für GPT-5/6 werden `max_completion_tokens` und passende Reasoning-Parameter verwendet.

## Schnittstellen

- `GET /health`: Serverversion, Konfiguration, Chat-/Aufgabenmodell und letzter tatsächlich geprüfter Upstream-Zustand. Ein konfigurierter Schlüssel allein belegt noch keine funktionierende KI.
- `POST /chat`: Lernhilfe mit kurzem Verlauf und Klassenstufe. Der Server übernimmt keinen Namen aus dem Kinderprofil.
- `POST /tasks`: Mathematik/Deutsch, Klasse 1–4, 3–12 angeforderte Aufgaben. Mathematikaufgaben benötigen unabhängig nachrechenbare Rechenschritte. Ungültige Antworten, doppelte Optionen, unsichere Inhalte und Wiederholungen werden verworfen. Deshalb kann die tatsächliche Charge kleiner ausfallen.

Die App verwendet bei gewählten einzelnen Einheiten den lokalen Generator, damit die KI keine Aufgabe unter einer falschen Einheit anbietet. Ein Vorrat ist pro Profil, Klasse und Fach gespeichert. Hinweise sind zum Üben verfügbar; im Testmodus bleiben Hilfen aus.

## Diagnose

Ein HTTP-200-Healthcheck bedeutet: der Proxy läuft. Einen echten `/chat`- oder `/tasks`-Aufruf ebenfalls prüfen. Fehlergründe sind `openai_authentication_failed`, `openai_quota_exceeded`, `openai_rate_limited`, `no_valid_tasks` oder ein Upstream-Fehler. Interne Provider-Antworten und Geheimnisse werden nicht an Kinder weitergegeben.

## Prüfung

```bash
node --test test/*.test.js
```

Die Tests prüfen Modellmigration und Parameter, fehlende Schlüssel, tatsächliche Erreichbarkeit, Fehlerdiagnose, Eingabegrenzen, Kinderschutz, Rechnungen und Aufgabenfilter. Sie ersetzen keinen echten Render-Aufruf und keinen pädagogischen Unterrichtstest.
