import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/web_seed_store.dart';
import '../models/quest.dart';
import '../models/streak_log.dart';

class QuestProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _webStore = WebSeedStore.instance;
  List<Quest> quests = [];
  List<StreakLog> streakLogs = [];

  List<Quest> get mainQuests => quests.where((q) => q.type == 'main').toList();
  List<Quest> get sideQuests => quests.where((q) => q.type == 'side').toList();
  List<Quest> get dailyQuests => quests.where((q) => q.type == 'daily').toList();
  List<Quest> get activeQuests => quests.where((q) => q.status == 'active').toList();

  Future<void> load() async {
    if (kIsWeb) {
      _webStore.ensureInit();
      quests = _webStore.quests.map((q) => q).toList();
      streakLogs = _webStore.streakLogs.map((s) => s).toList();
      notifyListeners();
      return;
    }

    final qRows = await _db.query('quests', orderBy: 'id ASC');
    quests = qRows.map((r) => Quest.fromMap(r)).toList();

    final sRows = await _db.query('streak_logs', orderBy: 'id ASC');
    streakLogs = sRows.map((r) => StreakLog.fromMap(r)).toList();
    notifyListeners();
  }

  StreakLog? streakFor(int questId) {
    try {
      return streakLogs.firstWhere((s) => s.questId == questId);
    } catch (_) {
      return null;
    }
  }

  /// Complete a quest. Returns the exp reward (with streak bonus for dailies).
  Future<int> completeQuest(int questId) async {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return 0;

    final quest = quests[idx];
    int reward = quest.expReward;

    if (quest.type == 'daily') {
      // Update streak
      final today = DateTime.now().toIso8601String().substring(0, 10);
      var streak = streakFor(questId);

      if (streak != null) {
        final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
        int newStreak = streak.lastCompletedDate == yesterday
            ? streak.currentStreak + 1
            : (streak.lastCompletedDate == today ? streak.currentStreak : 1);

        // Streak bonus: +10% per streak day, max +100%
        double bonus = 1.0 + (newStreak * 0.1).clamp(0.0, 1.0);
        reward = (quest.expReward * bonus).round();

        final updated = streak.copyWith(lastCompletedDate: today, currentStreak: newStreak);
        final sIdx = streakLogs.indexWhere((s) => s.questId == questId);
        if (sIdx != -1) streakLogs[sIdx] = updated;
        if (!kIsWeb) {
          await _db.update('streak_logs', updated.toMap(), where: 'quest_id = ?', whereArgs: [questId]);
        }
      }
      // Daily quests stay active
    } else {
      // Main/side quests become completed
      final updated = quest.copyWith(status: 'completed');
      quests[idx] = updated;
      if (!kIsWeb) {
        await _db.update('quests', updated.toMap(), where: 'id = ?', whereArgs: [questId]);
      }
    }

    if (kIsWeb) {
      _webStore.quests = quests.map((q) => q).toList();
      _webStore.streakLogs = streakLogs.map((s) => s).toList();
    }
    notifyListeners();
    return reward;
  }

  Future<void> addQuest(Quest quest) async {
    if (kIsWeb) {
      final nextId = (quests.map((q) => q.id ?? 0).fold<int>(0, (a, b) => b > a ? b : a)) + 1;
      quests.add(quest.copyWith(id: nextId));

      if (quest.type == 'daily') {
        streakLogs.add(StreakLog(
          id: streakLogs.length + 1,
          questId: nextId,
          lastCompletedDate: '',
          currentStreak: 0,
        ));
      }

      _webStore.quests = quests.map((q) => q).toList();
      _webStore.streakLogs = streakLogs.map((s) => s).toList();
      notifyListeners();
      return;
    }

    final id = await _db.insert('quests', quest.toMap());
    quests.add(quest.copyWith(id: id));

    // Create streak log for daily quests
    if (quest.type == 'daily') {
      final streakId = await _db.insert('streak_logs', {
        'quest_id': id,
        'last_completed_date': '',
        'current_streak': 0,
      });
      streakLogs.add(StreakLog(id: streakId, questId: id, lastCompletedDate: '', currentStreak: 0));
    }
    notifyListeners();
  }
}
