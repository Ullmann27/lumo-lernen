import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/learning_brain.dart';
import 'services/reward_orchestrator.dart';
import 'services/memory_graph.dart';
import 'services/consent_service.dart';
import 'services/companion_agent.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LearningBrain()),
        ChangeNotifierProvider(create: (_) => RewardOrchestrator()),
        ChangeNotifierProvider(create: (_) => MemoryGraph()),
        ChangeNotifierProvider(create: (_) => ConsentService()),
        ChangeNotifierProvider(create: (_) => CompanionAgent()),
      ],
      child: const LumoLernenApp(),
    ),
  );
}
