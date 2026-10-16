# NVIDIA Nemotron 3 Ultra – Lumo Nachhilfe-Pilot (15.10.2026)

## Stand

Im vorhandenen Lumo-Proxy ist der **optionale**, standardmäßig deaktivierte
NVIDIA-Chat-Pilot technisch verdrahtet. Weder OpenAI \`/chat\` und \`/tasks\` noch
die Offline-Aufgaben, Sulafat-Sprachausgabe oder Godot wurden umgeschaltet.

- API: \`POST https://integrate.api.nvidia.com/v1/chat/completions\`
- Model-ID: \`nvidia/nemotron-3-ultra-550b-a55b\`
- \`reasoning_effort: "none"\`, \`stream:false\`, \`max_tokens:320\`
- Begrenzter Eingang: Frage, Lernkontext, Klasse 1–4; **kein Name**, keine IDs,
  keine Profile, keine Gesprächshistorie, keine Geräteberechtigung.
- Bestehender Lumo-Kinderschutz vor/nach der Anfrage; Verdacht auf E-Mail,
  Telefonnummer und andere persönliche Angaben führt zu Ablehnung.
- Keine automatischen erneuten Provider-Anfragen, auch nicht bei Rate-Limits.
- Fehlende Freigabe oder Provider-Ausfall: **kein Modellwechsel**, lokaler
  Fallback der App bleibt erhalten.
- Nur die Konfiguration wird im Healthcheck beschrieben; eine tatsächliche
  erfolgreiche NVIDIA-Antwort ist damit ausdrücklich nicht nachgewiesen.

## Serverseitige Freigaben (alle erforderlich)

1. \`NVIDIA_API_KEY\`: ausschließlich im Secret-Store des Server-Deployments.
   NIEMALS in Git, Flutter-Buildflags, APKs, Testfixtures oder Debug-Logs.
2. \`LUMO_NVIDIA_PILOT_ENABLED=1\`: getrennte Server-Freigabe. Standard 0.
3. Ein realer serverseitiger Callback
   \`createLumoServer({authorizeNvidiaPilot})\`, der kurzlebige Bearer-Tokens
   **gegen einen verifizierten Eltern-Identitätsdienst** prüft und nach
   fortbestehender separater NVIDIA-Einwilligung liefert:
   \`{ parentVerified:true, principalId:"opaque", nvidiaConsent:true }\`.
   Es wird absichtlich **kein Dummy-Authenticator** installiert.
4. In Flutter muss ein Elternlogin ein kurzlebiges Token bereitstellen. Der
   \`LumoNvidiaPilotClient.ask\` nimmt dieses nur als Funktionsargument an und
   speichert es nicht. Der bestehende Chat verwendet weiter den bisherigen
   Proxy. Es gibt **noch keinen verbundenen produktiven Elternlogin und keinen
   aktivierten NVIDIA-Kindermodus**.

\`GET /nvidia/pilot/status\` meldet Konfiguration ohne externen Netzwerkverkehr.
\`POST /nvidia/pilot/chat\` verweigert standardmäßig mit HTTP 503. Ohne
Parent-Token gilt HTTP 401, ohne zusätzliche NVIDIA-Freigabe HTTP 403,
ungültiger Lerninhalt HTTP 400 und Limitüberschreitung HTTP 429.

Die Testlimits \`LUMO_NVIDIA_PILOT_PER_PARENT_DAY\` (Standard 15) und
\`LUMO_NVIDIA_PILOT_TOTAL_DAY\` (Standard 100) liegen derzeit **nur im
Serverprozess**. Für einen echten öffentlichen Betrieb müssen die Limits
persistent, über alle Serverinstanzen geteilt und atomar sein. Eine Prüfung
der Einwilligungsprozesse, Aufbewahrung, Datenschutzverträge und Kostenlimits
ist vor Freischaltung erforderlich.

## Nachhilfe und Dialog

Erlaubte Kontexte: \`companion\`, \`learning_tutor\`, \`math_coach\`,
\`reading_buddy\`, \`writing_helper\`, \`science_explorer\`.

Lernhilfen geben höchstens drei kurze Sätze und keine fertige Lösung für
laufende Übungsaufgaben. Die korrekte Bewertung, 20 Fragen der Quizshow,
gespeicherte App-Sterne, Lernfortschritte und Aufgabengeneratoren bleiben
ausschließlich in der bestehenden lokalen App-Logik.

## Prüfung ohne Kosten

\`\`\`bash
cd server/lumo-ai-proxy
npm test
\`\`\`

CI: \`.github/workflows/lumo-nvidia-pilot-node-tests.yml\`. Zusätzlich
laufen Flutter-Tests für \`test/lumo_nvidia_pilot_client_test.dart\` mit
simuliertem Loopback-Server. Tests nutzen **nie NVIDIA-Zugangsdaten**.

Ein echter NVIDIA-Produktionsaufruf, Deployment, Benutzer-Login oder APK
wurde mit diesem Pilot-Code weder durchgeführt noch behauptet.
