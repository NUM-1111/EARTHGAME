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
    final now = DateTime.now().toIso8601String();
    final ids = _collectDescendantSkillIds(id);
    if (ids.isEmpty) return;

    bool changed = false;
    for (int i = 0; i < skills.length; i++) {
      final s = skills[i];
      if (s.id == null) continue;
      if (!ids.contains(s.id)) continue;
      if (s.isArchived && s.archivedAt.isNotEmpty) continue;
      skills[i] = s.copyWith(isArchived: true, archivedAt: now);
      changed = true;
    }
    if (!changed) return;

    if (!kIsWeb) {
      for (final sid in ids) {
        final s = byId(sid);
        if (s == null) continue;
        await _db.update('skills', s.toMap(), where: 'id = ?', whereArgs: [sid]);
      }
    }

    if (kIsWeb) {
      _webStore.skills = skills.map((s) => s).toList();
    }
    notifyListeners();
  }

  Future<bool> restoreSkill(int id) async {
    final idx = skills.indexWhere((s) => s.id == id);
    if (idx == -1) return false;

    // Restore root skill should restore its whole subtree (because root archive is cascade).
    final restoring = skills[idx];

    // Safety rule: cannot restore a child if ANY ancestor is still archived.
    //
    // If parent is missing/deleted, allow restoring (and UI will show parent missing).
    if (restoring.parentId != null) {
      final visited = <int>{};
      var cursor = restoring.parentId;
      while (cursor != null) {
        if (visited.contains(cursor)) break; // guard against malformed cycles
        visited.add(cursor);
        final p = byId(cursor);
        if (p == null) break;
        if (p.isArchived) return false;
        cursor = p.parentId;
      }
    }

    final shouldRestoreSubtree = restoring.parentId == null;
    final ids = shouldRestoreSubtree ? _collectDescendantSkillIds(id) : <int>{id};

    bool changed = false;
    for (int i = 0; i < skills.length; i++) {
      final s = skills[i];
      if (s.id == null) continue;
      if (!ids.contains(s.id)) continue;

      var updated = s.copyWith(isArchived: false, archivedAt: '');
      // If parent is missing or archived, reparent to root (restore_as_root).
      if (updated.parentId != null) {
        final parent = byId(updated.parentId!);
        if (parent == null || parent.isArchived) {
          updated = updated.copyWith(parentId: null);
        }
      }

      if (skills[i] != updated) {
        skills[i] = updated;
        changed = true;
      }
    }

    if (!changed) return false;

    if (!kIsWeb) {
      for (final sid in ids) {
        final s = byId(sid);
        if (s == null) continue;
        await _db.update('skills', s.toMap(), where: 'id = ?', whereArgs: [sid]);
      }
    }
    if (kIsWeb) {
      _webStore.skills = skills.map((s) => s).toList();
    }
    notifyListeners();
    return true;
  }

  Set<int> _collectDescendantSkillIds(int rootId) {
    final root = byId(rootId);
    if (root == null || root.id == null) return <int>{};

    final result = <int>{rootId};
    bool added = true;
    while (added) {
      added = false;
      for (final s in skills) {
        final sid = s.id;
        if (sid == null) continue;
        final pid = s.parentId;
        if (pid == null) continue;
        if (result.contains(pid) && !result.contains(sid)) {
          result.add(sid);
          added = true;
        }
      }
    }
    return result;
  }

  // Expose for UI to coordinate quest archiving without duplicating logic.
  Set<int> collectDescendantSkillIdsForUi(int rootId) => _collectDescendantSkillIds(rootId);

  /// Downgrade rule: purge a root skill and all its descendants together.
  ///
  /// Safety rule:
  /// - If ANY quest references ANY skill in the subtree as `target_skill_id` or `loss_skill_id`,
  ///   return `false` and do not delete anything.
  Future<bool> purgeSkillCascade(int rootSkillId) async {
    final subtreeIds = _collectDescendantSkillIds(rootSkillId);
    if (subtreeIds.isEmpty) return false;

    // Only allow cascade purge for roots (parentId == null)
    final root = byId(rootSkillId);
    if (root == null || root.parentId != null) return false;

    if (kIsWeb) {
      final usedByQuest = _webStore.quests.any((q) {
        final t = q.targetSkillId;
        final l = q.lossSkillId;
        return (t != null && subtreeIds.contains(t)) || (l != null && subtreeIds.contains(l));
      });
      if (usedByQuest) return false;

      skills.removeWhere((s) => s.id != null && subtreeIds.contains(s.id));
      _webStore.skills = skills.map((s) => s).toList();
      notifyListeners();
      return true;
    }

    final db = await _db.database;
    final placeholders = List.filled(subtreeIds.length, '?').join(',');
    final args = subtreeIds.toList();
    final ref = await db.rawQuery(
      '''
SELECT id FROM quests
WHERE (target_skill_id IN ($placeholders)) OR (loss_skill_id IN ($placeholders))
LIMIT 1
''',
      [...args, ...args],
    );
    if (ref.isNotEmpty) return false;

    await db.rawDelete(
      'DELETE FROM skills WHERE id IN ($placeholders)',
      args,
    );
    skills.removeWhere((s) => s.id != null && subtreeIds.contains(s.id));
    notifyListeners();
    return true;
  }

  /// Completely delete a skill.
  ///
  /// Strict protection rule:
  /// - If any quest references this skill as `target_skill_id` or `loss_skill_id`,
  ///   return `false` and do not delete.
  /// - Otherwise delete the skill (SQLite delete / Web remove) and return `true`.
  Future<bool> purgeSkill(int skillId) async {
    final idx = skills.indexWhere((s) => s.id == skillId);
    if (idx == -1) return false;

    if (kIsWeb) {
      final usedByQuest = _webStore.quests.any((q) => q.targetSkillId == skillId || q.lossSkillId == skillId);
      if (usedByQuest) return false;

      // Reparent children to roots to avoid “orphan skills” after deleting a parent.
      for (int i = 0; i < skills.length; i++) {
        final s = skills[i];
        if (s.parentId == skillId) {
          skills[i] = s.copyWith(parentId: null);
        }
      }

      skills.removeAt(idx);
      _webStore.skills = skills.map((s) => s).toList();
      notifyListeners();
      return true;
    }

    final refRows = await _db.query(
      'quests',
      where: '(target_skill_id = ? OR loss_skill_id = ?)',
      whereArgs: [skillId, skillId],
    );
    if (refRows.isNotEmpty) return false;

    // SQLite: Reparent children to roots to avoid “orphan skills” after deleting a parent.
    final childIdxs = <int>[];
    for (int i = 0; i < skills.length; i++) {
      if (skills[i].parentId == skillId) childIdxs.add(i);
    }
    for (final i in childIdxs) {
      final child = skills[i].copyWith(parentId: null);
      skills[i] = child;
      await _db.update('skills', child.toMap(), where: 'id = ?', whereArgs: [child.id]);
    }

    await _db.delete('skills', where: 'id = ?', whereArgs: [skillId]);
    skills.removeAt(idx);
    notifyListeners();
    return true;
  }
}
