import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/tutoring/fach_nachhilfe.dart';
import '../../domain/tutoring/lumo_nachhilfe.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../widgets/fox/lumo_character.dart';

/// Nachhilfe mit Lumo für Englisch, Lesen und Sachunterricht – fünf Stufen wie
/// die Mathe-Nachhilfe: kleiner Tipp, anders erklärt, Lumo zeigt, gemeinsam,
/// selbst prüfen. Die Originalaufgabe wird hier nie beantwortet; das Kind
/// kehrt zur Aufgabe zurück. Die Seite öffnet nur, wenn Hilfe erlaubt ist
/// (nie in Tests und Schularbeiten). Kamera und Mikrofon bleiben aus.
class FachNachhilfeScreen extends StatefulWidget {
  const FachNachhilfeScreen({
    super.key,
    required this.aufgabe,
    this.beispiel,
    this.pruefung,
    this.startStufe = NachhilfeStufe.hinweis,
    this.reduceMotion = false,
    this.onSpeak,
    this.onStopSpeech,
    this.onPruefung,
    this.onMethode,
    this.lernstandSatz,
    this.tutor = const FachNachhilfe(),
  });

  final FachAufgabe aufgabe;

  /// Andere ähnliche Aufgabe, an der Lumo es ganz zeigen darf (Englisch).
  final FachAufgabe? beispiel;

  /// Ähnliche, eigenständige Aufgabe für „Selbst prüfen“.
  final FachAufgabe? pruefung;
  final NachhilfeStufe startStufe;
  final bool reduceMotion;

  /// Vorhandene deutsche Stimme; [langsam] nutzt den „Langsamer“-Weg.
  final Future<void> Function(String text, {bool langsam})? onSpeak;
  final VoidCallback? onStopSpeech;

  /// Ergebnis der Vergleichsaufgabe, genau einmal je Aufgabe.
  final ValueChanged<FachPruefung>? onPruefung;

  /// Jede gezeigte Erklärweise (für den Methodenwechsel der Übung).
  final ValueChanged<String>? onMethode;
  final String? lernstandSatz;
  final FachNachhilfe tutor;

  @override
  State<FachNachhilfeScreen> createState() => _FachNachhilfeScreenState();
}

class _FachNachhilfeScreenState extends State<FachNachhilfeScreen>
    with SingleTickerProviderStateMixin {
  final LumoCharacterController _lumo = LumoCharacterController();
  late final AnimationController _bewegung = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2600));
  late NachhilfeStufe _stufe;
  late FachPlan _plan;
  final Set<NachhilfeStufe> _gesehen = <NachhilfeStufe>{};
  String? _rueckmeldung;

  // Ausschließen
  final Set<String> _ausgeschlossen = <String>{};

  // Satz finden
  int? _satzGewaehlt;
  bool _satzRichtig = false;

  // Vorlesen
  Timer? _vorleseTakt;
  int? _vorleseSatz;

  // Prüfung
  int _pruefVersuche = 0;
  String? _pruefGewaehlt;
  bool _pruefFertig = false;
  bool _pruefGemeldet = false;

  @override
  void initState() {
    super.initState();
    _stufe = widget.startStufe;
    _starte();
  }

  @override
  void dispose() {
    _vorleseTakt?.cancel();
    widget.onStopSpeech?.call();
    _bewegung.dispose();
    _lumo.dispose();
    super.dispose();
  }

  void _starte() {
    _plan = widget.tutor.plan(widget.aufgabe, _stufe,
        beispiel: widget.beispiel, pruefung: widget.pruefung);
    _gesehen.add(_stufe);
    widget.onMethode?.call(_plan.methode);
    _ausgeschlossen.clear();
    _satzGewaehlt = null;
    _satzRichtig = false;
    _vorleseTakt?.cancel();
    _vorleseSatz = null;
    _pruefVersuche = 0;
    _pruefGewaehlt = null;
    _pruefFertig = false;
    _pruefGemeldet = false;
    if (widget.reduceMotion) {
      _bewegung.value = 1;
    } else {
      _bewegung.forward(from: 0);
    }
    _lumo.talk();
    unawaited(_sprich(_plan.sprechText, langsam: _plan.langsam));
    if (_plan.material.art == FachMaterialArt.vorlesen) _vorlesen();
  }

  Future<void> _sprich(String text, {bool langsam = false}) async {
    final speak = widget.onSpeak;
    if (speak == null || text.trim().isEmpty) return;
    try {
      await speak(text, langsam: langsam);
    } catch (_) {
      // Die Stimme ist eine Zugabe; der Text bleibt sichtbar.
    }
  }

  /// Satz für Satz aufleuchten lassen – im Tempo der langsamen Stimme.
  /// Wird innerhalb von setState (oder initState) aufgerufen.
  void _vorlesen() {
    _vorleseTakt?.cancel();
    final saetze = _plan.material.saetze;
    if (saetze.isEmpty) return;
    _vorleseSatz = 0;
    if (widget.reduceMotion) return;
    _vorleseTakt = Timer.periodic(const Duration(milliseconds: 2600), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        final next = (_vorleseSatz ?? 0) + 1;
        if (next >= saetze.length) {
          t.cancel();
        } else {
          _vorleseSatz = next;
        }
      });
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

  NachhilfeStufe? get _naechste {
    final i = _stufe.index + 1;
    return i < NachhilfeStufe.values.length ? NachhilfeStufe.values[i] : null;
  }

  /// Methodenwechsel nach einer nicht gelösten Prüfaufgabe: eine Erklärweise,
  /// die noch nicht gezeigt wurde, sonst „gemeinsam“.
  NachhilfeStufe get _andereErklaerweise {
    for (final s in const [
      NachhilfeStufe.andereErklaerung,
      NachhilfeStufe.vorzeigen,
      NachhilfeStufe.teilschritt,
    ]) {
      if (!_gesehen.contains(s)) return s;
    }
    return NachhilfeStufe.teilschritt;
  }

  void _ausschliessen(String wahl) {
    final m = _plan.material;
    if (_ausgeschlossen.contains(wahl) || _genugAusgeschlossen) return;
    setState(() {
      if (m.falsche.contains(wahl)) {
        _ausgeschlossen.add(wahl);
        _lumo.cheer();
        _rueckmeldung = _genugAusgeschlossen
            ? 'Stark! Jetzt bleiben nur noch wenige. Die Entscheidung triffst '
                'du in deiner Aufgabe.'
            : 'Genau, „$wahl“ passt nicht. Welche noch?';
      } else {
        _lumo.comfort();
        // Die richtige Antwort wird nie bestätigt – nur zum Nachdenken.
        _rueckmeldung =
            'Bist du dir sicher? Lies die Frage noch einmal. Streiche lieber '
            'eine Antwort, die ganz sicher nicht passt.';
      }
    });
    unawaited(_sprich(widget.tutor.sprechbar(_rueckmeldung!, widget.aufgabe)));
  }

  bool get _genugAusgeschlossen {
    final falsche = _plan.material.falsche.length;
    return falsche > 0 && _ausgeschlossen.length >= math.min(2, falsche);
  }

  void _satzWaehlen(int index) {
    if (_satzRichtig) return;
    setState(() {
      _satzGewaehlt = index;
      if (index == _plan.material.richtigerSatz) {
        _satzRichtig = true;
        _lumo.cheer();
        _rueckmeldung = 'Genau, dieser Satz hilft dir. Jetzt suchst du die '
            'Antwort in deiner Aufgabe.';
      } else {
        _lumo.comfort();
        _rueckmeldung =
            'Lies diesen Satz noch einmal: Hilft er bei der Frage? Probier '
            'einen anderen.';
      }
    });
    unawaited(_sprich(_rueckmeldung!));
  }

  void _pruefen(String wahl) {
    final p = _plan.aufgabe;
    if (_pruefFertig || _plan.material.auswahl.isEmpty) return;
    setState(() {
      _pruefVersuche++;
      _pruefGewaehlt = wahl;
      final richtig = wahl == p.antwort;
      if ((richtig || _pruefVersuche >= 2) && !_pruefGemeldet) {
        _pruefGemeldet = true;
        widget.onPruefung?.call(FachPruefung(
          aufgabe: p,
          antwort: wahl,
          versuche: _pruefVersuche,
          methode: _gesehen.length > 1
              ? FachNachhilfe.methodeFuer(widget.aufgabe,
                  _gesehen.where((s) => s != NachhilfeStufe.ueben).lastOrNull ??
                      NachhilfeStufe.hinweis)
              : 'pruefen',
        ));
      }
      if (richtig) {
        _pruefFertig = true;
        _lumo.cheer();
        _rueckmeldung = _pruefVersuche == 1
            ? 'Richtig! Das hast du ganz allein gelöst.'
            : 'Richtig! Beim zweiten Versuch hat es geklappt.';
      } else if (_pruefVersuche >= 2) {
        _pruefFertig = true;
        _lumo.comfort();
        _rueckmeldung = 'Noch nicht. Wir probieren es anders – Lumo erklärt '
            'es dir auf eine neue Weise.';
      } else {
        _lumo.comfort();
        _rueckmeldung = 'Noch nicht. Lies noch einmal in Ruhe.';
      }
    });
    unawaited(_sprich(_rueckmeldung!));
  }

  @override
  Widget build(BuildContext context) {
    final fach = widget.aufgabe.fachName;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1D3A),
        foregroundColor: Colors.white,
        title: Text('Nachhilfe · $fach',
            key: const ValueKey('fach-appbar-titel')),
        leading: IconButton(
          key: const ValueKey('fach-zurueck'),
          tooltip: 'Zurück zur Aufgabe',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: DecoratedBox(
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
                    key: const ValueKey('fach-lernstand'),
                    style: const TextStyle(
                        color: Color(0xFFB4D7E9),
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
              ],
              _stufenLeiste(),
              const SizedBox(height: 12),
              _lumoBlase(),
              if (_rueckmeldung != null) ...[
                const SizedBox(height: 10),
                Text(_rueckmeldung!,
                    key: const ValueKey('fach-rueckmeldung'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFFFFE08A),
                        fontSize: 19,
                        fontWeight: FontWeight.w800)),
              ],
            ];
            final material = _material();
            final aktionen = _aktionen();
            const rand = EdgeInsets.fromLTRB(16, 12, 16, 24);
            if (constraints.maxWidth >= 760) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: _spalte(rand, kopf)),
                  // Material und Knöpfe nebeneinander sichtbar, ohne Scrollen.
                  Expanded(
                    flex: 6,
                    child: _spalte(rand, [
                      material,
                      const SizedBox(height: 16),
                      aktionen,
                    ]),
                  ),
                ],
              );
            }
            return _spalte(rand, [
              ...kopf,
              const SizedBox(height: 14),
              material,
              const SizedBox(height: 16),
              aktionen,
            ]);
          }),
        ),
      ),
    );
  }

  /// Scrollende Spalte; alle Teile bleiben gebaut (Ziffern, Sätze, Knöpfe).
  Widget _spalte(EdgeInsets rand, List<Widget> kinder) => SingleChildScrollView(
        padding: rand,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: kinder),
      );

  Widget _stufenLeiste() => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final stufe in NachhilfeStufe.values)
          Tooltip(
            message: '${stufe.index + 1}. ${stufe.titel}',
            child: Semantics(
              button: true,
              selected: stufe == _stufe,
              label: 'Hilfestufe ${stufe.index + 1}: ${stufe.titel}',
              child: InkResponse(
                key: ValueKey('fach-stufe-${stufe.name}'),
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
                        : _gesehen.contains(stufe)
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
      ]);

  Widget _lumoBlase() {
    final breit = MediaQuery.sizeOf(context).width;
    final englisch = widget.aufgabe.fach == FachNachhilfeFach.englisch;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LumoCharacter(
          key: const ValueKey('fach-lumo'),
          pose: _pruefFertig && _plan.stufe == NachhilfeStufe.ueben
              ? LumoDesignFoxPose.cheer
              : LumoDesignFoxPose.teacherStick,
          size: breit < 520 ? 76 : 110,
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
              border: Border.all(color: const Color(0xFF73D4ED), width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_stufe.index + 1}. ${_plan.titel}',
                    key: const ValueKey('fach-titel'),
                    style: const TextStyle(
                        color: Color(0xFF1B5E7A),
                        fontSize: 16,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(_plan.text,
                    key: const ValueKey('fach-text'),
                    style: const TextStyle(
                        color: Color(0xFF10243A),
                        fontSize: 19,
                        height: 1.35,
                        fontWeight: FontWeight.w700)),
                if (widget.onSpeak != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const ValueKey('fach-anhoeren'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: const Color(0xFF1B5E7A)),
                    onPressed: () {
                      if (_plan.material.art == FachMaterialArt.vorlesen) {
                        setState(_vorlesen);
                      }
                      unawaited(
                          _sprich(_plan.sprechText, langsam: _plan.langsam));
                    },
                    icon: Icon(_plan.langsam
                        ? Icons.slow_motion_video_rounded
                        : Icons.volume_up_rounded),
                    label: Text(_plan.langsam ? 'Langsam vorlesen' : 'Anhören'),
                  ),
                ],
                if (englisch)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'Lumos Stimme spricht Deutsch. Englische Wörter zeigt '
                      'Lumo nur geschrieben – sprich sie so, wie du sie aus der '
                      'Schule kennst.',
                      key: ValueKey('fach-stimme-hinweis'),
                      style: TextStyle(
                          color: Color(0xFF41657A),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _aktionen() {
    final naechste = _naechste;
    final pruefungNichtGeschafft = _plan.stufe == NachhilfeStufe.ueben &&
        _pruefFertig &&
        _pruefGewaehlt != _plan.aufgabe.antwort;
    ButtonStyle gold() => FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: const Color(0xFFFFC94A),
          foregroundColor: const Color(0xFF10243A),
        );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        if (pruefungNichtGeschafft)
          FilledButton.icon(
            key: const ValueKey('fach-anders-erklaeren'),
            style: gold(),
            onPressed: () => _stufeWaehlen(_andereErklaerweise),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Anders erklärt',
                style: TextStyle(fontWeight: FontWeight.w800)),
          )
        else if (naechste != null)
          FilledButton.icon(
            key: const ValueKey('fach-mehr-hilfe'),
            style: gold(),
            onPressed: () => _stufeWaehlen(naechste),
            icon: const Icon(Icons.lightbulb_rounded),
            label: Text(
                naechste == NachhilfeStufe.ueben
                    ? 'Ähnliche Aufgabe allein'
                    : 'Mehr Hilfe: ${naechste.titel}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        FilledButton.icon(
          key: const ValueKey('fach-zur-aufgabe'),
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
      ],
    );
  }

  // ---- Material ---------------------------------------------------------

  Widget _karte({required Widget child, Key? key, Color? rand}) => Container(
        key: key,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xCC0E2744),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: rand ?? const Color(0xFF3B7FA6), width: 2),
        ),
        child: child,
      );

  /// Gestaffeltes Einblenden: Teil [i] von [n].
  Widget _erscheint(int i, int n, Widget child) => AnimatedBuilder(
        animation: _bewegung,
        builder: (context, child) {
          final start = n <= 1 ? 0.0 : i / (n + 1);
          final t = ((_bewegung.value - start) / (1 / (n + 1)))
              .clamp(0.0, 1.0);
          final kurve = Curves.easeOutBack.transform(t);
          return Opacity(
            opacity: t,
            child: Transform.scale(scale: .7 + .3 * kurve, child: child),
          );
        },
        child: child,
      );

  Widget _material() {
    final m = _plan.material;
    final aufgabeText = _aufgabeKarte();
    final Widget inhalt = switch (m.art) {
      FachMaterialArt.wort => _wort(m),
      FachMaterialArt.bildkarten => _bildkarten(m),
      FachMaterialArt.szene => _szene(m),
      FachMaterialArt.markierung => _markierung(m),
      FachMaterialArt.laute => _laute(m),
      FachMaterialArt.vorlesen => _vorlesenMaterial(m),
      FachMaterialArt.satzWahl => _satzWahl(m),
      FachMaterialArt.ausschliessen => _ausschliessenMaterial(m),
      FachMaterialArt.schaubild => _schaubild(m),
      FachMaterialArt.alltag => _alltag(),
      FachMaterialArt.pruefen => _pruefenMaterial(m),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (aufgabeText != null) ...[aufgabeText, const SizedBox(height: 12)],
        KeyedSubtree(key: ValueKey('fach-material-${m.art.name}'), child: inhalt),
      ],
    );
  }

  /// Die eigene Aufgabe bleibt sichtbar (außer bei der Prüfaufgabe und beim
  /// Lesen, wo der Text selbst das Material ist).
  Widget? _aufgabeKarte() {
    final art = _plan.material.art;
    if (art == FachMaterialArt.pruefen ||
        art == FachMaterialArt.vorlesen ||
        art == FachMaterialArt.satzWahl ||
        art == FachMaterialArt.laute ||
        art == FachMaterialArt.markierung) {
      return null;
    }
    return _karte(
      key: const ValueKey('fach-aufgabe'),
      child: Text('Deine Aufgabe: ${widget.aufgabe.prompt}',
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _wort(FachMaterial m) {
    final wort = m.wort ?? '';
    final zeichen = wort.characters.toList();
    return _karte(
      key: const ValueKey('fach-wort'),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          for (var i = 0; i < zeichen.length; i++)
            _erscheint(
              i,
              zeichen.length,
              Container(
                width: zeichen[i] == ' ' ? 18 : 48,
                height: 60,
                alignment: Alignment.center,
                decoration: zeichen[i] == ' '
                    ? null
                    : BoxDecoration(
                        color: const Color(0xFFFFF6D8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFC94A), width: 2),
                      ),
                child: Text(zeichen[i],
                    style: const TextStyle(
                        color: Color(0xFF10243A),
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bild(FachBildkarte k, {double gross = 54}) {
    if (k.farbe != null) {
      return Container(
        width: gross,
        height: gross,
        decoration: BoxDecoration(
          color: Color(k.farbe!),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70, width: 2),
        ),
      );
    }
    if (k.menge != null) {
      final n = k.menge!;
      return SizedBox(
        width: gross * 1.6,
        child: n == 0
            ? Center(
                child: Container(
                  width: gross * .6,
                  height: gross * .6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3)),
                ),
              )
            : Wrap(
                alignment: WrapAlignment.center,
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (var i = 0; i < n; i++)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: i < 5 || (i >= 10 && i < 15)
                              ? const Color(0xFFFF7A59)
                              : const Color(0xFFFFE08A),
                          shape: BoxShape.circle),
                    ),
                ],
              ),
      );
    }
    // Ohne Bild nur das Wort – kein Fragezeichen, das nach Lösung aussieht.
    if (k.bild == null) return SizedBox(height: gross * .3);
    return Text(k.bild!, style: TextStyle(fontSize: gross * .8));
  }

  Widget _bildkarten(FachMaterial m) => _karte(
        key: const ValueKey('fach-bildkarten'),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < m.karten.length; i++)
              _erscheint(
                i,
                m.karten.length,
                Container(
                  key: ValueKey('fach-bildkarte-${m.karten[i].wort}'),
                  width: 140,
                  constraints: const BoxConstraints(minHeight: 120),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16406A),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: const Color(0xFF73D4ED), width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _bild(m.karten[i]),
                      const SizedBox(height: 8),
                      Text(m.karten[i].wort,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _szene(FachMaterial m) => _karte(
        key: const ValueKey('fach-szene'),
        child: AnimatedBuilder(
          animation: _bewegung,
          builder: (context, _) {
            final hops = widget.reduceMotion
                ? 0.0
                : math.sin(_bewegung.value * math.pi * 3).abs() * 8;
            return Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 16,
              runSpacing: 12,
              children: [
                Transform.translate(
                  offset: Offset(0, -hops),
                  child: const LumoCharacter(
                    pose: LumoDesignFoxPose.bookPoint,
                    size: 96,
                    intro: false,
                    idleHops: false,
                    reduceMotion: true,
                  ),
                ),
                if (m.szeneBild != null)
                  Opacity(
                    opacity: _bewegung.value.clamp(0.0, 1.0),
                    child: _bild(m.szeneBild!, gross: 76),
                  ),
                if (m.sprechblase != null)
                  Container(
                    key: const ValueKey('fach-sprechblase'),
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFFC94A), width: 3),
                    ),
                    child: Text('„${m.sprechblase}“',
                        style: const TextStyle(
                            color: Color(0xFF10243A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ),
              ],
            );
          },
        ),
      );

  /// Text mit hervorgehobenen Wörtern oder Buchstabengruppen.
  Widget _hervorgehoben(String text, List<String> markiert,
      {double groesse = 21, Key? key, bool aktiv = false}) {
    final spans = <TextSpan>[];
    final klein = text.toLowerCase();
    var i = 0;
    final teile = [for (final m in markiert) if (m.isNotEmpty) m.toLowerCase()]
      ..sort((a, b) => b.length.compareTo(a.length));
    while (i < text.length) {
      String? treffer;
      for (final t in teile) {
        if (klein.startsWith(t, i)) {
          treffer = t;
          break;
        }
      }
      if (treffer != null) {
        spans.add(TextSpan(
            text: text.substring(i, i + treffer.length),
            style: const TextStyle(
                color: Color(0xFF10243A),
                backgroundColor: Color(0xFFFFE08A),
                fontWeight: FontWeight.w900)));
        i += treffer.length;
      } else {
        spans.add(TextSpan(text: text[i]));
        i++;
      }
    }
    return Text.rich(
      TextSpan(
          style: TextStyle(
              color: aktiv ? const Color(0xFFFFE08A) : Colors.white,
              fontSize: groesse,
              height: 1.45,
              fontWeight: aktiv ? FontWeight.w900 : FontWeight.w700),
          children: spans),
      key: key,
    );
  }

  Widget _markierung(FachMaterial m) => _karte(
        key: const ValueKey('fach-markierung'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.bild != null)
              Center(
                  child: Text(m.bild!, style: const TextStyle(fontSize: 64))),
            if (widget.aufgabe.lesetext.isNotEmpty && m.bild == null) ...[
              Text(widget.aufgabe.lesetext,
                  style: const TextStyle(
                      color: Color(0xFFB4D7E9),
                      fontSize: 18,
                      height: 1.4,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
            ],
            for (final s in m.saetze)
              _hervorgehoben(s, m.markiert, key: const ValueKey('fach-frage')),
          ],
        ),
      );

  Widget _laute(FachMaterial m) => _karte(
        key: const ValueKey('fach-laute'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.bild != null)
              Center(
                  child: Text(m.bild!, style: const TextStyle(fontSize: 64))),
            for (var i = 0; i < m.saetze.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _erscheint(
                    i,
                    m.saetze.length,
                    _hervorgehoben(m.saetze[i], m.markiert,
                        groesse: widget.aufgabe.istWortWahl ||
                                widget.aufgabe.istBildWort
                            ? 30
                            : 21)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  'Gelb: Buchstaben, die zusammen einen Laut ergeben.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .8),
                      fontSize: 15)),
            ),
          ],
        ),
      );

  Widget _vorlesenMaterial(FachMaterial m) => _karte(
        key: const ValueKey('fach-vorlesen'),
        rand: const Color(0xFFFFC94A),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.bild != null)
              Center(
                  child: Text(m.bild!, style: const TextStyle(fontSize: 64))),
            for (var i = 0; i < m.saetze.length; i++)
              AnimatedContainer(
                key: ValueKey('fach-vorlesen-$i'),
                duration: widget.reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _vorleseSatz == i
                      ? const Color(0x33FFE08A)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(m.saetze[i],
                    style: TextStyle(
                        color: _vorleseSatz == i
                            ? const Color(0xFFFFE08A)
                            : Colors.white,
                        fontSize: 22,
                        height: 1.4,
                        fontWeight: _vorleseSatz == i
                            ? FontWeight.w900
                            : FontWeight.w600)),
              ),
          ],
        ),
      );

  Widget _satzWahl(FachMaterial m) => _karte(
        key: const ValueKey('fach-satzwahl'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.aufgabe.frage,
                style: const TextStyle(
                    color: Color(0xFFFFE08A),
                    fontSize: 19,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (var i = 0; i < m.saetze.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  key: ValueKey('fach-satz-$i'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 56),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(12),
                    backgroundColor: _satzGewaehlt == i
                        ? (_satzRichtig
                            ? const Color(0xFF1F6B4A)
                            : const Color(0xFF5A3A2A))
                        : const Color(0xFF12366A),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF73D4ED)),
                  ),
                  onPressed: () => _satzWaehlen(i),
                  child: Text(m.saetze[i],
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      );

  Widget _ausschliessenMaterial(FachMaterial m) => _karte(
        key: const ValueKey('fach-ausschliessen'),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in m.auswahl)
              OutlinedButton.icon(
                key: ValueKey('fach-weg-$c'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 56),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  backgroundColor: _ausgeschlossen.contains(c)
                      ? const Color(0xFF2A2F3A)
                      : const Color(0xFF12366A),
                  foregroundColor: _ausgeschlossen.contains(c)
                      ? Colors.white54
                      : Colors.white,
                  side: const BorderSide(color: Color(0xFF73D4ED)),
                ),
                onPressed: () => _ausschliessen(c),
                icon: Icon(_ausgeschlossen.contains(c)
                    ? Icons.close_rounded
                    : Icons.help_outline_rounded),
                label: Text(c,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        decoration: _ausgeschlossen.contains(c)
                            ? TextDecoration.lineThrough
                            : null)),
              ),
          ],
        ),
      );

  Widget _schaubild(FachMaterial m) {
    final sb = m.schaubild!;
    return _karte(
      key: const ValueKey('fach-schaubild'),
      rand: const Color(0xFF5BD69A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sb.titel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFFFFE08A),
                  fontSize: 21,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final spalten = c.maxWidth >= 560 ? 3 : 2;
            final breite = (c.maxWidth - (spalten - 1) * 10) / spalten;
            return AnimatedBuilder(
              animation: _bewegung,
              builder: (context, _) {
                final aktiv =
                    (_bewegung.value * sb.knoten.length).floor().clamp(
                        0, sb.knoten.length - 1);
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < sb.knoten.length; i++)
                      _erscheint(
                        i,
                        sb.knoten.length,
                        _knoten(sb, i, breite,
                            leuchtet: !widget.reduceMotion && i == aktiv),
                      ),
                  ],
                );
              },
            );
          }),
          if (sb.kreis)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.autorenew_rounded,
                      color: Color(0xFF5BD69A), size: 26),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text('Und dann beginnt alles wieder von vorn.',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _knoten(FachSchaubild sb, int i, double breite,
      {required bool leuchtet}) {
    final k = sb.knoten[i];
    return Container(
      key: ValueKey('fach-knoten-$i'),
      width: breite,
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: k.verdeckt ? const Color(0xFF3A2F18) : const Color(0xFF16406A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: leuchtet
                ? const Color(0xFFFFE08A)
                : k.verdeckt
                    ? const Color(0xFFFFC94A)
                    : const Color(0xFF73D4ED),
            width: leuchtet ? 3.5 : 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(k.bild, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 6),
            Text('${i + 1}',
                style: const TextStyle(
                    color: Color(0xFFFFE08A),
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            if (i < sb.knoten.length - 1 || sb.kreis) ...[
              const Spacer(),
              const Icon(Icons.arrow_forward_rounded,
                  color: Color(0xFF5BD69A), size: 22),
            ],
          ]),
          const SizedBox(height: 4),
          Text(k.titel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900)),
          if (k.text.isNotEmpty)
            Text(k.text,
                style: TextStyle(
                    color: k.verdeckt ? const Color(0xFFFFE08A) : Colors.white,
                    fontSize: k.verdeckt ? 24 : 15.5,
                    height: 1.3,
                    fontWeight: k.verdeckt ? FontWeight.w900 : FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _alltag() => _karte(
        key: const ValueKey('fach-alltag'),
        rand: const Color(0xFFFFC94A),
        child: Row(
          children: [
            _erscheint(0, 1,
                const Text('🏡', style: TextStyle(fontSize: 64))),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Ein Bild aus deinem Alltag: Schließ kurz die Augen und stell '
                'es dir genau vor.',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

  Widget _pruefenMaterial(FachMaterial m) {
    final p = _plan.aufgabe;
    if (m.auswahl.isEmpty) {
      return _karte(
        key: const ValueKey('fach-pruefen-leer'),
        child: const Text('Gleich geht es mit deiner Aufgabe weiter.',
            style: TextStyle(color: Colors.white, fontSize: 18)),
      );
    }
    return _karte(
      key: const ValueKey('fach-pruefen'),
      rand: const Color(0xFFFFC94A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(p.prompt,
              key: const ValueKey('fach-pruef-aufgabe'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  height: 1.4,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final c in m.auswahl)
                FilledButton(
                  key: ValueKey('fach-pruef-$c'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 56),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    backgroundColor: _pruefGewaehlt == c
                        ? (c == p.antwort && _pruefFertig
                            ? const Color(0xFF3CCB7F)
                            : const Color(0xFFB0563F))
                        : const Color(0xFF1D5C8C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _pruefFertig ? null : () => _pruefen(c),
                  child: Text(c,
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
