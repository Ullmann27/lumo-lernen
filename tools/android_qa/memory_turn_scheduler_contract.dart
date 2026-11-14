import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../lib/features/games/memory/memory_turn_scheduler.dart';

class ManualTimer implements Timer {
  ManualTimer(this.callback);
  final void Function() callback;
  bool active = true;
  @override bool get isActive => active;
  @override int get tick => 0;
  @override void cancel() { active = false; }
  void deliverEvenIfQueuedBeforeCancellation() { active = false; callback(); }
}

int passed = 0, checks = 0;
final failed = <String>[];
void expect(bool ok,String reason) {
  checks++;
  if(!ok)throw StateError(reason);
}
Future<void> test(String name,FutureOr<void> Function() action) async {
  try { await action();passed++;stdout.writeln('PASS '+name); }
  catch(error,stack){failed.add(name);stderr.writeln('FAIL '+name+': '+error.toString()+'\n'+stack.toString());}
}

Future<void> main() async {
  await test('a real Dart Timer executes the exact scheduled interval once',()async{
    final done=Completer<int>();var calls=0;
    final scheduler=MemoryTurnScheduler();
    scheduler.schedule(4,(elapsed){calls++;done.complete(elapsed);});
    final elapsed=await done.future.timeout(const Duration(seconds:2));
    expect(elapsed==4 && calls==1,'actual event-loop callback');
    expect(scheduler.cancelElapsed()==0,'completed timer has no remaining charge');
    scheduler.dispose();
  });
  await test('partial elapsed is captured before cancellation',(){
    var now=100;final callbacks=<ManualTimer>[];
    final scheduler=MemoryTurnScheduler(milliseconds:()=>now,
      createTimer:(delay,action){final t=ManualTimer(action);callbacks.add(t);return t;});
    scheduler.schedule(850,(_)=>throw StateError('cancelled action'));
    now=400;
    expect(scheduler.cancelElapsed()==300,'original remaining 550ms');
    callbacks.single.deliverEvenIfQueuedBeforeCancellation();
    expect(!callbacks.single.isActive,'cancelled generation ignored');
    scheduler.dispose();
  });
  await test('an old queued callback cannot advance the newly scheduled round',(){
    var now=0,calls=0;final timers=<ManualTimer>[];
    final scheduler=MemoryTurnScheduler(milliseconds:()=>now,
      createTimer:(delay,action){final t=ManualTimer(action);timers.add(t);return t;});
    scheduler.schedule(900,(_){calls+=100;});
    now=200;scheduler.schedule(600,(elapsed){expect(elapsed==600,'new exact duration');calls++;});
    timers[0].deliverEvenIfQueuedBeforeCancellation();
    expect(calls==0,'old callback has no authority');
    timers[1].deliverEvenIfQueuedBeforeCancellation();
    expect(calls==1,'new callback only');
    scheduler.dispose();
  });
  await test('dispose prevents an already queued callback and any new schedule',(){
    final timers=<ManualTimer>[];var calls=0;
    final scheduler=MemoryTurnScheduler(createTimer:(delay,action){
      final t=ManualTimer(action);timers.add(t);return t;});
    scheduler.schedule(850,(_)=>calls++);
    scheduler.dispose();timers.single.deliverEvenIfQueuedBeforeCancellation();
    scheduler.schedule(850,(_)=>calls++);
    expect(calls==0 && timers.length==1,'disposed owner never resurrects');
  });
  await test('clock reversal cannot create negative elapsed time',(){
    var now=400;
    final scheduler=MemoryTurnScheduler(milliseconds:()=>now,
      createTimer:(delay,action)=>ManualTimer(action));
    scheduler.schedule(900,(_){});
    now=100;expect(scheduler.cancelElapsed()==0,'negative elapsed clamps to zero');
    scheduler.dispose();
  });
  await test('pause after the deadline charges at most the pending action',(){
    var now=0;
    final scheduler=MemoryTurnScheduler(milliseconds:()=>now,
      createTimer:(delay,action)=>ManualTimer(action));
    scheduler.schedule(850,(_){});
    now=10000;expect(scheduler.cancelElapsed()==850,'no imaginary subsequent turn');
    scheduler.dispose();
  });
  await test('non-game timer budgets fail instead of silently changing time',(){
    final scheduler=MemoryTurnScheduler();
    for(final duration in [0,-1,901]){
      var rejected=false;
      try{scheduler.schedule(duration,(_){ });}catch(_){rejected=true;}
      expect(rejected,'out of range duration');
    }
    scheduler.dispose();
  });
  stdout.writeln('MEMORY_TURN_SCHEDULER '+jsonEncode({
    'status':failed.isEmpty?'PASS':'FAIL','cases':passed+failed.length,
    'passed':passed,'failed':failed,'checks':checks,'skipped':0,
    'scope':'Actual production scheduler; one real Dart event-loop Timer plus deterministic delayed-callback and clock boundaries; no Android claim.'
  }));
  if(failed.isNotEmpty)exitCode=1;
}
