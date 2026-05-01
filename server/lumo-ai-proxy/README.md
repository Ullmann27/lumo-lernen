# Lumo AI Proxy – abgeschirmter Testserver

Dieser Ordner ist ein isolierter Test-Prototyp fuer die spaetere Lumo-KI-Anbindung.

## Warum ein Server?

Der OpenAI API-Key darf niemals in die Flutter-App oder APK. APKs koennen ausgelesen werden. Deshalb laeuft die Architektur so:

```text
Flutter-App -> Lumo AI Proxy -> OpenAI API
```

Der API-Key liegt nur am Server als Environment-Variable.

## Start lokal

```bash
cd server/lumo-ai-proxy
export OPENAI_API_KEY="sk-..."
export OPENAI_MODEL="gpt-4.1-mini"
node src/server.js
```

Healthcheck:

```bash
curl http://localhost:8787/health
```

Chat-Test:

```bash
curl -X POST http://localhost:8787/chat \
  -H "content-type: application/json" \
  -d '{"message":"Kannst du mir 7 plus 5 erklaeren?","childProfile":{"name":"Alina","grade":1}}'
```

## Kinderschutz

Der Proxy blockt vor dem Modell lokal verbotene Themen wie:

- sexuelle Inhalte
- Gewalt, Waffen, Krieg, Horror
- Selbstverletzung / Suizid mit sicherem Hilfe-Hinweis
- Politik / Extremismus
- Drogen, Alkohol, Nikotin
- private Daten wie Adresse, Passwort, Telefonnummer

Bei blockierten Themen gibt Lumo keine Details, sondern lenkt freundlich auf Schule, Freunde, Natur oder Lernaufgaben um.

## Erlaubter Rahmen

Lumo darf sprechen ueber:

- Mathehilfe
- Deutschhilfe
- Lesen und Schreiben
- Englischhilfe
- Sachunterricht
- Geografie fuer Kinder
- Natur, Tiere, Pflanzen, Wetter
- kindgerechte Filme, Cartoons, Maerchen
- Freundschaft und Alltag

## Noch nicht mit Flutter verbunden

Dieser Server ist absichtlich noch nicht automatisch in der App aktiv. Erst nach Elternfreigabe und sauberer Server-URL soll Flutter einen Client bekommen. Dadurch bleibt die aktuelle App stabil und offline-first.

## Naechster Integrationsschritt

1. Elternbereich: KI-Server aktivieren/deaktivieren.
2. Elternbereich: Proxy-URL setzen.
3. Flutter `LumoAiProxyClient` bauen.
4. Agent-Orchestrator nur bei Freigabe mit Proxy verbinden.
5. Chatverlauf lokal begrenzen und keine privaten Daten senden.
