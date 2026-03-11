import 'package:hive_flutter/hive_flutter.dart';

part 'category_model.g.dart';

@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  int sortOrder;

  @HiveField(4)
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.sortOrder,
    this.isDefault = false,
  });
}
