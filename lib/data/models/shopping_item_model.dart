import 'package:hive_flutter/hive_flutter.dart';

part 'shopping_item_model.g.dart';

@HiveType(typeId: 1)
class ShoppingItemModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String listId;

  @HiveField(2)
  String name;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  String unit;

  @HiveField(5)
  String categoryId;

  @HiveField(6)
  bool isChecked;

  @HiveField(7)
  String? imagePath;

  @HiveField(8)
  final DateTime createdAt;

  ShoppingItemModel({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity = 1,
    this.unit = 'Stk.',
    required this.categoryId,
    this.isChecked = false,
    this.imagePath,
    required this.createdAt,
  });
}
