# Lumo Lernen – Konnektoren-Strategie

**Stand:** 21.05.2026
**Autor:** Heinz Ullmann (Auftrag) + Claude Code (Umsetzung)
**Geltungsbereich:** Wie Claude Code mit Heinz' verbundenen Diensten arbeitet, damit die App grafisch, logisch und vermarktbar sauber wächst — ohne CI-Risiko und ohne Privatdaten.

---

## 0. Grundregel: CI vor allem

Bevor neue UI/Features gebaut werden:

1. PR-Status und letzten CI-Run prüfen.
2. Wenn rot: **nur Reparatur-Commits**, kein neues Feature.
3. Wenn grün: dann Design-/Code-Schritt.

Beispiel aus dieser Runde:
- PR #59 (Memory + Vier gewinnt + Würfel-Wettlauf) wurde gemerged, **Build 141 schlug danach fehl** weil `test/smoke_lumo_kart_test.dart` noch das gelöschte Kart-Modul importierte.
- Bevor diese Datei geschrieben wurde, **PR #60 (Test-Datei gelöscht)** als reiner Reparatur-Commit gemerged.
- Erst danach Dokumentation.

---

## 1. Konnektoren-Inventar

| Konnektor | In dieser Session direkt verfügbar? | Source-of-Truth für |
|---|---|---|
| **GitHub** | ✅ ja (MCP, scoped auf `Ullmann27/lumo-lernen`) | Code, PRs, CI, Releases |
| **Gmail** | ✅ ja (MCP) | nur GitHub/Play-Store/Lumo-Projektmails |
| **Google Kalender** | ✅ ja (MCP) | Sprint- und Test-Termine |
| **SketchUp** | ✅ ja (MCP) | 3D-Referenzen (optional) |
| **Web Search** | ✅ ja | Recherche zu Flutter/Android |
| **Figma** | ❌ nein in Cloud-Session | UI, Design Tokens, Komponenten |
| **Google Drive** | ❌ nein in Cloud-Session | Asset-Archiv, Baupläne, Übergaben |
| **Miro** | ❌ nein in Cloud-Session | Produktlandkarte, User-Journey |
| **Canva** | ❌ nein in Cloud-Session | Marketing, Play-Store-Grafiken |
| **Docusign** | ❌ nein in Cloud-Session | spätere Verträge/Lizenzen |
| **Google Compute Engine** | ❌ nein in Cloud-Session | späteres Backend |
| **MailerLite** | ❌ nein in Cloud-Session | spätere Eltern-Warteliste |

**Folge daraus:**
- GitHub, Gmail, Kalender, SketchUp und WebSearch kann Claude Code direkt steuern.
- Figma/Drive/Miro/Canva/Docusign/GCE/MailerLite sind in claude.ai (Web/Desktop) verbunden, **nicht in dieser Cloud-Session**. Wenn Heinz Inhalte daraus braucht, muss er sie aus claude.ai an Claude Code übergeben (PDF, Screenshot, Markdown).

---

## 2. Rollen pro Konnektor

### A. GitHub — Source of Truth für Code

**Was Claude Code damit darf:**
- PRs erstellen, mergen (nach grünem CI bzw. bei reinen Reparaturen)
- CI-Status und Annotations lesen
- Branches anlegen
- Releases lesen (für Build-Nummern)
- Issues lesen/kommentieren

**Was Claude Code NICHT darf:**
- Hooks deaktivieren (`--no-verify`)
- Force-Push auf `main`
- Bei rotem CI neue Features bauen
- Andere Repos berühren (Scope ist hart auf `Ullmann27/lumo-lernen`)
- Secrets ins Repo committen

### B. Gmail — Projektkommunikation

**Was Claude Code damit darf:**
- Nach `from:notifications@github.com` filtern für CI-Fehler
- Nach Google Play Console Mails suchen
- Nach Lumo-Projekt-Mails (Tester, Feedback) suchen

**Was Claude Code NICHT darf:**
- Privatmails der Familie lesen
- Bank-/Behörden-/Gesundheitsmails öffnen
- Mails ohne klaren Projektbezug auswerten
- E-Mails versenden ohne explizite Genehmigung

### C. Google Kalender — Sprintplanung

**Was Claude Code damit darf:**
- Vorschlag für Projekt-Termine machen (z.B. "Mo CI-Stabilität, Di Schreibcoach, Mi UI, Do Eltern, Fr APK-Test")
- Existierende Lumo-Termine lesen (sofern als solche markiert)

**Was Claude Code NICHT darf:**
- Privattermine lesen oder auswerten
- Termine ohne Heinz' OK eintragen

### D. SketchUp — 3D-Referenzen (optional)

**Was Claude Code damit darf:**
- 3D-Skizzen für Lumo-Lernzimmer, Kart-Strecke oder Buchstaben-Bühne machen, wenn Heinz das explizit anstößt
- Skills laden (`list_skills` / `read_skill`)

**Was Claude Code NICHT darf:**
- Die Flutter-App auf SketchUp/3D umbauen
- Komplexe 3D-Modelle ohne klaren App-Bezug erzeugen

### E. Figma — UI-System (von außen kuratieren)

**Heinz' Aufgabe:**
- Figma-Datei pflegen mit Lumo-Designsystem (Farben, Typografie, Buttons, Cards, Spacing, Screens).

**Wenn Claude Code Figma-Inhalte bekommt:**
- Design Tokens nach Flutter übersetzen → `lib/theme/`
- Wiederverwendbare Widgets → `lib/widgets/premium/`
- Erst eine kleine Komponente migrieren, CI prüfen, dann nächste.

**Was Claude Code NICHT darf:**
- Designs frei erfinden, wenn Figma vorhanden ist
- Mehrere Screens gleichzeitig umbauen

### F. Google Drive — Asset-Archiv

**Vorgeschlagene Struktur:**

```
Lumo Lernen/
├── 01_Bauplaene/
├── 02_Claude_Code_Auftraege/
├── 03_Screenshots_Fehler/
├── 04_Assets/
│   ├── Fuchs/
│   ├── Schreibcoach/
│   ├── Kart/                    (Achtung: in App entfernt)
│   ├── UI/
│   └── Marketing/
├── 05_App_Store/
├── 06_Datenschutz_Eltern/
├── 07_Releases_APK/
└── 08_Monetarisierung/
```

**Heinz' Aufgabe:**
- Diese Struktur in Drive anlegen.
- Nur Lumo-Material darin ablegen, keine Privatdokumente.

**Was Claude Code NICHT darf:**
- Privatordner lesen
- Dateien löschen oder umbenennen
- Sensible Dokumente (Rechtliches, Familie, Medizinisches, Finanzielles) öffnen

### G. Miro — Produktboard

**Vorgeschlagene Board-Sektionen:**

1. Lumo Vision
2. Aktueller Stand (Build, Module, Crashes)
3. Alleinstellungsmerkmale (Schreibcoach Live, Fehlerdetektiv, Eltern-Bericht)
4. Schreibcoach Live
5. Fehlerdetektiv
6. Elternbericht
7. Lumo Jump (Adventure)
8. Multiplayer-Spiele (Memory, Vier gewinnt, Würfel-Wettlauf)
9. Abo-Modell (Gratis / Lumo Plus)
10. Play-Store-Launch
11. DACH/EU-Roadmap
12. Risiken / Datenschutz / Kinder-App-Regeln

**Was Claude Code NICHT darf:**
- Mit Miro Code generieren
- Heinz' Familien-Boards oder andere Projekte berühren

### H. Canva — Marketing

**Klare Trennung:**
- Canva ist NIE Quelle für App-UI-Code.
- App-UI kommt aus Figma → Flutter.
- Canva ist für extern: Play Store, Eltern-Flyer, Social Media.

**Vorgeschlagene Assets:**
- Feature Graphic: „Lumo Lernen — Der Schreibcoach, der beim Schreiben hilft"
- Screenshot-Serie für Play Store
- Eltern-Erklärbild „So hilft Lumo deinem Kind"
- Abo-Vergleich Gratis ↔ Lumo Plus

**Was Claude Code NICHT darf:**
- Behaupten, ML-Kit/OCR sei fertig, wenn es nicht fertig ist
- Versprechen machen, die der Code nicht hält

### I. Docusign

**Aktuell:** nicht aktiv nutzen.
**Später relevant für:** Designer-Freigaben, Asset-Lizenzen, Entwicklervereinbarungen, Tester-Einwilligungen.

### J. Google Compute Engine

**Aktuell:** nicht aktiv nutzen.
**Später für:** Premium-TTS-Backend, KI-Proxy, sichere API-Keys, OCR-Backend.
**Hinweis:** Cloudflare Workers oder Supabase Edge Functions sind oft leichter als GCE. Nur einsetzen, wenn ein eigenes Backend bewusst geplant wird. **Aktuell läuft der Proxy auf Render.com** (`https://lumo-ai-proxy.onrender.com`).

### K. MailerLite

**Aktuell:** nicht aktiv in App einbauen.
**Später:** Eltern-Warteliste, Beta-Tester-Liste, Launch-Mail.
**Niemals:** Kinder direkt anschreiben, Daten ohne Einwilligung sammeln.

---

## 3. Workflow für jeden Auftrag

1. **CI-Check** zuerst.
2. **Quellen** prüfen (Figma → Code-Token, Drive → Asset, Miro → Roadmap).
3. **Kleinen Auftrag** definieren (max. 1-2 Files, 1 Feature).
4. **Code** ändern.
5. **Lokale Verifikation** (statische Code-Prüfung, Imports, Klammern).
6. **CI** prüfen.
7. **Doku** aktualisieren (Handover, Strategie, Roadmap).
8. **Marketing** (Canva) erst, wenn Funktion stabil ist.

---

## 4. Datenschutz und Familienschutz

- **Lumo ist eine Kinder-App.** Kinderdaten dürfen die App nicht verlassen.
- **Lokal-First:** Profil, Sterne, Schreib-Fortschritt, Fehlerlog liegen in `SharedPreferences`.
- **Kein Cloud-Zwang.** KI-Proxy ist optional (Elternentscheidung).
- **Keine privaten Konten:** Bank, Behörden, Gesundheit, Familie sind tabu für Claude Code, egal welcher Konnektor.
- **Keine Werbung** in der App.
- **Eltern-Gate** vor Settings + Profil bleibt.

---

## 5. Was diese Runde konkret geliefert hat

- PR #51-59 in einem Tag (von Phase 5+6 bis Memory mit Lumo-KI)
- Build 140 live, Build 141 fehlerhaft → PR #60 (Reparatur) → Build 142 läuft
- Dieses Strategie-Dokument
- Klare Trennung: Code (GitHub) vs Design (Figma) vs Marketing (Canva) vs Planung (Miro)

---

## 6. Empfohlene nächste Schritte (max. 5)

1. **CI grün halten** — Build 142 abwarten, falls rot: nur Reparatur.
2. **Figma-Datei für Lumo aufsetzen** (durch Heinz) — Design-System mit den schon vorhandenen Tokens aus `lib/theme/lumo_design_tokens.dart` synchronisieren.
3. **Miro-Board mit obigen 12 Sektionen** anlegen — als Single-Source für „was kommt als nächstes".
4. **Drive-Ordnerstruktur** wie unter 2.F anlegen, vorhandene Assets dorthin sortieren.
5. **Schreibcoach Phase 7** als nächster Code-Sprint (OCR/ML-Kit Re-Aktivierung), **erst wenn** Schreibcoach Phase 5+6 in der App ohne Crash benutzbar ist.

---

## 7. Akzeptanzkriterien dieses Dokuments

- [x] Welche Konnektoren verbunden sind (Kapitel 1)
- [x] Welche Rolle jeder hat (Kapitel 2)
- [x] Was Claude Code damit darf/nicht darf (jeweils pro Konnektor)
- [x] Datenschutz und Familienschutz (Kapitel 4)
- [x] Workflow (Kapitel 3)
- [x] Nächste Schritte (Kapitel 6)
- [x] Keine privaten Daten in diesem Dokument
