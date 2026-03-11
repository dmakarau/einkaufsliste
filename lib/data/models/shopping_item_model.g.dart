// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShoppingItemModelAdapter extends TypeAdapter<ShoppingItemModel> {
  @override
  final int typeId = 1;

  @override
  ShoppingItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShoppingItemModel(
      id: fields[0] as String,
      listId: fields[1] as String,
      name: fields[2] as String,
      quantity: fields[3] as double,
      unit: fields[4] as String,
      categoryId: fields[5] as String,
      isChecked: fields[6] as bool,
      imagePath: fields[7] as String?,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItemModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.listId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.isChecked)
      ..writeByte(7)
      ..write(obj.imagePath)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
