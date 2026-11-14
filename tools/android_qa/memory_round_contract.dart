import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../../lib/features/games/memory/memory_rules.dart';
import '../../lib/features/games/memory/memory_round.dart';
import '../../lib/features/games/memory/memory_table_session.dart';
import '../../lib/features/lumo3d/native_table_transport.dart';
import 'memory_original_board_fixture.dart';
import 'memory_original_opponent_fixture.dart';

class ContractMemoryCatalog implements MemoryCatalog {
  @override
  List<String> deal(String difficulty, math.Random random, String pack) =>
      MemoryBoard.deal(MemoryDifficulty.values.byName(difficulty), random,
          pack: MemoryThemePack.values.byName(pack)).map((m) => m.name).toList();
  @override
  int cardCount(String difficulty) => MemoryDifficulty.values.byName(difficulty).cards;
  @override
  bool containsMotif(String name) => MemoryMotif.values.any((m) => m.name == name);
  @override
  int starsFor(String difficulty, {required bool won, required bool draw}) =>
      MemoryDifficulty.values.byName(difficulty).starsFor(won: won, draw: draw);
}

class ContractMemoryStore implements MemoryStore {
  String? round;
  String? stats;
  String legacy = '{"old":"preserve"}';
  String? fail;
  Completer<void>? beforeWrite;
  int roundWrites = 0;
  int statsWrites = 0;
  @override
  Future<String?> readRound() async => round;
  @override
  Future<String?> readStats() async => stats;
  @override
  Future<void> writeRound(String value) async {
    final gate = beforeWrite;
    beforeWrite = null;
    if (gate != null) await gate.future;
    final failure = fail;
    fail = null;
    roundWrites++;
    if (failure == 'before') throw StateError('write rejected');
    round = value;
    if (failure == 'after') throw StateError('reply lost after commit');
  }
  @override
  Future<void> writeStats(String value) async { statsWrites++; stats = value; }
}

class ContractMemoryTransport implements NativeTableTransport {
  Map<String, Object?>? state;
  Map<String, dynamic> box = {};
  final List<Map<String, Object?>> publications = [];
  final List<String> closed = [];
  bool failOpenAfterWrite = false;
  bool failPublish = false;
  @override
  Future<void> open(String token, Map<String, Object?> value) async {
    expect(state == null, 'one active table');
    expect(value['token'] == token, 'open token');
    state = Map.from(value);
    if (failOpenAfterWrite) throw StateError('open reply lost');
  }
  @override
  Future<Map<String, dynamic>> poll(String token) async {
    expect(state?['token'] == token, 'poll owns exact token');
    return Map.from(box);
  }
  @override
  Future<void> publish(String token, Map<String, Object?> value) async {
    expect(value['token'] == token && state?['token'] == token, 'publish token');
    expect(value['owner'] == state?['owner'], 'publish child cannot change');
    expect((value['revision'] as int) > (state!['revision'] as int), 'strict new revision');
    expect((value['ack'] as int) >= (state!['ack'] as int), 'ACK monotonic');
    expect((value['rejected'] as int) >= (state!['rejected'] as int), 'rejection monotonic');
    if (failPublish) throw StateError('transport unavailable');
    state = Map.from(value);
    publications.add(Map.from(value));
  }
  @override
  Future<void> close(String token) async {
    closed.add(token);
    if (state?['token'] == token) state = null;
  }
}

const owner = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const other = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
int checks = 0;
int passed = 0;
final failures = <String>[];
final catalog = ContractMemoryCatalog();

void expect(bool condition, String reason) {
  checks++;
  if (!condition) throw StateError(reason);
}
void equal(Object? actual, Object? expected, String reason) =>
    expect(jsonEncode(actual) == jsonEncode(expected),
        reason + ': ' + jsonEncode(actual) + ' != ' + jsonEncode(expected));

Future<void> rejects(FutureOr<void> Function() action, String reason) async {
  var rejected = false;
  try { await action(); } catch (_) { rejected = true; }
  expect(rejected, reason);
}

Future<void> test(String name, FutureOr<void> Function() action) async {
  try {
    await action();
    passed++;
    stdout.writeln('PASS ' + name);
  } catch (error, stack) {
    failures.add(name);
    stderr.writeln('FAIL ' + name + ': ' + error.toString() + '\n' + stack.toString());
  }
}

Future<MemoryRoundController> open(
  ContractMemoryStore store, {
  String child = owner,
  String difficulty = 'leicht',
  String pack = 'alle',
  int seed = 73,
  bool Function()? current,
  MemoryAward? award,
}) => MemoryRoundController.open(
  owner: child, catalog: catalog, store: store, difficulty: difficulty,
  pack: pack, seed: seed, canUseProfile: current ?? () => true,
  award: award ?? (id, level, kind, lumo) async {},
);

Future<void> finish(MemoryRoundController controller) async {
  if (controller.round.paused) await controller.setPaused(false);
  final cards = [...controller.state.cards];
  for (final motif in cards.toSet()) {
    final first = cards.indexOf(motif);
    final second = cards.lastIndexOf(motif);
    if (controller.state.matched[first]) continue;
    expect(await controller.flip(first), 'first legal complete-round card');
    expect(await controller.flip(second), 'second legal complete-round card');
    await controller.advance(850);
  }
}

Map<String, dynamic> request(MemoryTableSession session, int sequence,
    String action, [Map<String, Object?> extra = const {}]) => {
  'token': session.token, 'roundId': session.controller.round.id,
  'revision': session.view['revision'], 'sequence': sequence,
  'action': action, ...extra,
};

Future<void> main(List<String> args) async {
  await test('fixture is the exact current original dealer with only a Color DTO', () {
    final original = File('lib/domain/games/memory_board.dart').readAsStringSync();
    final expected = original.replaceFirst(
      "import 'package:flutter/painting.dart';",
      'class Color { const Color(this.value); final int value; }',
    );
    equal(File('tools/android_qa/memory_original_board_fixture.dart').readAsStringSync(),
        expected, 'dealer, themes, enum and reward formula remain original');
  });

  await test('all five difficulties and four packs retain the original seeded dealer', () {
    for (final level in MemoryDifficulty.values) {
      for (final pack in MemoryThemePack.values) {
        for (var seed = 0; seed < 12; seed++) {
          final rules = MemoryRules.start(catalog, MemoryRandom(seed), level.name, pack.name);
          final expected = MemoryBoard.deal(level, math.Random(seed), pack: pack);
          equal(rules.cards, expected.map((m) => m.name).toList(), 'original deck');
          expect(rules.cards.length == level.cards, 'original size');
          expect(rules.cards.toSet().length == level.pairs, 'original pair count');
          final restored = MemoryRules.restore(catalog, Map<String, dynamic>.from(rules.toJson()));
          equal(restored.toJson(), rules.toJson(), 'full private restore');
        }
      }
    }
  });

  await test('opponent choices match the exact two old methods across 128 seeds', () {
    for (var seed = 0; seed < 128; seed++) {
      final originalRandom = math.Random(seed);
      final deck = MemoryBoard.deal(MemoryDifficulty.schwer, originalRandom);
      final old = OriginalMemoryOpponent(deck, originalRandom);
      final rules = MemoryRules.start(catalog, MemoryRandom(seed), 'schwer', 'alle');
      final a = 0;
      final b = rules.cards.indexWhere((m) => m != rules.cards[a]);
      expect(rules.flip(a) && rules.flip(b), 'real child mismatch');
      rules.elapse(850);
      expect(rules.turn == 'lumo' && rules.remainingMs == 900, 'original bot delay');
      old.observe(rules.matched, rules.faceUp, rules.known);
      final first = old.first();
      rules.elapse(900);
      equal(rules.first, first, 'same first bot decision');
      old.observe(rules.matched, rules.faceUp, rules.known);
      final second = old.second(first!);
      rules.elapse(900);
      final actualSecond = List<int>.generate(rules.cards.length, (i) => i)
          .singleWhere((i) => i != first && rules.faceUp[i] && !rules.matched[i]);
      equal(actualSecond, second, 'same second bot decision');
    }
  });

  await test('public state reveals only the actually exposed cards', () {
    final rules = MemoryRules.start(catalog, MemoryRandom(73), 'leicht', 'alle');
    final hidden = rules.publicState['cards'] as List;
    expect(hidden.every((value) => (value as Map)['motif'] == null), 'all hidden');
    expect(!rules.publicState.containsKey('known') && !rules.publicState.containsKey('random'),
        'no opponent memory or random stream');
    rules.flip(2);
    final exposed = rules.publicState['cards'] as List;
    expect((exposed[2] as Map)['motif'] == rules.cards[2], 'actual exposed motif');
    expect(exposed.where((value) => (value as Map)['motif'] != null).length == 1,
        'one revealed card only');
  });

  await test('850ms resolution and original repeated-pair turn are exact', () {
    final rules = MemoryRules.start(catalog, MemoryRandom(73), 'leicht', 'alle');
    final b = rules.cards.lastIndexOf(rules.cards[0]);
    rules.flip(0); rules.flip(b);
    rules.elapse(849);
    expect(rules.kindPairs == 0 && rules.remainingMs == 1, 'no early pair');
    rules.elapse(1);
    expect(rules.kindPairs == 1 && rules.turn == 'kind' && rules.canFlip, 'repeat turn');
    expect(rules.kindMoves == 1 && rules.kindStreak == 1, 'move and streak');
  });

  await test('original reward amounts are preserved on all difficulties', () {
    const expected = [[2,1,1], [3,1,1], [3,1,1], [4,2,1], [5,3,2]];
    for (var i = 0; i < MemoryDifficulty.values.length; i++) {
      final d = MemoryDifficulty.values[i];
      equal([catalog.starsFor(d.name, won:true,draw:false),
        catalog.starsFor(d.name,won:false,draw:true),
        catalog.starsFor(d.name,won:false,draw:false)],expected[i],d.name);
    }
  });

  await test('private corruption never manufactures a legal saved board', () async {
    final valid = MemoryRules.start(catalog, MemoryRandom(73), 'leicht', 'alle').toJson();
    for (final mutate in <void Function(Map<String,dynamic>)>[
      (v) => (v['cards'] as List)[0] = 'unknown',
      (v) => (v['matched'] as List)[0] = true,
      (v) => v['kindPairs'] = 1,
      (v) => v['phase'] = 'complete',
      (v) => v['remainingMs'] = 1,
      (v) => v['known'] = {'0':'unknown'},
      (v) => v['difficulty'] = 'invented',
    ]) {
      final copy = jsonDecode(jsonEncode(valid)) as Map<String,dynamic>;
      mutate(copy);
      await rejects(() => MemoryRules.restore(catalog,copy), 'corrupt private state rejected');
    }
  });

  await test('same ongoing round is restored paused without altering legacy bytes', () async {
    final store = ContractMemoryStore();
    final c = await open(store);
    await c.flip(0);
    final id = c.round.id, deck = [...c.state.cards], legacy = store.legacy;
    c.dispose();
    final restored = await open(store, seed:999, difficulty:'profi', pack:'garten');
    equal(restored.round.id,id,'same round ID');
    equal(restored.state.cards,deck,'same private deck');
    expect(restored.state.faceUp[0] && restored.round.paused,'same move and explicit pause');
    equal(store.legacy,legacy,'no unowned migration');
    expect(!await restored.flip(1),'paused touch refused');
    restored.dispose();
  });

  await test('random continuity survives save and restart', () async {
    final a = ContractMemoryStore(), b = ContractMemoryStore();
    final one = await open(a,child:owner);
    final two = await open(b,child:other);
    await one.restart(pack:'garten');
    await two.restart(pack:'garten');
    equal(one.state.cards,two.state.cards,'first same stream restart');
    one.dispose();
    final restored = await open(a);
    await restored.restart(difficulty:'profi');
    await two.restart(difficulty:'profi');
    equal(restored.state.cards,two.state.cards,'saved stream continues');
    expect(restored.state.random.calls.length > 0,'persisted random journal');
    restored.dispose();two.dispose();
  });

  await test('failed pre-write has no visible accepted flip', () async {
    final store = ContractMemoryStore();
    final c = await open(store);
    final before = store.round;
    store.fail='before';
    await rejects(() => c.flip(0),'write failure surfaced');
    equal(store.round,before,'old save unchanged');
    expect(!c.state.faceUp[0],'not exposed before durable commit');
    expect(await c.flip(0),'explicit retry works');
    c.dispose();
  });

  await test('lost post-write reply is read back before acceptance', () async {
    final store = ContractMemoryStore();
    final c = await open(store);
    store.fail='after';
    expect(await c.flip(0),'durably committed move recovered');
    final decoded = MemoryRound.read(store.round!,catalog,owner);
    expect(decoded.rules.faceUp[0] && c.state.faceUp[0],'disk and authority agree');
    c.dispose();
  });

  await test('corrupt statistics remain unchanged while legal play continues', () async {
    final store = ContractMemoryStore()..stats='not valid JSON';
    final c = await open(store);
    expect(!c.statsWritable,'statistics protected');
    await c.restart(pack:'tiere');
    await finish(c);
    equal(store.stats,'not valid JSON','old bytes retained');
    equal(store.statsWrites,0,'no overwrite');
    c.dispose();
  });

  await test('foreign or corrupt round is not replaced with a new board', () async {
    final original = ContractMemoryStore();
    final c = await open(original,child:other);
    c.dispose();
    final foreign = ContractMemoryStore()..round=original.round;
    final bytes=foreign.round;
    await rejects(() => open(foreign),'foreign child rejected');
    equal(foreign.round,bytes,'foreign bytes unchanged');
    foreign.round='{bad';
    await rejects(() => open(foreign),'corrupt record rejected');
    equal(foreign.round,'{bad','corrupt bytes unchanged');
  });

  await test('confirmed completed round reopens as a fresh same-settings round without another reward', () async {
    final store=ContractMemoryStore();
    final ledger=<String>{};
    var attempts=0;
    Future<void> award(String id,String difficulty,int kind,int lumo) async {
      attempts++;ledger.add(id);
      expect(id.startsWith('memory:'+owner+':'),'owner result ID');
      expect(kind+lumo==catalog.cardCount(difficulty)~/2,'real completed score');
    }
    final c=await open(store,award:award);
    await finish(c);
    final id=c.round.id;
    expect(c.round.rewarded && ledger.length==1,'reward receipt committed');
    c.dispose();
    final restored=await open(store,award:award);
    await restored.settleReward();
    expect(restored.round.id != id,'settled finish permits a new round ID');
    expect(!restored.round.paused && !restored.round.rewarded && !restored.state.complete,
        'new playable round has no inherited reward receipt');
    equal(restored.state.difficulty,'leicht','same completed difficulty');
    equal(restored.state.pack,'alle','same completed theme');
    expect(restored.state.faceUp.every((v)=>!v),'new complete board is concealed');
    equal(attempts,1,'no second reward invocation');
    equal(restored.best['leicht'],4,'same best moves');
    restored.dispose();
  });

  await test('crash gap after reward and before round receipt retries the same ID', () async {
    final store=ContractMemoryStore();
    final ledger=<String>{};
    var attempts=0;
    Future<void> award(String id,String difficulty,int kind,int lumo) async {
      attempts++;ledger.add(id);
      if(attempts==1) store.fail='before';
    }
    final c=await open(store,award:award);
    await rejects(()=>finish(c),'unconfirmed reward receipt surfaced');
    expect(ledger.length==1 && c.state.complete && !c.round.rewarded,'durable completed unacknowledged round');
    c.dispose();
    final restored=await open(store,award:award);
    equal(restored.round.id,c.round.id,'unsettled finish must retain its exact round ID');
    expect(restored.round.paused && restored.state.complete && !restored.round.rewarded,
        'unsettled finish is retained for explicit resume/recovery');
    await restored.settleReward();
    equal(attempts,2,'same operation explicitly retried');
    expect(ledger.length==1 && restored.round.rewarded,'idempotent wallet result only once');
    restored.dispose();
  });

  await test('profile change during a queued write cannot publish or award another child', () async {
    final store=ContractMemoryStore();
    var current=true;
    var awards=0;
    final c=await open(store,current:()=>current,
        award:(a,b,d,e)async{awards++;});
    final gate=Completer<void>();
    store.beforeWrite=gate;
    final pending=c.flip(0);
    final caught=pending.then<void>((_)=>throw StateError('stale action returned success'),onError:(Object _,StackTrace __){});
    await Future<void>.delayed(Duration.zero);
    current=false;
    gate.complete();
    await caught;
    equal(awards,0,'no foreign reward');
    final saved=MemoryRound.read(store.round!,catalog,owner);
    equal(saved.owner,owner,'captured old key only');
    await rejects(()=>c.restart(),'stale controller cannot restart');
    c.dispose();
  });

  await test('new controller reads only after an old accepted write has settled', () async {
    final store=ContractMemoryStore();
    final c=await open(store);
    final gate=Completer<void>();store.beforeWrite=gate;
    final pending=c.flip(0);
    await Future<void>.delayed(Duration.zero);
    c.dispose();
    final settled=pending.then<void>((_) {},onError:(Object _,StackTrace __){});
    var readDone=false;
    final next=open(store).then((v){readDone=true;return v;});
    await Future<void>.delayed(Duration.zero);
    expect(!readDone,'same owner waits behind accepted write');
    gate.complete();
    await settled;
    final restored=await next;
    expect(restored.state.faceUp[0] && restored.round.paused,'new read observes accepted old move');
    restored.dispose();
  });

  await test('external newer round cannot be overwritten by stale controller', () async {
    final store=ContractMemoryStore();
    final c=await open(store);
    final doc=jsonDecode(store.round!) as Map<String,dynamic>;
    doc['revision']=(doc['revision'] as int)+1;
    doc['paused']=true;store.round=jsonEncode(doc);
    final newer=store.round;
    await rejects(()=>c.flip(0),'stale snapshot rejected');
    equal(store.round,newer,'newer snapshot untouched');
    c.dispose();
  });

  await test('partial thinking time survives pause and same-round resume', () async {
    final store=ContractMemoryStore();final c=await open(store);
    final b=c.state.cards.indexWhere((v)=>v!=c.state.cards[0]);
    await c.flip(0);await c.flip(b);
    await c.setPaused(true,elapsedMs:300);
    equal(c.state.remainingMs,550,'partial resolution saved');
    await c.advance(550);
    equal(c.state.remainingMs,550,'paused timer cannot advance');
    await c.setPaused(false);await c.advance(549);
    equal(c.state.remainingMs,1,'resume keeps remaining budget');
    await c.advance(1);
    expect(c.state.turn=='lumo' && c.state.remainingMs==900,'original next opponent delay');
    c.dispose();
  });

  await test('native lifecycle owns play; accepted stale slot is terminal then Resume works', () async {
    final c=await open(ContractMemoryStore());
    final transport=ContractMemoryTransport();
    var tick=0;
    final session=MemoryTableSession(controller:c,transport:transport,
      now:()=>DateTime.fromMillisecondsSinceEpoch(1000000+tick),
      monotonicMilliseconds:()=>tick);
    await session.open(automaticPolling:false);
    expect(session.paused,'no fabricated foreground');
    transport.box={'lifecycle':{'active':true,'stamp':1000000,'pauseEpoch':0}};
    await session.pump();
    expect(session.interactive,'real current lifecycle required');
    transport.box['request']=request(session,1,'flip',{'index':0});
    tick=100;(transport.box['lifecycle'] as Map)['stamp']=1000100;
    await session.pump();
    equal(session.view['ack'],1,'durable move ACK');
    transport.box['request']=request(session,2,'flip',{'index':1});
    transport.box['lifecycle']={'active':false,'stamp':1000101,'pauseEpoch':1};tick=101;
    await session.pump();
    equal(session.view['rejected'],2,'same-session paused request terminal');
    expect(c.round.paused,'lifecycle pause saved');
    transport.box={'lifecycle':{'active':true,'stamp':1000200,'pauseEpoch':1},
      'request':request(session,3,'resume')};tick=200;
    await session.pump();
    equal(session.view['ack'],3,'Resume accepted after rejected slot');
    expect(session.interactive && c.state.faceUp[0],'same round resumed');
    await session.close();c.dispose();
  });

  await test('native stale revision and unknown fields are rejected without mutation', () async {
    final c=await open(ContractMemoryStore());final t=ContractMemoryTransport();
    final s=MemoryTableSession(controller:c,transport:t,now:()=>DateTime.fromMillisecondsSinceEpoch(1000));
    await s.open(automaticPolling:false);
    t.box={'lifecycle':{'active':true,'stamp':1000,'pauseEpoch':0}};
    await s.pump();final before=jsonEncode(c.round.toJson());
    t.box['request']={...request(s,1,'flip',{'index':0}),'revision':1};
    await s.pump();equal(s.view['rejected'],1,'stale revision terminal');
    t.box['request']=request(s,2,'flip',{'index':0,'win':true});
    await s.pump();equal(s.view['rejected'],2,'unknown opcode field terminal');
    equal(jsonEncode(c.round.toJson()),before,'no game-state injection');
    await s.close();c.dispose();
  });

  await test('2500ms heartbeat expiry pauses without background bot progress', () async {
    final c=await open(ContractMemoryStore());final t=ContractMemoryTransport();
    var tick=0;
    final s=MemoryTableSession(controller:c,transport:t,
      now:()=>DateTime.fromMillisecondsSinceEpoch(1000+tick),monotonicMilliseconds:()=>tick);
    await s.open(automaticPolling:false);
    t.box={'lifecycle':{'active':true,'stamp':1000,'pauseEpoch':0}};
    await s.pump();tick=2500;await s.pump();
    expect(s.paused && c.round.paused,'expiry at original 2500ms');
    t.box['request']=request(s,1,'flip',{'index':0});await s.pump();
    equal(s.view['rejected'],1,'expired foreground cannot flip');
    expect(c.state.faceUp.every((v)=>!v),'hidden board unchanged');
    await s.close();c.dispose();
  });

  await test('open reply lost closes only the newly owned token', () async {
    final c=await open(ContractMemoryStore());
    final t=ContractMemoryTransport()..failOpenAfterWrite=true;
    final s=MemoryTableSession(controller:c,transport:t);
    await rejects(()=>s.open(automaticPolling:false),'missing reply surfaced');
    equal(t.closed,[s.token],'exact partial-open cleanup');
    expect(!s.isOpen && !c.round.paused,'Flutter fallback retains fresh legal round');
    c.dispose();
  });

  await test('native Exit is acknowledged only after durable pause and save', () async {
    final store=ContractMemoryStore();final c=await open(store);
    final t=ContractMemoryTransport();
    final s=MemoryTableSession(controller:c,transport:t,now:()=>DateTime.fromMillisecondsSinceEpoch(1000));
    await s.open(automaticPolling:false);
    t.box={'lifecycle':{'active':true,'stamp':1000,'pauseEpoch':0}};
    await s.pump();
    t.box['request']=request(s,1,'exit');
    await s.pump();
    expect(s.view['exit']==true && s.view['ack']==1,'only accepted exit');
    expect(MemoryRound.read(store.round!,catalog,owner).paused,'pause saved before return');
    await s.close();c.dispose();
  });

  final outIndex=args.indexOf('--out');
  if(outIndex>=0) {
    if(outIndex+1>=args.length) throw ArgumentError('--out requires directory');
    final output=Directory(args[outIndex+1])..createSync(recursive:true);
    final fixtures=<String,Object?>{};
    for(final level in memoryDifficulties) {
      final c=await open(ContractMemoryStore(),difficulty:level);
      final s=MemoryTableSession(controller:c,transport:ContractMemoryTransport(),
        token:'cccccccccccccccccccccccccccccccc');
      fixtures[level]=s.view;
      c.dispose();
    }
    File(output.path+'/memory-states.json').writeAsStringSync(jsonEncode(fixtures)+'\n');
  }
  final result={'status':failures.isEmpty?'PASS':'FAIL','cases':passed+failures.length,
    'passed':passed,'failed':failures,'checks':checks,'skipped':0,
    'scope':'Production Dart authorities; original dealer and original opponent fixture; synthetic storage and lifecycle transport; no Android claim.'};
  stdout.writeln('MEMORY_ROUND_CONTRACT '+jsonEncode(result));
  if(failures.isNotEmpty)exitCode=1;
}
