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

## Sulafat-Stimme (Build nach 1925)

Die originale Stimme aus „Stimme testen“ ist **Gemini TTS / Sulafat** und bleibt
als Offline-Aufnahme erhalten. Für individuelle Unterrichtstexte bietet der
gleiche Proxy `POST /speech`: JSON `{"text":"...","style":"explain"}`; Antwort
`{"voice":"Sulafat","format":"audio/wav","audioBase64":"..."}`.
Weder der Android-TTS-Provider noch eine andere Sprecherstimme wird verwendet.

**Render-Konfiguration, nur nach Zustimmung zum richtigen Workspace:**

- `GEMINI_API_KEY`: Gemini API-Key ausschließlich als serverseitiges Secret.
- `LUMO_TTS_ENABLED=1`: notwendige Provider-Freigabe, aber allein keine Aktivierung.
  Ohne überprüfbare Elternautorisierung bleibt die Synthese weiterhin gesperrt.
- `GEMINI_TTS_MODEL=gemini-2.5-pro-preview-tts`: Referenzmodell der unveränderten Original-Stimmprobe. Ein Modellwechsel benötigt einen erneuten akustischen Vergleich und darf nicht stillschweigend erfolgen.
- `LUMO_TTS_PER_PARENT_DAY` (Standard 200), `LUMO_TTS_TOTAL_DAY` (Standard 1600)
  begrenzen Anfragen je verifiziertem Elternkonto und insgesamt pro Serverprozess.
  Der alte Variablenname `LUMO_TTS_PER_IP_DAY` wird nur als Konfigurationsfallback
  für das Elternlimit gelesen; untrusted `X-Forwarded-For` autorisiert niemanden.
  Die Zähler sind noch nicht persistent oder zwischen mehreren Instanzen geteilt.

### Verpflichtende Elternautorisierung vor Synthese

`createLumoServer` besitzt die Integrationsschnittstelle
`authorizeSpeech(bearerToken)`. Ein verifizierter bestehender Identitätsdienst muss
eine undurchsichtige `principalId`, `parentVerified: true` und die eigenständige
Freigabe `speechConsent: true` liefern. Token-Gültigkeit, Ablauf und Widerruf sind
Aufgabe dieses tatsächlichen Verifizierers. Ein boolesches `true`, ein Premium-Abo
oder ein bloß mitgesendetes `x-lumo-parent-token` genügen ausdrücklich nicht.

Ohne Verifizierer lautet die Konfigurationsdiagnose `configured: false`, selbst
bei vorhandenem Gemini-Schlüssel und eingeschaltetem Provider-Flag. Synthese
erhält dann HTTP 503 `sulafat_authorization_not_configured`. Fehlende/ungültige
Bearer-Autorisierung ergibt HTTP 401, fehlende Sprachfreigabe HTTP 403.
Unberechtigte Anfragen werden vor Lesen des Unterrichtstexts und vor einem
Provider-Aufruf beendet. Die Identitätsprüfung hat ein Zeitlimit von fünf Sekunden;
Fehler und Tokens erscheinen weder im Diagnosebody noch im Sprachlog.

Der Defaultstart `node src/server.js` installiert absichtlich keinen fingierten
Verifizierer. Ein reales Eltern-Identitätssystem, die sichere Ausstellung
kurzlebiger Tokens und deren Flutter-Anbindung sind weiterhin offene
Integrationsbedingungen. Kein gemeinsames Servergeheimnis in die APK einbauen.
Die Testadapter in `test/sulafatTts.test.js` sind ausschließlich lokale Fakes und
dürfen nicht als produktive Authentifizierung verwendet werden.

Dies härtet den Sprachpfad, ist aber keine vollständige Sicherheitsfreigabe
des gesamten Proxys. Insbesondere die bestehenden Chat-/Aufgabenendpunkte,
dauerhafte Kostenlimits, Einwilligungsnachweis und Betriebslogs brauchen eine
gesonderte öffentliche Releaseprüfung. Der aktuelle produktive Render-Dienst
wurde durch diese Quelländerung nicht neu bereitgestellt.

`GET /speech/status` prüft ausschließlich die Konfiguration und verursacht keinen
Provider-Aufruf. `configured: true` bedeutet nicht, dass eine Hörprobe bestanden
wurde; `providerVerified` bleibt bewusst false. Die App diagnostiziert alte Server
ohne diesen Endpunkt getrennt von der Chat-KI. Ausgaben verwenden das feste Profil
`lumo-sulafat-reference-v1`; komprimierte oder falsch deklarierte Audiodaten werden
abgelehnt, statt als PCM abgespielt. Client-Abbruch beendet auch den Provider-Request.

**Eltern-Freigabe:** Im Elternbereich den neuen Schalter „Online-Lumo-Stimme
(Sulafat)“ aktivieren. Nur dann wird der jeweils vorzulesende Text über den
Lumo-Server an Gemini geschickt. Ohne diese Freigabe bleiben neue dynamische
Sätze stumm, statt mit Android zu sprechen. Die App sollte im Fehlerfall auf
die fehlende Online-Stimme hinweisen. Das Cloud-Angebot braucht Internet,
kann Kosten verursachen und darf nicht ohne Datenschutz-/Einwilligungsprüfung
für Kinder freigegeben werden. Keine Kindertexte im Provider-Diagnoselog.

Für die 3D-Lernspiele ist der Austausch der **52 Legacy-WAVs** aus
`Ullmann27/lumo-godot` PR #48 vorbereitet, aber ohne tatsächliche Synthese
und Hörprüfung noch nicht abgeschlossen. Der aktuelle Runtime-Guard blockiert
die alten Stimmen. Eine technische Test-APK mit dieser Sperre ist kein fertiges
app-weites Sprachrelease: Dafür muss `sulafat_manifest.json` vollständig sein
und jede neue Datei, das Referenzmodell und das Profil verifizieren.
Niemals nur die Flutter-Stimmprobe als vollständige app-weite Hörprüfung ausgeben.
