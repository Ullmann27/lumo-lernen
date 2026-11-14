# Zwei bestehende Voice-/Scroll-Testverträge an den expliziten Orientierungsparameter binden

**Basis:** Host `c081cfaaa3e7ddedbca21a46f63dbe4a8cc0d111`, fehlgeschlagener Studio-Run `43545886722`, Job `132296974547`.

Der Originaljob führte 445 Build-/Erhaltungsverträge aus und scheiterte an genau zwei Mock-Aufruferwartungen in `scripts/tests/test_android_voice_scroll.py`. Beide erwarteten weiterhin den Aufruf ohne `orientation`, obwohl der freigegebene `leave`-Helper seine unveränderte Standardorientierung `landscape` nun ausdrücklich an `native_text` weitergibt. Die Beschriftungen `Zum Lernen` und `Zur Spielewelt`, der einzelne Touch und `exact=True` im Kart-Fall bleiben korrekt.

## Einziger Quelldiff

Nur die zwei vorhandenen `assert_called_once_with`-Erwartungen erhalten `orientation="landscape"`. Alle übrigen Syntaxknoten bleiben identisch; kein Test, keine Assertion, kein Limit und keine Produkt- oder Workflowdatei wird entfernt oder gelockert. Die beiden benötigten Originalhelper sind Gitblob-geprüft an c081 gebunden und in `baseline`/`patched` bytegleich.

## Tatsächlicher Gegenlauf

```sh
python3 -m unittest discover -s scripts/tests -p 'test_android_voice_scroll.py' -v
```

Im Ordner `baseline`: sieben Tests, genau zwei Fehler; beide entsprechen dem Original-CI-Fehler. Im Ordner `patched`: **7/7 PASS**, 0,063 s laut Unittest-Ausgabe. Logs und Prozess-Exitcodes sind unverändert gesichert. Das sind lokale Vertragsprüfungen mit den realen geparsten Helperfunktionen und gemockten Eingaben, kein Emulatorlauf.

Der ursprüngliche c081-Lauf bleibt **FAILURE**. Seine nachgelagerten Android-, Creative-, Update- und Publisher-Jobs wurden übersprungen. Die beiden vollständigen aktuellen Python-Testgruppen führt Root nach Integration gesondert aus; dieser enge Sieben-Fall-Lauf wird nicht als deren Erfolg ausgegeben.
