import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/web_seed_store.dart';
import '../models/quest.dart';
import '../models/streak_log.dart';
import 'character_provider.dart';
import 'journal_provider.dart';
import '../models/quest_journal.dart';

class DebuffApplyResult {
  final int dailyMissDays;
  final int sideOverdueDays;
  final int dailyExpDelta; // negative or 0
  final int sideExpDelta; // negative or 0

  const DebuffApplyResult({
    this.dailyMissDays = 0,
    this.sideOverdueDays = 0,
    this.dailyExpDelta = 0,
    this.sideExpDelta = 0,
  });

  int get totalExpDelta => dailyExpDelta + sideExpDelta;

  bool get hasAny => dailyMissDays > 0 || sideOverdueDays > 0 || totalExpDelta != 0;
  bool get hasSideOverdue => sideOverdueDays > 0;

  DebuffApplyResult merge(DebuffApplyResult other) => DebuffApplyResult(
        dailyMissDays: dailyMissDays + other.dailyMissDays,
        sideOverdueDays: sideOverdueDays + other.sideOverdueDays,
        dailyExpDelta: dailyExpDelta + other.dailyExpDelta,
        sideExpDelta: sideExpDelta + other.sideExpDelta,
      );
}

class QuestProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _webStore = WebSeedStore.instance;
  List<Quest> quests = [];
  List<StreakLog> streakLogs = [];
  Future<void>? _loadFuture;

  List<Quest> get activeItems => quests.where((q) => !q.isArchived).toList();
  List<Quest> get archivedItems => quests.where((q) => q.isArchived).toList();

  List<Quest> get mainQuests => activeItems.where((q) => q.type == 'main').toList();
  List<Quest> get sideQuests => activeItems.where((q) => q.type == 'side').toList();
  List<Quest> get dailyQuests => activeItems.where((q) => q.type == 'daily').toList();
  List<Quest> get activeQuests => activeItems.where((q) => q.status == 'active').toList();

  Future<void> load() {
    _loadFuture ??= _loadInternal();
    return _loadFuture!;
  }

  Future<void> ensureLoaded() => load();

  Future<void> reload() async {
    _loadFuture = null;
    await load();
  }

  Future<void> _loadInternal() async {
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
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final updated = quest.copyWith(status: 'completed', completedDate: today);
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

  Future<void> setQuestCompleted(int questId) async {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final updated = quests[idx].copyWith(status: 'completed', completedDate: today);
    quests[idx] = updated;
    if (!kIsWeb) {
      await _db.update('quests', updated.toMap(), where: 'id = ?', whereArgs: [questId]);
    }
    if (kIsWeb) {
      _webStore.quests = quests.map((q) => q).toList();
    }
    notifyListeners();
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

  Future<void> updateQuestDescription(int questId, String? description) async {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final updated = quests[idx].copyWith(description: description);
    quests[idx] = updated;
    if (!kIsWeb) {
      await _db.update('quests', updated.toMap(), where: 'id = ?', whereArgs: [questId]);
    }
    if (kIsWeb) {
      _webStore.quests = quests.map((q) => q).toList();
    }
    notifyListeners();
  }

  Future<void> archiveQuest(int questId) async {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final now = DateTime.now().toIso8601String();
    final updated = quests[idx].copyWith(
      isArchived: true,
      archivedAt: now,
      archivedReason: 'user',
      archivedBySkillId: null,
    );
    quests[idx] = updated;
    if (!kIsWeb) {
      await _db.update('quests', updated.toMap(), where: 'id = ?', whereArgs: [questId]);
    }
    if (kIsWeb) {
      _webStore.quests = quests.map((q) => q).toList();
    }
    notifyListeners();
  }

  Future<void> restoreQuest(int questId) async {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final updated = quests[idx].copyWith(
      isArchived: false,
      archivedAt: '',
      archivedReason: null,
      archivedBySkillId: null,
    );
    quests[idx] = updated;
    if (!kIsWeb) {
      await _db.update('quests', updated.toMap(), where: 'id = ?', whereArgs: [questId]);
    }
    if (kIsWeb) {
      _webStore.quests = quests.map((q) => q).toList();
    }
    notifyListeners();
  }

  Future<void> archiveQuestsBySkillIds(Set<int> skillIds, {required int rootSkillId}) async {
    if (skillIds.isEmpty) return;
    final now = DateTime.now().toIso8601String();

    bool changed = false;
    for (int i = 0; i < quests.length; i++) {
      final q = quests[i];
      if (q.isArchived) continue;
      final linked = (q.targetSkillId != null && skillIds.contains(q.targetSkillId)) ||
          (q.lossSkillId != null && skillIds.contains(q.lossSkillId));
      if (!linked) continue;
      quests[i] = q.copyWith(
        isArchived: true,
        archivedAt: now,
        archivedReason: 'skill',
        archivedBySkillId: rootSkillId,
      );
      changed = true;
    }

    if (!changed) return;

    if (kIsWeb) {
      _webStore.quests = quests.map((q) => q).toList();
      notifyListeners();
      return;
    }

    final db = await _db.database;
    final placeholders = List.filled(skillIds.length, '?').join(',');
    final args = [...skillIds, ...skillIds];
    await db.rawUpdate(
      '''
UPDATE quests
SET is_archived = 1,
    archived_at = ?,
    archived_reason = 'skill',
    archived_by_skill_id = ?
WHERE is_archived = 0
  AND ((target_skill_id IN ($placeholders)) OR (loss_skill_id IN ($placeholders)))
''',
      [now, rootSkillId, ...args],
    );

    notifyListeners();
  }

  Future<void> restoreAutoArchivedQuestsBySkillRoot(int rootSkillId) async {
    bool changed = false;
    for (int i = 0; i < quests.length; i++) {
      final q = quests[i];
      if (!q.isArchived) continue;
      if (q.archivedReason != 'skill') continue;
      if (q.archivedBySkillId != rootSkillId) continue;
      quests[i] = q.copyWith(
        isArchived: false,
        archivedAt: '',
        archivedReason: null,
        archivedBySkillId: null,
      );
      changed = true;
    }

    if (!changed) return;

    if (kIsWeb) {
      _webStore.quests = quests.map((q) => q).toList();
      notifyListeners();
      return;
    }

    final db = await _db.database;
    await db.rawUpdate(
      '''
UPDATE quests
SET is_archived = 0,
    archived_at = NULL,
    archived_reason = NULL,
    archived_by_skill_id = NULL
WHERE is_archived = 1
  AND archived_reason = 'skill'
  AND archived_by_skill_id = ?
''',
      [rootSkillId],
    );

    notifyListeners();
  }

  /// Completely delete a quest and its related records.
  /// Also removes the quest's journal entries and daily streak log.
  ///
  /// Returns `true` if deleted, `false` otherwise.
  Future<bool> purgeQuest(int questId) async {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return false;

    // SQLite: remove dependent rows first to avoid FK issues and orphan logs.
    if (!kIsWeb) {
      await _db.delete('quest_journals', where: 'quest_id = ?', whereArgs: [questId]);
      await _db.delete('streak_logs', where: 'quest_id = ?', whereArgs: [questId]);
      await _db.delete('quests', where: 'id = ?', whereArgs: [questId]);
      streakLogs.removeWhere((s) => s.questId == questId);
    } else {
      quests.removeAt(idx);
      // Remove streak logs for daily quests
      streakLogs.removeWhere((s) => s.questId == questId);
      // Remove web journal entries (stored as raw maps)
      _webStore.questJournals.removeWhere((m) => (m['quest_id'] as int) == questId);
      _webStore.quests = quests.map((q) => q).toList();
      _webStore.streakLogs = streakLogs.map((s) => s).toList();
      notifyListeners();
      return true;
    }

    // Update in-memory list for both platforms
    quests.removeAt(idx);
    notifyListeners();
    return true;
  }

  Future<DebuffApplyResult> applyPendingDebuffs(CharacterProvider cp, JournalProvider jp) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

    await jp.pruneOlderThanDays(30);

    DebuffApplyResult result = const DebuffApplyResult();
    for (final quest in quests) {
      if (quest.isArchived) continue;
      if (quest.status != 'active') continue;
      if (!quest.debuffEnabled) continue;
      if (quest.expReward <= 0) continue; // safety: abnormal tasks do nothing

      if (quest.type == 'daily') {
        result = result.merge(await _applyDailyDebuff(quest, cp, jp, today: today, yesterday: yesterday));
      }
      if (quest.type == 'side') {
        result = result.merge(await _applySideOverdueDebuff(quest, cp, jp, today: today, yesterday: yesterday));
      }
    }
    return result;
  }

  Future<DebuffApplyResult> _applyDailyDebuff(Quest quest, CharacterProvider cp, JournalProvider jp, {required String today, required String yesterday}) async {
    final streak = streakFor(quest.id ?? -1);
    if (streak == null) return const DebuffApplyResult();

    // If never completed, do not retroactively penalize.
    final lastCompleted = streak.lastCompletedDate.isEmpty ? today : streak.lastCompletedDate;
    final lastApplied = streak.lastDebuffAppliedDate.isEmpty ? lastCompleted : streak.lastDebuffAppliedDate;

    String cursor = _addDays(_maxDate(lastCompleted, lastApplied), 1);
    if (cursor.compareTo(yesterday) > 0) return const DebuffApplyResult();

    int missDays = 0;
    int totalDelta = 0;
    while (cursor.compareTo(yesterday) <= 0) {
      final penalty = (quest.expReward * 0.5).round();
      await cp.applyExpDelta(-penalty);
      missDays++;
      totalDelta -= penalty;
      await jp.upsert(QuestJournal(
        questId: quest.id!,
        logDate: cursor,
        completed: false,
        expDelta: -penalty,
        reason: 'miss',
        createdAt: DateTime.now().toIso8601String(),
      ));
      cursor = _addDays(cursor, 1);
    }

    final updated = streak.copyWith(lastDebuffAppliedDate: yesterday);
    final sIdx = streakLogs.indexWhere((s) => s.questId == quest.id);
    if (sIdx != -1) streakLogs[sIdx] = updated;
    if (!kIsWeb) {
      await _db.update('streak_logs', updated.toMap(), where: 'quest_id = ?', whereArgs: [quest.id!]);
    }
    if (kIsWeb) {
      _webStore.streakLogs = streakLogs.map((s) => s).toList();
    }
    notifyListeners();
    return DebuffApplyResult(dailyMissDays: missDays, dailyExpDelta: totalDelta);
  }

  Future<DebuffApplyResult> _applySideOverdueDebuff(Quest quest, CharacterProvider cp, JournalProvider jp, {required String today, required String yesterday}) async {
    if (quest.debuffDueDays == null) return const DebuffApplyResult();
    final created = quest.createdDate.isEmpty ? today : quest.createdDate;
    final due = _addDays(created, quest.debuffDueDays!);

    // Only overdue days count.
    if (yesterday.compareTo(due) < 0) return const DebuffApplyResult();

    final lastApplied = quest.lastDebuffAppliedDate.isEmpty ? _addDays(due, -1) : quest.lastDebuffAppliedDate;
    String cursor = _addDays(lastApplied, 1);
    if (cursor.compareTo(due) < 0) cursor = due;

    if (cursor.compareTo(yesterday) > 0) return const DebuffApplyResult();

    String lastDid = '';
    int overdueDays = 0;
    int totalDelta = 0;
    while (cursor.compareTo(yesterday) <= 0) {
      final penalty = (quest.expReward * 0.5).round();
      await cp.applyExpDelta(-penalty);
      overdueDays++;
      totalDelta -= penalty;
      await jp.upsert(QuestJournal(
        questId: quest.id!,
        logDate: cursor,
        completed: false,
        expDelta: -penalty,
        reason: 'overdue',
        createdAt: DateTime.now().toIso8601String(),
      ));
      lastDid = cursor;
      cursor = _addDays(cursor, 1);
    }

    if (lastDid.isEmpty) return const DebuffApplyResult();
    await _updateQuestDebuffAppliedDate(quest.id!, lastDid);
    return DebuffApplyResult(sideOverdueDays: overdueDays, sideExpDelta: totalDelta);
  }

  Future<void> _updateQuestDebuffAppliedDate(int questId, String date) async {
    final idx = quests.indexWhere((q) => q.id == questId);
    if (idx == -1) return;
    final updated = quests[idx].copyWith(lastDebuffAppliedDate: date);
    quests[idx] = updated;
    if (!kIsWeb) {
      await _db.update('quests', updated.toMap(), where: 'id = ?', whereArgs: [questId]);
    }
    if (kIsWeb) {
      _webStore.quests = quests.map((q) => q).toList();
    }
    notifyListeners();
  }

  String _addDays(String yyyyMmDd, int days) {
    final dt = DateTime.parse('${yyyyMmDd}T00:00:00');
    final next = dt.add(Duration(days: days));
    return next.toIso8601String().substring(0, 10);
  }

  String _maxDate(String a, String b) => a.compareTo(b) >= 0 ? a : b;
}
