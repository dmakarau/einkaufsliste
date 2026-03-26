import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/auth_user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/shopping_item_repository.dart';
import '../../../data/repositories/shopping_list_repository.dart';
import '../../../data/services/sync_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    required SyncService syncService,
    required ShoppingListRepository listRepository,
    required ShoppingItemRepository itemRepository,
    required CategoryRepository categoryRepository,
  }) : _authRepo = authRepository,
       _sync = syncService,
       _listRepo = listRepository,
       _itemRepo = itemRepository,
       _catRepo = categoryRepository,
       super(const AuthInitial()) {
    _authSub = _authRepo.authStateStream.listen(_onAuthStateChanged);
  }

  final AuthRepository _authRepo;
  final SyncService _sync;
  final ShoppingListRepository _listRepo;
  final ShoppingItemRepository _itemRepo;
  final CategoryRepository _catRepo;
  late final StreamSubscription<AppUser?> _authSub;

  Future<void> _onAuthStateChanged(AppUser? user) async {
    if (user != null) {
      // Sync before emitting so BlocListener reloads lists with fresh data.
      await _sync.pullAll(
        listRepo: _listRepo,
        itemRepo: _itemRepo,
        catRepo: _catRepo,
      );
      emit(AuthAuthenticated(user));
    } else {
      // Clear Hive before emitting so loadLists() sees empty boxes.
      await _listRepo.clearAll();
      await _itemRepo.clearAll();
      await _catRepo.clearAll();
      emit(const AuthUnauthenticated());
    }
  }

  void checkAuthStatus() {
    final user = _authRepo.currentUser;
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      await _authRepo.signIn(email: email, password: password);
      // _onAuthStateChanged handles state update + sync via stream
    } catch (e) {
      emit(AuthError(_extractMessage(e)));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    emit(const AuthLoading());
    try {
      await _authRepo.signUp(email: email, password: password);
      // _onAuthStateChanged handles state update + sync via stream
    } catch (e) {
      emit(AuthError(_extractMessage(e)));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      await _authRepo.signOut();
      // Hive is cleared in _onAuthStateChanged when the stream fires with null user.
    } catch (e) {
      emit(AuthError(_extractMessage(e)));
    }
  }

  String _extractMessage(Object e) {
    if (e is AuthRepositoryException) return e.message;
    return e.toString();
  }

  @override
  Future<void> close() {
    _authSub.cancel();
    return super.close();
  }
}
