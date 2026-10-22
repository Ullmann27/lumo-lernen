# Lernatelier: verlässliche Erklärungen

Stand: 18. Oktober 2026. Ausgangscommit: `0e6373e`, Arbeitsbranch
`codex/lumo-learning-lab-2026-10-18`.

## Befund und Änderung

Die vorhandene zentrale Stimme schützt bereits langsame native Starts,
Stummschalten, Navigation, verspätete Stop-/Pause-/Resume-Antworten und den
Übergang von Lob zur nächsten Frage. Die bestehenden Tests wurden gelesen und
erneut ausgeführt. Es wurde **kein weiterer reproduzierter zentraler Fehler**
als Begründung für einen Umbau behauptet.

Für das neue Lernatelier gibt es stattdessen einen kleinen Seitencontroller:
[`LumoLearningNarration`](../../../lib/core/lumo_learning_narration.dart).
Er verwendet ausschließlich `LumoVoice.instance`, auf Wunsch eine übergebene
`LumoVoice`-Instanz. Keine weitere Audioausgabe und kein neuer Anbieter.

| API | Verhalten |
| --- | --- |
| `read(String text)` | Stoppt bisheriges Audio und eine laufende Vorbereitung sofort, merkt sich die Erklärung und wartet auf deren Ende. Die neueste ausdrückliche Anforderung gewinnt. |
| `feedback(String text)` | Spricht nur bei freier Ausgabe. Bei zentralem `preparing`, `speaking` oder `paused` sowie eigener aktiver/pausierter Erklärung wird Feedback verworfen und nicht aufgestaut. |
| `pause()` | Stoppt auch eine noch nicht hörbare erste Zeile. Die Erklärung bleibt für Wiederholen erhalten. |
| `repeat()` | Startet die gemerkte Erklärung von vorn. |
| `stop()` | Stoppt und entfernt die gemerkte Erklärung, beispielsweise beim Aufgabenwechsel. |
| `dispose()` | Bricht ab und verwirft spätere Anforderungen und verspätete Abschlüsse. |
| `currentText`, `isPaused`, `isActive` | Lesbare Zustände; Änderungen werden über `ChangeNotifier` gemeldet. |

Alle Wiedergabemethoden liefern `Future<void>`. Ein Abschluss einer alten
Anforderung verändert keine neuere Erklärung. Ein Stimmenprofilwechsel während
eines ausstehenden Stops verhindert den Start unter dem neuen Profil. Ein
Wechsel während der Wiedergabe wird durch den vorhandenen zentralen Stop
beendet. Es gibt keine automatische Fortsetzung nach einem Profilwechsel.

Die Pause dieses Controllers beendet die Erklärung; Wiederholen beginnt vorn.
Die vorhandenen allgemeinen `LumoSpeechControls` behalten ihre native
Pause/Fortsetzen-Funktion an derselben Medienposition.

Die lokale F2-Stimme, der ausdrücklich auswählbare Sulafat-Pfad, vorhandene
Aufnahmen und bestehende Freigaben bleiben bestehen. Die stillgelegte
`flutter_tts`-Ersatzstimme wird nicht aktiviert. Die Spracheingabe stoppt
zentrale Audioausgabe vor dem Mikrofonstart; ihr vorhandener Android-Test
verhindert einen Cloud-Recognizer, falls lokale Erkennung fehlt.

**Verfügbarkeitsgrenze:** Neue Erklärungstexte benötigen die bestehende
Bestätigung der lokalen Sprachlizenz im Elternbereich. Ohne sie bleiben
fehlende Aufnahmen bewusst stumm; `lastError` erklärt den Zustand und der Text
bleibt lesbar. Dieser Controller erteilt keine Lizenz und keine Onlinefreigabe.

## Ausgeführte Prüfungen

Zunächst fehlte die neue Controllerdatei: der neue Test konnte die API nicht
auflösen. Mit kompilierender leerer API schlugen sieben Verhaltenstests fehl,
darunter Pause und Wiedergabe/Wiederholen. Danach wurde die minimale
Implementierung ergänzt.

12 deterministische Sitzungstests prüfen spätes Ende, langsamen Stop,
Vorbereitung abbrechen, Pause/Wiederholen, Feedback bei allen belegten
Ausgabezuständen, Stop, Profilwechsel und Dispose. Vier weitere Tests verbinden
den Controller mit dem **echten zentralen Dart-Player und dem ausgelieferten
F2-Katalog**: Clipauswahl, Warten auf Abschluss, Pause/Wiederholen, fremde
Audioausgabe und Profilwechsel. Ihre nativen Audiokanäle sind simuliert.

```bash
/workspace/flutter/bin/flutter test --no-pub \
  test/learning_speech_narration_test.dart \
  test/learning_speech_playback_test.dart \
  test/lumo_voice_clips_test.dart \
  test/lumo_free_voice_test.dart \
  test/lumo_voice_word_boundary_test.dart \
  test/voice_mute_regression_test.dart \
  test/lumo_speech_privacy_test.dart \
  test/lumo_speech_readiness_test.dart \
  test/lumo_speech_matrix_test.dart \
  test/lumo_free_speech_matrix_test.dart --reporter expanded
```

Ergebnis: **164 bestanden, Exitcode 0**. Darin enthalten sind die unveränderten
Sulafat- und F2-Situationsmatrizen sowie die Originaldatei-Prüfsummen,
native Pause/Fortsetzen, Musikabsenkung, Navigation und Stummschaltung.

```bash
/workspace/flutter/bin/flutter analyze --no-pub \
  lib/core/lumo_learning_narration.dart \
  test/learning_speech_narration_test.dart \
  test/learning_speech_playback_test.dart
```

Ergebnis: **No issues found**, Exitcode 0. Die Gesamtprüfung des integrierten
Appstands wird separat durch den Hauptauftrag dokumentiert.

## Hörbare Originaldateien und decodierte Messwerte

Diese drei Dateien sind bereits vorhandene, ausgelieferte **Lumo-Frei/F2**-
Aufnahmen. Sie sind keine drei neu erzeugten Stimmen. Ihre tatsächlichen Bytes
wurden mit `ffprobe` untersucht und mit `ffmpeg` vollständig als Mono-Float-PCM
decodiert. Die Messung verwendet die decodierten Samples und deren RMS/Spitze,
nicht eine simulierte native Wiedergabe.

| Aufnahme | Text | Decodierte Samples | Dauer | Spitze dBFS | RMS dBFS |
| --- | --- | ---: | ---: | ---: | ---: |
| [Begrüßung](../../../assets/audio/voice/lumo_free/free_b5e456b1bd716ab4.m4a) | Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues! | 174080 | 7,253333 s | -1,945 | -18,616 |
| [Mathefrage](../../../assets/audio/voice/lumo_free/free_93be75059975918a.m4a) | 3 plus 4 - wie viel ist das? | 69632 | 2,901333 s | -2,617 | -24,214 |
| [Ermutigung](../../../assets/audio/voice/lumo_free/free_35ef73b1f35d39a7.m4a) | Fast! Schau nochmal. | 54272 | 2,261333 s | -1,763 | -23,364 |

Alle drei: AAC, mono, **24.000 Hz**; alle decodierten Samples endlich,
kein Absolutwert größer oder gleich 1. Die 24 kHz gelten für diese gespeicherten
Clips. Der vorhandene lokale Android-Synthesepfad verlangt weiterhin seine
echten 44.100 Hz. Containerdauer und decodierte Sampledauer weichen aufgrund
von AAC-Frames/Padding leicht voneinander ab.

SHA-256 der unveränderten Quelldateien:

```text
35820e387b1d1cb377ff0192dfb29aa9ad9fb46cbde88eb560ba557676797c32  free_b5e456b1bd716ab4.m4a
ae11593098ce58966d4ac9b2bda40c7fb6a48e85fddfdc363af455d4ef87d793  free_93be75059975918a.m4a
f4c70ece270fc9a20cdba0dfafcfe5ae9e652ae1905b394211f05506ae3a7c9e  free_35ef73b1f35d39a7.m4a
```

Reproduzierbare Messung, vom Repository-Stamm aus:

```python
import array, hashlib, json, math, pathlib, subprocess

for name in ["free_b5e456b1bd716ab4", "free_93be75059975918a",
             "free_35ef73b1f35d39a7"]:
    path = pathlib.Path("assets/audio/voice/lumo_free") / (name + ".m4a")
    probe = json.loads(subprocess.check_output([
        "ffprobe", "-v", "error", "-show_streams", "-show_format",
        "-of", "json", str(path)]))
    raw = subprocess.check_output([
        "ffmpeg", "-v", "error", "-i", str(path), "-map", "0:a:0",
        "-ac", "1", "-f", "f32le", "-"])
    samples = array.array("f")
    samples.frombytes(raw)  # Messumgebung: little-endian Linux x86_64
    rate = int(probe["streams"][0]["sample_rate"])
    peak = max(abs(x) for x in samples)
    rms = math.sqrt(sum(x*x for x in samples) / len(samples))
    print(name, len(samples), len(samples)/rate,
          20*math.log10(peak), 20*math.log10(rms),
          sum(abs(x) >= 1 for x in samples),
          all(math.isfinite(x) for x in samples),
          hashlib.sha256(path.read_bytes()).hexdigest())
```

Herkunft: vorhandener [F2-Katalog](../../../assets/audio/voice/lumo_free/catalog.json)
und [Produktionsmanifest](../../education/2026-10-11-free-voice/audio-production-manifest.json).
Die ursprünglichen sechs Sulafat-Dateien wurden über die vorhandenen
Prüfsummentests erhalten. Als Figurenreferenz wurde das vorhandene
[Lumo mit Buch](../../../assets/lumo_design/fox/fox_book_point.png) tatsächlich
geöffnet: oranges Fell, weiße Schnauze/Schweifspitze, Stirnbrille, blaue Jacke.
Keine Fuchsdatei wurde geändert oder durch eine neue Figur ersetzt.

## Abgrenzung der Belege

Die verlinkten Dateien sind hörbare bestehende Assets. Die beschriebenen
Flutter-Tests prüfen Ablauf und Routing mit simulierten nativen Ereignissen.
Die PCM-Messung bestätigt decodierbare, nicht stumme Audiodaten und deren
Pegel. Sie belegt weder eine Lautsprecheraufnahme aus der laufenden Android-App
noch einen menschlichen Qualitätstest von Aussprache, Natürlichkeit oder
Emotionalität. Eine solche Laufzeitaufnahme mit Ton und eine Prüfung am
physischen Fold wurden in diesem Teilauftrag nicht durchgeführt. Keine neue
Stimmfarbe, kein neuer API-Zugang und keine behauptete Audioqualität wurden
aus den Tests abgeleitet.
