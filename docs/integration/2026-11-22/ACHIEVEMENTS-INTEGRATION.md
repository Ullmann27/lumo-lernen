# Profilgebundene Auszeichnungen mit echter Auszahlung

Stand: 22.11.2026. Umfang: vorhandenen 14er-Katalog anschließen; keine neuen Auszeichnungen oder zusätzlichen Aufgaben erfinden.

## Belegte Lücke und Ursprungsfunktion

Die hochgeladene HTML-App 05 besitzt `checkAchievements`, `claimAchievement(id)` und `renderAchievements` (insbesondere Zeilen 646 und 831). Die Variante 09 verwendet denselben ausdrücklichen Claim-Ablauf (Zeilen 278 und 309): Freischalten und Einsammeln sind getrennt; ein bereits eingesammelter Bonus darf nicht nochmals ausgezahlt werden. Die alte Flutter-Wand zeigte dagegen `+rewardStars`, hatte keinen Claim-Knopf und keine Wallet-Buchung. Der alte Tracker speicherte geräteweite Zähler ohne Kinderprofil und meldete Unlocks vor bestätigter Speicherung.

Die aktuelle Implementierung behält alle 14 IDs, Ziele, Titel, Stufen und Sternepreise. Eine nachweislich falsche Beschreibung wurde berichtigt: Der reale `LumoQuestLibrary`-Katalog enthält vier Quests insgesamt, je eine für Klasse 1 bis 4. `all_quests` beschreibt jetzt diese vier vorhandenen Abenteuer. Es werden keine vier Quests je Klasse behauptet.

## Erreichbarer Ablauf

Die bestehende Auszeichnungswand bleibt der Einstieg. Sie zeigt den gespeicherten Fortschritt dieses Kinderprofils und für freigeschaltete Boni einen mindestens 48 dp hohen Knopf „N Sterne abholen“. Erst nach bestätigter Auszahlung erscheint „Schon eingesammelt.“ und die Erfolgsmeldung „N Sterne sind gespeichert.“. Während des Schreibens bleibt die Aktion gesperrt.

Der AppShell-Hinweis auf eine neue Auszeichnung sagt nun „N Sterne abholen“; ein bloßes Freischalten behauptet keine Auszahlung mehr. Die Wand erklärt außerdem, dass frühere geräteweite Abzeichen aufbewahrt, aber keinem Kind ohne sichere Zuordnung zugesprochen werden. Die bestehende gemeinsame Sternetasche wird nicht aufgeteilt oder zurückgesetzt.

## Welche tatsächlichen Belege zählen

| Vorhandene Auszeichnungen | Quelle und Abgrenzung |
|---|---|
| `first_steps`, `ten_tasks` | Dauerhaft gespeicherte richtig gelöste Aufgaben aus Aufgabenprotokollen und vorhandenen profilgebundenen Lernfortschritten; überschneidende Standardzählungen werden nicht addiert. Elternaufgaben bleiben eigene Protokolleinträge und werden nicht in Curriculum-Zähler geschrieben. |
| `math_master_25`, `german_master_25` | Gespeicherte richtige Standardantworten im jeweiligen Fach. Elternaufgaben mit einem Fach im Beschreibungstext sind kein standardisierter Fachnachweis. |
| `login_3days`, `streak_7`, `streak_30` | Zusammenhängende belegte lokale Lerntage aus vorhandenen Profil-/Aufgabenaufzeichnungen. Keine erfundenen App-Starts. Ungültige und zukünftige Datumswerte zählen nicht. Bereits erreichte Serien bleiben als Auszeichnung erhalten. |
| `first_ki_chat` | Der bestehende `childAskedQuestion`-Bus des tatsächlichen `LumoConversationController`; Aufnahme des ursprünglichen Profil-Lease vor dem ersten asynchronen Schritt. Keine Speicherung von Frageinhalt. |
| `live_first` | Ein nichtleeres tatsächliches Sprachergebnis im noch gültigen LIVE-Aufnahmekontext oder ein erfolgreich zurückgekehrtes Kamerafoto. Bloßes Öffnen oder Starten der Aufnahme reicht nicht. Foto-/Sprachinhalt bleibt außerhalb der Auszeichnungsdaten. |
| `first_quest`, `all_quests` | Abschluss im vorhandenen StoryReader nach Lösung sämtlicher eingebetteter Auswahlaufgaben und dem bestehenden Abschluss-/Speicherpfad. Die echte Quest-ID wird einmal je Profil vermerkt; Wiederholung erhöht den Zähler nicht. |
| `perfect_mission` | Vorher-/Nachher-Snapshots der echten Tagesmission nach erfolgreicher Schul-/Protokoll-/Missionsspeicherung. Der Beleg beginnt bei null, muss alle Stationszuwächse lückenlos sehen und darf bis Abschluss keinen gespeicherten falschen Versuch im Missionsfach des Tages enthalten. Eine ältere Teilmission gilt nicht rückwirkend als fehlerfrei. |
| `stars_100`, `stars_500` | Neue, dem tatsächlichen ursprünglichen Profil zugeordnete positive Wallet-Buchungen. Gemeinsames historisches `totalEarnedStars` wird keinem Kind zugesprochen. Spätere Ausgaben vermindern die bereits verdienten Sterne nicht. |

Es entsteht kein zweites Antwortbewertungssystem. Fachliche Richtigkeit, Schulfortschritt und bestehende Belohnungsbeträge kommen weiterhin aus ihren bisherigen Quellen. Neue Ereignisbelege enthalten nur die für den jeweiligen Badge nötigen Metadaten.

## Einmalige, dauerhafte Auszahlung

`AchievementClaim(ownerId, achievementId)` berechnet die feste ID `achievement:<SHA-256 des ownerId>:<achievementId>`. Der Betrag stammt ausschließlich aus dem bestehenden Katalog. Auch `streak_30` wird mit seinen vollen 150 Sternen verbucht; eine kleinere Game-Reward-Obergrenze wird hier nicht übernommen.

1. `AchievementRepository.beginClaim` schreibt vor dem Wallet-Aufruf den offenen Claim zum ursprünglichen Kinderprofil.
2. Der AppState-Delegator prüft aktiven Profil-Lease, Besitzer, vorhandene dauerhafte Freischaltung und laufende ältere Reward-Schreibvorgänge.
3. `RewardWalletRepository.claimAchievement` schreibt Sterne, kumulative Einnahmen, Profil-Einnahmen und Receipt in einem gemeinsamen Snapshot. Ein vorhandener identischer Receipt wird positiv erneut persistiert, ohne nochmals zu zahlen.
4. Erst nach positivem Wallet-Ergebnis wird der offene Claim bestätigt. Die Wand verlangt Receipt und abgeschlossene Bestätigung, bevor sie „eingesammelt“ anzeigt.

Ein Abbruch nach der Zahlung oder eine ungewisse Antwort hält dieselbe Claim-ID. Das erneute Abholen bestätigt den vorhandenen Beleg; es erzeugt keine zweite Zahlung. Ein Wechsel von A zu B leert As Anzeige synchron; ein noch abschließender Vorgang bleibt an A gebunden und zeigt B keine Erfolgsmeldung.

Die Regressionen fanden zusätzlich einen vorhandenen Wallet-Persistenzfehler: `SharedPreferences.setString` kann den Dart-Cache bereits ändern, obwohl der Plattform-Write `false` zurückgibt. Der Wallet-Schreibpfad lädt bei Fehlern jetzt neu. Ein weiterer Gegenfall modelliert einen weiterhin sichtbaren nativen Speicher-Cache trotz negativer Antwort. Dafür bleibt der offene Claim bis zu einem positiven idempotenten Retry erhalten; ein geladener unbestätigter Receipt genügt nicht für die Erfolgsmeldung.

## Daten und Kompatibilität

Neue Profilablage: `lumo_achievements_v2::<URI-kodierte Profil-ID>` mit `version`, `studentId`, `counters`, `unlocked`, `quests`, `mission`, `pendingClaims`. Kurze Änderungen laufen durch die vorhandene gemeinsame `LearningStorage`-Queue; konkurrierende Instanzen lesen vor jedem Schreiben neu. Fehlerhafte oder neuere Daten werden nicht durch einen leeren Stand ersetzt.

Die alte geräteweite Ablage `lumo.achievements.unlocked` / `lumo.achievements.counters` bleibt unverändert erhalten. Neue Auszahlungsbelege stehen im bestehenden Wallet als `achievementClaims`; `earnedStarsByOwner` ergänzt nur tatsächlich zuordenbare neue Einnahmen. Claims sind keine `gameResultIds` und erhöhen keinen Spielezähler.

Die vorhandene Sicherungsauswahl erfasst alle neuen Schlüssel. Der Wallet-Validator verwendet `RewardWallet.fromJson` und übernimmt die zusätzlichen Felder. Der Schreibtrainer, Journal-Editor, native Host und Standard-Curriculum werden für diese Integration nicht ersetzt.

## Prüfung

Gezielter Befehl im vorhandenen Flutter-SDK, `PUB_CACHE=/home/agent/lumo-tools/pub-cache`:

```sh
flutter test --no-pub --concurrency=1 --reporter expanded \
  test/achievement_repository_test.dart \
  test/achievement_flow_test.dart \
  test/live_pro_question_coach_test.dart \
  test/story_nextgen_flow_test.dart \
  test/story_completion_storage_test.dart \
  test/story_answer_retry_test.dart
```

**Finaler lokaler Nachweis: 28/28 neue Fälle bestanden**, mit Exit 0 in zwei isolierten Läufen:

| Lauf | Ergebnis | Beleg |
|---|---:|---|
| `achievement_flow_test.dart` | 16/16 PASS | `local-proof/achievement-flow-final.log` |
| `achievement_repository_test.dart` | 12/12 PASS | `local-proof/achievement-repository-final.log` |

Der Flow enthält ausdrücklich alle vier echten Quest-Abläufe mit Auswahlantworten, Rückblick und gespeichertem Abschluss, den tatsächlichen LIVE-UI-Rückruf mit synthetischem Recognizer, die 390 × 844-Wand vor/nach bestätigtem Claim, Double-submit, Restart nach verlorener Bestätigungsantwort, den negativen nativen Cache-Gegenfall, Wechsel A→B während der Zahlung, 150-Sterne-Vollbetrag, das Verweigern fremder/gesperrter Claims und die echte Tagesmissionsanbindung. Eine falsche Übung zählt als Lerntag, aber nicht als gelöste Aufgabe. Noch unbestätigte Claim-Sterne schalten auch kein weiteres Sterne-Ziel frei.

Die beiden finalen Läufe verwendeten jeweils `timeout 90s env PUB_CACHE=/home/agent/lumo-tools/pub-cache` vor dem oben genannten Flutter-Aufruf, jeweils mit nur einer der beiden neuen Testdateien. Frühere Sammelläufe trafen einen Compiler-/Dateiladefehler der begrenzten lokalen Laufzeit. Nach Freigabe reproduzierbarer Godot-/Gradle-Caches bestanden die isolierten finalen Läufe. Sie werden nicht als ein gemeinsamer größerer grüner Lauf ausgegeben.

Die vier bestehenden Story-/LIVE-Suites oben bestanden mit 20 Fällen im vorherigen vollständigen Sammellauf; dessen damals noch fehlerhafte zusätzliche neue Widget-Fixtures wurden anschließend korrigiert und sind im finalen 16er-Beleg enthalten. Der endgültige Workflow führt die erforderlichen Bestandsprüfungen erneut am gepinnten APK-Quellstand aus.

Bildbelege aus dem echten Widget mit `LumoAppTheme.light()` und geladenen Nunito-Schriften: `local-proof/achievements-ready.png` und `local-proof/achievements-claimed.png`. Beide wurden visuell geprüft. Der Titel steht auf einer festen dunklen AppBar; Erklärung/Retry stehen auf einer kontrastreichen dunklen Lesefläche. Die Bilder sind Widget-Raster, keine Android-Gerätescreenshots; im Desktop-Test fehlen einzelne Emoji-/Symbol-Fallbackglyphen. Die lesbaren Knopf- und Statusbezeichnungen sind davon unabhängig.

Diese Widget-Prüfungen verwenden synthetische Gerätecallbacks und sind kein Nachweis einer physischen Mikrofon-/Kameramessung. Der gemeinsame APK-/Android-Abnahmelauf wird getrennt an den endgültigen Quellstand und die signierte Kandidatendatei gebunden. Offline-Lerntage sind lokale Kalenderbelege; die App behauptet keine extern authentifizierte Gerätezeit.

## Schlussregression: laufende Lerndialoge behalten ihren Besitzer

Der abschließende Gesamtlauf fand zwei echte Fehler in den bestehenden Core-Dialogtests: Eine neu gespeicherte Chat-Auszeichnung schob die alte Vollbild-Feier als fremde Route über den eigenen Lerndialog. Der vorhandene Eigentümerschutz zog daraufhin richtigerweise dessen Aufgaben-Kontext zurück. Die Fach- und Speicherschicht war davon unabhängig.

AppShell zeigt bei aktivem Aufgaben-Kontext, einem bereits geöffneten Dialog, im direkten Lumo-Chat sowie bei ruhigen oder reduzierten Animationen ausschließlich den bestehenden nichtmodalen Auszeichnungshinweis. Außerhalb dieser Situationen darf die Feier weiter erscheinen. Ihr Timer entfernt nun ausschließlich ihre konkrete Route, statt einen möglicherweise inzwischen darüber geöffneten anderen Dialog zu schließen. Die bereits gespeicherte Auszeichnung und der ausdrückliche Claim bleiben unverändert.

Nach dieser Korrektur bestanden `test/learning/core_conversation_route_test.dart` mit **11/11** und `test/achievement_flow_test.dart` erneut mit **16/16**, jeweils isoliert mit 90-Sekunden-Limit und Exit 0. Der zusätzliche Core-Gegenfall verwendet aktivierte Animationen, prüft die dauerhaft gespeicherte `first_ki_chat`-Freischaltung und verlangt, dass derselbe Aufgaben-/Dialog-Owner auch nach Ablauf des früheren Timers erhalten bleibt. Die zehn bisherigen Eigentümerschutzfälle wurden nicht abgeschwächt. Belege: `local-proof/achievement-core-route-final.log` und `local-proof/achievement-flow-after-route-fix.log`.
