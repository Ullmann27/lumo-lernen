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

- `GET /health`: Serverversion, Konfiguration, Chat-/Aufgabenmodell und letzter tatsächlich geprüfter Upstream-Zustand. `ok` zeigt die Erreichbarkeit des Proxys; `openAiConfigured` meldet einen hinterlegten Schlüssel. `openAiAvailable` wird erst nach einem erfolgreichen KI-Aufruf wahr und bei einem späteren Upstream-Fehler wieder falsch. Der Zustand ist die letzte Beobachtung, kein zusätzlicher Live-Aufruf.
- `POST /chat`: Lernhilfe mit kurzem Verlauf und Klassenstufe. Der Server übernimmt keinen Namen aus dem Kinderprofil.
- `POST /tasks`: Mathematik/Deutsch, Klasse 1–4, 3–12 angeforderte Aufgaben. Mathematikaufgaben benötigen unabhängig nachrechenbare, zusammenhängende Rechenschritte. Der Proxy erstellt daraus den angezeigten Aufgabentext und die Erklärung; freie KI-Sachgeschichten werden nicht übernommen, weil korrekte Metadaten deren Inhalt nicht beweisen. Ungültige Antworten, doppelte Optionen, unsichere Inhalte und Wiederholungen werden verworfen. Deshalb kann die tatsächliche Charge kleiner ausfallen.

Gleichzeitige Aufgabenanfragen mit derselben Klasse, demselben Fach sowie identischen normalisierten Themen und Anzahlen teilen eine laufende Erzeugung und deren Ergebnis. Andere Anforderungen bleiben unabhängig; der Verlauf je Klasse/Fach führt ihre Ergebnisse zusammen. Bodies über 16 KiB erhalten HTTP 413; danach wird die Verbindung zeitnah geschlossen, auch wenn ein Client den Upload nicht beendet.

`/chat` akzeptiert die festen Kontexte `companion`, `learning_tutor`, `reading_buddy`, `writing_helper`, `math_coach`, `science_explorer` und `parent_advisor`. Die Regeln stehen ausschließlich am Server; eine frei mitgesendete `persona` wird ignoriert. `extras` erlaubt kurze Aufgabenfelder (`subject`, `unit`, `topic`, `topic_id`, `mode`, `visual`), `attempt` zwischen 0 und 10 und eine bekannte App-`section`. Der Lernfuchs erklärt Bereiche und bietet freiwillige nächste Schritte an, führt aber keine Modellaktionen oder Navigation aus. Datenschutz und Kinderschutz gelten für alle Kontexte.

Die App verwendet bei gewählten einzelnen Einheiten den lokalen Generator, damit die KI keine Aufgabe unter einer falschen Einheit anbietet. Ein Vorrat ist pro Profil, Klasse und Fach gespeichert. Hinweise sind zum Üben verfügbar; im Testmodus bleiben Hilfen aus.

## Diagnose

Ein HTTP-200-Healthcheck bedeutet: der Proxy läuft. Einen echten `/chat`- oder `/tasks`-Aufruf ebenfalls prüfen. Fehlergründe sind `openai_authentication_failed`, `openai_quota_exceeded`, `openai_rate_limited`, `openai_model_unavailable`, `openai_configuration_error`, `no_valid_tasks` oder ein Upstream-Fehler. Ein Rate-Limit wird nicht durch automatische Wiederholungen verstärkt. Der Eltern-Test bestätigt nur eine erfolgreiche Antwort mit `source: openai_proxy`, keine lokale Ersatzantwort. Interne Provider-Antworten und Geheimnisse werden nicht an Kinder weitergegeben.

## Prüfung

```bash
node --test test/*.test.js
```

Die Tests prüfen Modellmigration und Parameter, fehlende Schlüssel, tatsächliche Erreichbarkeit, Fehlerdiagnose, Eingabegrenzen einschließlich unvollständiger TCP-Uploads, Kinderschutz einschließlich deutscher Komposita, Rechnungen, Aufgabenfilter und parallele Aufgabenanfragen. Sie ersetzen keinen echten Render-Aufruf und keinen pädagogischen Unterrichtstest.
