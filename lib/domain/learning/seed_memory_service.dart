import 'dart:math';

class SeenSeedRecord {
  const SeenSeedRecord({
    required this.childId,
    required this.templateId,
    required this.seedHash,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.seenCount,
  });

  final String childId;
  final String templateId;
  final String seedHash;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int seenCount;

  SeenSeedRecord copyWith({
    DateTime? lastSeenAt,
    int? seenCount,
  }) {
    return SeenSeedRecord(
      childId: childId,
      templateId: templateId,
      seedHash: seedHash,
      firstSeenAt: firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      seenCount: seenCount ?? this.seenCount,
    );
  }
}

abstract class SeedMemoryRepository {
  Future<SeenSeedRecord?> findSeenSeed({
    required String childId,
    required String templateId,
    required String seedHash,
  });

  Future<void> markSeen({
    required String childId,
    required String templateId,
    required String seedHash,
    required DateTime seenAt,
  });
}

class InMemorySeedMemoryRepository implements SeedMemoryRepository {
  final Map<String, SeenSeedRecord> _records = <String, SeenSeedRecord>{};

  @override
  Future<SeenSeedRecord?> findSeenSeed({
    required String childId,
    required String templateId,
    required String seedHash,
  }) async {
    return _records[_key(childId, templateId, seedHash)];
  }

  @override
  Future<void> markSeen({
    required String childId,
    required String templateId,
    required String seedHash,
    required DateTime seenAt,
  }) async {
    final key = _key(childId, templateId, seedHash);
    final existing = _records[key];
    if (existing == null) {
      _records[key] = SeenSeedRecord(
        childId: childId,
        templateId: templateId,
        seedHash: seedHash,
        firstSeenAt: seenAt,
        lastSeenAt: seenAt,
        seenCount: 1,
      );
      return;
    }

    _records[key] = existing.copyWith(
      lastSeenAt: seenAt,
      seenCount: existing.seenCount + 1,
    );
  }

  String _key(String childId, String templateId, String seedHash) =>
      '$childId::$templateId::$seedHash';
}

class SeedCandidate {
  const SeedCandidate({
    required this.rawSeed,
    required this.seedHash,
  });

  final String rawSeed;
  final String seedHash;
}

class SeedMemoryService {
  SeedMemoryService({
    required SeedMemoryRepository repository,
    Random? random,
  })  : _repository = repository,
        _random = random ?? Random();

  final SeedMemoryRepository _repository;
  final Random _random;

  Future<SeedCandidate> nextUnusedSeed({
    required String childId,
    required String templateId,
    required Map<String, Object?> seedContext,
    Duration cooldown = const Duration(days: 21),
    int maxAttempts = 80,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rawSeed = _buildSeed(
        templateId: templateId,
        seedContext: seedContext,
        attempt: attempt,
      );
      final seedHash = stableSeedHash(rawSeed);
      final seen = await _repository.findSeenSeed(
        childId: childId,
        templateId: templateId,
        seedHash: seedHash,
      );

      if (seen == null || currentTime.difference(seen.lastSeenAt) >= cooldown) {
        await _repository.markSeen(
          childId: childId,
          templateId: templateId,
          seedHash: seedHash,
          seenAt: currentTime,
        );
        return SeedCandidate(rawSeed: rawSeed, seedHash: seedHash);
      }
    }

    final fallbackSeed = _buildFallbackSeed(
      templateId: templateId,
      seedContext: seedContext,
      now: currentTime,
    );
    final fallbackHash = stableSeedHash(fallbackSeed);
    await _repository.markSeen(
      childId: childId,
      templateId: templateId,
      seedHash: fallbackHash,
      seenAt: currentTime,
    );
    return SeedCandidate(rawSeed: fallbackSeed, seedHash: fallbackHash);
  }

  String _buildSeed({
    required String templateId,
    required Map<String, Object?> seedContext,
    required int attempt,
  }) {
    final entries = seedContext.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final context = entries.map((entry) => '${entry.key}=${entry.value}').join('|');
    final entropy = _random.nextInt(1 << 32);
    return '$templateId|$context|attempt=$attempt|entropy=$entropy';
  }

  String _buildFallbackSeed({
    required String templateId,
    required Map<String, Object?> seedContext,
    required DateTime now,
  }) {
    final millis = now.microsecondsSinceEpoch;
    final entropy = _random.nextInt(1 << 32);
    return '$templateId|fallback=$millis|entropy=$entropy|context=${seedContext.length}';
  }

  static String stableSeedHash(String value) {
    // 64-bit FNV-1a style hash. Stable across app launches and does not need
    // external crypto dependencies.
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * prime) & 0x7fffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
