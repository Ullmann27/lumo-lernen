# API37-Originalbefund auf Host28462 / Native29080

Dieser Nachweis gehört ausschließlich zum fehlgeschlagenen Studio-Job132563694495 in Run43626348519. Der Speicherstand ist inzwischen überholt. Die spätere Memory-/Wallet-/C4-/OCR-Fassung wird hier nicht abgenommen.

Der vollständige Originallog wurde genau einmal abgerufen und bytegebunden gespeichert. Zusätzlich wurden ausschließlich `21_kart_preview_skip.json` und `21_kart_preview_skip_touch-surface-readiness.json` aus Artefakt14128934085 selektiv gelesen:66.289B mit strikten206-Bereichen und vollständigen Mitglieds-CRCs. Die publizierte Gesamtgröße beträgt65.852.093B; die publizierte SHA256 wird als Metadatum geführt. Kein vollständiger lokaler ZIP-SHA-/Gesamt-CRC-Nachweis und keine aktuelle Bildsichtung werden behauptet.

Die allgemeine Tour verzeichnet16 erfolgreiche Schritte, einen fehlgeschlagenen Kart-Start und vier nicht erreichte Renn-/Pausegates. Danach waren Flutter-Rückkehr, Profil-/Lernstand und Neustartschutz erfolgreich. Die nachgeordneten Learning/Cards-, C4-, Quiz-, Memory- und Englischprüfer wurden nicht gestartet.

Die beiden Originaljournale präzisieren die Ursache: Der alte generische OCR-Reader findet im ersten vollständigen Frame keine passende Caption. Der nächste Frame folgt22,468855s später; dieser Abstand enthält mehrere Arbeitsschritte und ist keine isolierte OCR-Dauer. Zwei spätere Zielbeobachtungen stimmen geometrisch überein und der Helper protokolliert einen echten Touch. Er kehrt jedoch erst am Ende seiner verbliebenen35,339683s zurück. Der äußere unveränderte55s-Check weist den Ablauf sofort danach zurück; Cue- und Nachbildabschluss fehlen. Ein beobachteter Touch ist daher kein erfolgreicher Rennstart.

Der bereits separat geprüfte schnelle Previewreader war in diesem Host nicht enthalten. Seine Wirkung muss der nächste echte APK-Lauf zeigen. Es wurden hier keine Produktdateien, Tests, Workflows oder Git-Refs geändert.
