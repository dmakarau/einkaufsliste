part of 'family_cubit.dart';

sealed class FamilyState extends Equatable {
  const FamilyState();
}

final class FamilyLoading extends FamilyState {
  const FamilyLoading();

  @override
  List<Object?> get props => [];
}

final class FamilyNoGroup extends FamilyState {
  const FamilyNoGroup();

  @override
  List<Object?> get props => [];
}

final class FamilyHasPendingInvite extends FamilyState {
  const FamilyHasPendingInvite({
    required this.group,
    required this.inviterEmail,
  });

  final FamilyGroupModel group;
  final String inviterEmail;

  @override
  List<Object?> get props => [group, inviterEmail];
}

final class FamilyHasGroup extends FamilyState {
  const FamilyHasGroup({
    required this.group,
    required this.members,
    required this.isOwner,
  });

  final FamilyGroupModel group;
  final List<FamilyGroupMemberModel> members;
  final bool isOwner;

  @override
  List<Object?> get props => [group, members, isOwner];
}

final class FamilyError extends FamilyState {
  const FamilyError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
