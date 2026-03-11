import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_list_model.dart';
import '../../core/constants/hive_boxes.dart';

class ShoppingListRepository {
  Box<ShoppingListModel> get _box => Hive.box<ShoppingListModel>(HiveBoxes.shoppingLists);

  List<ShoppingListModel> getAll() {
    final lists = _box.values.toList();
    lists.sort((a, b) {
      if (a.isDefault) return -1;
      if (b.isDefault) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return lists;
  }

  ShoppingListModel? getById(String id) {
    try {
      return _box.values.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  ShoppingListModel? getDefault() {
    try {
      return _box.values.firstWhere((l) => l.isDefault);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(ShoppingListModel list) async {
    await _box.put(list.id, list);
  }

  Future<void> update(ShoppingListModel list) async {
    await list.save();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  bool isEmpty() => _box.isEmpty;

  Future<void> clearAll() async => _box.clear();
}
