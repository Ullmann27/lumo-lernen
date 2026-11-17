/// Die Kart-Flotte aus Lumo Kart, wie sie das Spiel freischaltet.
///
/// Spiegel von `scripts/games/kart_fleet.gd` im Repository lumo-godot
/// (Kennung, Name, Rolle, Sternschwelle). Die Bilder unter
/// `assets/lumo_design/karts/` sind echte Aufnahmen der Kart-Modelle aus der
/// Spiel-Engine. `scripts/verify_kart_fleet_mirror.py` vergleicht diese Liste
/// beim APK-Bau mit dem gepinnten Spielstand.
class KartFleetEntry {
  const KartFleetEntry(this.id, this.name, this.role, this.unlockStars);

  final String id;
  final String name;
  final String role;

  /// So viele Sterne muss das Kind insgesamt verdient haben.
  final int unlockStars;

  String get asset => 'assets/lumo_design/karts/$id.webp';
}

abstract final class KartFleetCatalog {
  /// Aufsteigend nach Sternschwelle.
  static const List<KartFleetEntry> all = [
    KartFleetEntry('comet', 'Comet', 'Allrounder', 0),
    KartFleetEntry('gecko_velo', 'Gecko Velo', 'Flink', 0),
    KartFleetEntry('boru_rally', 'Boru Rally', 'Rallye', 4),
    KartFleetEntry('glider', 'Glider', 'Wendig', 8),
    KartFleetEntry('nala_comet', 'Nala Comet', 'Sportlich', 10),
    KartFleetEntry('noa_tide', 'Noa Tide', 'Komfort', 12),
    KartFleetEntry('iva_aurora', 'Iva Aurora', 'Aero', 16),
    KartFleetEntry('turbo', 'Aurora GT', 'Highspeed', 18),
    KartFleetEntry('zuri_volt', 'Zuri Volt', 'Elektro', 20),
    KartFleetEntry('blitz', 'Blitz', 'Dragster', 32),
    KartFleetEntry('terra', 'Terra', 'Gelände', 48),
    KartFleetEntry('koloss', 'Koloss', 'Schwergewicht', 66),
    KartFleetEntry('phantom', 'Phantom', 'Drift-Profi', 88),
    KartFleetEntry('stella', 'Stella', 'Champion', 120),
  ];

  /// Freigeschaltete Karts, das zuletzt verdiente zuerst.
  static List<KartFleetEntry> unlocked(int earnedStars) => [
        for (final kart in all.reversed)
          if (earnedStars >= kart.unlockStars) kart,
      ];

  /// Das nächste noch gesperrte Kart; `null`, wenn alle frei sind.
  static KartFleetEntry? next(int earnedStars) {
    for (final kart in all) {
      if (earnedStars < kart.unlockStars) return kart;
    }
    return null;
  }
}
