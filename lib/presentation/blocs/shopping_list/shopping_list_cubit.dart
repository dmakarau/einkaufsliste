import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/shopping_list_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/shopping_item_repository.dart';
import '../../../data/repositories/shopping_list_repository.dart';
import '../../../data/services/sync_service.dart';
import 'shopping_list_state.dart';

class ShoppingListCubit extends Cubit<ShoppingListState> {
  ShoppingListCubit({
    required ShoppingListRepository listRepository,
    required ShoppingItemRepository itemRepository,
    required CategoryRepository categoryRepository,
    required SyncService syncService,
  }) : _listRepo = listRepository,
       _itemRepo = itemRepository,
       _catRepo = categoryRepository,
       _sync = syncService,
       super(const ShoppingListLoading());

  final ShoppingListRepository _listRepo;
  final ShoppingItemRepository _itemRepo;
  final CategoryRepository _catRepo;
  final SyncService _sync;
  final _uuid = const Uuid();

  void loadLists() {
    try {
      final lists = _listRepo.getAll();
      emit(ShoppingListLoaded(lists));
    } catch (e) {
      emit(ShoppingListError(e.toString()));
    }
  }

  Future<void> addList(String name) async {
    final list = ShoppingListModel(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _listRepo.add(list);
    unawaited(
      _sync.pushList(list).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] pushList error: $e\n$s');
      }),
    );
    loadLists();
  }

  Future<void> renameList(String id, String newName) async {
    final list = _listRepo.getById(id);
    if (list == null) return;
    list.name = newName;
    await _listRepo.update(list);
    unawaited(
      _sync.pushList(list).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] pushList error: $e\n$s');
      }),
    );
    loadLists();
  }

  Future<void> deleteList(String id) async {
    final list = _listRepo.getById(id);
    if (list == null || list.isDefault) return;
    await _itemRepo.deleteByListId(id);
    await _listRepo.delete(id);
    unawaited(
      _sync.deleteList(id).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] deleteList error: $e\n$s');
      }),
    );
    loadLists();
  }

  // ---------------------------------------------------------------------------
  // Family group sharing
  // ---------------------------------------------------------------------------

  Future<void> shareList(String listId, String groupId) async {
    final list = _listRepo.getById(listId);
    if (list == null) return;
    final updated = list.copyWith(familyGroupId: groupId);
    await _listRepo.update(updated);
    unawaited(
      _sync.shareList(listId, groupId).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] shareList error: $e\n$s');
      }),
    );
    loadLists();
  }

  Future<void> unshareList(String listId) async {
    final list = _listRepo.getById(listId);
    if (list == null) return;
    final updated = list.copyWith(clearFamilyGroupId: true);
    await _listRepo.update(updated);
    unawaited(
      _sync.unshareList(listId).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] unshareList error: $e\n$s');
      }),
    );
    loadLists();
  }

  // ---------------------------------------------------------------------------
  // Realtime group subscription
  // ---------------------------------------------------------------------------

  void watchGroup(String groupId) {
    _sync.subscribeToGroupChanges(groupId, _onGroupChange);
  }

  Future<void> _onGroupChange() async {
    // Pull fresh data from Supabase into Hive before refreshing the UI.
    // loadLists() alone only re-reads Hive, which hasn't been updated yet.
    try {
      await _sync.pullAll(
        listRepo: _listRepo,
        itemRepo: _itemRepo,
        catRepo: _catRepo,
      );
    } catch (e, s) {
      debugPrint('[SyncService] pullAll error on group change: $e\n$s');
    }
    loadLists();
  }

  void stopWatching() {
    _sync.unsubscribeGroupChanges();
  }
}
