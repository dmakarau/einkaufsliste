import 'package:equatable/equatable.dart';

class FamilyGroupMemberModel extends Equatable {
  final String id;
  final String groupId;
  final String? userId;
  final String email;
  final String role; // 'admin' | 'member'
  final String status; // 'pending' | 'accepted'
  final DateTime createdAt;

  const FamilyGroupMemberModel({
    required this.id,
    required this.groupId,
    this.userId,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  factory FamilyGroupMemberModel.fromMap(Map<String, dynamic> map) {
    return FamilyGroupMemberModel(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String?,
      email: map['email'] as String,
      role: map['role'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [id, groupId, userId, email, role, status, createdAt];
}
