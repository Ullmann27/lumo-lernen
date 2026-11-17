import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../../lib/features/games/memory/memory_rules.dart';
import '../../lib/features/games/memory/memory_round.dart';
import '../../lib/features/games/memory/memory_table_session.dart';
import '../../lib/features/lumo3d/native_table_transport.dart';
import 'memory_original_board_fixture.dart';

// This executable is an explicit QA boundary: real production rules/controller/
// session, original dealer fixture, a local disk store, deterministic lifecycle
// clock and idempotent award ledger. It is not Android Binder/SharedPreferences.
const owner = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const epochMilliseconds = 1794657600000;

void require(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> atomicText(File file, String text) async {
  final temporary = File('${file.path}.tmp');
  await temporary.writeAsString(text, flush: true);
  await temporary.rename(file.path);
}

Future<void> atomicJson(File file, Object value) => atomicText(file, jsonEncode(value));

class OriginalCatalog implements MemoryCatalog {
  const OriginalCatalog();
  @override
  List<String> deal(String difficulty, math.Random random, String pack) =>
      MemoryBoard.deal(MemoryDifficulty.values.byName(difficulty), random,
          pack: MemoryThemePack.values.byName(pack)).map((motif) => motif.name).toList();
  @override
  int cardCount(String difficulty) => MemoryDifficulty.values.byName(difficulty).cards;
  @override
  bool containsMotif(String name) => MemoryMotif.values.any((motif) => motif.name == name);
  @override
  int starsFor(String difficulty, {required bool won, required bool draw}) =>
      MemoryDifficulty.values.byName(difficulty).starsFor(won: won, draw: draw);
}

class DiskStore implements MemoryStore {
  DiskStore(this.directory);
  final Directory directory;
  File get round => File('${directory.path}/round-$owner.json');
  File get stats => File('${directory.path}/stats-$owner.json');
  @override
  Future<String?> readRound() async => await round.exists() ? round.readAsString() : null;
  @override
  Future<String?> readStats() async => await stats.exists() ? stats.readAsString() : null;
  @override
  Future<void> writeRound(String value) => atomicText(round, value);
  @override
  Future<void> writeStats(String value) => atomicText(stats, value);
}

class DiskTransport implements NativeTableTransport {
  DiskTransport(this.directory);
  final Directory directory;
  String? activeToken;
  Map<String, Object?>? state;
  Map<String, dynamic> box = {};
  final closedTokens = <String>[];
  int publications = 0;
  @override
  Future<void> open(String token, Map<String, Object?> value) async {
    require(activeToken == null && value['token'] == token && value['owner'] == owner,
        'one profile-bound native transport');
    activeToken = token;
    state = Map.from(value);
    await atomicJson(File('${directory.path}/public-state.json'), state!);
  }
  @override
  Future<Map<String, dynamic>> poll(String token) async {
    require(activeToken == token, 'poll exact active token');
    return Map.from(box);
  }
  @override
  Future<void> publish(String token, Map<String, Object?> value) async {
    require(activeToken == token && value['token'] == token && value['owner'] == owner,
        'publish exact active token and owner');
    require((value['revision'] as int) > (state!['revision'] as int), 'strict publication revision');
    state = Map.from(value);
    publications++;
    await atomicJson(File('${directory.path}/public-state.json'), state!);
  }
  @override
  Future<void> close(String token) async {
    closedTokens.add(token);
    if (activeToken == token) activeToken = null;
  }
}

class Authority {
  Authority(this.directory) : store = DiskStore(directory), transport = DiskTransport(directory);
  final Directory directory;
  final DiskStore store;
  final DiskTransport transport;
  final catalog = const OriginalCatalog();
  late MemoryRoundController controller;
  late MemoryTableSession session;
  int clock = 0;
  int pauseEpoch = 0;
  bool active = true;
  int lastInput = 0;
  int awardCalls = 0;
  String? initialRound;
  Map<String, Object?>? unfinishedReopen;
  Map<String, Object?>? completedRound;
  Map<String, Object?>? paidReopen;
  final requests = <Map<String, Object?>>[];
  final states = <Map<String, Object?>>[];
  final tokens = <String>[];
  final botPhases = <String>{};
  static const otherChildRaw = '{"schema":1,"unrelatedChild":"preserve exact bytes"}';

  Future<void> award(String resultId, String difficulty, int kind, int lumo) async {
    require(resultId == controller.round.resultId && controller.state.complete,
        'reward belongs to actual completed round');
    awardCalls++;
    final file = File('${directory.path}/wallet.json');
    final value = await file.exists()
        ? jsonDecode(await file.readAsString()) as Map<String, dynamic>
        : <String, dynamic>{'stars': 0, 'xp': 0, 'ids': <String>[]};
    final ids = List<String>.from(value['ids'] as List);
    if (!ids.contains(resultId)) {
      final stars = catalog.starsFor(difficulty, won: kind > lumo, draw: kind == lumo);
      ids.add(resultId);
      value['ids'] = ids;
      value['stars'] = (value['stars'] as int) + stars;
      value['xp'] = (value['xp'] as int) + stars * 8;
      await atomicJson(file, value);
    }
  }

  Future<void> open() async {
    controller = await MemoryRoundController.open(
      owner: owner, catalog: catalog, store: store, award: award,
      canUseProfile: () => true, difficulty: 'leicht', pack: 'alle', seed: 73,
    );
    session = MemoryTableSession(
      controller: controller, transport: transport,
      now: () => DateTime.fromMillisecondsSinceEpoch(epochMilliseconds + clock),
      monotonicMilliseconds: () => clock,
    );
    await session.open(automaticPolling: false);
    tokens.add(session.token);
    initialRound ??= controller.round.id;
    await pump(null);
  }

  Future<void> pump(String? rawRequest) async {
    Map<String, dynamic>? request;
    if (rawRequest != null) {
      // Preserve the original request text across Godot's JSON decoder. A
      // parse/stringify round-trip there would silently change int fields.
      final parsed = jsonDecode(rawRequest);
      require(parsed is Map<String, dynamic>, 'raw native intent is a JSON object');
      request = parsed as Map<String, dynamic>;
      require(request['sequence'] is int && request['revision'] is int,
          'native integer fields retain exact JSON types');
    }
    transport.box = {
      'lifecycle': {'active': active, 'pauseEpoch': pauseEpoch,
        'stamp': epochMilliseconds + clock},
      if (request != null) 'request': request,
    };
    await session.pump();
    require(session.view['error'] == null, 'production session reports no persistence error');
    if (request != null) {
      requests.add({'input_id': lastInput, 'raw': rawRequest, 'request': request,
        'ack': session.view['ack'], 'rejected': session.view['rejected'],
        'recordRevision': controller.round.revision});
      require(session.view['ack'] == request['sequence'], 'every intended legal native request receives durable ACK');
    }
    if (controller.state.turn == 'lumo') botPhases.add(controller.state.phase);
    states.add({'input_id': lastInput, 'clock_ms': clock, 'state': session.view});
    await privatePlan();
  }

  Future<void> privatePlan() async {
    final cards = controller.state.cards;
    final pairs = <List<int>>[];
    final seen = <String>{};
    for (var i = 0; i < cards.length; i++) {
      if (seen.add(cards[i])) pairs.add([i, cards.indexOf(cards[i], i + 1)]);
    }
    final second = cards.indexWhere((motif) => motif != cards.first);
    await atomicJson(File('${directory.path}/private-test-control.json'), {
      'scope': 'QA oracle only; never consumed by the production renderer',
      'roundId': controller.round.id, 'mismatch': [0, second], 'pairs': pairs,
    });
  }

  Future<void> reopen(String mode) async {
    require(session.view['exit'] == true && controller.round.paused,
        'reopen only after actual native exit was durably acknowledged');
    final before = controller.round;
    final beforeToken = session.token;
    final rawBefore = await store.readRound();
    final walletFile = File('${directory.path}/wallet.json');
    final walletBefore = await walletFile.exists() ? await walletFile.readAsString() : null;
    await atomicText(File('${directory.path}/$mode-before-round.json'), rawBefore!);
    await session.close();
    controller.dispose();
    await open();
    require(session.token != beforeToken, 'reopen creates a new native session token');
    if (mode == 'unfinished-reopen') {
      require(!before.rules.complete && controller.round.id == before.id && controller.round.paused,
          'unfinished saved round identity and explicit pause restored');
      require(jsonEncode(controller.state.toJson()) == jsonEncode(before.rules.toJson()),
          'unfinished deck, timing, opponent memory and random stream restored exactly');
      unfinishedReopen = {'roundId': before.id, 'restoredRoundId': controller.round.id,
        'oldToken': beforeToken, 'newToken': session.token, 'paused': true,
        'remainingMs': controller.state.remainingMs};
    } else {
      require(before.rules.complete && before.rewarded && !controller.state.complete &&
          controller.round.id != before.id, 'paid completed reopen starts one distinct new round');
      require(controller.state.difficulty == before.rules.difficulty &&
          controller.state.pack == before.rules.pack, 'paid reopen retains selected level and motifs');
      require(await walletFile.readAsString() == walletBefore, 'paid reopen does not pay again');
      completedRound = before.toJson();
      paidReopen = {'completedRoundId': before.id, 'newRoundId': controller.round.id,
        'oldToken': beforeToken, 'newToken': session.token, 'best': controller.best,
        'difficulty': controller.state.difficulty, 'pack': controller.state.pack};
    }
  }

  Future<bool> step(Map<String, dynamic> input) async {
    require(input['id'] is int && input['id'] == lastInput + 1, 'strict QA step order');
    require(input['clock_ms'] is int && (input['clock_ms'] as int) >= clock &&
        (input['clock_ms'] as int) - clock <= 10000, 'bounded monotonic QA clock');
    lastInput = input['id'] as int;
    clock = input['clock_ms'] as int;
    final control = input['control'];
    if (control == 'unfinished-reopen' || control == 'paid-reopen') {
      require(input['request_raw'] == null, 'reopen is a separate QA lifecycle boundary');
      await reopen(control as String);
    } else if (control == 'finish') {
      require(input['request_raw'] == null && session.view['exit'] == true,
          'finish follows final acknowledged native return');
      await finish();
    } else {
      require(control == null, 'no undeclared QA control');
      final raw = input['request_raw'];
      require(raw == null || raw is String, 'native request stays raw JSON text');
      await pump(raw as String?);
    }
    await atomicJson(File('${directory.path}/step-receipt.json'), {
      'id': lastInput, 'clock_ms': clock, 'status': 'ACK',
      'token': session.token, 'roundId': controller.round.id,
      'revision': session.view['revision'],
    });
    return control == 'finish';
  }

  Future<void> finish() async {
    require(unfinishedReopen != null && paidReopen != null && completedRound != null,
        'both actual save/reopen boundaries observed');
    require(botPhases.contains('botFirst') && botPhases.contains('botSecond') && botPhases.contains('resolve'),
        'real Dart opponent progressed through both decisions');
    final finalRules = completedRound!['rules'] as Map<String, Object?>;
    require(finalRules['kindPairs'] == 4 && finalRules['lumoPairs'] == 0 &&
        finalRules['kindMoves'] == 4 && completedRound!['rewarded'] == true,
        'four legal actual card pairs completed and persisted');
    final wallet = jsonDecode(await File('${directory.path}/wallet.json').readAsString()) as Map<String, dynamic>;
    require(wallet['stars'] == 2 && wallet['xp'] == 16 && (wallet['ids'] as List).length == 1 && awardCalls == 1,
        'original easy reward acknowledged exactly once in QA ledger');
    require(controller.best['leicht'] == 4 && controller.best['schwer'] == 17,
        'new best added and pre-existing level best retained');
    require(await File('${directory.path}/other-child.json').readAsString() == otherChildRaw,
        'unrelated child bytes preserved');
    final stats = jsonDecode((await store.readStats())!) as Map<String, dynamic>;
    require(stats['retained'] == 'original-field', 'unrelated statistics field retained');
    await session.close();
    await atomicJson(File('${directory.path}/authority-result.json'), {
      'schema': 1, 'success': true,
      'scope': 'Production Dart rules/controller/session with original dealer fixture, explicit QA disk store/transport, monotonic clock fixture and idempotent award ledger; no Android/device FPS claim.',
      'owner': owner, 'initial_round': initialRound, 'tokens': tokens,
      'unfinished_reopen': unfinishedReopen, 'completed_round': completedRound,
      'paid_reopen': paidReopen, 'wallet': wallet, 'award_calls': awardCalls,
      'bot_phases': botPhases.toList()..sort(), 'requests': requests,
      'states': states, 'publications': transport.publications,
      'closed_tokens': transport.closedTokens,
    });
    controller.dispose();
    stdout.writeln('[MemoryNativeAuthority] complete inputs=$lastInput requests=${requests.length} rewards=$awardCalls');
  }
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) throw ArgumentError('Pass one fresh QA exchange directory');
  final directory = Directory(arguments.single).absolute;
  await directory.create(recursive: true);
  require(!await File('${directory.path}/public-state.json').exists(), 'QA output must be fresh');
  final authority = Authority(directory);
  await atomicText(File('${directory.path}/other-child.json'), Authority.otherChildRaw);
  await atomicJson(authority.store.stats, {'difficulty': 'leicht', 'best': {'schwer': 17}, 'retained': 'original-field'});
  final limit = Stopwatch()..start();
  try {
    await authority.open();
    stdout.writeln('[MemoryNativeAuthority] ready');
    while (limit.elapsed < const Duration(seconds: 300)) {
      final inputFile = File('${directory.path}/input.json');
      if (await inputFile.exists()) {
        final input = jsonDecode(await inputFile.readAsString());
        require(input is Map<String, dynamic>, 'QA input object');
        if (input['id'] != authority.lastInput && await authority.step(input as Map<String, dynamic>)) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    throw TimeoutException('Memory authority pair did not finish within 300 wall seconds');
  } catch (error, stack) {
    await atomicJson(File('${directory.path}/authority-failure.json'), {
      'success': false, 'error': error.toString(), 'stack': stack.toString(),
      'last_input': authority.lastInput, 'requests': authority.requests,
    });
    stderr.writeln('$error\n$stack');
    exitCode = 1;
  }
}
