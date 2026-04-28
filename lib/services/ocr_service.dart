class OcrService {
  const OcrService();

  Future<String> recognizeImagePath(String imagePath) async {
    // Foundation only: real on-device OCR can be wired later with Google ML Kit.
    // Keeping this service isolated prevents camera/OCR changes from breaking the AppShell.
    if (imagePath.trim().isEmpty) return '';
    return 'OCR vorbereitet fuer: $imagePath';
  }

  bool get isAvailable => true;
}
