enum AvatarMood { happy, thinking, encouraging, celebrating }

class AvatarDirector {
  AvatarMood _mood = AvatarMood.happy;
  AvatarMood get mood => _mood;

  void setMood(AvatarMood mood) {
    _mood = mood;
  }

  String get moodEmoji {
    switch (_mood) {
      case AvatarMood.happy:
        return '😊';
      case AvatarMood.thinking:
        return '🤔';
      case AvatarMood.encouraging:
        return '💪';
      case AvatarMood.celebrating:
        return '🎉';
    }
  }
}
