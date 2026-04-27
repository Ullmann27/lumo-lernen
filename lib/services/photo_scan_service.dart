// Stub – Real OCR requires camera plugin and parent consent
class PhotoScanService {
  bool _consentGranted = false;

  void grantConsent() => _consentGranted = true;
  void revokeConsent() => _consentGranted = false;

  Future<String?> scanImage() async {
    if (!_consentGranted) {
      throw Exception('Elternerlaubnis für Foto-Analyse erforderlich.');
    }
    // Stub: In production, use camera + ML Kit OCR
    return '12 + 7';
  }
}
