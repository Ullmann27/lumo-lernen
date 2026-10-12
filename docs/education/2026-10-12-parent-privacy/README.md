# Elternbereich: Profilnamen und sichere Kopfleiste

Dieser Folgecommit baut auf Produktquelle `65009c4115d6674e730f15b145671c9a87ae1de7`
auf. Er ist noch nicht Bestandteil der ausgelieferten APK 1933; er gehört in den
nächsten integrierten, neu versionierten Kandidaten.

Die optional angeforderten KI-Wochenberichte in Insight und im Elternbericht
hatten den lokal gespeicherten Kindernamen automatisch in ihren Anfragetext
übernommen. Beide formulieren die Anfrage jetzt mit „das Kind“. Schulstufe,
Fachzusammenfassung, Förderhinweise und vorhandener Eltern-/KI-Zugriff bleiben
wie bisher. Lokale Profilnamen, Lernstände und Einstellungen werden nicht
umbenannt oder zurückgesetzt. Dies entfernt den automatisch vorangestellten
Profilnamen; es macht Lerninhalte und sämtliche übrigen Datenflüsse nicht
pauschal anonym.

Vier Prüfungen bedienen die tatsächlichen Elternwidgets und den vorhandenen
`LumoAiProxyClient` mit einem vollständig lokalen simulierten HTTP-Transport:
Beide Anfragen enthalten den Profilnamen nicht; Klasse und Elternkontext bleiben
enthalten; ohne KI-Freigabe und ohne ausdrücklichen Knopfdruck wird kein Client
erstellt. Keine echten Server-, Sprach- oder kostenpflichtigen API-Anfragen
wurden für diese Tests ausgeführt. Die ursprünglichen Quellen scheiterten an
Namensübertragung und Kopfleistenüberschneidung; die korrigierten Quellen bestehen.

Der tatsächliche Flutter-Bildvergleich zeigte außerdem, dass sich die Insight-
Begrüßung mit der transparenten Kopfleiste überschnitt. Der bestehende Hintergrund
bleibt bestehen; `SafeArea` hält den Inhalt unterhalb der Kopfleiste. Der Test
prüft die wirklichen Textrechtecke, statt nur die Existenz des Namens.

- Vorher: [überdeckte Begrüßung](flutter-runtime/insight-before-overlapping-header.png)
- Nachher: [sichere Kopfleiste](flutter-runtime/insight-after-safe-header.png)

Beide Bilder stammen aus Flutter-Widget-Laufzeiten mit Original-Schrift und
430×932 Zielgröße. Sie sind keine Android-/Fold-Hardwareaufnahmen. Die Linux-
Testumgebung bildet manche Emoji-Glyphen als Ersatzzeichen ab; daraus folgt
keine Aussage über Android-Emoji-Darstellung.

18 Eltern-, Analyse- und UI-Prüfungen bestanden. Der einmalige frische Review des
vollständigen Änderungsumfangs hatte keine Befunde. Die vollständige CI des
Folgecommits wird separat zugeordnet; sie ist nicht die CI der unveränderten
1933-APK. Store-Publikation, Zahlungen und kostenpflichtige Sprachaufrufe wurden
nicht aktiviert. Die übrige Play-Datenfluss-/Lizenz-/Geräteabnahme bleibt offen.
