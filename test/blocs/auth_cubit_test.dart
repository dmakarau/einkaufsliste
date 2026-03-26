import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shopping_list/data/models/auth_user.dart';
import 'package:shopping_list/data/repositories/auth_repository.dart';
import 'package:shopping_list/presentation/blocs/auth/auth_cubit.dart';
import 'package:shopping_list/presentation/blocs/auth/auth_state.dart';

import '../helpers/fake_sync_service.dart';

/// Hand-written fake that avoids mocktail interacting with a Stream getter.
/// The cubit subscribes to authStateStream in its constructor, which conflicts
/// with mocktail's recording mode when the getter is stubbed via when().
class _FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  Exception? _signInError;
  Exception? _signUpError;
  Exception? _signOutError;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateStream => _controller.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (_signInError != null) throw _signInError!;
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    if (_signUpError != null) throw _signUpError!;
  }

  @override
  Future<void> signOut() async {
    if (_signOutError != null) throw _signOutError!;
  }

  void emitUser(AppUser? user) => _controller.add(user);
  void setCurrentUser(AppUser? user) => _currentUser = user;
  void failSignInWith(String message) =>
      _signInError = AuthRepositoryException(message);
  void failSignUpWith(String message) =>
      _signUpError = AuthRepositoryException(message);
  void failSignOutWith(String message) =>
      _signOutError = Exception(message);
  Future<void> dispose() => _controller.close();
}

/// Pumps the async event loop enough times to let _onAuthStateChanged complete.
/// The null-user path awaits 3 repo calls before emitting, so 5 iterations
/// gives a comfortable margin regardless of Dart scheduler ordering.
Future<void> _pump() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.microtask(() {});
  }
}

void main() {
  late _FakeAuthRepository authRepo;
  late MockShoppingListRepository listRepo;
  late MockShoppingItemRepository itemRepo;
  late MockCategoryRepository catRepo;
  late FakeSyncService sync;
  late AuthCubit cubit;

  setUp(() {
    authRepo = _FakeAuthRepository();
    listRepo = MockShoppingListRepository();
    itemRepo = MockShoppingItemRepository();
    catRepo = MockCategoryRepository();
    sync = FakeSyncService();
    cubit = AuthCubit(
      authRepository: authRepo,
      syncService: sync,
      listRepository: listRepo,
      itemRepository: itemRepo,
      categoryRepository: catRepo,
    );
  });

  tearDown(() async {
    await cubit.close();
    await authRepo.dispose();
  });

  group('checkAuthStatus', () {
    test('emits AuthAuthenticated when user is signed in', () {
      authRepo.setCurrentUser(const AppUser(id: 'user-1', email: 'test@test.com'));

      cubit.checkAuthStatus();

      expect(cubit.state, isA<AuthAuthenticated>());
      expect((cubit.state as AuthAuthenticated).user.id, 'user-1');
    });

    test('emits AuthUnauthenticated when no user', () {
      cubit.checkAuthStatus();

      expect(cubit.state, const AuthUnauthenticated());
    });
  });

  group('signIn', () {
    test('emits AuthLoading then AuthAuthenticated on success', () async {
      await cubit.signIn(email: 'test@test.com', password: 'pass123');
      expect(cubit.state, const AuthLoading());

      authRepo.emitUser(const AppUser(id: 'user-1', email: 'test@test.com'));
      await _pump();

      expect(cubit.state, isA<AuthAuthenticated>());
      expect(sync.pullAllCalled, 1);
    });

    test('emits AuthLoading then AuthError on failure', () async {
      authRepo.failSignInWith('Invalid credentials');

      await cubit.signIn(email: 'test@test.com', password: 'wrong');

      expect(cubit.state, const AuthError('Invalid credentials'));
    });
  });

  group('signUp', () {
    test('emits AuthLoading then AuthAuthenticated on success', () async {
      await cubit.signUp(email: 'new@test.com', password: 'pass123');
      expect(cubit.state, const AuthLoading());

      authRepo.emitUser(const AppUser(id: 'user-2', email: 'new@test.com'));
      await _pump();

      expect(cubit.state, isA<AuthAuthenticated>());
    });

    test('emits AuthLoading then AuthError on failure', () async {
      authRepo.failSignUpWith('Email already in use');

      await cubit.signUp(email: 'taken@test.com', password: 'pass123');

      expect(cubit.state, const AuthError('Email already in use'));
    });
  });

  group('signOut', () {
    test('emits AuthLoading then AuthUnauthenticated and clears repos', () async {
      when(() => listRepo.clearAll()).thenAnswer((_) async {});
      when(() => itemRepo.clearAll()).thenAnswer((_) async {});
      when(() => catRepo.clearAll()).thenAnswer((_) async {});

      await cubit.signOut();
      expect(cubit.state, const AuthLoading());

      authRepo.emitUser(null);
      await _pump();

      expect(cubit.state, const AuthUnauthenticated());
      verify(() => listRepo.clearAll()).called(1);
      verify(() => itemRepo.clearAll()).called(1);
      verify(() => catRepo.clearAll()).called(1);
    });

    test('emits AuthError on signOut failure', () async {
      authRepo.failSignOutWith('Network error');

      await cubit.signOut();

      expect(cubit.state, isA<AuthError>());
    });
  });

  group('auth state stream', () {
    test('calls pullAll and emits AuthAuthenticated when user arrives', () async {
      authRepo.emitUser(const AppUser(id: 'user-1', email: 'test@test.com'));
      await _pump();

      expect(cubit.state, isA<AuthAuthenticated>());
      expect(sync.pullAllCalled, 1);
    });

    test('clears repos and emits AuthUnauthenticated when user leaves', () async {
      when(() => listRepo.clearAll()).thenAnswer((_) async {});
      when(() => itemRepo.clearAll()).thenAnswer((_) async {});
      when(() => catRepo.clearAll()).thenAnswer((_) async {});

      authRepo.emitUser(null);
      await _pump();

      expect(cubit.state, const AuthUnauthenticated());
      verify(() => listRepo.clearAll()).called(1);
      verify(() => itemRepo.clearAll()).called(1);
      verify(() => catRepo.clearAll()).called(1);
    });
  });
}
