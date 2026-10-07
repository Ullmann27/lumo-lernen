"""Sammelt feste Lumo-Sätze aus dem App-Quellcode für die Clip-Produktion."""
import json, re, sys
root = sys.argv[1]
src = open(f'{root}/lib/features/learning_modules/lumo_phrases.dart').read()
style_of = {'_correctPhrases': 'celebrate', '_wrongGentlePhrases': 'comfort', '_hintPhrases': 'explain',
            '_greetingPhrases': 'greeting', '_celebratePhrases': 'celebrate', '_comfortPhrases': 'comfort'}
out = []
for name, style in style_of.items():
    body = re.search(name + r' = \[(.*?)\];', src, re.S).group(1)
    out += [{'text': t, 'style': style} for t in re.findall(r"'([^']+)'", body)]
lc = open(f'{root}/lib/features/learning/learning_content.dart').read()
body = re.search(r'String get _welcomeForKind \{(.*?)\n  \}', lc, re.S).group(1)
out += [{'text': t, 'style': 'greeting'} for t in re.findall(r"return '([^']+)';", body)]
for t in ['Hallo! Ich bin Lumo, dein Lernfuchs. Ich spreche jetzt ruhiger, freundlicher und menschlicher.',
          'Hallo! Was sollen wir heute spielen?', 'Welcher Bruch wurde gegessen?', 'Wie spät ist es?',
          'Welche Form ist das?', 'Mach den Strich ein bisschen länger!']:
    out.append({'text': t, 'style': 'greeting' if t.startswith('Hallo') else 'explain'})
for a in range(1, 6):
    for b in range(1, 11 - a):
        out.append({'text': f'{a} plus {b} - wie viel ist das?', 'style': 'explain'})
for a in range(3, 11):
    for b in range(1, a):
        out.append({'text': f'{a} minus {b}. Wie viele bleiben?', 'style': 'explain'})
for a in range(1, 11):
    for b in range(1, 11):
        out.append({'text': f'{a} mal {b}. Wie viel ist das?', 'style': 'explain'})
json.dump(out, open(sys.argv[2], 'w'), ensure_ascii=False, indent=0)
print(len(out))
