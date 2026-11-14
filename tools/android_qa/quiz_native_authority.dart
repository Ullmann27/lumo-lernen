import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../lib/domain/quiz/quiz_question_bank.dart';
import '../../lib/features/lumo3d/native_table_transport.dart';
import '../../lib/features/quiz/quiz_show_round.dart';
import '../../lib/features/quiz/quiz_table_session.dart';

/// QA boundary only: real production controller/session, disk CAS and native
/// input; Android Binder/SharedPreferences are covered by their separate gates.
class DiskStore implements QuizRoundStore {
  DiskStore(this.directory);
  final Directory directory;
  File file(String owner) => File('${directory.path}/round-$owner.json');
  @override
  Future<QuizRound?> load(String owner, bool Function() current) async {
    if (!current()) throw StateError('profile');
    final path = file(owner);
    if (!path.existsSync()) return null;
    final result = QuizRound.decode(await path.readAsString(), owner);
    if (!current()) throw StateError('profile');
    return result;
  }
  @override
  Future<void> save(QuizRound next, QuizRound? previous, bool Function() current) async {
    if (!current()) throw StateError('profile');
    final target = file(next.owner);
    final raw = target.existsSync() ? await target.readAsString() : null;
    if (raw != (previous == null ? null : jsonEncode(previous.toJson()))) throw StateError('CAS');
    next.replay();
    final pending = File('${target.path}.tmp');
    await pending.writeAsString(jsonEncode(next.toJson()), flush: true);
    await pending.rename(target.path);
    if (!current()) throw StateError('profile');
  }
}

class DiskTransport implements NativeTableTransport {
  DiskTransport(this.directory);
  final Directory directory;
  late QuizRoundController controller;
  final List<Map<String, dynamic>> requests = [];
  int lastSequence = 0;
  Future<void> write(String name, Object value) async {
    final target = File('${directory.path}/$name');
    final pending = File('${target.path}.tmp');
    await pending.writeAsString(jsonEncode(value), flush: true);
    await pending.rename(target.path);
  }
  Future<void> state(Map<String, Object?> value) async {
    await write('public-state.json', value);
    // Never part of production launch options or public renderer state.
    // The QA input driver needs the current expected answer to play real tasks.
    await write('private-test-control.json', {
      'roundId': controller.round.id,
      'number': controller.state.displayQuestionNumber,
      'correctIndex': controller.state.currentQuestion.correctIndex,
      'scope': 'QA oracle only; not read by production QuizStudio',
    });
  }
  @override
  Future<void> open(String token, Map<String, Object?> value) => state(value);
  @override
  Future<void> publish(String token, Map<String, Object?> value) => state(value);
  @override
  Future<Map<String, dynamic>> poll(String token) async {
    Map<String, dynamic> read(String name) {
      final file = File('${directory.path}/$name');
      return file.existsSync() ? Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map) : {};
    }
    final request = read('request.json');
    final sequence = request['sequence'];
    if (sequence is int && sequence > lastSequence) {
      lastSequence = sequence;
      requests.add({...request, 'observed_at': DateTime.now().toUtc().toIso8601String()});
    }
    return {'lifecycle': read('lifecycle.json'), 'request': request};
  }
  @override
  Future<void> close(String token) async { await write('closed.json', {'token': token}); }
}

Future<void> main(List<String> args) async {
  if (args.length != 1) throw ArgumentError('Expected isolated QA directory');
  final directory = Directory(args.single)..createSync(recursive: true);
  if (File('${directory.path}/public-state.json').existsSync()) throw StateError('QA directory must be fresh');
  final transport = DiskTransport(directory);
  final paid = <String>{};
  var stars = 0;
  var current = true;
  final controller = await QuizRoundController.open(
    owner: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    grade: 1, seed: 71, store: DiskStore(directory), canUseProfile: () => current,
    makeQuestions: (subject, seed) => const QuizQuestionBank().generateGameQuestions(
      grade: 1, random: Random(seed), preferSubject: subject == 'alle' ? null : subject),
    award: (id, amount) async {
      if (paid.add(id)) stars += amount;
      await transport.write('wallet.json', {'stars': stars, 'ids': paid.toList()});
    },
  );
  transport.controller = controller;
  final session = QuizTableSession(controller: controller, transport: transport);
  await session.open();
  final started = DateTime.now();
  var finished = false;
  while (DateTime.now().difference(started).inSeconds < 300) {
    if (File('${directory.path}/native-result.json').existsSync()) { finished = true; break; }
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }
  await session.close();
  current = false;
  final result = {
    'finished': finished, 'stars': stars, 'paid_ids': paid.toList(),
    'round': controller.round.toJson(), 'requests': transport.requests,
    'scope': 'Production Dart engine/bank/controller/session plus actual Godot input; explicit QA disk/Binder boundary',
  };
  await transport.write('authority-result.json', result);
  controller.dispose();
  if (!finished) { stderr.writeln('Quiz native authority timed out'); exitCode = 1; }
  else { print('[QuizNativeAuthority] complete requests=${transport.requests.length} stars=$stars'); }
}
