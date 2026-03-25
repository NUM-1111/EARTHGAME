// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:life_elden/app.dart';
import 'package:life_elden/providers/character_provider.dart';
import 'package:life_elden/providers/skill_provider.dart';
import 'package:life_elden/providers/equipment_provider.dart';
import 'package:life_elden/providers/quest_provider.dart';
import 'package:life_elden/providers/journal_provider.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CharacterProvider()),
          ChangeNotifierProvider(create: (_) => SkillProvider()),
          ChangeNotifierProvider(create: (_) => EquipmentProvider()),
          ChangeNotifierProvider(create: (_) => QuestProvider()),
          ChangeNotifierProvider(create: (_) => JournalProvider()),
        ],
        child: const LifeEldenApp(),
      ),
    );
    await tester.pump();
    expect(find.text('L I F E  E L D E N'), findsOneWidget);
  });
}
