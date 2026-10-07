#!/usr/bin/env python3
"""One-time, source-hash-bounded visual patch authored for Heinz's PR.

Only listed files change. Reuses the already reviewed PR204 settings visual
snapshot; no curriculum/Card rules copied. No external code execution,
AI-generated repair loop, force push, credentials, signing or runtime flags.
This file is a transparent transport script for large existing source files.
"""
from pathlib import Path
import hashlib
import subprocess
import re

ROOT = Path(__file__).resolve().parents[2]
EXPECTED = {
 'lib/features/games/games_content.dart': ('b30abd6a993fba313ff551d996fe9faf81f7d06324de318cdc69a8b2a4e72356','9232f2dec080965d0267eec06e116dec93880b4b005243fe125d8aa9c9df252e'),
 'lib/features/learning/learning_dna_card.dart': ('701522d29807b989a03b2be4754bb13bdd3cbe7019912498eee3082435c47777','f322b5ffc7f63472194571ca78cb7f0f7bbbc7806c6b063a812ce7f88456079a'),
 'lib/features/parents/widgets/lumo_ai_policy_selector.dart': ('320a89392dc4e486bc3f8a7d951d59e2f5898709b0d4e3d70939bfe8c99fddc7','9525111b7cbdd1e222287c8318c9f94cd77e643575a3609cc830a310acd85239'),
 'lib/features/rewards/test_photo_entry_card.dart': ('699e88cdb32eb6566014d5062de759166b4add89766d0d91587efc0ec548d0f1','5a5887f270bef6b35eb0e5527d9b6bbeae63ede6dcf8e8f832ee37f530aa253a'),
 'lib/features/settings/parent_report_card.dart': ('4d1889144d2699e849be131cc34f726f3ba197087a79d7186caedf23d5da171e','8645def7350ba6b2382fcf429cc5041593aaff33774b1f7b3aec2b3382608185'),
 'lib/features/settings/settings_content.dart': ('8fedc28479b8758cd2dccb46a223341a94894dfacfe457a344d237b8c9d85beb','a965fbad42cb68ff90fc87d520dd9a70c7e2646100a544a0335f4e4d1a657977'),
 'lib/features/settings/writing_report_card.dart': ('9097505418e32d84a57effccb0fe27eba77b30205d2e8a2e727155c57b663d8d','b89fe190afb2ba344d481f0ea6763c2648b9bb89fdc4ada529714af0c3693332'),
}
for path, expected in EXPECTED.items():
    if hashlib.sha256((ROOT/path).read_bytes()).hexdigest() != expected[0]:
        raise SystemExit('Input changed; stop instead of overwriting: '+path)
root=ROOT

def write(path,s):
    (root/path).write_text(s)

def addtokens(s):
    if "import '../../theme/lumo_visual_tokens.dart';" not in s:
        s=s.replace("import '../../app/app_theme.dart';","import '../../app/app_theme.dart';\nimport '../../theme/lumo_visual_tokens.dart';")
    return s

def textcolors(s):
    for n in (900,800,700): s=s.replace(f'LumoColors.ink{n}','LumoVisualTokens.white')
    for n in (600,500,400,300): s=s.replace(f'LumoColors.ink{n}','LumoVisualTokens.muted')
    s=s.replace('LumoColors.ink100','LumoVisualTokens.glassRow')
    s=s.replace('LumoColors.orangeSurface','const Color(0xCC403421)')
    s=re.sub(r'LumoTextStyles\.(caption|body|label|heading[123])(?=\s*[,\)])',r'LumoTextStyles.\1.copyWith(color: LumoVisualTokens.muted)',s)
    return s

s=subprocess.check_output(['git','show','17ab56f3912694b3226dde702bd6482ac61509dd:lib/features/settings/settings_content.dart'],text=True)
s=s.replace("import '../../widgets/premium/lumo_magic_background.dart';", "import '../../widgets/design/lumo_design_system.dart';\nimport '../../widgets/design/lumo_night_scope.dart';")
start=s.index('class SettingsContent extends StatefulWidget')
end=s.index('  /// Diagnose-Versionslabel.',start)
s=s[:start]+'''/// All settings, sheets and dialogs share the same night surface.
/// The State must live below the scope so showDialog captures this Theme.
class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key, required this.appState});
  final LumoAppState appState;

  @override
  Widget build(BuildContext context) => LumoNightScope(
        child: _SettingsContentBody(appState: appState),
      );
}

class _SettingsContentBody extends StatefulWidget {
  const _SettingsContentBody({required this.appState});
  final LumoAppState appState;

  @override
  State<_SettingsContentBody> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContentBody> {
'''+s[end:]
s=s.replace('return LumoMagicBackground(\n      intensity: .85,\n      starCount: 18,', '''return LumoSceneBackground(
      scene: LumoScene.profile,
      dimmed: true,
      showPlaceholderLabel: false,''')
s=s.replace('return LumoMagicBackground(\n      intensity: 0.85,\n      starCount: 18,', '''return LumoSceneBackground(
      scene: LumoScene.profile,
      dimmed: true,
      showPlaceholderLabel: false,''')
s=s.replace('padding: const EdgeInsets.all(26),', 'padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 600 ? 14 : 24),')
s=textcolors(s)
s=s.replace('); // close LumoMagicBackground', '); // close night scene')
write('lib/features/settings/settings_content.dart',s)

paths=['lib/features/settings/writing_report_card.dart','lib/features/learning/learning_dna_card.dart','lib/features/rewards/test_photo_entry_card.dart','lib/features/settings/parent_report_card.dart']
replacements={
 'Color(0xFFFFFFFF)':'Color(0xE6123760)',
 'Color(0xFFFAF5FF)':'Color(0xE609264B)',
 'Color(0xFFF3E8FF)':'Color(0xE6082148)',
 'Color(0xFFFDF4FF)':'Color(0xE6123760)',
 'Color(0xFFFAE8FF)':'Color(0xE609264B)',
 'Color(0xFFEDE9FE)':'Color(0xFF29476E)',
 'Color(0xFFE9D5FF)':'Color(0xFF536DA3)',
 'Color(0xFFD8B4FE)':'Color(0xFF7B95DA)',
 'Color(0xFF581C87)':'LumoVisualTokens.white',
 'Color(0xFF6D28D9)':'LumoVisualTokens.muted',
 'Color(0xFF7C3AED)':'Color(0xFF9F93FF)',
 'Color(0xFFFEF3C7)':'Color(0xFF403421)',
 'Color(0xFF92400E)':'LumoVisualTokens.gold',
 'Color(0xFFFEE2E2)':'Color(0xFF44242C)',
 'Color(0xFFFEF2F2)':'Color(0xFF44242C)',
 'Color(0xFFB91C1C)':'Color(0xFFFFB4B4)',
 'Color(0xFFDCFCE7)':'Color(0xFF123E38)',
 'Color(0xFF14532D)':'Color(0xFFA3E5BF)',
 'Color(0xFF064E3B)':'Color(0xFFB1F0D7)',
 'Color(0xFF065F46)':'Color(0xFFA3E5BF)',
 'Color(0xFFE5E7EB)':'Color(0xFF173760)',
 'Color(0xFFD1D5DB)':'Color(0xFF09264B)',
}
for path in paths:
    s=addtokens((root/path).read_text())
    s=textcolors(s)
    for a,b in replacements.items():s=s.replace(a,b)
    s=re.sub(r'const (LumoVisualTokens\.\w+)',r'\1',s)
    s=s.replace('fillColor: Colors.white','fillColor: LumoVisualTokens.glassRow')
    s=s.replace('color: tintColor ?? Colors.white','color: tintColor ?? LumoVisualTokens.glassRow')
    s=s.replace('Colors.white.withOpacity(0.95)','LumoVisualTokens.glassRow')
    s=s.replace('                                Colors.white,','                                LumoVisualTokens.glass,')
    if path.endswith('test_photo_entry_card.dart'):
        s=s.replace('    setState(() => _saving = true);\n    try {','''    final submittedNote = _selectedNote;
    final submittedImage = _imagePath;
    setState(() => _saving = true);
    try {''')
        s=s.replace('note: _selectedNote,','note: submittedNote,').replace('imagePath: _imagePath,','imagePath: submittedImage,')
        s=s.replace('final points = TestPhotoEntry.pointsForNote(_selectedNote);','final points = TestPhotoEntry.pointsForNote(submittedNote);')
        s=s.replace('Punkte für Note $_selectedNote','Punkte für Note $submittedNote')
        s=s.replace('colors: [color, color.withOpacity(0.75)]','colors: [Color.alphaBlend(color.withOpacity(.35), LumoVisualTokens.glass), LumoVisualTokens.navigation]')
        s=s.replace('color: selected ? Colors.white : color,','color: selected ? LumoVisualTokens.white : LumoVisualTokens.muted,')
        s=s.replace('child: InkWell(\n                    onTap:', "child: InkWell(\n                    key: ValueKey('parent-test-note-$note'),\n                    onTap:")
        s=s.replace('backgroundColor:\n              points > 0 ? const Color(0xFF22C55E) : LumoVisualTokens.muted,','backgroundColor:\n              points > 0 ? const Color(0xFF123E38) : LumoVisualTokens.glassRow,')
        s=s.replace('style: const TextStyle(fontWeight: FontWeight.w900),','style: const TextStyle(fontWeight: FontWeight.w900, color: LumoVisualTokens.white),')
    write(path,s)

p=ROOT/'lib/features/games/games_content.dart'
s=p.read_text()
s=s.replace("import 'spielwelt/spielwelt_hub.dart';", "import 'spielwelt/spielwelt_hub.dart';\nimport 'widgets/lumo_game_spotlights.dart';\nimport '../../widgets/design/lumo_night_scope.dart';")
s=s.replace('    HapticFeedback.mediumImpact();\n    // Heinz 2026-05-21', '    if (_launchingGame) return;\n    setState(() => _launchingGame = true);\n    HapticFeedback.mediumImpact();\n    // Heinz 2026-05-21')
start=s.index('  Future<void> _launchLumoCards()')
end=s.index('  Future<void> _launchLevel',start)
block=s[start:end]
block=block.replace('    await Navigator.of(context).push<void>(', '    try {\n      await Navigator.of(context).push<void>(')
block=block.replace('    if (mounted) await _load();','''      if (mounted) await _load();
    } finally {
      if (mounted) setState(() => _launchingGame = false);
    }''')
s=s[:start]+block+s[end:]
s=s.replace('  void _openGame(GameId id, VoidCallback launch) {','  void _openGame(GameId id, VoidCallback launch) {\n    if (_launchingGame) return;')
old='''              SliverToBoxAdapter(
                child: SpielweltHub(
                  portals: _portals(),
                  reduceMotion: _reduceMotion,
                  onAdventure: () => _openGame(GameId.memory, _launchMemory),
                  onParents: () => widget.onSection?.call(LumoSection.settings),
                  onProgress: () => widget.onSection?.call(LumoSection.profile),
                  onSettings: () => widget.onSection?.call(LumoSection.settings),
                ),
              ),'''
new='''              SliverToBoxAdapter(
                child: LumoGameSpotlights(
                  onCards: () => _openGame(GameId.cards, _launchLumoCards),
                  onKart: () => _openGame(GameId.kart, () => _launch3D('kart')),
                  busy: _launchingGame,
                  reduceMotion: _reduceMotion,
                ),
              ),
              SliverToBoxAdapter(
                child: LumoNightScope(child: ExpansionTile(
                  key: const PageStorageKey('extra-spielwelten'),
                  title: const Text('Weitere Spielwelten entdecken'),
                  subtitle: const Text('Alle bisherigen Spiele und Portale'),
                  collapsedIconColor: LumoVisualTokens.cyanBright,
                  collapsedTextColor: LumoVisualTokens.white,
                  textColor: LumoVisualTokens.white,
                  children: [SpielweltHub(
                    portals: _portals(),
                    reduceMotion: _reduceMotion,
                    onAdventure: () => _openGame(GameId.memory, _launchMemory),
                    onParents: () => widget.onSection?.call(LumoSection.settings),
                    onProgress: () => widget.onSection?.call(LumoSection.profile),
                    onSettings: () => widget.onSection?.call(LumoSection.settings),
                  )],
                )),
              ),'''
if old not in s: raise SystemExit('Missing original Spielwelt root')
s=s.replace(old,new)
s=s.replace('onMemory: _launchMemory,\n                    onLumoCards: _launchLumoCards,','onMemory: () => _openGame(GameId.memory, _launchMemory),')
old='''                  child: _KartWideCard(
                    launching: _launchingGame,
                    onPlay: () => _openGame(GameId.kart, () => _launch3D('kart')),
                    options: _kartOptions(),
                  ),'''
new='''                  child: LumoNightScope(child: ExpansionTile(
                    title: const Text('3D-Profiloptionen'),
                    subtitle: const Text('Keine Aufgaben während des Rennens'),
                    children: [Padding(padding: const EdgeInsets.all(12), child: _kartOptions())],
                  )),'''
if old not in s: raise SystemExit('Missing original Kart root')
s=s.replace(old,new)
s=s.replace('    required this.onLumoCards,\n','').replace('  final VoidCallback onLumoCards;\n','')
s=s.replace('''      _GameTile(
        title: 'Lumo Cards',
        subtitle: 'Karten-Duell gegen Lumo!',
        art: const _CardsArt(),
        onPlay: onLumoCards,
      ),\n''','')
s=s.replace('''      final width = (constraints.maxWidth - gap) / 2;
      final height = (width * .7).clamp(118.0, 190.0) *
          MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);''','''      final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
      final columns = constraints.maxWidth >= 620 && !largeText ? 2 : 1;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;''')
s=s.replace('SizedBox(width: width, height: height, child: tile)','SizedBox(width: width, child: tile)')
start=s.index('class _GameTile extends')
end=s.index('class _PlayPill',start)
block=s[start:end]
block=block.replace('padding: const EdgeInsets.all(6)','padding: const EdgeInsets.all(12)')
block=block.replace('''              Expanded(
                flex: 9,
                child: ClipRRect(''','''              SizedBox(
                width: 72, height: 80,
                child: ClipRRect(''')
block=block.replace('const SizedBox(width: 6)','const SizedBox(width: 12)')
block=block.replace('                      maxLines: 2,\n                      overflow: TextOverflow.ellipsis,\n','')
block=block.replace('fontSize: 14,','fontSize: 17,')
block=block.replace('''                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,''','''                    Text(
                        subtitle,''')
block=block.replace('fontSize: 10.5,','fontSize: 14,')
block=block.replace('''                        ),
                      ),
                    ),
                    const _PlayPill(label: 'Spielen'),''','''                        ),
                    ),
                    const SizedBox(height: 8),
                    const Row(children: [
                      Text('Spielen', style: TextStyle(color: LumoVisualTokens.cyanBright, fontWeight: FontWeight.w800)),
                      Icon(Icons.arrow_forward_rounded, color: LumoVisualTokens.cyanBright, size: 20),
                    ]),''')
s=s[:start]+block+s[end:]
start=s.index('class _KartWideCard extends')
nextclass=s.find('\nclass ',start+6)
s=s[:start]+s[nextclass+1:]
start=s.index('class _CardsArt extends')
end=s.find('\nclass ',start+6)
s=s[:start]+s[end+1:]
p.write_text(s)

r=ROOT
p=r/'lib/features/parents/widgets/lumo_ai_policy_selector.dart'
s=p.read_text().replace("import '../../../app/app_theme.dart';","import '../../../app/app_theme.dart';\nimport '../../../theme/lumo_visual_tokens.dart';")
s=s.replace('return LumoModernCard(\n      padding:', '''return LumoModernCard(
      color: Theme.of(context).brightness == Brightness.dark ? LumoVisualTokens.glassRow : null,
      borderColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF6486AA) : null,
      padding:''')
s=s.replace('style: LumoTextStyles.heading2)', 'style: LumoTextStyles.heading2.copyWith(color: Theme.of(context).colorScheme.onSurface))')
s=s.replace('color: LumoColors.ink600','color: Theme.of(context).colorScheme.onSurfaceVariant')
s=s.replace('    final borderColor = selected ? LumoColors.orange : LumoColors.ink100;\n    final background = selected ? LumoColors.orange.withOpacity(.10) : Colors.white;', '''    final dark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = dark
        ? (selected ? LumoVisualTokens.cyanBright : const Color(0xFF6486AA))
        : (selected ? LumoColors.orange : LumoColors.ink100);
    final background = dark
        ? (selected ? const Color(0xFF14527B) : LumoVisualTokens.navigation)
        : (selected ? LumoColors.orange.withOpacity(.10) : Colors.white);''')
s=s.replace('color: selected ? LumoColors.orange : LumoColors.ink900,','color: dark ? LumoVisualTokens.white : (selected ? LumoColors.orange : LumoColors.ink900),')
s=s.replace('color: selected ? LumoColors.ink700 : LumoColors.ink500,','color: dark ? LumoVisualTokens.muted : (selected ? LumoColors.ink700 : LumoColors.ink500),')
s=s.replace('color: selected ? LumoColors.orange : LumoColors.ink300,','color: dark ? LumoVisualTokens.cyanBright : (selected ? LumoColors.orange : LumoColors.ink300),')
s=s.replace('color: selected ? Colors.white : LumoColors.orangeSurface,','color: Theme.of(context).brightness == Brightness.dark ? LumoVisualTokens.glassRow : (selected ? Colors.white : LumoColors.orangeSurface),')
p.write_text(s)

p=r/'lib/features/settings/parent_report_card.dart'
s=p.read_text().replace('decoration: lumoCard(),','decoration: lumoCard(color: LumoVisualTokens.glass, border: Border.all(color: LumoVisualTokens.cyan)),' )
s=s.replace("child: const Text('Elternbericht wird erstellt …'", "child: Text('Elternbericht wird erstellt …'")
s=s.replace('width: 250,','constraints: const BoxConstraints(maxWidth: 250),')
s=s.replace("? const [Color(0xFFFFB96B), Color(0xFFFF7A2F)]", "? const [Color(0xFF175381), Color(0xFF0B3155)]")
s=s.replace("colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],", "colors: [Color(0xFF174D75), Color(0xFF09264B)],")
p.write_text(s)

p=r/'lib/features/settings/writing_report_card.dart'
s=p.read_text().replace('Color(0xFFFFF7ED)','Color(0xFF403421)')
p.write_text(s)
p=r/'lib/features/settings/settings_content.dart'
s=p.read_text().replace('// Modernisierung 2026-06-03: Settings auf LumoMagicBackground wie Home.\n    // Niedrige Intensitaet damit der Settings-Fokus erhalten bleibt.', '// Same approved night scene as the profile; controls retain a quiet glass surface.')
s=s.replace('''                child: Text(
                  emoji,
                  style: TextStyle(fontSize: compact ? 30 : 38, height: 1.0),
                ),''','''                child: LumoFoxPose(pose: LumoDesignFoxPose.tabletThumb, size: avatarSize),''')
p.write_text(s)
p=r/'lib/features/games/games_content.dart'
s=p.read_text().replace("import '../../core/lumo_asset_diagnostics.dart';\n",'')
start=s.index('class _PlayPill extends')
end=s.find('\nclass ',start+6)
s=s[:start]+s[end+1:]
p.write_text(s)

for path, expected in EXPECTED.items():
    actual = hashlib.sha256((ROOT/path).read_bytes()).hexdigest()
    if actual != expected[1]:
        raise SystemExit('Unexpected output; do not commit: '+path+' '+actual)
print('[ParentGamesPatch] PASS: all reviewed output hashes match')
