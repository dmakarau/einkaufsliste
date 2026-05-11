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
  }) : _groupRepo = familyGroupRepository,
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
        _groupRepo.subscribeToMemberChanges(group.id, _refreshMembers);
        return;
      }

      // Check for pending invitations by email.
      final invites = await _groupRepo.getPendingInvites();
      _groupRepo.unsubscribeMemberChanges();
      if (invites.isNotEmpty) {
        final invite = invites.first;
        // Requires RLS on family_groups to allow pending invitees to SELECT
        // (see .claude/rules/supabase.md — run the extended RLS policy if needed).
        final pendingGroup = await _groupRepo.getGroupById(invite.groupId);
        _groupRepo.unsubscribeInvites();
        if (pendingGroup != null) {
          emit(FamilyHasPendingInvite(group: pendingGroup));
          return;
        }
        // Group not visible via RLS yet — still show a generic pending state.
        emit(
          FamilyHasPendingInvite(
            group: FamilyGroupModel(
              id: invite.groupId,
              name: '—',
              ownerId: '',
              createdAt: invite.createdAt,
            ),
          ),
        );
        return;
      }

      // No group and no pending invite — subscribe to incoming invites so the
      // UI updates immediately when the admin sends one.
      final email = _authRepo.currentUser?.email;
      if (email != null) {
        _groupRepo.subscribeToInvites(email, loadGroupStatus);
      }
      emit(const FamilyNoGroup());
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }

  Future<void> _refreshMembers() async {
    final current = state;
    if (current is! FamilyHasGroup) return;
    try {
      final members = await _groupRepo.getMembers(current.group.id);
      final uid = _authRepo.currentUser?.id;
      final email = _authRepo.currentUser?.email;
      // Only accepted rows count — pending invite rows for the same email also
      // pass RLS (email = auth.email()) and would falsely signal still-member.
      final stillMember = members.any(
        (m) => m.isAccepted && (m.userId == uid || m.email == email),
      );
      if (!stillMember) {
        // Use microtask so loadGroupStatus() runs after the current Realtime
        // callback exits — removing a channel from within its own callback can
        // cause the Supabase client to behave unexpectedly.
        Future.microtask(loadGroupStatus);
        return;
      }
      emit(
        FamilyHasGroup(
          group: current.group,
          members: members,
          isOwner: current.isOwner,
        ),
      );
    } on FamilyGroupRepositoryException {
      Future.microtask(loadGroupStatus);
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
      emit(
        FamilyHasGroup(
          group: current.group,
          members: members,
          isOwner: current.isOwner,
        ),
      );
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
      _groupRepo.unsubscribeMemberChanges();
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
      _groupRepo.unsubscribeMemberChanges();
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
      // Realtime will fire _refreshMembers() — explicit reload here ensures the
      // UI updates immediately even if the Realtime event arrives with a delay.
      final members = await _groupRepo.getMembers(current.group.id);
      emit(
        FamilyHasGroup(
          group: current.group,
          members: members,
          isOwner: current.isOwner,
        ),
      );
    } on FamilyGroupRepositoryException catch (e) {
      emit(FamilyError(e.message));
    }
  }

  @override
  Future<void> close() {
    _groupRepo.unsubscribeMemberChanges();
    _groupRepo.unsubscribeInvites();
    return super.close();
  }
}
