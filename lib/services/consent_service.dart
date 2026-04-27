import 'package:flutter/foundation.dart';

class ConsentService extends ChangeNotifier {
  bool _microphone = false;
  bool _photoAnalysis = false;
  bool _aiVoice = false;
  bool _cloudSync = false;

  bool get microphone => _microphone;
  bool get photoAnalysis => _photoAnalysis;
  bool get aiVoice => _aiVoice;
  bool get cloudSync => _cloudSync;

  void setMicrophone(bool value) {
    _microphone = value;
    notifyListeners();
  }

  void setPhotoAnalysis(bool value) {
    _photoAnalysis = value;
    notifyListeners();
  }

  void setAiVoice(bool value) {
    _aiVoice = value;
    notifyListeners();
  }

  void setCloudSync(bool value) {
    _cloudSync = value;
    notifyListeners();
  }

  void deleteAllData() {
    _microphone = false;
    _photoAnalysis = false;
    _aiVoice = false;
    _cloudSync = false;
    notifyListeners();
  }
}
