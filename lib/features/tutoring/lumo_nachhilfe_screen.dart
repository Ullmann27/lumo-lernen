import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/tutoring/lumo_nachhilfe.dart';
import '../../domain/tutoring/native_learning_activity.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';
import 'nachhilfe_material.dart';

/// Ergebnis der Verständnisprüfung (Stufe 5) an einer ähnlichen Aufgabe.
/// [selbststaendig] ist nur wahr, wenn das Kind sie beim ersten Versuch ohne
/// Material gelöst hat – erst das zählt als Hinweis auf Verständnis.
class NachhilfePruefung {
  const NachhilfePruefung({
    required this.aufgabe,
    required this.ergebnis,
    required this.antwort,
    required this.richtig,
    required this.versuche,
  });

  final NachhilfeAufgabe aufgabe;
  final int ergebnis;
  final int antwort;
  final bool richtig;
  final int versuche;

  bool get selbststaendig => richtig && versuche == 1;
  String get prompt => '${aufgabe.text} = ?';
}

/// Lumo-Nachhilfe für eine konkrete Aufgabe.
///
/// Fünf Hilfestufen: kleiner Tipp, andere Erklärung, Lumo zeigt am Material,
/// gemeinsam (das Kind tippt jeden Zwischenschritt ein, Lumo wartet) und
/// Verständnisprüfung an einer ähnlichen Aufgabe. Plus bis 20 nutzt dieselben
/// Pläne wie die 3D-Szene. Die Originalaufgabe wird hier nie beantwortet:
/// das Kind kehrt zur Aufgabe zurück und rechnet selbst. Die Seite wird nur
/// geöffnet, wenn Hilfe erlaubt ist (nie in Tests und Schularbeiten).
class LumoNachhilfeScreen extends StatefulWidget {
  const LumoNachhilfeScreen({
    super.key,
    required this.aufgabe,
    this.fehler = NachhilfeFehlermuster.keines,
    this.startStufe = NachhilfeStufe.hinweis,
    this.reduceMotion = false,
    this.onSpeak,
    this.onStopSpeech,
    this.open3D,
    this.tutor = const LumoNachhilfe(),
    this.onPruefung,
    this.lernstandSatz,
    this.startWeg,
  });

  final NachhilfeAufgabe aufgabe;
  final NachhilfeFehlermuster fehler;
  final NachhilfeStufe startStufe;
  final bool reduceMotion;

  /// Vorhandene Sprachausgabe der App (z. B. LumoVoice); null = stumm.
  final Future<void> Function(String text)? onSpeak;
  final VoidCallback? onStopSpeech;

  /// Öffnet die 3D-Fassung; null, wenn 3D auf diesem Gerät nicht verfügbar ist.
  final Future<bool> Function(
      BuildContext context, NativeLearningActivity activity)? open3D;
  final LumoNachhilfe tutor;

  /// Meldet das Ergebnis der Verständnisprüfung genau einmal je Prüfaufgabe.
  final ValueChanged<NachhilfePruefung>? onPruefung;

  /// Ruhiger Satz aus dem Lernstand (nur bei belastbaren Daten).
  final String? lernstandSatz;

  /// Weg aus einem wiederkehrenden Muster im Verlauf (ohne Rückmeldung).
  final NachhilfeWeg? startWeg;

  @override
  State<LumoNachhilfeScreen> createState() => _LumoNachhilfeScreenState();
}

class _LumoNachhilfeScreenState extends State<LumoNachhilfeScreen> {
  final LumoCharacterController _lumo = LumoCharacterController();
  final Set<NachhilfeWeg> _gesehen = <NachhilfeWeg>{};
  late NachhilfeWeg _weg;
  late NachhilfeStufe _stufe;
  late NachhilfePlan _plan;
  int _schritt = 0;
  int _reihe1 = 0;
  int _reihe2 = 0;
  int _position = 0;
  final List<(int, int)> _spruenge = <(int, int)>[];
  List<int>? _zerlegung;
  int? _gewaehlt;
  int _fehlversuche = 0;
  bool _fertig = false;
  bool _vorgezeigt = false;
  String? _rueckmeldung;
  bool _oeffne3D = false;
  NachhilfeAktion? _stangen;
  NachhilfeAktion? _punkte;
  NachhilfeAktion? _bild;
  String _eingabe = '';
  (int, int) _perlenVorher = (0, 0);
  bool _pruefPhase = false;
  int _pruefVersuche = 0;
  bool _pruefGemeldet = false;
  bool? _pruefRichtig;

  @override
  void initState() {
    super.initState();
    final startWeg = widget.startWeg;
    _weg = startWeg != null &&
            widget.tutor.wegeFuer(widget.aufgabe).contains(startWeg)
        ? startWeg
        : widget.tutor.wegFuer(widget.aufgabe, fehler: widget.fehler);
    _stufe = widget.startStufe;
    _starte();
    if (widget.fehler != NachhilfeFehlermuster.keines) {
      _rueckmeldung = widget.fehler.rueckmeldung;
    }
  }

  @override
  void dispose() {
    widget.onStopSpeech?.call();
    _lumo.dispose();
    super.dispose();
  }

  void _starte() {
    _gesehen.add(_weg);
    _plan = widget.tutor.plan(widget.aufgabe, _weg, _stufe);
    _schritt = 0;
    _reihe1 = 0;
    _reihe2 = 0;
    _position = 0;
    _spruenge.clear();
    _zerlegung = null;
    _gewaehlt = null;
    _fehlversuche = 0;
    _fertig = false;
    _vorgezeigt = false;
    _stangen = null;
    _punkte = null;
    _bild = null;
    _eingabe = '';
    _pruefVersuche = 0;
    _pruefGemeldet = false;
    _pruefRichtig = null;
    // Stufe 5: zuerst ganz allein, ohne Material und ohne Schritte.
    _pruefPhase = _stufe == NachhilfeStufe.ueben;
    if (_pruefPhase) {
      _lumo.talk();
      unawaited(_sprich(_plan.einleitung));
      return;
    }
    _betreteSchritt();
  }

  NachhilfeSchritt? get _aktuell =>
      _schritt < _plan.schritte.length ? _plan.schritte[_schritt] : null;

  bool get _lumoIstDran => _aktuell?.akteur == NachhilfeAkteur.lumo;

  void _betreteSchritt() {
    final s = _aktuell;
    if (s == null) {
      _fertig = true;
      _lumo.cheer();
      unawaited(_sprich('${_plan.lob} ${_plan.abschluss}'));
      return;
    }
    _eingabe = '';
    _perlenVorher = (_reihe1, _reihe2);
    if (s.akteur == NachhilfeAkteur.lumo) {
      _lumo.talk();
      _zeigeVor(s);
    } else if (s.aktion.art == 'bild') {
      _bild = s.aktion;
    }
    unawaited(_sprich(s.text));
  }

  /// Lumo führt den Schritt am Material aus (Zielzustand anwenden).
  void _zeigeVor(NachhilfeSchritt s) {
    final aktion = s.aktion;
    switch (aktion.art) {
      case 'perlen':
        _reihe1 = aktion.wert('reihe1');
        _reihe2 = aktion.wert('reihe2');
      case 'huepfen':
        _huepfe(aktion.wert('von'), aktion.wert('nach'));
      case 'zerlegen':
        _zerlegung = [aktion.wert('teil1'), aktion.wert('teil2')];
      case 'ergebnis':
        _gewaehlt = aktion.wert('richtig');
      case 'stangen':
        _stangen = aktion;
      case 'punkte':
        _punkte = aktion;
      case 'bild':
        _bild = aktion;
    }
    if (s.frage != null) _eingabe = '${s.frage}';
    _vorgezeigt = true;
  }

  void _huepfe(int von, int nach) {
    if (von != _position) _position = von;
    if (von != nach) _spruenge.add((von, nach));
    _position = nach;
  }

  Future<void> _sprich(String text) async {
    final speak = widget.onSpeak;
    if (speak == null || text.trim().isEmpty) return;
    try {
      await speak(text);
    } catch (_) {
      // Sprache ist eine Zugabe; der Text bleibt sichtbar.
    }
  }

  void _weiter() {
    setState(() {
      _schritt++;
      _fehlversuche = 0;
      _vorgezeigt = false;
      _rueckmeldung = null;
      _betreteSchritt();
    });
  }

  void _geschafft() {
    _lumo.cheer();
    _rueckmeldung = 'Genau!';
    _weiter();
  }

  void _daneben(String hinweis) {
    _fehlversuche++;
    _lumo.comfort();
    final s = _aktuell!;
    if (_fehlversuche >= 2) {
      _rueckmeldung = 'Ich zeige es dir einmal. Danach machst du weiter.';
      _zeigeVor(s);
    } else {
      _rueckmeldung = hinweis;
    }
    unawaited(_sprich(_rueckmeldung!));
  }

  void _perleAntippen(int reihe, int index) {
    final s = _aktuell;
    if (s == null || _lumoIstDran || s.aktion.art != 'perlen' || _vorgezeigt) {
      return;
    }
    setState(() {
      final vorher = reihe == 1 ? _reihe1 : _reihe2;
      final neu = index < vorher ? index : index + 1;
      if (reihe == 1) {
        _reihe1 = neu;
      } else {
        _reihe2 = neu;
      }
      final z1 = s.aktion.wert('reihe1'), z2 = s.aktion.wert('reihe2');
      // Beim Wegnehmen (Minus) ist „zu weit“ die andere Richtung.
      final weg = z1 + z2 < _perlenVorher.$1 + _perlenVorher.$2;
      if (_reihe1 == z1 && _reihe2 == z2) {
        _geschafft();
      } else if (!weg && (_reihe1 > z1 || _reihe2 > z2)) {
        _daneben('Das sind zu viele. Schieb eine Perle zurück.');
      } else if (weg && (_reihe1 < z1 || _reihe2 < z2)) {
        _daneben(
            'Das sind zu viele weggeschoben. Schieb eine Perle wieder nach links.');
      } else {
        _rueckmeldung = null;
      }
    });
  }

  void _steinAntippen(int zahl) {
    final s = _aktuell;
    if (s == null || _lumoIstDran || s.aktion.art != 'huepfen' || _vorgezeigt) {
      return;
    }
    setState(() {
      final ziel = s.aktion.wert('nach');
      final vor = ziel >= s.aktion.wert('von');
      if (zahl == ziel) {
        _huepfe(s.aktion.wert('von'), ziel);
        _geschafft();
      } else if (vor) {
        _daneben(zahl < ziel
            ? 'Noch nicht ganz. Lumo muss weiter springen.'
            : 'Zu weit. Zähl die Sprünge noch einmal.');
      } else {
        _daneben(zahl > ziel
            ? 'Noch nicht ganz. Lumo muss weiter zurückspringen.'
            : 'Zu weit zurück. Zähl die Sprünge noch einmal.');
      }
    });
  }

  void _zerlegungWaehlen(List<int> teile) {
    final s = _aktuell;
    if (s == null ||
        _lumoIstDran ||
        s.aktion.art != 'zerlegen' ||
        _vorgezeigt) {
      return;
    }
    setState(() {
      if (teile[0] == s.aktion.wert('teil1') &&
          teile[1] == s.aktion.wert('teil2')) {
        _zerlegung = teile;
        _geschafft();
      } else {
        _daneben(
            'Mit ${teile[0]} wird die Reihe nicht genau 10. Probier es noch einmal.');
      }
    });
  }

  void _ergebnisWaehlen(int wert) {
    final s = _aktuell;
    if (s == null ||
        _lumoIstDran ||
        s.aktion.art != 'ergebnis' ||
        _vorgezeigt) {
      return;
    }
    setState(() {
      if (wert == s.aktion.wert('richtig')) {
        _gewaehlt = wert;
        _geschafft();
      } else {
        _daneben(
            'Schau noch einmal aufs Material und zähl in Zehnern und Einern.');
      }
    });
  }

  void _ziffer(int z) {
    if (_eingabe.length >= 3) return;
    setState(() => _eingabe = _eingabe == '0' ? '$z' : '$_eingabe$z');
  }

  void _loeschen() {
    if (_eingabe.isEmpty) return;
    setState(() => _eingabe = _eingabe.substring(0, _eingabe.length - 1));
  }

  /// Zwischenschritt: Erst nach der richtigen Zahl bewegt sich das Material.
  void _eingabeFertig() {
    final wert = int.tryParse(_eingabe);
    if (wert == null) return;
    if (_pruefPhase) {
      _pruefen(wert);
      return;
    }
    final s = _aktuell;
    if (s == null || s.frage == null || _lumoIstDran || _vorgezeigt) return;
    setState(() {
      if (wert == s.frage) {
        // Das Material bewegt sich jetzt; Lumo wartet, bis das Kind „Weiter“
        // tippt, damit die Bewegung in Ruhe zu sehen ist.
        _zeigeVor(s);
        _fehlversuche = 0;
        _lumo.cheer();
        _rueckmeldung = 'Genau! ${s.frage}.';
        unawaited(_sprich(_rueckmeldung!));
      } else {
        _eingabe = '';
        _daneben(s.hilfe ?? 'Schau noch einmal genau aufs Material.');
        if (_vorgezeigt) {
          _rueckmeldung =
              'Ich zeige es dir einmal: ${s.frage}. Danach machst du weiter.';
        }
      }
    });
  }

  /// Stufe 5: eigenständige ähnliche Aufgabe. Zwei Versuche ohne Material;
  /// danach darf das Kind Schritt für Schritt mit Lumo üben.
  void _pruefen(int wert) {
    final aufgabe = _plan.aufgabe;
    setState(() {
      _pruefVersuche++;
      final richtig = wert == aufgabe.ergebnis;
      if (richtig || _pruefVersuche >= 2) {
        _pruefRichtig = richtig;
        if (!_pruefGemeldet) {
          _pruefGemeldet = true;
          widget.onPruefung?.call(NachhilfePruefung(
            aufgabe: aufgabe,
            ergebnis: aufgabe.ergebnis,
            antwort: wert,
            richtig: richtig,
            versuche: _pruefVersuche,
          ));
        }
      }
      if (richtig) {
        _lumo.cheer();
        _fertig = true;
        _rueckmeldung = _pruefVersuche == 1
            ? 'Richtig! Das hast du ganz allein gelöst.'
            : 'Richtig! Beim zweiten Versuch hat es geklappt.';
        unawaited(_sprich('$_rueckmeldung ${_plan.abschluss}'));
        return;
      }
      _lumo.comfort();
      _eingabe = '';
      final fehler = widget.tutor.erkenneFehler(aufgabe, wert);
      _rueckmeldung = _pruefVersuche >= 2
          ? 'Noch nicht. Wir rechnen sie jetzt Schritt für Schritt zusammen.'
          : (fehler != NachhilfeFehlermuster.keines
              ? fehler.rueckmeldung
              : 'Noch nicht. Rechne noch einmal in Ruhe.');
      unawaited(_sprich(_rueckmeldung!));
    });
  }

  void _pruefMitLumo() {
    widget.onStopSpeech?.call();
    setState(() {
      _pruefPhase = false;
      _rueckmeldung = null;
      _schritt = 0;
      _betreteSchritt();
    });
  }

  void _stufeWaehlen(NachhilfeStufe stufe) {
    widget.onStopSpeech?.call();
    setState(() {
      _stufe = stufe;
      _rueckmeldung = null;
      _starte();
    });
  }

  void _andersZeigen() {
    widget.onStopSpeech?.call();
    setState(() {
      final wege = widget.tutor.wegeFuer(widget.aufgabe);
      final offen = wege.where((w) => !_gesehen.contains(w)).toList();
      _weg = offen.isNotEmpty
          ? offen.first
          : widget.tutor.naechsterWeg(widget.aufgabe, _weg);
      _rueckmeldung = null;
      _starte();
    });
  }

  void _wegWaehlen(NachhilfeWeg weg) {
    widget.onStopSpeech?.call();
    setState(() {
      _weg = weg;
      _rueckmeldung = null;
      _starte();
    });
  }

  bool get _mit3D =>
      widget.open3D != null && widget.aufgabe.typ == NachhilfeTyp.additionBis20;

  Future<void> _in3D() async {
    final open = widget.open3D;
    if (open == null || !_mit3D || _oeffne3D) return;
    final activity = NativeLearningActivity.fromNachhilfe(
      widget.aufgabe,
      startWeg: _weg,
      startStufe: _stufe,
      fehler: widget.fehler,
      tutor: widget.tutor,
    );
    if (activity == null) return;
    widget.onStopSpeech?.call();
    setState(() => _oeffne3D = true);
    var zurueck = false;
    try {
      zurueck = await open(context, activity);
    } finally {
      if (mounted) setState(() => _oeffne3D = false);
    }
    // „Zur Aufgabe“ in 3D führt direkt zurück zur selben Aufgabe. Startet die
    // 3D-Szene nicht, bleibt die 2D-Nachhilfe offen.
    if (zurueck && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = _aktuell;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1D3A),
        foregroundColor: Colors.white,
        title: Text('Nachhilfe mit Lumo · ${widget.aufgabe.text} = ?'),
        leading: IconButton(
          key: const ValueKey('nachhilfe-zurueck'),
          tooltip: 'Zurück zur Aufgabe',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B1D3A), Color(0xFF123B6B), Color(0xFF0E2A4E)],
            ),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final kopf = <Widget>[
              if (widget.lernstandSatz != null) ...[
                Text(widget.lernstandSatz!,
                    key: const ValueKey('nachhilfe-lernstand'),
                    style: const TextStyle(
                        color: Color(0xFFB4D7E9),
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
              ],
              _stufenLeiste(),
              const SizedBox(height: 10),
              // Die andere Erklärung (Stufe 2) braucht keinen Rechenweg.
              if (!_pruefPhase &&
                  _stufe != NachhilfeStufe.andereErklaerung) ...[
                _wegeLeiste(),
                const SizedBox(height: 14),
              ],
              _lumoBlase(s),
              if (_rueckmeldung != null) ...[
                const SizedBox(height: 10),
                Text(
                  _rueckmeldung!,
                  key: const ValueKey('nachhilfe-rueckmeldung'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFFFE08A),
                      fontSize: 19,
                      fontWeight: FontWeight.w800),
                ),
              ],
            ];
            final fuss = <Widget>[
              const SizedBox(height: 14),
              if (!_pruefPhase) _fortschritt(),
              const SizedBox(height: 14),
              _aktionen(s),
            ];
            const rand = EdgeInsets.fromLTRB(16, 12, 16, 24);
            // Aufgeklapptes Fold oder Tablet: Lumo links, Material rechts.
            if (constraints.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      padding: rand,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [...kopf, ...fuss],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      padding: rand,
                      child: _material(s),
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              padding: rand,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...kopf,
                  const SizedBox(height: 14),
                  _material(s),
                  ...fuss,
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Auf dem Handy eine waagrechte Leiste (spart Höhe für das Material),
  /// auf breiten Bildschirmen umbrechend.
  Widget _leiste({
    required List<Widget> children,
    double spacing = 8,
    double runSpacing = 8,
  }) {
    if (MediaQuery.sizeOf(context).width >= 760) {
      return Wrap(spacing: spacing, runSpacing: runSpacing, children: children);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final chip in children)
          Padding(padding: EdgeInsets.only(right: spacing), child: chip),
      ]),
    );
  }

  /// Hilfeleiter: fünf runde Stufen (je 52 dp) und der Name der aktuellen.
  Widget _stufenLeiste() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final stufe in NachhilfeStufe.values)
              Tooltip(
                message: '${stufe.index + 1}. ${stufe.titel}',
                child: Semantics(
                  button: true,
                  selected: stufe == _stufe,
                  label: 'Hilfestufe ${stufe.index + 1}: ${stufe.titel}',
                  child: InkResponse(
                    key: ValueKey('nachhilfe-stufe-${stufe.name}'),
                    onTap: () => _stufeWaehlen(stufe),
                    radius: 30,
                    child: AnimatedContainer(
                      duration: widget.reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 250),
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stufe == _stufe
                            ? const Color(0xFFFFC94A)
                            : stufe.index < _stufe.index
                                ? const Color(0xFF2B6E8F)
                                : const Color(0xFF1D415B),
                        border: Border.all(
                            color: const Color(0xFF73D4ED),
                            width: stufe == _stufe ? 3 : 1.5),
                      ),
                      child: ExcludeSemantics(
                        child: Text('${stufe.index + 1}',
                            style: TextStyle(
                                color: stufe == _stufe
                                    ? const Color(0xFF10243A)
                                    : Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 6),
          Text('Stufe ${_stufe.index + 1} von 5: ${_stufe.titel}',
              key: const ValueKey('nachhilfe-stufe-titel'),
              style: const TextStyle(
                  color: Color(0xFFFFE08A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ],
      );

  Widget _wegeLeiste() => _leiste(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final weg in widget.tutor.wegeFuer(widget.aufgabe))
            ChoiceChip(
              key: ValueKey('nachhilfe-weg-${weg.name}'),
              avatar: Icon(_wegIcon(weg),
                  size: 20,
                  color: weg == _weg
                      ? const Color(0xFF10243A)
                      : const Color(0xFF73D4ED)),
              label: Text(weg.titel),
              selected: weg == _weg,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              labelStyle: TextStyle(
                  color: weg == _weg ? const Color(0xFF10243A) : Colors.white,
                  fontWeight: FontWeight.w700),
              selectedColor: const Color(0xFF73D4ED),
              backgroundColor: const Color(0xFF16324F),
              onSelected: (_) => _wegWaehlen(weg),
            ),
        ],
      );

  IconData _wegIcon(NachhilfeWeg weg) => switch (weg) {
        NachhilfeWeg.rechenrahmen => Icons.blur_linear_rounded,
        NachhilfeWeg.zahlenstrahl => Icons.linear_scale_rounded,
        NachhilfeWeg.zerlegen => Icons.call_split_rounded,
        NachhilfeWeg.verdoppeln => Icons.filter_2_rounded,
        NachhilfeWeg.tauschen => Icons.swap_horiz_rounded,
        NachhilfeWeg.stangen => Icons.view_week_rounded,
        NachhilfeWeg.punktefeld => Icons.grid_on_rounded,
        NachhilfeWeg.kernaufgabe => Icons.star_rounded,
      };

  Widget _lumoBlase(NachhilfeSchritt? s) {
    final text = _pruefPhase
        ? (_fertig ? '${_plan.lob}\n${_plan.abschluss}' : _plan.einleitung)
        : s == null
            ? '${_plan.lob}\n${_plan.abschluss}'
            : (_schritt == 0 ? '${_plan.einleitung}\n${s.text}' : s.text);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LumoCharacter(
          pose: _fertig
              ? LumoDesignFoxPose.cheer
              : LumoDesignFoxPose.teacherStick,
          size: MediaQuery.sizeOf(context).width < 520 ? 76 : 96,
          controller: _lumo,
          reduceMotion: widget.reduceMotion,
          intro: false,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _lumoIstDran
                      ? const Color(0xFFFFC94A)
                      : const Color(0xFF73D4ED),
                  width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pruefPhase
                      ? (_fertig ? 'Geschafft!' : 'Jetzt ganz allein')
                      : s == null
                          ? 'Geschafft!'
                          : (_lumoIstDran ? 'Lumo zeigt' : 'Du bist dran'),
                  style: const TextStyle(
                      color: Color(0xFF187CAD),
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(text,
                    key: const ValueKey('nachhilfe-text'),
                    style: const TextStyle(
                        color: Color(0xFF12366A),
                        fontSize: 19,
                        height: 1.3,
                        fontWeight: FontWeight.w600)),
                if (widget.onSpeak != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      key: const ValueKey('nachhilfe-vorlesen'),
                      tooltip: 'Vorlesen',
                      iconSize: 28,
                      color: const Color(0xFF187CAD),
                      icon: const Icon(Icons.volume_up_rounded),
                      onPressed: () => unawaited(_sprich(text)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _material(NachhilfeSchritt? s) {
    final art = _materialArt();
    final reduce = widget.reduceMotion;
    final eingabeOffen = _pruefPhase
        ? !_fertig && (_pruefRichtig == null)
        : s != null && s.frage != null && !_lumoIstDran && !_vorgezeigt;
    return Container(
      key: const ValueKey('nachhilfe-material'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2744),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B7FA6), width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${_plan.aufgabe.text} = ?',
            key: const ValueKey('nachhilfe-aufgabe'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
          ),
          if (_plan.anZwilling)
            Text(
              _pruefPhase
                  ? 'Prüfaufgabe – ganz allein'
                  : 'Übungsaufgabe – fast wie ${widget.aufgabe.text}',
              key: const ValueKey('nachhilfe-zwilling-hinweis'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFB4D7E9),
                  fontSize: 17,
                  fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 12),
          if (!_pruefPhase) ...[
            if (art == 'perlen') _rechenrahmen(),
            if (art == 'huepfen' && _plan.aufgabe.typ.bis100)
              _zahlenstrahl100(),
            if (art == 'huepfen' && !_plan.aufgabe.typ.bis100) _zahlenstrahl(),
            if (art == 'stangen' && _stangen != null)
              NachhilfeStangenFeld(
                  // Tauschaufgabe 7 + 45: Lumo legt 45 hin, 7 kommt dazu.
                  aufgabe: _plan.weg == NachhilfeWeg.tauschen &&
                          _plan.aufgabe.typ == NachhilfeTyp.additionBis100
                      ? NachhilfeAufgabe.additionBis100(
                          _plan.aufgabe.b, _plan.aufgabe.a)!
                      : _plan.aufgabe,
                  zustand: _stangen!,
                  reduceMotion: reduce),
            if (art == 'punkte' && _punkte != null)
              NachhilfePunktefeld(zustand: _punkte!, reduceMotion: reduce),
            if (art == 'bild' && _bild != null)
              NachhilfeBildkarte(bild: _bild!, reduceMotion: reduce),
            if (s?.aktion.art == 'zerlegen' || _zerlegung != null) _zerlegen(s),
            if (s?.aktion.art == 'ergebnis') ...[
              const SizedBox(height: 12),
              _ergebnis(s!),
            ],
          ],
          if (eingabeOffen) ...[
            const SizedBox(height: 12),
            NachhilfeZiffernblock(
              kompakt: MediaQuery.sizeOf(context).width < 520,
              eingabe: _eingabe,
              onZiffer: _ziffer,
              onLoeschen: _loeschen,
              onFertig: _eingabeFertig,
            ),
          ],
        ],
      ),
    );
  }

  static const _materialArten = {
    'perlen',
    'huepfen',
    'stangen',
    'punkte',
    'bild'
  };

  /// Welches Material gerade sichtbar ist (das zuletzt benutzte bleibt stehen).
  String _materialArt() {
    for (var i = _schritt.clamp(0, _plan.schritte.length - 1); i >= 0; i--) {
      final art = _plan.schritte[i].aktion.art;
      if (_materialArten.contains(art)) return art;
    }
    for (final schritt in _plan.schritte) {
      final art = schritt.aktion.art;
      if (_materialArten.contains(art)) return art;
    }
    return 'perlen';
  }

  /// Zahlenstrahl bis 100: Ausschnitt um alle Sprünge des Plans.
  Widget _zahlenstrahl100() {
    final werte = <int>[
      for (final s in _plan.schritte)
        if (s.aktion.art == 'huepfen') ...[
          s.aktion.wert('von'),
          s.aktion.wert('nach')
        ]
    ];
    var von = (werte.reduce((x, y) => x < y ? x : y) ~/ 10) * 10;
    var bis = ((werte.reduce((x, y) => x > y ? x : y) + 9) ~/ 10) * 10;
    if (bis - von < 10) bis = von + 10;
    if (bis > 100) {
      bis = 100;
      von = von.clamp(0, 90);
    }
    return NachhilfeZahlenstrahl(
      von: von,
      bis: bis,
      position: _position,
      spruenge: List.unmodifiable(_spruenge),
      reduceMotion: widget.reduceMotion,
    );
  }

  Widget _rechenrahmen() {
    Widget reihe(int nummer, int links) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LayoutBuilder(builder: (context, constraints) {
            final breite = constraints.maxWidth;
            final perle = ((breite - 40) / 12).clamp(22.0, 40.0);
            double mitte(int i) =>
                (i < links ? i * perle : breite - (10 - i) * perle) + perle / 2;
            // Die ganze Reihe ist Tippfläche (52 dp hoch, volle Breite): ein
            // Tipp zwischen zwei Perlen wählt die nächstgelegene.
            return GestureDetector(
              key: ValueKey('nachhilfe-reihe-$nummer'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                var beste = 0;
                for (var i = 1; i < 10; i++) {
                  if ((mitte(i) - details.localPosition.dx).abs() <
                      (mitte(beste) - details.localPosition.dx).abs()) {
                    beste = i;
                  }
                }
                _perleAntippen(nummer, beste);
              },
              child: SizedBox(
                height: 52,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 25,
                      child:
                          Container(height: 3, color: const Color(0xFFB7C7D6)),
                    ),
                    for (var i = 0; i < 10; i++)
                      AnimatedPositioned(
                        duration: widget.reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 380),
                        curve: Curves.easeOutBack,
                        left: i < links ? i * perle : breite - (10 - i) * perle,
                        top: 26 - perle / 2,
                        child: GestureDetector(
                          key: ValueKey('nachhilfe-perle-$nummer-$i'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _perleAntippen(nummer, i),
                          child: SizedBox(
                            width: perle.clamp(24.0, 48.0),
                            height: 48,
                            child: Center(
                              child: Container(
                                width: perle - 2,
                                height: perle - 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    center: const Alignment(-0.35, -0.4),
                                    colors: i < 5
                                        ? const [
                                            Color(0xFFFF8A80),
                                            Color(0xFFD32F2F)
                                          ]
                                        : const [
                                            Color(0xFFFFFFFF),
                                            Color(0xFFC9D6E3)
                                          ],
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x55000000),
                                        blurRadius: 4,
                                        offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        );
    return Column(
      children: [
        reihe(1, _reihe1),
        reihe(2, _reihe2),
        const SizedBox(height: 6),
        Text(
          'Links: $_reihe1 + $_reihe2 Perlen',
          key: const ValueKey('nachhilfe-perlen-stand'),
          style: const TextStyle(color: Color(0xFFB4D7E9), fontSize: 16),
        ),
      ],
    );
  }

  Widget _zahlenstrahl() => SizedBox(
        height: 104,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 21,
          itemBuilder: (context, zahl) {
            final hier = zahl == _position;
            final besucht = _spruenge.any((sp) => sp.$2 == zahl);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 40,
                    child: hier
                        ? const Icon(Icons.pets_rounded,
                            color: Color(0xFFFF9F43),
                            size: 34,
                            semanticLabel: 'Lumo steht hier')
                        : null,
                  ),
                  InkWell(
                    key: ValueKey('nachhilfe-stein-$zahl'),
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _steinAntippen(zahl),
                    child: Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: zahl == 10
                            ? const Color(0xFFFFC94A)
                            : (besucht
                                ? const Color(0xFF73D4ED)
                                : const Color(0xFF1D415B)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color:
                                hier ? Colors.white : const Color(0xFF4F9BB8),
                            width: hier ? 3 : 2),
                      ),
                      child: Text('$zahl',
                          style: TextStyle(
                              color: zahl == 10 || besucht
                                  ? const Color(0xFF10243A)
                                  : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

  Widget _zerlegen(NachhilfeSchritt? s) {
    final aktion = s?.aktion.art == 'zerlegen'
        ? s!.aktion
        : _plan.schritte.firstWhere((x) => x.aktion.art == 'zerlegen').aktion;
    final ganz = aktion.wert('ganz');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Text('Zahlenhaus: $ganz = ? + ?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final teile in aktion.zerlegungen)
                ChoiceChip(
                  key: ValueKey('nachhilfe-zerlegung-${teile[0]}-${teile[1]}'),
                  label: Text('${teile[0]} und ${teile[1]}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800)),
                  selected: _zerlegung != null &&
                      _zerlegung![0] == teile[0] &&
                      _zerlegung![1] == teile[1],
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  selectedColor: const Color(0xFFFFC94A),
                  onSelected: (_) => _zerlegungWaehlen(teile),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ergebnis(NachhilfeSchritt s) => Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final wert in s.aktion.optionen)
            SizedBox(
              width: 76,
              height: 64,
              child: FilledButton(
                key: ValueKey('nachhilfe-option-$wert'),
                style: FilledButton.styleFrom(
                  backgroundColor: _gewaehlt == wert
                      ? const Color(0xFF3CCB7F)
                      : const Color(0xFF1D415B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _ergebnisWaehlen(wert),
                child: Text('$wert',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      );

  Widget _fortschritt() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _plan.schritte.length; i++)
            Container(
              width: 34,
              height: 10,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: i < _schritt
                    ? const Color(0xFF3CCB7F)
                    : (i == _schritt
                        ? const Color(0xFFFFC94A)
                        : const Color(0xFF2B4D6B)),
              ),
            ),
        ],
      );

  Widget _aktionen(NachhilfeSchritt? s) {
    final weiterMoeglich =
        !_pruefPhase && s != null && (_lumoIstDran || _vorgezeigt);
    final pruefNochmal = _pruefPhase && _pruefRichtig == false;
    final naechste = widget.tutor.naechsteStufe(_stufe);
    ButtonStyle stil(Color farbe) => OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: Colors.white,
          backgroundColor: farbe,
          side: const BorderSide(color: Color(0xFF73D4ED)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (weiterMoeglich)
          FilledButton.icon(
            key: const ValueKey('nachhilfe-weiter'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              backgroundColor: const Color(0xFFFFC94A),
              foregroundColor: const Color(0xFF10243A),
            ),
            onPressed: _weiter,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Weiter',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        if (pruefNochmal)
          FilledButton.icon(
            key: const ValueKey('nachhilfe-pruef-mit-lumo'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              backgroundColor: const Color(0xFFFFC94A),
              foregroundColor: const Color(0xFF10243A),
            ),
            onPressed: _pruefMitLumo,
            icon: const Icon(Icons.school_rounded),
            label: const Text('Mit Lumo Schritt für Schritt',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        if (_fertig)
          FilledButton.icon(
            key: const ValueKey('nachhilfe-zur-aufgabe'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              backgroundColor: const Color(0xFF3CCB7F),
              foregroundColor: const Color(0xFF10243A),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Zur Aufgabe',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        if (naechste != null)
          OutlinedButton.icon(
            key: const ValueKey('nachhilfe-mehr-hilfe'),
            style: stil(const Color(0xFF12366A)),
            onPressed: () => _stufeWaehlen(naechste),
            icon: const Icon(Icons.support_rounded),
            label: Text('Mehr Hilfe: ${naechste.titel}'),
          ),
        if (_stufe != NachhilfeStufe.andereErklaerung)
          OutlinedButton.icon(
            key: const ValueKey('nachhilfe-anders'),
            style: stil(const Color(0xFF12366A)),
            onPressed: _andersZeigen,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Anders zeigen'),
          ),
        if (_mit3D)
          OutlinedButton.icon(
            key: const ValueKey('nachhilfe-3d'),
            style: stil(const Color(0xFF2A1F5C)),
            onPressed: _oeffne3D ? null : () => unawaited(_in3D()),
            icon: const Icon(Icons.view_in_ar_rounded),
            label: Text(_oeffne3D ? '3D wird geöffnet …' : 'In 3D mit Lumo'),
          ),
      ],
    );
  }
}
