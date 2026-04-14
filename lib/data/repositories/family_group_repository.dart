import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_group_member_model.dart';
import '../models/family_group_model.dart';

class FamilyGroupRepositoryException implements Exception {
  const FamilyGroupRepositoryException(this.message);
  final String message;
}

class FamilyGroupRepository {
  const FamilyGroupRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;
  String? get _email => _client.auth.currentUser?.email;

  /// Returns a group by [id]. Requires the caller to be able to see it via RLS.
  Future<FamilyGroupModel?> getGroupById(String id) async {
    try {
      final rows =
          await _client.from('family_groups').select().eq('id', id);
      if (rows.isEmpty) return null;
      return FamilyGroupModel.fromMap(rows.first);
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Returns the group the current user owns or is an accepted member of.
  Future<FamilyGroupModel?> getMyGroup() async {
    try {
      final rows = await _client.from('family_groups').select();
      if (rows.isEmpty) return null;
      return FamilyGroupModel.fromMap(rows.first);
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Returns pending invitations addressed to the current user's email.
  Future<List<FamilyGroupMemberModel>> getPendingInvites() async {
    final email = _email;
    if (email == null) return [];
    try {
      final rows = await _client
          .from('family_group_members')
          .select()
          .eq('email', email)
          .eq('status', 'pending');
      return rows.map(FamilyGroupMemberModel.fromMap).toList();
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Returns all members (accepted + pending) of [groupId].
  Future<List<FamilyGroupMemberModel>> getMembers(String groupId) async {
    try {
      final rows = await _client
          .from('family_group_members')
          .select()
          .eq('group_id', groupId)
          .order('created_at');
      return rows.map(FamilyGroupMemberModel.fromMap).toList();
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Creates a new group and adds the current user as admin.
  Future<FamilyGroupModel> createGroup(String name) async {
    final uid = _uid;
    final email = _email;
    if (uid == null || email == null) {
      throw const FamilyGroupRepositoryException('Not authenticated');
    }
    try {
      final groupRow = await _client
          .from('family_groups')
          .insert({'name': name, 'owner_id': uid})
          .select()
          .single();
      final group = FamilyGroupModel.fromMap(groupRow);

      await _client.from('family_group_members').insert({
        'group_id': group.id,
        'user_id': uid,
        'email': email,
        'role': 'admin',
        'status': 'accepted',
        'invited_by': uid,
      });

      return group;
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Invites [email] to [groupId]. Inserts a pending member row.
  Future<void> inviteMember(String email, String groupId) async {
    final uid = _uid;
    if (uid == null) throw const FamilyGroupRepositoryException('Not authenticated');
    try {
      await _client.from('family_group_members').insert({
        'group_id': groupId,
        'email': email.trim().toLowerCase(),
        'role': 'member',
        'status': 'pending',
        'invited_by': uid,
      });
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Accepts the pending invite for the current user in [groupId].
  Future<void> acceptInvite(String groupId) async {
    final uid = _uid;
    final email = _email;
    if (uid == null || email == null) {
      throw const FamilyGroupRepositoryException('Not authenticated');
    }
    try {
      await _client
          .from('family_group_members')
          .update({'status': 'accepted', 'user_id': uid})
          .eq('group_id', groupId)
          .eq('email', email);
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Removes the current user from [groupId].
  Future<void> leaveGroup(String groupId) async {
    final uid = _uid;
    if (uid == null) throw const FamilyGroupRepositoryException('Not authenticated');
    try {
      await _client
          .from('family_group_members')
          .delete()
          .eq('group_id', groupId)
          .eq('user_id', uid);
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Removes a specific member row by [memberId]. Owner use only.
  Future<void> removeMember(String memberId) async {
    try {
      await _client.from('family_group_members').delete().eq('id', memberId);
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }

  /// Deletes the group entirely. Cascades to members; sets family_group_id
  /// to null on shopping_lists via ON DELETE SET NULL.
  Future<void> deleteGroup(String groupId) async {
    try {
      await _client.from('family_groups').delete().eq('id', groupId);
    } on PostgrestException catch (e) {
      throw FamilyGroupRepositoryException(e.message);
    }
  }
}
