import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/web_seed_store.dart';
import '../models/skill.dart';

class SkillProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _webStore = WebSeedStore.instance;
  List<Skill> skills = [];

  List<Skill> get roots => skills.where((s) => s.parentId == null).toList();

  List<Skill> childrenOf(int parentId) =>
      skills.where((s) => s.parentId == parentId).toList();

  Skill? byId(int id) {
    try {
      return skills.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Compute aggregated exp for a node (own + all descendants)
  int aggregatedExp(int id) {
    final node = byId(id);
    if (node == null) return 0;
    int total = node.currentExp;
    for (final child in childrenOf(id)) {
      total += aggregatedExp(child.id!);
    }
    return total;
  }

  /// Compute aggregated level for a node
  int aggregatedLevel(int id) {
    final node = byId(id);
    if (node == null) return 0;
    int total = node.level;
    for (final child in childrenOf(id)) {
      total += aggregatedLevel(child.id!);
    }
    return total;
  }

  Future<void> load() async {
    if (kIsWeb) {
      _webStore.ensureInit();
      skills = _webStore.skills.map((s) => s).toList();
      notifyListeners();
      return;
    }

    final rows = await _db.query('skills', orderBy: 'id ASC');
    skills = rows.map((r) => Skill.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addExpToSkill(int skillId, int amount) async {
    final idx = skills.indexWhere((s) => s.id == skillId);
    if (idx == -1) return;

    var skill = skills[idx];
    int newExp = skill.currentExp + amount;
    int newLevel = skill.level;

    // Level up loop
    while (newExp >= 100 * newLevel) {
      newExp -= 100 * newLevel;
      newLevel++;
    }

    skill = skill.copyWith(currentExp: newExp, level: newLevel);
    skills[idx] = skill;

    if (!kIsWeb) {
      await _db.update('skills', skill.toMap(), where: 'id = ?', whereArgs: [skillId]);
    }

    // Propagate partial exp to parent
    if (skill.parentId != null) {
      await addExpToSkill(skill.parentId!, (amount * 0.3).round());
    }

    if (kIsWeb) {
      // Keep web store in sync.
      _webStore.skills = skills.map((s) => s).toList();
    }
    notifyListeners();
  }

  Future<void> addSkill(String name, int? parentId) async {
    if (kIsWeb) {
      final nextId = (skills.map((s) => s.id ?? 0).fold<int>(0, (a, b) => b > a ? b : a)) + 1;
      skills.add(Skill(id: nextId, name: name, parentId: parentId, currentExp: 0, level: 1));
      _webStore.skills = skills.map((s) => s).toList();
      notifyListeners();
      return;
    }

    final id = await _db.insert('skills', {
      'name': name,
      'parent_id': parentId,
      'current_exp': 0,
      'level': 1,
    });
    skills.add(Skill(id: id, name: name, parentId: parentId));
    notifyListeners();
  }
}
