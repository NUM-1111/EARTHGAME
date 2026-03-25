import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/equipment.dart';
import '../models/quest.dart';
import '../models/skill.dart';
import '../models/streak_log.dart';
import 'seed_data.dart';

/// Web fallback store.
///
/// NOTE:
/// - Current project uses SQLite for persistence on mobile/desktop.
/// - sqflite_common_ffi_web 在该环境下存在 wasm 初始化兼容性问题，
///   为了让你先跑通前端 UI，这里在 web 端先用内存存储 seeded data。
class WebSeedStore {
  WebSeedStore._();

  static final WebSeedStore instance = WebSeedStore._();

  bool _inited = false;
  List<Skill> skills = [];
  List<Equipment> equipment = [];
  List<Quest> quests = [];
  List<StreakLog> streakLogs = [];
  List<Map<String, dynamic>> questJournals = [];

  // Character meta
  String name = 'Jiang Yiwu';
  int totalLevel = 1;
  int totalExp = 0;
  String title = '无用之人';

  void ensureInit() {
    if (_inited) return;

    // Character defaults
    final ch = SeedData.defaultCharacter;
    name = ch['name'] as String? ?? 'Jiang Yiwu';
    final tl = ch['total_level'];
    final te = ch['total_exp'];
    totalLevel = (tl is int)
        ? tl
        : int.tryParse(tl?.toString() ?? '1') ?? 1;
    totalExp = (te is int)
        ? te
        : int.tryParse(te?.toString() ?? '0') ?? 0;
    title = ch['title'] as String? ?? '无用之人';

    // Skills: SeedData.skills uses explicit ids
    skills = SeedData.skills.map((m) => Skill.fromMap(m)).toList();

    // Equipment: assign stable incremental ids
    equipment = [];
    for (int i = 0; i < SeedData.equipment.length; i++) {
      final e = SeedData.equipment[i];
      equipment.add(Equipment.fromMap({
        ...e,
        'id': i + 1,
        'is_equipped': e['is_equipped'] ?? 0,
      }));
    }

    // Quests: assign incremental ids in the same order as SeedData.quests
    quests = [];
    for (int i = 0; i < SeedData.quests.length; i++) {
      final q = SeedData.quests[i];
      quests.add(Quest.fromMap({
        ...q,
        'id': i + 1,
      }));
    }

    // Streak logs: one per daily quest
    streakLogs = [];
    for (final q in quests) {
      if (q.type == 'daily') {
        streakLogs.add(StreakLog(
          id: streakLogs.length + 1,
          questId: q.id!,
          lastCompletedDate: '',
          currentStreak: 0,
          lastDebuffAppliedDate: '',
        ));
      }
    }

    questJournals = [];
    _inited = true;
  }

  // Helpers
  StreakLog? streakFor(int questId) {
    for (final s in streakLogs) {
      if (s.questId == questId) return s;
    }
    return null;
  }
}

void assertWebStoreOnly() {
  if (!kIsWeb) {
    throw StateError('WebSeedStore should only be used on web.');
  }
}

