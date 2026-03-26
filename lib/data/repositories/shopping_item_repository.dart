import 'package:hive_flutter/hive_flutter.dart';
import '../models/shopping_item_model.dart';
import '../../core/constants/hive_boxes.dart';

class ShoppingItemRepository {
  Box<ShoppingItemModel> get _box =>
      Hive.box<ShoppingItemModel>(HiveBoxes.shoppingItems);

  List<ShoppingItemModel> getByListId(String listId) {
    return _box.values.where((item) => item.listId == listId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> add(ShoppingItemModel item) async {
    await _box.put(item.id, item);
  }

  Future<void> update(ShoppingItemModel item) async {
    await item.save();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteByListId(String listId) async {
    final keys = _box.values
        .where((item) => item.listId == listId)
        .map((item) => item.id)
        .toList();
    await _box.deleteAll(keys);
  }

  Future<void> clearAll() async => _box.clear();
}
