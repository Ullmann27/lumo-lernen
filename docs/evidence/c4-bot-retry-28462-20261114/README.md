# Vier gewinnt: bestätigte Fortsetzung nach Speicherfehlern

Basis: Host28462a7547048b75fa114e6f5832248e54c94faa. Implementiert im gemeinsamen Entwicklungscommit e2db0d60af51266caa9b54ffd08eb0947ae99ac6.

Der vorhandene Flutter-Fallback speicherte Züge vor ihrer Anzeige. Nach einem fehlgeschlagenen Botzug pausierte er aber ohne eine neue Botaktion einzureihen. Fortsetzen konnte das Spiel deshalb auf Lumos Zug stehen lassen. Wenn der Endzug bereits gespeichert war, seine Belohnung aber scheiterte, blieb die Ergebnisanzeige ebenfalls offen.

Der geänderte _place-Fehlerpfad prüft dieselbe aktive Profillease und Rundengeneration. Ein noch ausstehender Botzug wird auf der bereits pausierten Uhr neu eingereiht. Für ein schon beendetes Brett wird ausschließlich die bestehende idempotente settleReward-Methode erneut aufgerufen; kein weiterer Stein wird gesetzt. Ein bestätigtes Ergebnis wird über einen erneut bewachten Callback der pausierbaren Uhr angezeigt. Dadurch hält auch eine Pause während des Wallet-Awaits die Ergebnisanzeige zurück.

Die unabhängige Prüfung hatte den letzten Lifecycle-Rand konkret gefunden. Der eingefrorene Nachfolger schließt ihn und enthält einen zusätzlichen Gegenfall mit gehaltener tatsächlicher Plattformantwort, inactive-Lifecyclepause und erneuter ausdrücklicher Fortsetzung. Die Peernote bleibt unverändert daneben erhalten.

Sechs neue Widgetfälle verwenden den echten Bildschirm, Controller, Speicheradapter und die Wallet. Nur die Plattform-I/O-Grenze wird kontrolliert: einmaliger Botfehler, wiederholter Botfehler, Neustart nach Fehler, lokaler Goldspieler ohne automatischen Bot, fehlgeschlagene Endbelohnung und Lifecyclepause während der Wiederholung. Diese Fälle sind vorbereitet, aber beim ersten CI-Versuch e2db wegen zweier separater Memory-Compilerfehler noch nicht gestartet. Es wird kein erfolgreicher Widgetlauf behauptet.

Die bestehenden Spielregeln, Botstrategie, Rundendaten und übrige Produktdatei bleiben erhalten. Der Test modelliert eine negative Plattformantwort vor Persistierung; native Cache- und physische Diskgarantien werden daraus nicht abgeleitet.
