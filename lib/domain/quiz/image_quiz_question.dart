import 'package:flutter/foundation.dart';

import 'quiz_show.dart';

/// Visuelle Kategorie fuer Bild-Quiz-Fragen.
enum ImageQuizVisualCategory {
  shapes,
  colors,
  animals,
  foodAndVegetables,
  school,
  traffic,
  body,
  austria,
}

/// Eine einzelne Antwort-Option mit Bild/Emoji.
@immutable
class ImageChoice {
  const ImageChoice({
    required this.id,
    required this.label,
    this.assetPath,
    this.emojiFallback,
    this.semanticTags = const <String>[],
    this.shapeType,
    this.color,
  });

  final String id;
  final String label;
  final String? assetPath;
  final String? emojiFallback;
  final List<String> semanticTags;
  final String? shapeType;
  final String? color;
}

/// Eine Quiz-Frage mit Bild-/Emoji-Antwortoptionen (2x2 Grid).
@immutable
class ImageQuizQuestion {
  const ImageQuizQuestion({
    required this.id,
    required this.grade,
    required this.subject,
    required this.unit,
    required this.prompt,
    required this.imageChoices,
    required this.correctIndex,
    this.explanation,
    this.difficulty = QuizDifficulty.easy,
    this.visualCategory = ImageQuizVisualCategory.shapes,
  });

  final String id;
  final int grade;
  final String subject;
  final String unit;
  final String prompt;
  final List<ImageChoice> imageChoices;
  final int correctIndex;
  final String? explanation;
  final QuizDifficulty difficulty;
  final ImageQuizVisualCategory visualCategory;

  bool get isValid =>
      imageChoices.length == 4 &&
      correctIndex >= 0 &&
      correctIndex < 4 &&
      prompt.trim().isNotEmpty;

  ImageChoice get correctChoice => imageChoices[correctIndex];
}
