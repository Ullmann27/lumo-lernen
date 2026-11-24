# Unveränderlicher Android-Replay für 2028

Dieser getrennte Prüfeinstieg verwendet ausschließlich die bereits gebaute x86-APK aus Quelllauf **43774460935**. APK-Quelle ist `fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242`, native Quelle `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`, Version **0.13.16 / 2028**. Die feste Config und der neue Entry prüfen ZIP-, APK-, PCK-, Paket-, Versions- und Signaturidentität. Es gibt keinen Build- oder Veröffentlichungsschritt in diesem Replayworkflow.

Der ursprüngliche Quelllauf bleibt **FAIL**: Quellvalidierung und beide Builds bestanden; die Androidtour brach beim noch einblendenden Berechtigungsdialog ab. Ein erfolgreicher neuer Replay würde diesen Originalbefund nicht umschreiben. Alle ursprünglichen Protokolle bleiben im bestehenden Archiv erhalten.

## Ablauf und Grenzen

1. Der Download prüft den tatsächlichen Checkout, den vollständigen Git-Diff zur APK-Quelle, die festen Quelljobs und das genaue x86-Artefakt. Zulässig sind ausschließlich Prüfer-/Workflow-/Dokumentationsänderungen sowie die einzeln benannten Config-/Publisher-/Statusdateien. Ein Produktdelta wird auch bei Sparsecheckout abgewiesen.
2. Der Bashwrapper führt die vollständige ursprüngliche Androidtour aus. Ein Fehler verhindert den Start der zusätzlichen Tour und damit deren Rücksetzen der Testinstallation.
3. Die zusätzliche Tour verlangt die komplette aktuelle Originalprüfung einschließlich nativer Frage „Warum zuerst zwei?“, beobachteter Bewegung, echter Audio-Callbacks und gemessener Figur-/Audio-/Effektfenster. Vor der Neuinstallation prüft sie auf demselben Emulator nochmals die installierten APK-Bytes und das tatsächlich vorhandene fiktive Profil.
4. Der vorhandene `ReferenceProbe` navigiert real durch die nativen Banane- und Musteraufgaben. Er bewahrt den ungewerteten Muster-Rückkehrbeleg vor einer gegebenenfalls ausdrücklich bedienten Core-Antwort. Die Wertung erfolgt ausschließlich im bestehenden Core-Weg.
5. `verify_2028_tours(original, extra, *, qa_commit, qa_workflow_run, original_result_sha256)` verbindet beide Originalresultate. Dieselbe Funktion wird vom getrennten Publisher verwendet. Die vorhandenen `current-build`- und historischen 2027-Guards bleiben unverändert.

Die neue QA-Commitidentität und der neue QA-Workflowlauf sind ausdrücklich verschieden von der APK-Quelle und dem ursprünglichen Buildlauf. Ergebnisse tragen `mode: immutable-replay`, `qa_commit`, `qa_workflow_run`, `apk_source`, `native_source` und `source_build_run` getrennt. Es werden keine Felder alter Resultate umgeschrieben.

## Dateien und Workflow-Schnittstelle

Der Laufzweig lautet `qa/lumo-nextgen-2028-android-20261116`. Der Implementierungszweig wird separat gesichert; Root legt den Laufzweig erst nach Integration des Berechtigungslesers und sämtlicher Publisherdateien an. Ein Push der festen Config `config/nextgen-2028-replay.json` startet dann den Replayworkflow. `replayAttempt` ist das einzige variable Configfeld.

```sh
python3 .github/probes/lumo_nextgen_2028_replay_reference_android_probe.py download \
  --candidate candidate/x86 --out evidence/download \
  --qa-commit "$GITHUB_SHA" --workflow-run-id "$GITHUB_RUN_ID"
bash .github/probes/run_lumo_nextgen_2028_replay_android.sh
python3 .github/probes/lumo_nextgen_2028_replay_reference_android_probe.py verify \
  --original evidence/android/original-android/learning-android-result.json \
  --reference evidence/android/reference-android/reference-android-result.json \
  --qa-commit "$GITHUB_SHA" --workflow-run-id "$GITHUB_RUN_ID" \
  --out evidence/replay-result.json
```

Das Artefakt heißt **`lumo-nextgen-2028-replay-evidence`**. `evidence/` wird als Artefaktwurzel hochgeladen:

- `android/original-android/learning-android-result.json` mit sämtlichen tatsächlichen XML-/Bild-/Video-/Rohprotokollen der Originaltour.
- `android/reference-android/reference-android-result.json` mit den tatsächlichen Banane-/Musterbelegen.
- `download/original-run.json`, `original-x86-artifact.json`, `original-validate-job.json`, `original-build-job.json` und `verified-download.json`.
- `source/qa-source-binding.json` mit beiden Commit-/Treeidentitäten und allen geänderten Pfaden.
- `checkers/` und `emulator/` für Prüferprotokolle und die tatsächliche Rendererumgebung.
- `replay-result.json` entsteht ausschließlich nach Bestehen beider vollständiger Ergebnisprüfungen.

## Lokale Prüfung

Die neuen Tests sind reine Prüferfixtures sowie echte Bash-/Git-Unterprozesse. Sie behaupten keinen Android-PASS. Sie prüfen falsche Herkunft, alte Resultate, fehlende Sprach-/Leistungs-/Rückkehrbelege, den erhaltenen Originalfehler, Produktdeltas trotz Sparsecheckout und die drei Wrapperfälle: erster Fehler verhindert zweite Tour; zweiter Fehler propagiert; beide erfolgreichen Stubprozesse passieren. Die bestehenden Current-Gates und die sieben Publisherprüfungen laufen unverändert mit.

Ein realer Erfolg bleibt bis zum neuen Androidlauf offen. Auch danach belegen Emulatoraufnahmen keine physische ARM64-/Fold7-Abnahme, akustisch geprüfte Aussprache, echte gesprochene Erkennung oder 60 FPS. Die zusätzliche Tour beschreibt eine neue Installation derselben APK mit einem neu über die UI angelegten fiktiven Klasse-1-Profil.
