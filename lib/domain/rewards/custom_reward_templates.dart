import 'reward_shop.dart';

/// Named family ideas from baseVouchers() in the supplied working HTML 05.
/// Prices are deliberately not copied from its different XP/star economy.
/// Choosing an idea never creates a voucher; parents enter its price and save.
class CustomRewardTemplate {
  const CustomRewardTemplate(this.title, this.category, this.emoji);
  final String title;
  final CustomRewardCategory category;
  final String emoji;
}

const customRewardTemplates = <CustomRewardTemplate>[
  CustomRewardTemplate('Picknick', CustomRewardCategory.leisure, '🧺'),
  CustomRewardTemplate('Schatzsuche', CustomRewardCategory.leisure, '🗺️'),
  CustomRewardTemplate('Seifenblasen', CustomRewardCategory.leisure, '🫧'),
  CustomRewardTemplate('Ballspiel', CustomRewardCategory.sport, '⚽'),
  CustomRewardTemplate('Roller', CustomRewardCategory.sport, '🛴'),
  CustomRewardTemplate('Radfahren', CustomRewardCategory.sport, '🚲'),
  CustomRewardTemplate('Klettern', CustomRewardCategory.sport, '🧗'),
  CustomRewardTemplate(
      'Hörgeschichte', CustomRewardCategory.entertainment, '🎧'),
  CustomRewardTemplate('Kinderlied', CustomRewardCategory.entertainment, '🎵'),
  CustomRewardTemplate('Puppenspiel', CustomRewardCategory.entertainment, '🎭'),
  CustomRewardTemplate('Knete', CustomRewardCategory.creative, '🎨'),
  CustomRewardTemplate('Papierflieger', CustomRewardCategory.creative, '✂️'),
  CustomRewardTemplate('Wasserfarben', CustomRewardCategory.creative, '🎨'),
  CustomRewardTemplate('Brettspiel', CustomRewardCategory.family, '🎲'),
  CustomRewardTemplate('Kuschelrunde', CustomRewardCategory.family, '💛'),
  CustomRewardTemplate('Puzzle', CustomRewardCategory.family, '🧩'),
];
