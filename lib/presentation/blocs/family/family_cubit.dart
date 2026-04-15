import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/family_group_member_model.dart';
import '../../../data/models/family_group_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/family_group_repository.dart';

part 'family_state.dart';

class FamilyCubit extends Cubit<FamilyState> {
  FamilyCubit({
    required FamilyGroupRepository familyGroupRepository,
    required AuthRepository authRepository,
  })  : _groupRepo = familyGroupRepository,
        _authRepo = authRepository,
        super(const FamilyLoading());

  final FamilyGroupRepository _groupRepo;
  final AuthRepository _authRepo;

  // ---------------------------------------------------------------------------
  // Load group status — called on sign-in and after any group mutation.
  // ---------------------------------------------------------------------------

  Future<void> loadGroupStatus() async {
    if (_authRepo.currentUser == null) return;
    emit(const FamilyLoading());
    try {
      // Check if already in a group (own or joined).
      final group = await _groupRepo.getMyGroup();
      if (group != null) {
        final members = await _groupRepo.getMembers(group.id);
        final isOwner = group.ownerId == _authRepo.currentUser!.id;
        emit(FamilyHasGroup(group: group, members: members, isOwner: isOwner));
        return;
      }

      // Check for pending invitations by email.
      final invites = await _groupRepo.getPendingInvites();
      if (invites.isNotEmpty) {
        final invite = invites.first;
        // Requires RLS on family_groups to allow pending invitees to SELECT
        // (see .claude/rules/supabase.md — run the extended RLS policy if needed).
        final pendingGroup = await _groupRepo.getGroupById(invite.groupId);
        if (pendingGroup != null) {
          emit(FamilyHasPendingInvite(group: pendingGroup));
          return;
        }
        // Group not visible via RLS yet — still show a generic pending state.
        emit(FamilyHasPendingInvite(
          group: FamilyGroupModel(
            id: invite.groupId,
            name: '—',
            ownerId: '',
            createdAt: invite.createdAt,
          ),
        ));
        return;
      }

      emit(const FamilyNoGroup());
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Create a new group.
  // ---------------------------------------------------------------------------

  Future<void> createGroup(String name) async {
    emit(const FamilyLoading());
    try {
      await _groupRepo.createGroup(name);
      await loadGroupStatus();
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Invite a member by email.
  // ---------------------------------------------------------------------------

  Future<void> inviteMember(String email) async {
    final current = state;
    if (current is! FamilyHasGroup) return;
    try {
      await _groupRepo.inviteMember(email, current.group.id);
      // Refresh member list.
      final members = await _groupRepo.getMembers(current.group.id);
      emit(FamilyHasGroup(
        group: current.group,
        members: members,
        isOwner: current.isOwner,
      ));
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Accept a pending invitation.
  // ---------------------------------------------------------------------------

  Future<void> acceptInvite(String groupId) async {
    emit(const FamilyLoading());
    try {
      await _groupRepo.acceptInvite(groupId);
      await loadGroupStatus();
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Leave the current group.
  // ---------------------------------------------------------------------------

  Future<void> leaveGroup() async {
    final current = state;
    if (current is! FamilyHasGroup) return;
    if (current.isOwner) return;
    emit(const FamilyLoading());
    try {
      await _groupRepo.leaveGroup(current.group.id);
      emit(const FamilyNoGroup());
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Delete the group entirely (owner only).
  // ---------------------------------------------------------------------------

  Future<void> deleteGroup() async {
    final current = state;
    if (current is! FamilyHasGroup || !current.isOwner) return;
    emit(const FamilyLoading());
    try {
      await _groupRepo.deleteGroup(current.group.id);
      emit(const FamilyNoGroup());
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Remove a member (owner only).
  // ---------------------------------------------------------------------------

  Future<void> removeMember(String memberId) async {
    final current = state;
    if (current is! FamilyHasGroup || !current.isOwner) return;
    try {
      await _groupRepo.removeMember(memberId);
      final members = await _groupRepo.getMembers(current.group.id);
      emit(FamilyHasGroup(
        group: current.group,
        members: members,
        isOwner: current.isOwner,
      ));
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }
}
