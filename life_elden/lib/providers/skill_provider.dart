import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/web_seed_store.dart';
import '../models/skill.dart';

class SkillProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _webStore = WebSeedStore.instance;
  List<Skill> skills = [];

  List<Skill> get activeItems => skills.where((s) => !s.isArchived).toList();
  List<Skill> get archivedItems => skills.where((s) => s.isArchived).toList();

  List<Skill> get roots => activeItems.where((s) => s.parentId == null).toList();

  List<Skill> childrenOf(int parentId) =>
      activeItems.where((s) => s.parentId == parentId).toList();

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
    await applyExpDeltaToSkill(skillId, amount, propagateToParent: true);
  }

  /// Apply an exp delta to a skill.
  ///
  /// - Positive delta: level up as needed.
  /// - Negative delta: level down as needed (min level = 1, min exp = 0).
  /// - Parent propagation only happens for positive deltas (by design).
  Future<void> applyExpDeltaToSkill(int skillId, int delta, {bool propagateToParent = false}) async {
    final idx = skills.indexWhere((s) => s.id == skillId);
    if (idx == -1) return;

    var skill = skills[idx];
    int newExp = skill.currentExp + delta;
    int newLevel = skill.level;

    // Level up loop
    while (newExp >= 100 * newLevel) {
      newExp -= 100 * newLevel;
      newLevel++;
    }

    // Level down loop (min level 1)
    while (newExp < 0) {
      if (newLevel <= 1) {
        newLevel = 1;
        newExp = 0;
        break;
      }
      newLevel--;
      newExp += 100 * newLevel;
    }

    skill = skill.copyWith(currentExp: newExp, level: newLevel);
    skills[idx] = skill;

    if (!kIsWeb) {
      await _db.update('skills', skill.toMap(), where: 'id = ?', whereArgs: [skillId]);
    }

    if (propagateToParent && delta > 0 && skill.parentId != null) {
      await applyExpDeltaToSkill(skill.parentId!, (delta * 0.3).round(), propagateToParent: true);
    }

    if (kIsWeb) {
      _webStore.skills = skills.map((s) => s).toList();
    }
    notifyListeners();
  }

  Future<void> addSkill(String name, int? parentId) async {
    if (kIsWeb) {
      final nextId = (skills.map((s) => s.id ?? 0).fold<int>(0, (a, b) => b > a ? b : a)) + 1;
      skills.add(Skill(id: nextId, name: name, parentId: parentId, description: '', currentExp: 0, level: 1));
      _webStore.skills = skills.map((s) => s).toList();
      notifyListeners();
      return;
    }

    final id = await _db.insert('skills', {
      'name': name,
      'parent_id': parentId,
      'description': '',
      'current_exp': 0,
      'level': 1,
    });
    skills.add(Skill(id: id, name: name, parentId: parentId));
    notifyListeners();
  }

  Future<void> updateDescription(int id, String description) async {
    final idx = skills.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final updated = skills[idx].copyWith(description: description);
    skills[idx] = updated;
    if (!kIsWeb) {
      await _db.update('skills', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    if (kIsWeb) {
      _webStore.skills = skills.map((s) => s).toList();
    }
    notifyListeners();
  }

  Future<void> archiveSkill(int id) async {
    final idx = skills.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final now = DateTime.now().toIso8601String();
    final updated = skills[idx].copyWith(isArchived: true, archivedAt: now);
    skills[idx] = updated;
    if (!kIsWeb) {
      await _db.update('skills', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    if (kIsWeb) {
      _webStore.skills = skills.map((s) => s).toList();
    }
    notifyListeners();
  }

  Future<void> restoreSkill(int id) async {
    final idx = skills.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final updated = skills[idx].copyWith(isArchived: false, archivedAt: '');
    skills[idx] = updated;
    if (!kIsWeb) {
      await _db.update('skills', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    if (kIsWeb) {
      _webStore.skills = skills.map((s) => s).toList();
    }
    notifyListeners();
  }
}
