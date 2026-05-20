// ════════════════════════════════════════════════════════════════════════
//                    LUMO KART - DATENMODELLE
// ════════════════════════════════════════════════════════════════════════
//
// Vorbereitete Datenmodelle fuer Fahrer, Karts und Strecken.
// Phase 1 nutzt nur jeweils einen Eintrag (Lumo / Starter Kart /
// Blumen-Tal-Runde). Spaetere Phasen koennen weitere Eintraege
// freischalten.

/// Stat-Block fuer Fahrer/Karts. Werte 0..10. Spaeter beeinflussen sie
/// die KartTuning-Werte multiplikativ.
class KartStats {
  const KartStats({
    this.speed = 6,
    this.acceleration = 6,
    this.handling = 6,
    this.boost = 6,
  });

  final int speed;
  final int acceleration;
  final int handling;
  final int boost;
}

class KartDriverModel {
  const KartDriverModel({
    required this.id,
    required this.name,
    required this.species,
    required this.portraitAsset,
    this.unlocked = false,
    this.stats = const KartStats(),
    this.tagline = '',
  });

  final String id;
  final String name;
  final String species;
  final String portraitAsset;
  final bool unlocked;
  final KartStats stats;
  final String tagline;
}

class KartVehicleModel {
  const KartVehicleModel({
    required this.id,
    required this.name,
    required this.spriteAsset,
    this.unlocked = false,
    this.stats = const KartStats(),
    this.description = '',
  });

  final String id;
  final String name;
  final String spriteAsset;
  final bool unlocked;
  final KartStats stats;
  final String description;
}

class KartTrackModel {
  const KartTrackModel({
    required this.id,
    required this.name,
    required this.previewAsset,
    required this.theme,
    this.unlocked = false,
    this.difficulty = 1,
    this.description = '',
  });

  final String id;
  final String name;
  final String previewAsset;

  /// Visuelles Theme der Strecke, z.B. 'meadow', 'forest', 'beach'.
  final String theme;

  final bool unlocked;

  /// 1 = leicht, 5 = sehr schwer.
  final int difficulty;
  final String description;
}

/// Katalog der in Phase 1 verfuegbaren Inhalte. Gesperrte Eintraege
/// sind sichtbar im Menue, aber nicht spielbar.
class KartCatalog {
  const KartCatalog._();

  static const KartDriverModel lumoDriver = KartDriverModel(
    id: 'lumo',
    name: 'Lumo',
    species: 'Fuchs',
    portraitAsset: 'assets/lumo_sprite_pack/lumo_main.png',
    unlocked: true,
    stats: KartStats(speed: 7, acceleration: 7, handling: 7, boost: 7),
    tagline: 'Lumo liebt schnelle Kurven.',
  );

  static const List<KartDriverModel> drivers = <KartDriverModel>[
    lumoDriver,
    KartDriverModel(
      id: 'hase',
      name: 'Hopsi',
      species: 'Hase',
      portraitAsset: 'assets/lumo_sprite_pack/lumo_main.png',
      stats: KartStats(speed: 8, acceleration: 7, handling: 5, boost: 6),
      tagline: 'Bald freischaltbar.',
    ),
    KartDriverModel(
      id: 'elefant',
      name: 'Toni',
      species: 'Elefant',
      portraitAsset: 'assets/lumo_sprite_pack/lumo_main.png',
      stats: KartStats(speed: 5, acceleration: 5, handling: 8, boost: 9),
      tagline: 'Bald freischaltbar.',
    ),
    KartDriverModel(
      id: 'reh',
      name: 'Mira',
      species: 'Reh',
      portraitAsset: 'assets/lumo_sprite_pack/lumo_main.png',
      stats: KartStats(speed: 7, acceleration: 8, handling: 7, boost: 5),
      tagline: 'Bald freischaltbar.',
    ),
    KartDriverModel(
      id: 'igel',
      name: 'Pieks',
      species: 'Igel',
      portraitAsset: 'assets/lumo_sprite_pack/lumo_main.png',
      stats: KartStats(speed: 6, acceleration: 6, handling: 8, boost: 7),
      tagline: 'Bald freischaltbar.',
    ),
  ];

  static const KartVehicleModel starterKart = KartVehicleModel(
    id: 'starter',
    name: 'Starter Kart',
    spriteAsset:
        'assets/lumo_kart/kart/lumo_kart_360_vehicle_sheet_asset_001.png',
    unlocked: true,
    stats: KartStats(speed: 6, acceleration: 7, handling: 7, boost: 6),
    description: 'Ein zuverlaessiges Kart fuer alle Strecken.',
  );

  static const List<KartVehicleModel> vehicles = <KartVehicleModel>[
    starterKart,
    KartVehicleModel(
      id: 'turbo',
      name: 'Turbo Flitzer',
      spriteAsset:
          'assets/lumo_kart/kart/lumo_kart_360_vehicle_sheet_asset_004.png',
      stats: KartStats(speed: 9, acceleration: 6, handling: 5, boost: 8),
      description: 'Bald freischaltbar.',
    ),
    KartVehicleModel(
      id: 'cruiser',
      name: 'Wolken Cruiser',
      spriteAsset:
          'assets/lumo_kart/kart/lumo_kart_360_vehicle_sheet_asset_007.png',
      stats: KartStats(speed: 7, acceleration: 7, handling: 8, boost: 7),
      description: 'Bald freischaltbar.',
    ),
  ];

  static const KartTrackModel meadowLap = KartTrackModel(
    id: 'meadow_lap',
    name: 'Blumen-Tal-Runde',
    previewAsset:
        'assets/lumo_kart/environment/environment_world_decor_asset_001.png',
    theme: 'meadow',
    unlocked: true,
    difficulty: 1,
    description:
        'Eine sonnige Wiesen-Strecke mit sanften Kurven und vielen Sternen.',
  );

  static const List<KartTrackModel> tracks = <KartTrackModel>[
    meadowLap,
    KartTrackModel(
      id: 'forest_loop',
      name: 'Waldlichtung',
      previewAsset:
          'assets/lumo_kart/environment/environment_world_decor_asset_010.png',
      theme: 'forest',
      difficulty: 2,
      description: 'Bald freischaltbar.',
    ),
    KartTrackModel(
      id: 'beach_dash',
      name: 'Sandstrand',
      previewAsset:
          'assets/lumo_kart/environment/environment_world_decor_asset_020.png',
      theme: 'beach',
      difficulty: 3,
      description: 'Bald freischaltbar.',
    ),
  ];
}
