import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/learning_brain.dart';
import 'services/reward_orchestrator.dart';
import 'services/memory_graph.dart';
import 'services/consent_service.dart';
import 'services/companion_agent.dart';
import 'services/local_store.dart';
import 'services/wwm_question_service.dart';
import 'services/wwm_game_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localStore = LocalStore();
  final wwmService = WwmQuestionService(localStore);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LearningBrain()),
        ChangeNotifierProvider(create: (_) => RewardOrchestrator()),
        ChangeNotifierProvider(create: (_) => MemoryGraph()),
        ChangeNotifierProvider(create: (_) => ConsentService()),
        ChangeNotifierProvider(create: (_) => CompanionAgent()),
        Provider<WwmQuestionService>.value(value: wwmService),
        ChangeNotifierProvider(create: (_) => WwmGameState(wwmService)),
      ],
      child: const LumoLernenApp(),
    ),
  );
}
