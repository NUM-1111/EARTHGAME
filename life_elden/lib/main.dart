import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/character_provider.dart';
import 'providers/skill_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/quest_provider.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mobile/desktop uses SQLite.
  // Web uses an in-memory seeded fallback (see WebSeedStore) to avoid
  // sqflite_common_ffi_web wasm initialization issues.
  if (!kIsWeb) {
    await DatabaseHelper.instance.database;
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CharacterProvider()..load()),
        ChangeNotifierProvider(create: (_) => SkillProvider()..load()),
        ChangeNotifierProvider(create: (_) => EquipmentProvider()..load()),
        ChangeNotifierProvider(create: (_) => QuestProvider()..load()),
      ],
      child: const LifeEldenApp(),
    ),
  );
}
