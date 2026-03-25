import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'seed_data.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    String path;
    if (kIsWeb) {
      // Web: no filesystem path needed, just a db name
      path = 'life_elden.db';
    } else {
      final dbPath = await getDatabasesPath();
      path = p.join(dbPath, 'life_elden.db');
    }

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Character meta table ──
    await db.execute('''
      CREATE TABLE character_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // ── Skills ──
    await db.execute('''
      CREATE TABLE skills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        current_exp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (parent_id) REFERENCES skills(id)
      )
    ''');

    // ── Equipment ──
    await db.execute('''
      CREATE TABLE equipment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rarity TEXT NOT NULL DEFAULT 'Common',
        buff_description TEXT NOT NULL DEFAULT '',
        is_equipped INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // ── Quests ──
    await db.execute('''
      CREATE TABLE quests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'daily',
        status TEXT NOT NULL DEFAULT 'active',
        target_skill_id INTEGER,
        exp_reward INTEGER NOT NULL DEFAULT 0,
        description TEXT,
        FOREIGN KEY (target_skill_id) REFERENCES skills(id)
      )
    ''');

    // ── Streak logs ──
    await db.execute('''
      CREATE TABLE streak_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quest_id INTEGER NOT NULL,
        last_completed_date TEXT NOT NULL,
        current_streak INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (quest_id) REFERENCES quests(id)
      )
    ''');

    // ── Inject seed data ──
    await _seedAll(db);
  }

  Future<void> _seedAll(Database db) async {
    // Character defaults
    final ch = SeedData.defaultCharacter;
    for (final entry in ch.entries) {
      await db.insert('character_meta', {'key': entry.key, 'value': entry.value.toString()});
    }

    // Skills
    for (final s in SeedData.skills) {
      await db.insert('skills', s);
    }

    // Equipment
    for (final e in SeedData.equipment) {
      await db.insert('equipment', e);
    }

    // Quests
    for (final q in SeedData.quests) {
      await db.insert('quests', q);
    }

    // Streak logs for daily quests (initial)
    final dailyQuests = SeedData.quests.where((q) => q['type'] == 'daily');
    int questIdCounter = 1;
    for (final q in SeedData.quests) {
      if (q['type'] == 'daily') {
        await db.insert('streak_logs', {
          'quest_id': questIdCounter,
          'last_completed_date': '',
          'current_streak': 0,
        });
      }
      questIdCounter++;
    }
  }

  // ─── Generic helpers ───

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return db.rawQuery(sql, args);
  }

  // ─── Character-specific helpers ───

  Future<String> getCharMeta(String key, {String fallback = ''}) async {
    final rows = await query('character_meta', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return fallback;
    return rows.first['value'] as String;
  }

  Future<void> setCharMeta(String key, String value) async {
    final db = await database;
    await db.insert('character_meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
