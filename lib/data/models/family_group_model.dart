import 'package:equatable/equatable.dart';

class FamilyGroupModel extends Equatable {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;

  const FamilyGroupModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
  });

  factory FamilyGroupModel.fromMap(Map<String, dynamic> map) {
    return FamilyGroupModel(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['owner_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, ownerId, createdAt];
}
