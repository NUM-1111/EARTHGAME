import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/web_seed_store.dart';
import '../models/equipment.dart';

class EquipmentProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;
  final _webStore = WebSeedStore.instance;
  List<Equipment> items = [];

  List<Equipment> get equipped => items.where((e) => e.isEquipped).toList();

  Future<void> load() async {
    if (kIsWeb) {
      _webStore.ensureInit();
      items = _webStore.equipment.map((e) => e).toList();
      notifyListeners();
      return;
    }

    final rows = await _db.query('equipment', orderBy: 'id ASC');
    items = rows.map((r) => Equipment.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> addEquipment(Equipment eq) async {
    if (kIsWeb) {
      final nextId = (items.map((e) => e.id ?? 0).fold<int>(0, (a, b) => b > a ? b : a)) + 1;
      items.add(eq.copyWith(id: nextId));
      _webStore.equipment = items.map((e) => e).toList();
      notifyListeners();
      return;
    }

    final id = await _db.insert('equipment', eq.toMap());
    items.add(eq.copyWith(id: id));
    notifyListeners();
  }

  Future<void> toggleEquip(int id) async {
    final idx = items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final eq = items[idx];
    final updated = eq.copyWith(isEquipped: !eq.isEquipped);
    items[idx] = updated;
    if (!kIsWeb) {
      await _db.update('equipment', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    if (kIsWeb) {
      _webStore.equipment = items.map((e) => e).toList();
    }
    notifyListeners();
  }

  Future<void> deleteEquipment(int id) async {
    items.removeWhere((e) => e.id == id);
    if (!kIsWeb) {
      await _db.delete('equipment', where: 'id = ?', whereArgs: [id]);
    }
    if (kIsWeb) {
      _webStore.equipment = items.map((e) => e).toList();
    }
    notifyListeners();
  }

  Future<void> updateBuffDescription(int id, String buffDescription) async {
    final idx = items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final updated = items[idx].copyWith(buffDescription: buffDescription);
    items[idx] = updated;
    if (!kIsWeb) {
      await _db.update('equipment', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    if (kIsWeb) {
      _webStore.equipment = items.map((e) => e).toList();
    }
    notifyListeners();
  }
}
