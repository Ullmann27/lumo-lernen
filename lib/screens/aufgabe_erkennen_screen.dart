import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/recognition_engine.dart';

class AufgabeErkennenScreen extends StatefulWidget {
  const AufgabeErkennenScreen({super.key});

  @override
  State<AufgabeErkennenScreen> createState() => _AufgabeErkennenScreenState();
}

class _AufgabeErkennenScreenState extends State<AufgabeErkennenScreen> {
  final TextEditingController _controller = TextEditingController();
  RecognitionResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recognize() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _result = RecognitionEngine.recognize(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Aufgabe erkennen'),
        backgroundColor: AppTheme.softGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Was möchtest du lernen?',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'z.B. "12 + 7" oder "Was reimt sich auf Haus?"',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _recognize(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _recognize,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Erkennen'),
              ),
              const SizedBox(height: 24),
              if (_result != null) _buildResultCard(),
              const Divider(height: 40),
              Text('Beispiele:',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...[
                '12 + 7',
                '18 - 5',
                '2, 4, 6, ?',
                'Anfangsbuchstabe Mama',
                'Was reimt sich auf Haus?',
                'Neue Note Mathe 2',
              ].map((example) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        _controller.text = example;
                        _recognize();
                      },
                      child: Text(example),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    return Card(
      color: AppTheme.turquoise.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 Erkannt: ${r.type}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Antwort: ${r.answer}',
                style: const TextStyle(fontSize: 16)),
            if (r.explanation != null) ...[
              const SizedBox(height: 8),
              Text(r.explanation!,
                  style:
                      const TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}
