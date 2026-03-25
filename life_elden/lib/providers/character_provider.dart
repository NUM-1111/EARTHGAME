import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/web_seed_store.dart';

class CharacterProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _webStore = WebSeedStore.instance;
  Future<void>? _loadFuture;

  String name = 'Jiang Yiwu';
  int totalLevel = 1;
  int totalExp = 0;
  String title = '无用之人';
  List<String> activeBuffs = [];

  /// Exp needed for next level: 100 * currentLevel
  int get expToNextLevel => 100 * totalLevel;
  double get expProgress => totalExp / expToNextLevel;

  /// Character phase based on total level
  String get phase {
    if (totalLevel >= 30) return '黄金树守卫';
    if (totalLevel >= 11) return '流浪骑士';
    return '无用之人';
  }

  /// Avatar asset key based on phase
  String get avatarAsset {
    if (totalLevel >= 30) return 'golden_guardian';
    if (totalLevel >= 11) return 'wandering_knight';
    return 'tarnished';
  }

  Future<void> load() {
    _loadFuture ??= _loadInternal();
    return _loadFuture!;
  }

  Future<void> ensureLoaded() => load();

  Future<void> _loadInternal() async {
    if (kIsWeb) {
      _webStore.ensureInit();
      name = _webStore.name;
      totalLevel = _webStore.totalLevel;
      totalExp = _webStore.totalExp;
      title = _webStore.title;
      notifyListeners();
      return;
    }

    name = await _db.getCharMeta('name', fallback: 'Jiang Yiwu');
    totalLevel = int.tryParse(await _db.getCharMeta('total_level', fallback: '1')) ?? 1;
    totalExp = int.tryParse(await _db.getCharMeta('total_exp', fallback: '0')) ?? 0;
    title = await _db.getCharMeta('title', fallback: '无用之人');
    notifyListeners();
  }

  Future<void> addExp(int amount) async {
    await applyExpDelta(amount);
  }

  /// Apply an exp delta to the character.
  ///
  /// - Positive delta: level up as needed.
  /// - Negative delta: level down as needed (min level = 1, min exp = 0).
  Future<void> applyExpDelta(int delta) async {
    if (kIsWeb) {
      _webStore.ensureInit();
      _applyDeltaInMemory(delta);
      _webStore.totalExp = totalExp;
      _webStore.totalLevel = totalLevel;
      _webStore.title = title;
      notifyListeners();
      return;
    }

    _applyDeltaInMemory(delta);
    await _save();
    notifyListeners();
  }

  void _applyDeltaInMemory(int delta) {
    totalExp += delta;

    // Level up loop
    while (totalExp >= expToNextLevel) {
      totalExp -= expToNextLevel;
      totalLevel++;
    }

    // Level down loop (min level 1)
    while (totalExp < 0) {
      if (totalLevel <= 1) {
        totalLevel = 1;
        totalExp = 0;
        break;
      }
      totalLevel--;
      totalExp += 100 * totalLevel;
    }

    title = phase;
  }

  Future<void> updateName(String newName) async {
    if (kIsWeb) {
      _webStore.ensureInit();
      name = newName;
      _webStore.name = newName;
      notifyListeners();
      return;
    }

    name = newName;
    await _db.setCharMeta('name', newName);
    notifyListeners();
  }

  Future<void> _save() async {
    await _db.setCharMeta('total_level', totalLevel.toString());
    await _db.setCharMeta('total_exp', totalExp.toString());
    await _db.setCharMeta('title', title);
  }
}
