# Datenschutz und Datenflüsse – Lumo Lernen (Entwicklungsstand)
 
**Geprüfter Quellstand:** `claude/continue-previous-chat-KtY7p`, 9. Oktober 2026.  
**Wichtig:** Diese Bestandsaufnahme ersetzt keine rechtliche Datenschutzerklärung,
DSGVO-Prüfung, Prüfung von Auftragsverarbeitern oder Freigabe für den Play Store.

## Standardbetrieb ohne aktivierte Online-KI

- Lernstände, Einstellungen, Belohnungen und Kinderprofile werden in der App
  lokal gespeichert (unter anderem `shared_preferences`).
- Der KI-Proxy ist in den Standardeinstellungen **deaktiviert**
  (`AppSettings.aiProxyEnabled = false`).
- Lokale Lernaufgaben und die eingebundenen Godot-Spiele sind grundsätzlich
  ohne aktive KI-Verbindung vorgesehen. Daraus folgt **nicht**, dass alle
  App-Funktionen in jeder Situation garantiert ohne Internet auskommen.
- Kamerazugriff, Mikrofon/Spracherkennung und KI müssen getrennt geprüft und
  jeweils kontrolliert freigegeben werden. Eine System-Spracherkennung kann,
  abhängig von Gerät/Dienst, eine Netzwerkverarbeitung verwenden.

## Optionale KI-Funktion – tatsächlich implementierter Datenfluss

Wenn der KI-Proxy in den Einstellungen aktiviert und für den jeweiligen
Bereich freigegeben wird, sendet `LumoAiProxyClient.ask()` einen HTTP-POST
an `<konfigurierter Proxy>/chat`. Aus dem Code geht hervor, dass das
JSON unter anderem Folgendes enthält:

- Frage/Nachricht und bis zu acht letzte Chat-Nachrichten;
- Schulstufe (`childProfile.grade`), den genutzten Kontext und gegebenenfalls
  begrenzte Informationen zu Schulfach, Thema oder Einheit.

Ein Feld für den **Kindernamen** wird im gezeigten Chat-Payload nicht explizit
gesendet. Freitexte können trotzdem Namen oder sensible Informationen enthalten.
Der Standard-Endpunkt ist `https://lumo-ai-proxy.onrender.com`.
Welche Daten dort protokolliert, weiterverarbeitet oder an einen
KI-Anbieter übermittelt werden und wann sie gelöscht werden, muss
vor einer Veröffentlichung am Server und mit den Dienstleistern geprüft
und transparent erklärt werden.

**Sicherheitsbefund:** Der Einstellungs- und HTTP-Client-Code lässt
gegenwärtig auch benutzerdefinierte `http://`-URLs zu. Vor einem
öffentlichen Kinder-App-Release müssen unverschlüsselte externe
Proxyverbindungen verhindert und die Auswirkungen auf lokale Tests
getrennt abgesichert werden.

## Noch nicht abschließend nachgewiesen

- Alle möglichen ausgehenden Verbindungen von nativen Plugins, ML Kit,
  Spracherkennung und KI-Diagnose;
- tatsächliche Lösch- und Aufbewahrungsfristen des Proxys, Unterauftragsverarbeiter,
  Hostingstandort, AV-Verträge, Betroffenenrechte und Elternzustimmung;
- korrekte Datentrennung bei mehreren Kinderprofilen auf einem Gerät;
- Einhaltung der jeweils einschlägigen DSGVO-, Jugendschutz- und
  Google-Play-Vorgaben (nicht pauschal behaupten).

Für eine produktive Datenschutzerklärung braucht es nach dieser technischen
Bestandsaufnahme eine eigene datenschutzrechtliche Prüfung und einen
klar benannten Verantwortlichen samt Kontaktmöglichkeit.
