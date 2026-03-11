import 'package:hive_flutter/hive_flutter.dart';

part 'shopping_list_model.g.dart';

@HiveType(typeId: 0)
class ShoppingListModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final bool isDefault;

  @HiveField(3)
  final DateTime createdAt;

  ShoppingListModel({
    required this.id,
    required this.name,
    this.isDefault = false,
    required this.createdAt,
  });
}
