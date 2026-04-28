class OcrReadResult {
  const OcrReadResult({
    required this.text,
    required this.confidence,
    required this.sourceLabel,
    required this.needsReview,
  });

  final String text;
  final double confidence;
  final String sourceLabel;
  final bool needsReview;
}

class OcrService {
  const OcrService();

  Future<OcrReadResult> readFromTextInput(String text) async {
    final clean = text.trim();
    return OcrReadResult(
      text: clean,
      confidence: clean.isEmpty ? 0 : .72,
      sourceLabel: 'text_input',
      needsReview: clean.isEmpty || clean.length > 180,
    );
  }

  Future<OcrReadResult> readWithFutureOnDeviceConnector() async {
    return const OcrReadResult(
      text: '',
      confidence: 0,
      sourceLabel: 'future_on_device_ocr',
      needsReview: true,
    );
  }

  bool get isAvailable => true;
}
