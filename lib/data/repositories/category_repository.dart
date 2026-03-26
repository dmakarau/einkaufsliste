import 'package:hive_flutter/hive_flutter.dart';
import '../models/category_model.dart';
import '../../core/constants/hive_boxes.dart';

class CategoryRepository {
  Box<CategoryModel> get _box => Hive.box<CategoryModel>(HiveBoxes.categories);

  List<CategoryModel> getAll() {
    return _box.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  CategoryModel? getById(String id) {
    try {
      return _box.values.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  Future<void> update(CategoryModel category) async {
    await category.save();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  bool isEmpty() => _box.isEmpty;

  Future<void> clearAll() async => _box.clear();
}
