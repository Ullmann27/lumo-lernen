# Lumo Cards Sound Effects

Hier kommen die SFX-Dateien fuer Lumo Cards rein. `LumoSound` (lib/core/lumo_sound.dart) sucht nach folgenden Pfaden — fehlende Dateien werden stillschweigend ignoriert (kein Crash):

| Dateiname             | Wann                                          |
|-----------------------|-----------------------------------------------|
| `card_whoosh.m4a`     | Karte wird ausgespielt                        |
| `card_draw.m4a`       | Karte vom Stapel gezogen                      |
| `plus2_storm.m4a`     | Sternenregen (+2) gegen den Gegner            |
| `plus4_thunder.m4a`   | Super-Sternenregen (+4)                       |
| `win_fanfare.m4a`     | Spieler gewinnt                               |
| `lose_buzz.m4a`       | Spieler verliert                              |
| `click.m4a`           | UI-Klick (Buttons, Tap-Feedback)              |
| `error.m4a`           | Ungueltige Aktion                             |

## Lizenz-Anforderung

Alle Files muessen **CC0** (Public Domain) ODER selbst aufgenommen ODER vom Owner lizenziert sein. Empfehlung: freesound.org mit Filter "Creative Commons 0".

## Empfohlene Eigenschaften

- Format: `.m4a` (AAC, kompakter als WAV/MP3, gut von audioplayers unterstuetzt)
- Dauer: 0.3 - 1.5 s pro Effekt (Fanfare bis ~2.5 s)
- Lautstaerke: leichter Headroom (-6 dB), die App-Lautstaerke wird vom OS gesteuert
- Mono ist OK; Stereo wenn der Effekt es braucht (Fanfare)
