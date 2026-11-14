# Geprüfte Übernahme in den Studiozweig

Host `28462a75` wurde nach erfolgreichen aktuellen Featureprüfungen in den Entwicklungs-Studiozweig übernommen. Die Bewegung war ein Fast-forward von `b721` mit erwartetem alten SHA und `force:false`; der anschließend gelesene Ref bestätigte den neuen Kopf. PR #506 ist dadurch in diesen Entwicklungszweig integriert. Die produktiven Main-Zweige wurden nicht verändert.

## Tatsächlicher Nachweis

[Featurelauf 43624674585](https://github.com/Ullmann27/lumo-lernen/actions/runs/43624674585) ist vollständig erfolgreich: alle drei Jobs und die vollständige Flutter-Suite mit **2.632 bestandenen, keinen fehlgeschlagenen und keinen übersprungenen Tests**.

Die zehn neuen ASR- und vierzehn neuen Memoryfälle wurden einzeln im originalen maschinellen Flutterprotokoll identifiziert. Root hat ihre tatsächlichen Start- und Endzeilen nochmals verglichen. Alle 24 sind erfolgreich und weder verborgen noch übersprungen. Die Gesamtdifferenz allein wurde nicht als Nachweis verwendet. Das originale JSONL hat 1.767.777 Bytes und SHA256 `273c38c24fa7694f15f21ed9d2aba05a6f39e6be6591620f1a34b3c1977be939`.

Die benötigten vier Originalmember wurden gezielt aus dem aktuellen CI-Archiv gelesen. Das gesamte 343-MB-Archiv wurde nicht heruntergeladen; sein Gesamt-SHA ist damit kein lokal nachgeprüfter Hash. Die einzelnen Member sind vollständig durch CRC und SHA gebunden. Eine lokale Flutter- oder Dartausführung fand nicht statt.

## Neuer Androidkandidat

[Studio 43626348519](https://github.com/Ullmann27/lumo-lernen/actions/runs/43626348519) ist auf exakt `28462a75` mit Native `29080` gestartet. Der ersetzte Lauf `43619285124 / b721` wurde tatsächlich als `cancelled` beobachtet. Der neue Lauf muss seine eigenen Native-, APK-, API35-/API37-, Creative-, Update- und Publisherprüfungen bestehen. Diese Übernahme ist noch keine APK- oder Gerätefreigabe.

Die vorherige Evidenzintegration `69bca208` fügte 184 manifestierte Original- und Reviewdateien hinzu und bewahrte alle 8.201 früheren Blätter. Ihr vollständiger Commit- und Baumvergleich ist hier ebenfalls dokumentiert. Frühere Berichte bleiben datierte Momentaufnahmen.
