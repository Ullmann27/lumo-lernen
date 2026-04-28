import 'package:flutter/material.dart';

class ReferenceHomeDashboard extends StatelessWidget {
  const ReferenceHomeDashboard({
    super.key,
    required this.stars,
    required this.xp,
    required this.level,
    required this.progress,
    required this.lumo,
    required this.onMath,
    required this.onGerman,
    required this.onEnglish,
    required this.onPractice,
    required this.onTest,
    required this.onSchoolwork,
    required this.onPhoto,
    required this.onContinue,
    required this.onProfile,
  });

  final int stars;
  final int xp;
  final int level;
  final int progress;
  final Widget lumo;
  final VoidCallback onMath;
  final VoidCallback onGerman;
  final VoidCallback onEnglish;
  final VoidCallback onPractice;
  final VoidCallback onTest;
  final VoidCallback onSchoolwork;
  final VoidCallback onPhoto;
  final VoidCallback onContinue;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xfffffbf4),
          borderRadius: BorderRadius.circular(34),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.10), blurRadius: 34, offset: const Offset(0, 18))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(children: [_sidebar(), Expanded(child: _main()), _rightPanel()]),
      ),
    );
  }

  Widget _sidebar() => Container(
        width: 164,
        color: const Color(0xfffff6ec),
        padding: const EdgeInsets.fromLTRB(20, 24, 12, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Lumo\nLernen', style: TextStyle(fontSize: 26, height: .88, fontWeight: FontWeight.w900, color: Color(0xffff6d00))),
          const SizedBox(height: 28),
          _nav(Icons.home_rounded, 'Start', true, () {}),
          _nav(Icons.school_rounded, 'Lernen', false, onMath),
          _nav(Icons.edit_rounded, 'Übungen', false, onPractice),
          _nav(Icons.bar_chart_rounded, 'Fortschritt', false, onProfile),
          _nav(Icons.star_rounded, 'Belohnungen', false, () {}),
          _nav(Icons.person_rounded, 'Profil', false, onProfile),
          const Spacer(),
          InkWell(
            onTap: onProfile,
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: _box(22, Colors.white.withOpacity(.88)),
              child: const Row(children: [CircleAvatar(radius: 16, backgroundColor: Color(0xffffd4a4), child: Text('🦊', style: TextStyle(fontSize: 14))), SizedBox(width: 8), Expanded(child: Text('Lena\nKlasse 2', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, height: 1.05, fontSize: 13))), Icon(Icons.chevron_right_rounded, size: 18)]),
            ),
          ),
        ]),
      );

  Widget _main() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 26, 22, 26),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Hallo, Lena! 👋', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Bereit für ein neues Lernabenteuer?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xff6c625c))),
          const SizedBox(height: 22),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _stat('Sterne', '$stars /50', Icons.star_rounded, const Color(0xffa855f7)),
              _gap,
              _stat('XP Punkte', '$xp', Icons.workspace_premium_rounded, const Color(0xffffb000)),
              _gap,
              _stat('Level', '$level Einsteiger', Icons.diamond_rounded, const Color(0xff14b8a6)),
              _gap,
              _stat('Lernfortschritt', '$progress%', Icons.donut_large_rounded, const Color(0xff3b82f6)),
            ]),
          ),
          const SizedBox(height: 26),
          const Text('Was möchtest du lernen?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final columns = c.maxWidth >= 620 ? 3 : 2;
            final w = (c.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(spacing: 14, runSpacing: 14, children: [
              _card(w, 'Mathematik', 'Zahlen, Rechnen,\nGeometrie & mehr', 'Weiterlernen', Icons.calculate_rounded, '1²', const Color(0xfffff1c4), const Color(0xffff8a00), onMath),
              _card(w, 'Deutsch', 'Lesen, Schreiben,\nGrammatik', 'Weiterlernen', Icons.menu_book_rounded, 'A', const Color(0xfff7e5ff), const Color(0xff8b5cf6), onGerman),
              _card(w, 'Englisch', 'Wörter, Sätze,\nVerstehen', 'Weiterlernen', Icons.language_rounded, 'Hi!', const Color(0xffe3fff6), const Color(0xff14b8a6), onEnglish),
              _card(w, 'Übung', 'Interaktive Übungen\nund Spiele', 'Üben', Icons.edit_rounded, '★', const Color(0xffffe2df), const Color(0xffff6b6b), onPractice),
              _card(w, 'Test', 'Teste dein Wissen\nund sammle Sterne', 'Test starten', Icons.assignment_turned_in_rounded, '✓', const Color(0xffe4f0ff), const Color(0xff3b82f6), onTest),
              _card(w, 'Schularbeit', 'Gemischter Test\nmit Note', 'Starten', Icons.description_rounded, 'A+', const Color(0xfffff0c9), const Color(0xffff9b21), onSchoolwork),
            ]);
          }),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth >= 620 ? (c.maxWidth - 14) / 2 : c.maxWidth;
            return Wrap(spacing: 14, runSpacing: 14, children: [
              _wide(w, 'Aufgabe fotografieren', 'Mach ein Foto deiner Aufgabe\nund lass dir helfen!', 'Foto machen', Icons.photo_camera_rounded, const Color(0xfff3d7ff), const Color(0xffa855f7), onPhoto),
              _wide(w, 'Weiterlernen', 'Setze da weiter, wo du\naufgehört hast', 'Anzeigen', Icons.play_circle_rounded, const Color(0xffdffaf2), const Color(0xff14b8a6), onContinue),
            ]);
          }),
        ]),
      );

  Widget _rightPanel() => Container(
        width: 250,
        padding: const EdgeInsets.fromLTRB(0, 12, 14, 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFCC80).withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Text('Hallo!\nWomit wollen wir\nheute lernen?', style: TextStyle(fontSize: 14, color: Color(0xFF333333), fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            Expanded(child: Center(child: lumo)),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Tagesziel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF333333))),
                SizedBox(height: 4),
                Text('Schließe 3 Aktivitäten ab', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 20), SizedBox(width: 4), Icon(Icons.check_circle, color: Colors.green, size: 20), SizedBox(width: 4), Icon(Icons.circle_outlined, color: Color(0xFFCCCCCC), size: 20)]),
                  Text('3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF555555))),
                  Text('🎁', style: TextStyle(fontSize: 20)),
                ]),
              ]),
            ),
          ]),
        ),
      );

  Widget _nav(IconData icon, String label, bool selected, VoidCallback tap) => Padding(padding: const EdgeInsets.only(bottom: 14), child: InkWell(onTap: tap, borderRadius: BorderRadius.circular(22), child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10), decoration: BoxDecoration(color: selected ? const Color(0xffffefe1) : Colors.transparent, borderRadius: BorderRadius.circular(22), boxShadow: selected ? _shadow : null), child: Row(children: [Container(width: 38, height: 38, decoration: _box(14, Colors.white), child: Icon(icon, color: selected ? const Color(0xffff7a1a) : const Color(0xff8e7d74), size: 21)), const SizedBox(width: 9), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: selected ? const Color(0xffff6d00) : const Color(0xff5f5650))))]))));

  Widget _stat(String title, String value, IconData icon, Color color) => Container(width: 150, height: 100, padding: const EdgeInsets.all(12), decoration: _box(22, Colors.white.withOpacity(.84)), child: Row(children: [Icon(icon, color: color, size: 31), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: .55, minHeight: 7, color: color, backgroundColor: color.withOpacity(.13)))]))]));

  Widget _card(double width, String title, String sub, String cta, IconData icon, String art, Color color, Color accent, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(28), child: Container(width: width.clamp(155, 285).toDouble(), height: 150, padding: const EdgeInsets.all(15), decoration: _box(28, color), child: Stack(children: [Positioned(right: 4, bottom: 0, child: Text(art, style: TextStyle(fontSize: 45, color: accent.withOpacity(.78), fontWeight: FontWeight.w900))), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(radius: 17, backgroundColor: Colors.white, child: Icon(icon, color: accent, size: 19)), const SizedBox(width: 8), Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: accent.darken())))]), const SizedBox(height: 8), Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.12, fontWeight: FontWeight.w700, color: Color(0xff655c55))), const Spacer(), _small(cta, accent)])])));

  Widget _wide(double width, String title, String sub, String button, IconData icon, Color color, Color accent, VoidCallback tap) => InkWell(onTap: tap, borderRadius: BorderRadius.circular(28), child: Container(width: width, height: 138, padding: const EdgeInsets.all(15), decoration: _box(28, color), child: Stack(children: [Positioned(right: 12, bottom: 5, child: Icon(icon, size: 60, color: accent.withOpacity(.52))), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(radius: 17, backgroundColor: Colors.white, child: Icon(icon, color: accent, size: 19)), const SizedBox(width: 8), Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent.darken())))]), const SizedBox(height: 8), Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.12, fontWeight: FontWeight.w700, color: Color(0xff655c55))), const Spacer(), _small(button, accent)])])));

  Widget _small(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(.75), borderRadius: BorderRadius.circular(99)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color.darken())), const SizedBox(width: 3), Icon(Icons.arrow_forward_rounded, size: 14, color: color.darken())]));

  BoxDecoration _box(double radius, Color color) => BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), border: Border.all(color: Colors.white.withOpacity(.70)), boxShadow: _shadow);

  Widget get _gap => const SizedBox(width: 14);
}

extension _ColorX on Color {
  Color darken([double amount = .22]) => HSLColor.fromColor(this).withLightness((HSLColor.fromColor(this).lightness - amount).clamp(0.0, 1.0)).toColor();
}

final List<BoxShadow> _shadow = [BoxShadow(color: Colors.deepOrange.withOpacity(.10), blurRadius: 20, offset: const Offset(0, 10)), BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 14, offset: const Offset(0, 4))];
