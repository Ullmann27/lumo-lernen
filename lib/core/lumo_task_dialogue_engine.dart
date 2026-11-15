import '../widgets/fox/lumo_companion_requests.dart';
import 'lumo_child_speech_normalizer.dart';
import 'primary_school_word_data.dart';

/// Only a task-scoped, deterministic conversation aid. It cannot grade an
/// answer, submit a learning event, award rewards or change the visible task.
/// An unrecognised request is returned to the existing companion policy.
enum LumoTaskDialogueAction {
  hint,
  replay,
  slower,
  clarify,
  correction,
  independent,
  stop,
}

class LumoTaskDialogueDecision {
  const LumoTaskDialogueDecision({
    required this.text,
    required this.action,
    this.focus,
    this.subtitle,
  });

  final String text;
  final LumoTaskDialogueAction action;

  /// Semantic scene target; the lesson renderer must validate the target
  /// against its own visible objects before it moves the avatar's gaze.
  final String? focus;
  final String? subtitle;
}

class LumoTaskDialogueEngine {
  const LumoTaskDialogueEngine();

  LumoTaskDialogueDecision? respond({
    required String input,
    required LumoCompanionTaskContext? task,
    String? previousReply,
  }) {
    final text = input.trim();
    final q = _simple(text);

    if (_isStop(q)) {
      return const LumoTaskDialogueDecision(
        text: '',
        action: LumoTaskDialogueAction.stop,
      );
    }
    if (task == null || text.isEmpty) return null;

    final correction = RegExp(
      r'^(?:nein[,. ]*)?(?:ich meinte|ich meine|ich hab(?:e)? gesagt)\s+([a-zäöüß0-9 ]{1,40})[.!? ]*$',
      caseSensitive: false,
    ).firstMatch(text.toLowerCase());
    if (correction != null) {
      final spoken = correction.group(1)!.trim();
      // Do not grade this: ASR corrections only clarify the heard words.
      final normalized = const LumoChildSpeechNormalizer()
          .normalizeText(spoken);
      if (normalized.isEmpty || normalized.length > 40) {
        return const LumoTaskDialogueDecision(
          text: 'Welche Zahl oder welches Wort meinst du? Bitte sag es noch einmal.',
          action: LumoTaskDialogueAction.clarify,
        );
      }
      return LumoTaskDialogueDecision(
        text: 'Du meinst ' + spoken + '. Danke für die Korrektur. '
            'Die Spracherkennung wird nicht als falsche Lernantwort gewertet. '
            'Du kannst deine Antwort jetzt bestätigen oder selbst eingeben.',
        action: LumoTaskDialogueAction.correction,
      );
    }

    if (_any(q, const ['allein versuchen', 'selber versuchen',
        'selbst versuchen', 'keinen tipp', 'ohne hilfe'])) {
      return const LumoTaskDialogueDecision(
        text: 'Gerne. Versuch es erst selbst. Ich gebe dir keinen weiteren Tipp.',
        action: LumoTaskDialogueAction.independent,
      );
    }

    final replay = _any(q, const ['noch einmal', 'nochmal', 'wiederhol',
        'wiederhole']);
    final slower = _any(q, const ['langsamer', 'langsam sprechen',
        'sprich langsam', 'nicht so schnell']);
    final why = _any(q, const ['warum', 'wieso']);
    final different = _any(q, const ['anders erklaer', 'anders erklar',
        'anders zeigen', 'andere erklaerung']);
    final second = _any(q, const ['zweiten schritt', 'zweite schritt',
        'schritt zwei', 'schritt 2']);
    final show = _any(q, const ['zeig mir', 'zeige mir']);
    final help = _any(q, const ['verstehe nicht', 'erklaer', 'erklar',
        'hilf mir', 'wie geht', 'was wiederholt sich', 'was soll ich']);
    final learningIntent =
        replay || slower || why || different || second || show || help;
    if (!learningIntent) return null;

    if (task.isExam) {
      return const LumoTaskDialogueDecision(
        text: 'Im Test probierst du es selbst. Danach können wir es gemeinsam anschauen.',
        action: LumoTaskDialogueAction.hint,
      );
    }
    if (!task.answering) {
      return const LumoTaskDialogueDecision(
        text: 'Diese Aufgabe ist schon beendet. Wir können sie später gemeinsam wiederholen.',
        action: LumoTaskDialogueAction.clarify,
      );
    }

    final prompt = _simple(task.prompt);
    final isSyllableTask = _any(_simple(task.unit), const ['silbe', 'silben']) ||
        _any(prompt, const ['silbe', 'silben']);
    if (isSyllableTask && prompt.contains('banane')) {
      final parts = PrimarySchoolWordData.syllablesFor('Banane') ??
          const ['Ba', 'na', 'ne'];
      if (parts.length == 3) {
        return LumoTaskDialogueDecision(
          text: slower
              ? 'Hör ganz langsam zu: ' + parts.join('. ') + '. '
                  'Jetzt darfst du die Silben selbst sprechen.'
              : 'Wir teilen das Wort in Silben: ' + parts.join(' – ') +
                  '. Zeig auf jede Silbe, während wir sie sprechen.',
          subtitle: parts.join(' · '),
          action: slower ? LumoTaskDialogueAction.slower :
              (replay ? LumoTaskDialogueAction.replay :
               LumoTaskDialogueAction.hint),
          focus: 'syllables',
        );
      }
    }

    final math = RegExp(r'(\d{1,2})\s*\+\s*(\d{1,2})').firstMatch(task.prompt);
    if (math != null) {
      final left = int.parse(math.group(1)!);
      final right = int.parse(math.group(2)!);
      final free = 10 - left;
      if (left > 0 && left < 10 && right >= free &&
          right <= 10 && _any(q, const ['warum', 'zuerst',
          'zweiten schritt', 'zeig mir', 'anders', 'erklaer', 'erklar',
          'noch einmal', 'nochmal', 'langsamer', 'verstehe nicht'])) {
        final tenFrame = _simple(task.localHelp ?? '') +
            ' ' + _simple(task.previousHelp ?? '') + ' ' + prompt;
        final visible = _any(tenFrame, const ['zehnerfeld', 'zehnerrahmen']);
        final space = visible
            ? 'Im Zehnerfeld sind noch ' + _word(free) + ' Plätze frei. '
            : 'Bis zum nächsten Zehner fehlen ' + _word(free) + '. ';
        final remaining = right - free;
        final answer = second
            ? 'Im ersten Schritt legen wir ' + _word(free) +
                ' dazu und erreichen zehn. Von den ' + _word(right) +
                ' bleiben ' + _word(remaining) +
                ' übrig. Was machst du im zweiten Schritt mit ihnen?'
            : different
                ? 'Stell dir zehn freie Plätze vor. ' + _word(left) +
                    ' sind schon besetzt. Wie viele fehlen noch bis zehn?'
                : space + 'Deshalb nehmen wir von den ' + _word(right) +
                    ' zuerst ' + _word(free) +
                    '. Zeig mir die freien Plätze. Wie viele bleiben von den '
                    + _word(right) + ' danach übrig?';
        return LumoTaskDialogueDecision(
          text: answer,
          action: slower ? LumoTaskDialogueAction.slower :
              (replay ? LumoTaskDialogueAction.replay :
              LumoTaskDialogueAction.hint),
          focus: 'ten-frame',
        );
      }
    }

    final pattern = prompt.replaceAll(RegExp(r'[^a-z]+'), ' ');
    if (RegExp(r'kreis\s+dreieck\s+kreis\s+dreieck\s+kreis')
        .hasMatch(pattern) &&
        _any(q, const ['wiederholt', 'muster', 'warum', 'zeig',
            'erklaer', 'erklar', 'nochmal', 'langsamer'])) {
      final releasePattern = task.helpLevel >= 2;
      return LumoTaskDialogueDecision(
        text: releasePattern
            ? 'Die kleine Gruppe Kreis, Dreieck kommt immer wieder. '
                'Zeig zuerst auf die erste Gruppe und dann auf die nächste.'
            : 'Vergleiche die erste und die dritte Form. '
                'Und die zweite und die vierte. Was fällt dir auf?',
        action: LumoTaskDialogueAction.hint,
        focus: 'pattern',
      );
    }

    if (q.contains('die zwei da') || q.contains('diese zwei')) {
      return const LumoTaskDialogueDecision(
        text: 'Welche zwei meinst du? Zeig sie mir bitte auf der Aufgabe.',
        action: LumoTaskDialogueAction.clarify,
      );
    }
    if (slower || replay) {
      final previous = previousReply?.trim();
      final hint = task.localHelp?.trim();
      final replayText = previous?.isNotEmpty == true ? previous! :
          (hint?.isNotEmpty == true ? hint! : null);
      if (replayText != null) {
        return LumoTaskDialogueDecision(
          text: replayText,
          action: slower ? LumoTaskDialogueAction.slower :
              LumoTaskDialogueAction.replay,
        );
      }
    }

    // Only the task owner knows the correct next hint. Do not invent steps
    // or silently grant higher help levels here.
    if (different) {
      return const LumoTaskDialogueDecision(
        text: 'Wir können es anders versuchen. Zeig zuerst, welcher Teil '
            'der Aufgabe unklar ist. Dann schauen wir genau diesen Teil an.',
        action: LumoTaskDialogueAction.clarify,
      );
    }
    final localHint = task.localHelp?.trim();
    if (localHint?.isNotEmpty == true) {
      return LumoTaskDialogueDecision(
        text: localHint!,
        action: LumoTaskDialogueAction.hint,
      );
    }
    return const LumoTaskDialogueDecision(
      text: 'Welchen Schritt verstehst du nicht? '
          'Du kannst ihn mir zeigen oder in eigenen Worten beschreiben.',
      action: LumoTaskDialogueAction.clarify,
    );
  }

  bool _isStop(String q) =>
      RegExp(r'^(stopp|stop|halt|hoer auf|hoer bitte auf)[.! ]*$')
          .hasMatch(q);

  bool _any(String input, List<String> terms) =>
      terms.any(input.contains);

  String _simple(String input) => input
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');

  String _word(int number) => const [
    'null', 'eins', 'zwei', 'drei', 'vier', 'fünf', 'sechs',
    'sieben', 'acht', 'neun', 'zehn'
  ][number.clamp(0, 10).toInt()];
}
