import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/web_seed_store.dart';
import '../models/quest_journal.dart';

class JournalProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _webStore = WebSeedStore.instance;

  List<QuestJournal> items = [];

  Future<void> loadLastDays(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);

    if (kIsWeb) {
      _webStore.ensureInit();
      final rows = _webStore.questJournals.where((m) => (m['log_date'] as String).compareTo(cutoff) >= 0).toList();
      items = rows.map((m) => QuestJournal.fromMap(m)).toList()
        ..sort((a, b) => b.logDate.compareTo(a.logDate));
      notifyListeners();
      return;
    }

    final rows = await _db.query('quest_journals', where: 'log_date >= ?', whereArgs: [cutoff], orderBy: 'log_date DESC, id DESC');
    items = rows.map((m) => QuestJournal.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> upsert(QuestJournal j) async {
    if (kIsWeb) {
      _webStore.ensureInit();
      final idx = _webStore.questJournals.indexWhere((m) => (m['quest_id'] as int) == j.questId && (m['log_date'] as String) == j.logDate);
      final map = j.toMap()..remove('id');
      if (idx == -1) {
        _webStore.questJournals.add({'id': _webStore.questJournals.length + 1, ...map});
      } else {
        _webStore.questJournals[idx] = {..._webStore.questJournals[idx], ...map};
      }
      notifyListeners();
      return;
    }

    // SQLite: honor UNIQUE(quest_id, log_date) with replace.
    await (await _db.database).insert(
      'quest_journals',
      j.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  Future<void> pruneOlderThanDays(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String().substring(0, 10);
    if (kIsWeb) {
      _webStore.ensureInit();
      _webStore.questJournals.removeWhere((m) => (m['log_date'] as String).compareTo(cutoff) < 0);
      notifyListeners();
      return;
    }
    final db = await _db.database;
    await db.delete('quest_journals', where: 'log_date < ?', whereArgs: [cutoff]);
    notifyListeners();
  }
}

