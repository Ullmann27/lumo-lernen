// One-time, bounded mechanical migration of the legacy presentation methods.
// It refuses a changed task generator or answer/storage/reward implementation.
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';

const modules = {
  minus_bis_10: ['Mathe-Abenteuer', "'Minus bis 10'", 'calculate_rounded', 'Aufgabe',
    '_answered && _selectedAnswer != _correct'],
  zahlen_bis_10: ['Mathe-Abenteuer', "'Zahlen bis 10'", 'pin_rounded', 'Aufgabe',
    '_answered && _selectedAnswer != _correctAnswer'],
  formen: ['Mathe-Abenteuer', "'Formen erkennen'", 'category_rounded', 'Aufgabe',
    '_answered && _selectedAnswer != _correctShape'],
  uhr_lernen: ['Mathe-Abenteuer', "'Die Uhr'", 'schedule_rounded', 'Uhrzeit'],
  geld: ['Mathe-Abenteuer', "'Geld lernen'", 'payments_rounded', 'Aufgabe'],
  zahlen_bis_100: ['Mathe-Abenteuer', "'Zahlen bis 100'", 'pin_rounded', 'Aufgabe'],
  einmaleins: ['Mathe-Abenteuer',
    "widget.fullRange ? 'Großes 1×1' : 'Einmaleins 2/5/10'", 'grid_view_rounded',
    'Aufgabe', '_answered && _selectedAnswer != _correct'],
  bruchrechnen: ['Mathe-Abenteuer', "'Bruchrechnen'", 'pie_chart_rounded', 'Bruch'],
  artikel_lernen: ['Wörter-Abenteuer', "'Der / Die / Das'", 'menu_book_rounded', 'Wort',
    '_answered && _selectedAnswer != _correctArticle'],
  mehrzahl: ['Wörter-Abenteuer', "'Mehrzahl bilden'", 'auto_stories_rounded', 'Aufgabe'],
  wortarten: ['Wörter-Abenteuer', "'Wortarten'", 'menu_book_rounded', 'Aufgabe'],
  zeitformen: ['Wörter-Abenteuer', "'Zeitformen'", 'history_rounded', 'Aufgabe'],
  tiere: ['Welt-Abenteuer', "'Tiere lernen'", 'pets_rounded', 'Aufgabe'],
  farben: ['Welt-Abenteuer', "'Farben lernen'", 'palette_rounded', 'Aufgabe'],
  jahreszeiten: ['Welt-Abenteuer', "'Jahreszeiten'", 'nature_rounded', 'Aufgabe'],
  wetter: ['Welt-Abenteuer', "'Wetter lernen'", 'cloud_rounded', 'Aufgabe'],
  verkehr: ['Welt-Abenteuer', "'Verkehr & Sicherheit'", 'traffic_rounded', 'Aufgabe'],
};

function skipString(text, start) {
  const quote = text[start];
  const triple = text.slice(start, start + 3) === quote.repeat(3);
  const end = triple ? quote.repeat(3) : quote;
  for (let i = start + end.length; i < text.length; i++) {
    if (text[i] === '\\') {
      i++;
    } else if (text.slice(i, i + 2) === '${') {
      i = closing(text, i + 1, '{', '}');
    } else if (text.slice(i, i + end.length) === end) {
      return i + end.length - 1;
    }
  }
  throw new Error('Unterminated Dart string');
}

function closing(text, start, open, close) {
  let depth = 0;
  for (let i = start; i < text.length; i++) {
    if (text.slice(i, i + 2) === '//') {
      const next = text.indexOf('\n', i + 2);
      i = next < 0 ? text.length : next;
    } else if (text.slice(i, i + 2) === '/*') {
      const next = text.indexOf('*/', i + 2);
      if (next < 0) throw new Error('Unterminated comment');
      i = next + 1;
    } else if (text[i] === "'" || text[i] === '"') {
      i = skipString(text, i);
    } else if (text[i] === open) {
      depth++;
    } else if (text[i] === close && --depth === 0) {
      return i;
    }
  }
  throw new Error(`Missing ${close} for ${open} at ${start}`);
}

function method(text, name, returnType = 'Widget') {
  const match = new RegExp(`\\b${returnType}\\s+${name}\\s*\\(`).exec(text);
  if (!match) throw new Error(`Missing ${name}`);
  const parameters = text.indexOf('(', match.index);
  const paramsEnd = closing(text, parameters, '(', ')');
  const brace = text.indexOf('{', paramsEnd);
  const end = closing(text, brace, '{', '}') + 1;
  return { start: match.index, end, text: text.slice(match.index, end) };
}

function replaceMethod(text, name, transform) {
  const old = method(text, name);
  return text.slice(0, old.start) + transform(old.text) + text.slice(old.end);
}

function childOfScrollView(build) {
  const start = build.indexOf('SingleChildScrollView(');
  if (start < 0) throw new Error('Module does not use the expected scroll view');
  const parenthesis = build.indexOf('(', start);
  const end = closing(build, parenthesis, '(', ')');
  const call = build.slice(parenthesis + 1, end);
  const child = /\bchild\s*:\s*/.exec(call);
  if (!child) throw new Error('Scroll view has no child');
  const expressionStart = child.index + child[0].length;
  const expressionParen = call.indexOf('(', expressionStart);
  const expressionEnd = closing(call, expressionParen, '(', ')') + 1;
  return call.slice(expressionStart, expressionEnd);
}

const selected = process.argv.find(arg => arg.startsWith('--only='))
  ?.slice('--only='.length).split(',') ?? Object.keys(modules);
const protectedMethods = ['_generateTask', '_onAnswer', '_nextTask', '_showFinish'];
const normalized = text => text
  .replace(/setState\(\(\)\s*=>\s*_correctCount\+\+\);/g, '_correctCount++;')
  .replace(/\s+/g, '');

const verifyOnly = process.argv.includes('--verify');
let verifiedMethods = 0;
function tokenized(text) {
  text = text.replace(
    /setState\(\(\)\s*=>\s*_correctCount\+\+\);/g, '_correctCount++;');
  let result = '';
  for (let i = 0; i < text.length; i++) {
    if (text.slice(i, i + 2) === '//') {
      const next = text.indexOf('\n', i + 2);
      i = next < 0 ? text.length : next;
    } else if (text.slice(i, i + 2) === '/*') {
      const next = text.indexOf('*/', i + 2);
      if (next < 0) throw Error('Unterminated comment');
      i = next + 1;
    } else if (text[i] === "'" || text[i] === '"') {
      const end = skipString(text, i);
      result += text.slice(i, end + 1);
      i = end;
    } else if (!/\s/.test(text[i])) {
      result += text[i];
    }
  }
  return result;
}
function verifyMethods(name, names) {
  const file = `lib/features/learning_modules/${name}/${name}_screen.dart`;
  const old = execFileSync('git', ['show',
    `bef1403ed5d0243f8c6daca2717e998081cab15e:${file}`],
    { encoding: 'utf8' });
  const current = fs.readFileSync(file, 'utf8');
  for (const methodName of names) {
    const type = '(?:void|Future<void>|bool)';
    if (tokenized(method(old, methodName, type).text) !==
        tokenized(method(current, methodName, type).text)) {
      throw Error(`${name}: protected ${methodName} differs from build 1928`);
    }
    verifiedMethods++;
  }
  console.log(`${name}: ${names.length} protected methods unchanged`);
}

for (const name of selected) {
  if (verifyOnly) {
    verifyMethods(name, protectedMethods);
    continue;
  }
  const metadata = modules[name];
  if (!metadata) throw new Error(`Unknown module ${name}`);
  const file = `lib/features/learning_modules/${name}/${name}_screen.dart`;
  const original = fs.readFileSync(file, 'utf8');
  if (original.includes('child: LumoLearningModuleFrame(')) {
    console.log(`${name}: already migrated, not overwritten`);
    continue;
  }
  let source = original;
  const oldBuild = method(source, 'build');
  let child = childOfScrollView(oldBuild.text);
  child = child
    .replace(/const SizedBox\(height: (24|28|32)\)/g,
      (_, value) => `const SizedBox(height: ${Number(value) > 28 ? 16 : 12})`)
    .replace(/Opacity\(opacity:\s*_entryCtrl\.value/g,
      'Opacity(opacity: LumoLessonStyle.reducedMotion(context, widget.appState) ? 1 : _entryCtrl.value')
    .replace(/color: (?:const )?Color\(0xFF(?:7C3AED|B45309|92400E|6D28D9)\)/g,
      'color: LumoVisualTokens.white');
  const [title, moduleTitle, icon, progressLabel, mistake] = metadata;
  const replacement = `Widget build(BuildContext context) {
    return LearningModuleProgressScope(
      progress: _progress,
      child: LumoLearningModuleFrame(
        appState: widget.appState,
        title: '${title}',
        moduleTitle: ${moduleTitle},
        icon: Icons.${icon},
        taskIndex: _taskIdx,
        totalTasks: _totalTasks,
        correctAnswers: _correctCount,
        progressLabel: '${progressLabel}',
        ${mistake ? `hasMistake: ${mistake},` : ''}
        canLeave: () => !_progress.hasPending,
        child: ${child},
      ),
    );
  }`;
  source = source.slice(0, oldBuild.start) + replacement +
    source.slice(oldBuild.end);
  source = replaceMethod(source, '_buildTopBar', () => '');
  source = source.replace(
    "import '../../../widgets/design/lumo_design_system.dart';",
    "import '../../../widgets/design/lumo_learning_module_frame.dart';\n" +
      "import '../../../theme/lumo_visual_tokens.dart';",
  );
  source = source.replace(/\b_correctCount\+\+;/g,
    'setState(() => _correctCount++);');

  const methods = [...source.matchAll(/\bWidget\s+(_build\w+)\s*\(/g)]
    .map(match => match[1]);
  for (const methodName of methods) {
    if (/^_build(?:TaskHeader|FrageHeader|WordCard|SingularBox|SatzAnzeige|WortAnzeige|BigNumber|Dots|Visualization|ShapeVisualization)/.test(methodName)) {
      source = replaceMethod(source, methodName, text => text
        .replace(/color: Colors\.white\b/g,
          'color: LumoVisualTokens.lessonPanel.withValues(alpha: .65)')
        .replace(/color: _gradient\[1\](?:\.withOpacity\(0\.6\))?/g,
          'color: LumoVisualTokens.white')
        .replace(/color: _gradient\[0\]\.withOpacity\(0\.[134]\)/g,
          'color: LumoVisualTokens.cyan.withValues(alpha: .55)')
        .replace(/color: Color\(0xFF6B7280\)/g,
          'color: LumoVisualTokens.muted'));
    }
    if (/^_build(?:Answer|Options|CentAnswer|CoinAnswer|ColorOptions|WortGrid|WortartGrid|ZeitOptions|SatzOptions)/.test(methodName)) {
      source = replaceMethod(source, methodName, old => {
        let text = old
          .replace(/Color bgColor = Colors\.white;/g,
            'Color bgColor = LumoVisualTokens.lessonAnswer;')
          .replace(/Color textColor = (?:_gradient\[1\]|jz\.themeColor);/g,
            'Color textColor = LumoVisualTokens.white;')
          .replace(/Color borderColor = (?:_gradient\[0\]|jz\.themeColor|w\.color)\.withOpacity\(0\.[35]\);/g,
            'Color borderColor = LumoVisualTokens.cyan.withValues(alpha: .8);')
          .replace(/bgColor = const Color\(0xFFFEF3C7\);/g,
            'bgColor = const Color(0xFFFEF3C7);\n' +
              'textColor = const Color(0xFF713F12);')
          .replace(/GridView\.count\(/g, 'LumoLessonAnswerGrid(')
          .replace(/GestureDetector\(/g,
            'LumoLessonAnswerTap(\n' +
              'correct: _answered && isSelected ? isCorrect : null,');
        let cursor = 0;
        while (true) {
          const match = /decoration:\s*BoxDecoration\(/g;
          match.lastIndex = cursor;
          const found = match.exec(text);
          if (!found) break;
          const start = text.indexOf('BoxDecoration(', found.index);
          const opening = text.indexOf('(', start);
          const end = closing(text, opening, '(', ')') + 1;
          const decoration = text.slice(start, end);
          const background = /\bcolor:\s*bgColor,/.test(decoration)
            ? 'bgColor'
            : /\bcolor:\s*Colors\.white,/.test(decoration) &&
                /\bcolor:\s*borderColor,/.test(decoration)
              ? 'LumoVisualTokens.lessonAnswer'
              : null;
          if (background) {
            const replacement = `LumoLessonStyle.answer(background: ${background}, border: borderColor)`;
            text = text.slice(0, start) + replacement + text.slice(end);
            cursor = start + replacement.length;
          } else {
            cursor = end;
          }
        }
        // Actual color dots/coins retain their pedagogical colors.
        if (methodName === '_buildColorOptions') {
          text = text.replace(/color: _gradient\[1\]/g,
            'color: LumoVisualTokens.white');
        }
        return text;
      });
    }
    if (/^_build/.test(methodName)) {
      source = replaceMethod(source, methodName, text => text
        .replace(/final (shake) = math\.sin/g,
          'final $1 = LumoLessonStyle.reducedMotion(context, widget.appState) ? 0.0 : math.sin')
        .replace(/isSelected && isCorrect\n(\s*)\?/g,
          'isSelected && isCorrect && !LumoLessonStyle.reducedMotion(context, widget.appState)\n$1?')
        .replace(/duration: const Duration\(milliseconds: 200\)/g,
          'duration: LumoLessonStyle.reducedMotion(context, widget.appState) ? Duration.zero : const Duration(milliseconds: 200)'));
    }
  }
  for (const methodName of protectedMethods) {
    const returnType = methodName === '_showFinish'
      ? '(?:Future<void>|void)' : 'void';
    const before = method(original, methodName, returnType).text;
    const after = method(source, methodName, returnType).text;
    if (normalized(before) !== normalized(after)) {
      throw new Error(`${name}: protected ${methodName} changed; refusing write`);
    }
  }
  fs.writeFileSync(file, source);
  console.log(`${name}: migrated presentation, all protected task/storage/reward methods unchanged`);
}

if (verifyOnly) {
  verifyMethods('plus_bis_10', [
    '_generateTask', '_handleAnswer', '_saveAnswer', '_cancelPendingAnswer',
    '_retrySave', '_continueAfterCorrect', '_handleCorrect', '_handleWrong',
    '_nextTask', '_showFinish', '_saveFinish', '_scheduleFeedback',
    '_speakTask', '_leaveTo', 'didChangeAppLifecycleState',
  ]);
  verifyMethods('wort_diktat', [
    'initState', '_onSelfRate', '_onFinish', '_nextTask', '_showFinish',
    '_sayWord', '_repeatWord', '_clearAllStrokes',
  ]);
  console.log(`LUMO_LEARNING_LOGIC_PASS: ${verifiedMethods} protected methods`);
}

// Read-only proof that the durable boundary and Sulafat provider remain intact.
for (const file of [
  'lib/features/learning_modules/learning_module_progress.dart',
  'lib/core/lumo_voice.dart',
  'lib/features/writing/lumo_writing_coach_screen.dart',
]) {
  const before = execFileSync('git', ['show',
    `bef1403ed5d0243f8c6daca2717e998081cab15e:${file}`], { encoding: 'utf8' });
  if (fs.readFileSync(file, 'utf8') !== before) {
    throw new Error(`Protected existing file changed: ${file}`);
  }
}
