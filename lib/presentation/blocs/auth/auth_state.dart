import 'package:equatable/equatable.dart';

import '../../../data/models/auth_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final AppUser user;
  final bool isSynced;

  const AuthAuthenticated(this.user, {this.isSynced = false});

  @override
  List<Object?> get props => [user.id, isSynced];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
