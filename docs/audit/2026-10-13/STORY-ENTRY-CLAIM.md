# Begrenzter Anschluss: Geschichten-Einstiege

Basis: geprüfter Head `fe3778847c88c35a40e99ae5012c1f160680b908`, 1.476 PASS / 117 SKIP / 24 Infos, Actions 38394508328. Eigener Folgebranch `chatgpt/lumo-story-entry-2026-10-13`.

Fehlende direkte Bibliotheksrouten an Home, Deutsch, aktivem Lesen und Akademie. Vorhandene Bibliothek/Setup/Reader verwenden; kein zweites Storysystem. Freie Einstiege behalten lokale Klassenwahl. Akademie übergibt ihre ausgewählte Klasse als Filter und gesperrte Setupklasse, auch beim Stöbern über der Profilklasse. Profilklasse und bestehende Hefte/Metadaten nicht ändern; Öffnen bucht keinen Lernfortschritt.

Geplanter Scope: `home_content.dart`, `lumo_deutsch_screen.dart`, `reading_content.dart`, `lumo_akademie_screen.dart` plus tatsächliche Navigations-/Resizeprüfungen. Beim Übergang aus aktivem Lesen Mikrofonaufnahme abbrechen (vorhandene Generation sperrt verspätete Callbacks), Vorlesen stoppen, Mehrfachtippen sperren und Rückkehr erhalten. Vorhandene Lese-, Deutsch- und Discoverymodule bleiben erreichbar.

Antwortpersistenz/Reward-Deduplizierung und Storyillustrationen sind getrennte Schritte; kein Datenformat, Wallet, Stimme, Godotpin oder Buildsystem in diesem Anschlussblock ändern. Zuerst vier echte Navigationsregressionen gegen unveränderte Produktion, danach kleine Anschlüsse und vollständige Analyse/Suite. APK erst nach weiteren Integrationen und Abnahme; Freigabe des Nutzers liegt vor. Kein Main-Merge/Release.
