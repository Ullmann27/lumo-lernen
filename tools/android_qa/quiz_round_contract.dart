import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../lib/domain/quiz/quiz_question_bank.dart';
import '../../lib/domain/quiz/quiz_show.dart';
import '../../lib/features/lumo3d/native_table_transport.dart';
import '../../lib/features/quiz/quiz_show_round.dart';
import '../../lib/features/quiz/quiz_table_session.dart';

const ownerA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const ownerB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
int checks = 0, passed = 0, failed = 0;
void check(bool value, String message) {
  checks++;
  if (!value) throw StateError(message);
}
Future<void> rejects(FutureOr<void> Function() fn) async {
  var rejected = false;
  try { await fn(); } catch (_) { rejected = true; }
  check(rejected, 'Operation must reject');
}
Future<void> test(String name, FutureOr<void> Function() run) async {
  try { await run(); passed++; print('PASS $name'); }
  catch (error, stack) { failed++; print('FAIL $name: $error\n$stack'); }
}

List<QuizQuestion> questions(String subject, int seed, {int grade = 1}) =>
    const QuizQuestionBank().generateGameQuestions(grade: grade,
      random: Random(seed), preferSubject: subject == 'alle' ? null : subject);

class MemoryStore implements QuizRoundStore {
  final Map<String, String> data = {};
  bool failBefore = false, failAfter = false;
  void Function()? duringSave;
  int writes = 0;
  @override
  Future<QuizRound?> load(String owner, bool Function() current) async {
    if (!current()) throw StateError('profile');
    final raw = data[owner];
    return raw == null ? null : QuizRound.decode(raw, owner);
  }
  @override
  Future<void> save(QuizRound next, QuizRound? previous, bool Function() current) async {
    if (!current()) throw StateError('profile');
    final old = data[next.owner];
    if (old != (previous == null ? null : jsonEncode(previous.toJson()))) {
      throw StateError('CAS');
    }
    next.replay();
    if (failBefore) { failBefore = false; throw StateError('before write'); }
    data[next.owner] = jsonEncode(next.toJson()); writes++;
    duringSave?.call(); duringSave = null;
    if (!current()) throw StateError('profile');
    if (failAfter) { failAfter = false; throw StateError('after write'); }
  }
}

class Harness {
  Harness({MemoryStore? storage}) : storage = storage ?? MemoryStore();
  final MemoryStore storage;
  bool current = true, walletFault = false;
  int stars = 0, awardAttempts = 0;
  final Set<String> paid = {};
  late QuizRoundController c;
  Future<void> open({String owner = ownerA, int grade = 1, int seed = 8}) async {
    c = await QuizRoundController.open(owner: owner, grade: grade,
      store: storage, canUseProfile: () => current,
      makeQuestions: (subject, seed) => questions(subject, seed, grade: grade),
      seed: seed, award: (id, amount) async {
        awardAttempts++;
        if (paid.add(id)) stars += amount;
        if (walletFault) { walletFault = false; throw StateError('after wallet'); }
      });
  }
  Future<void> correct(int number) async {
    for (var i = 0; i < number; i++) {
      check(await c.select(c.state.currentQuestion.correctIndex), 'correct select');
      check(await c.reveal(), 'correct reveal');
      if (!c.state.gameOver) check(await c.next(), 'next');
    }
  }
}

class Transport implements NativeTableTransport {
  Map<String, dynamic> box = {};
  Map<String, Object?>? published;
  int closes = 0;
  bool failOpenAfterAccept = false;
  @override
  Future<void> open(String token, Map<String, Object?> state) async {
    published = state;
    if (failOpenAfterAccept) throw StateError('accepted open but lost reply');
  }
  @override
  Future<Map<String, dynamic>> poll(String token) async => box;
  @override
  Future<void> publish(String token, Map<String, Object?> state) async { published = state; }
  @override
  Future<void> close(String token) async { closes++; }
}

class Studio {
  final Harness game = Harness();
  final Transport transport = Transport();
  int time = 10000, sequence = 0, epoch = 0;
  late QuizTableSession session;
  Future<void> open() async {
    await game.open();
    session = QuizTableSession(controller: game.c, transport: transport,
      token: 'cccccccccccccccccccccccccccccccc',
      now: () => DateTime.fromMillisecondsSinceEpoch(time));
    await session.open(automaticPolling: false);
    transport.box = {'lifecycle': {'stamp': time, 'active': true, 'pauseEpoch': epoch}};
    await session.pump();
  }
  Map<String, dynamic> intent(String action, [Map<String, Object?> extra = const {}]) => {
    'token': session.token, 'roundId': game.c.round.id,
    'revision': session.view['revision'], 'sequence': ++sequence, 'action': action,
    ...extra,
  };
  Future<void> send(String action, [Map<String, Object?> extra = const {}]) async {
    transport.box = {'lifecycle': {'stamp': time, 'active': true, 'pauseEpoch': epoch},
      'request': intent(action, extra)};
    await session.pump();
  }
}

Future<void> main() async {
  await test('all existing grade/subject banks persist and replay', () {
    for (var grade = 1; grade <= 4; grade++) {
      for (final subject in QuizRound.subjects) {
        for (var seed = 0; seed < 32; seed++) {
          final round = QuizRound(owner: ownerA, id: 'dddddddddddddddddddddddddddddddd',
            grade: grade, seed: seed, subject: subject, revision: 1,
            questions: questions(subject, seed, grade: grade), actions: const []);
          final restored = QuizRound.decode(jsonEncode(round.toJson()), ownerA);
          check(restored.questions.length == 20, '20 original questions');
          check(restored.questions.last.subject == 'Logik-Finale', 'grade-specific finale');
          check(restored.replay().currentQuestionIndex == 0, 'initial state');
        }
      }
    }
  });
  await test('50:50 clears a newly hidden selection', () {
    const engine = QuizShowEngine();
    final initial = engine.start(questions: questions('alle', 7));
    final hidden = engine.useJoker(initial, QuizJoker.fiftyFifty).fiftyFiftyHiddenOptions.first;
    final selected = engine.selectAnswer(initial, hidden);
    final after = engine.useJoker(selected, QuizJoker.fiftyFifty);
    check(after.selectedOption == null, 'hidden answer must no longer be selected');
    check(identical(engine.reveal(after), after), 'cannot confirm hidden previous answer');
  });
  await test('zero-star first mistake ends and persists without wallet mutation', () async {
    final h = Harness(); await h.open();
    await h.c.select((h.c.state.currentQuestion.correctIndex + 1) % 4);
    await h.c.reveal();
    check(h.c.state.gameOver && !h.c.state.won, 'ended loss');
    check(h.c.round.rewarded && h.stars == 0 && h.awardAttempts == 0, 'zero reward ACK');
  });
  await test('existing safe spots pay only 50/200/800 after later mistake', () async {
    for (final pair in [(5, 50), (10, 200), (15, 800)]) {
      final h = Harness(); await h.open(); await h.correct(pair.$1);
      check(h.c.state.securedStars == pair.$2 && h.stars == 0, 'safe spot not paid early');
      await h.c.select((h.c.state.currentQuestion.correctIndex + 1) % 4);
      await h.c.reveal(); await h.c.settleReward();
      check(h.stars == pair.$2 && h.paid.length == 1, 'exact secured payout once');
    }
  });
  await test('20 original questions award 5000 once across reopen', () async {
    final h = Harness(); await h.open(); await h.correct(20);
    final id = h.c.round.id;
    check(h.c.state.won && h.stars == 5000 && h.awardAttempts == 1, 'final win');
    h.c.dispose(); await h.open(); await h.c.settleReward();
    check(h.c.round.id == id && h.c.state.won && h.stars == 5000 && h.awardAttempts == 1,
      'resume preserves settled final result');
  });
  await test('question/joker/selection history restores exactly', () async {
    final h = Harness(); await h.open(); await h.correct(3);
    await h.c.joker(QuizJoker.audience); await h.c.joker(QuizJoker.callLumo);
    await h.c.select(h.c.state.currentQuestion.correctIndex);
    final saved = jsonEncode(h.c.round.toJson());
    h.c.dispose(); await h.open();
    check(jsonEncode(h.c.round.toJson()) == saved, 'exact saved history');
    check(h.c.state.usedJokers.length == 2 && h.c.state.audienceVotes!.reduce((a,b)=>a+b)==100,
      'jokers reconstructed by original engine');
  });
  await test('unlimited reconsideration keeps bounded history', () async {
    final h = Harness(); await h.open();
    for (var i = 0; i < 150; i++) { await h.c.select(i % 4); }
    check(h.c.round.actions.length == 1 && h.c.state.selectedOption == 1, 'selection compacted');
    final d = QuizRound.decode(jsonEncode(h.c.round.toJson()), ownerA);
    check(d.replay().selectedOption == 1, 'same replay after compaction');
  });
  await test('profile is checked after in-flight save before UI install', () async {
    final h = Harness(); await h.open(); final old = h.c.round;
    h.storage.duringSave = () { h.current = false; };
    await rejects(() => h.c.select(1));
    check(identical(h.c.round, old), 'old owner result cannot install after profile change');
    check(!h.storage.data.containsKey(ownerB), 'other child untouched');
    await rejects(() => h.c.reveal());
  });
  await test('children have separate stored rounds', () async {
    final store = MemoryStore(); final a=Harness(storage:store), b=Harness(storage:store);
    await a.open(); await a.c.select(2); await b.open(owner:ownerB);
    check(a.c.round.id != b.c.round.id && b.c.state.selectedOption == null, 'different rounds');
    check(store.data.length==2, 'two keys only');
  });
  await test('write-before failure recovers without acknowledged selection', () async {
    final h=Harness(); await h.open(); h.storage.failBefore=true;
    await rejects(()=>h.c.select(2)); check(h.c.state.selectedOption==null,'not installed');
    await h.c.settleReward(); check(h.c.state.selectedOption==null,'prior durable value');
    check(await h.c.select(2),'explicit retry');
  });
  await test('write-after failure reloads durable selection without duplicate', () async {
    final h=Harness(); await h.open(); h.storage.failAfter=true;
    await rejects(()=>h.c.select(2)); check(h.c.state.selectedOption==null,'no unconfirmed install');
    await h.c.settleReward(); check(h.c.state.selectedOption==2,'durable recovery');
    check(!await h.c.select(2) && h.c.round.actions.length==1,'no repeated action');
  });
  await test('wallet interruption before round ACK deduplicates result ID', () async {
    final h=Harness(); await h.open(); await h.correct(5);
    await h.c.select((h.c.state.currentQuestion.correctIndex+1)%4);h.walletFault=true;
    await rejects(()=>h.c.reveal()); check(h.stars==50 && !h.c.round.rewarded,'wallet before round ACK');
    await h.c.settleReward();check(h.stars==50 && h.c.round.rewarded && h.awardAttempts==2,'same ID dedup');
  });
  await test('simultaneous commands serialize and cannot award twice', () async {
    final h=Harness();await h.open();await h.c.select((h.c.state.currentQuestion.correctIndex+1)%4);
    final results=await Future.wait([h.c.reveal(),h.c.reveal()]);
    check(results.where((v)=>v).length==1 && h.c.round.rewarded,'single reveal');
  });
  await test('stale independent controller cannot overwrite newer round', () async {
    final store=MemoryStore();final a=Harness(storage:store),b=Harness(storage:store);
    await a.open();await b.open();await a.c.select(1);await rejects(()=>b.c.select(2));
    await b.c.settleReward();check(b.c.state.selectedOption==1,'CAS recovers latest round');
  });
  await test('invalid/foreign saves reject without destructive replacement', () async {
    final h=Harness();await h.open();final raw=h.storage.data[ownerA]!;
    await rejects(()=>QuizRound.decode(raw,ownerB));
    final doc=jsonDecode(raw) as Map<String,dynamic>;doc['rewarded']=true;
    await rejects(()=>QuizRound.decode(jsonEncode(doc),ownerA));
    doc['rewarded']=false;doc['actions']=[{'action':'next'}];
    await rejects(()=>QuizRound.decode(jsonEncode(doc),ownerA));
    check(h.storage.data[ownerA]==raw,'original unchanged');
  });
  await test('native view hides answers and explanation before reveal', () async {
    final s=Studio();await s.open();
    check(s.session.view['correctIndex']==null && s.session.view['explanation']==null,'private answer');
    await s.send('select',{'option':s.game.c.state.currentQuestion.correctIndex});
    await s.send('reveal');
    check(s.session.view['correctIndex']==s.game.c.state.currentQuestion.correctIndex,'answer after reveal');
    await s.session.close();
  });
  await test('duplicate/stale/foreign native intent never repeats a move', () async {
    final s=Studio();await s.open();await s.send('select',{'option':1});
    final revision=s.game.c.round.revision;await s.session.pump();
    check(s.game.c.round.revision==revision,'duplicate ignored');
    final stale=s.intent('reveal');stale['revision']=1;
    s.transport.box['request']=stale;await s.session.pump();
    check(s.session.view['rejected']==s.sequence && !s.game.c.state.revealed,'stale negative ACK');
    final foreign=s.intent('reveal');foreign['roundId']='ffffffffffffffffffffffffffffffff';
    s.transport.box['request']=foreign;await s.session.pump();
    check(!s.game.c.state.revealed,'foreign round');await s.session.close();
  });
  await test('hidden/extra renderer result fields are rejected', () async {
    final s=Studio();await s.open();await s.send('select',{'option':0,'awardedStars':5000});
    check(s.session.view['rejected']==1 && s.game.c.state.selectedOption==null && s.game.stars==0,'injected result');
    await s.session.close();
  });
  await test('2500ms lease pause and stale slot permit explicit resume', () async {
    final s=Studio();await s.open();final queued=s.intent('select',{'option':2});
    s.time+=2500;s.transport.box['request']=queued;await s.session.pump();
    check(s.session.paused && s.session.view['rejected']==1,'expired slot rejected');
    await s.send('resume');check(!s.session.paused && s.session.view['ack']==2,'resume fresh slot');
    check(s.game.c.state.selectedOption==null,'expired selection not applied');
    await s.session.close();
  });
  await test('pause epoch persists pause until explicit resume', () async {
    final s=Studio();await s.open();s.epoch++;await s.send('select',{'option':2});
    check(s.session.paused && s.game.c.state.selectedOption==null,'epoch fence');
    await s.send('resume');await s.send('select',{'option':2});
    check(s.game.c.state.selectedOption==2,'new explicit action after resume');await s.session.close();
  });
  await test('native subject change is paused and starts real new bank', () async {
    final s=Studio();await s.open();final id=s.game.c.round.id;
    await s.send('subject',{'subject':'Deutsch'});check(s.game.c.round.id==id,'cannot abandon active round silently');
    await s.send('pause');await s.send('subject',{'subject':'Deutsch'});
    check(s.game.c.round.id!=id && s.game.c.round.subject=='Deutsch' && !s.session.paused,'new subject round');
    await s.session.close();
  });
  await test('profile revocation closes native authority before request', () async {
    final s=Studio();await s.open();s.game.current=false;await s.send('select',{'option':0});
    check(!s.session.isOpen && s.transport.closes==1 && s.game.c.state.selectedOption==null,'profile close');
  });
  await test('accepted native open with lost reply closes the exact token', () async {
    final h=Harness();await h.open();final t=Transport()..failOpenAfterAccept=true;
    final session=QuizTableSession(controller:h.c,transport:t);
    await rejects(()=>session.open(automaticPolling:false));
    check(t.published?['token']==session.token && t.closes==1 && !session.isOpen,
      'partial native open cleaned up');
    await session.close();check(t.closes==1,'no fictitious second active close');
  });
  await test('old grade round resumes while new round uses current grade', () async {
    final h=Harness();await h.open(grade:1);final id=h.c.round.id;
    h.c.dispose();await h.open(grade:2);
    check(h.c.round.id==id && h.c.round.grade==1,'existing round retained');
    await h.c.restart(seed:9);
    check(h.c.round.id!=id && h.c.round.grade==2,'new round captures current grade');
    check(h.c.round.questions.last.id.startsWith('final_g2_'),'current grade question bank');
  });
  await test('completed native round changes subject without another pause', () async {
    final s=Studio();await s.open();
    await s.send('select',{'option':(s.game.c.state.currentQuestion.correctIndex+1)%4});
    await s.send('reveal');check(s.game.c.state.gameOver,'ended round');
    final id=s.game.c.round.id;await s.send('subject',{'subject':'Sachunterricht'});
    check(s.game.c.round.id!=id && s.game.c.round.subject=='Sachunterricht','new result-screen subject');
    await s.session.close();
  });
  print('[QuizRoundContract] ${failed==0?'PASS':'FAIL'} cases=$passed failed=$failed checks=$checks skips=0');
  exitCode=failed==0?0:1;
}
