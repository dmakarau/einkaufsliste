import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/shopping_item_model.dart';
import '../../../data/repositories/shopping_item_repository.dart';
import '../../../data/services/sync_service.dart';
import 'shopping_item_state.dart';

class ShoppingItemCubit extends Cubit<ShoppingItemState> {
  ShoppingItemCubit({
    required ShoppingItemRepository itemRepository,
    required SyncService syncService,
  }) : _repo = itemRepository,
       _sync = syncService,
       super(const ShoppingItemLoading());

  final ShoppingItemRepository _repo;
  final SyncService _sync;
  final _uuid = const Uuid();
  String? _currentListId;
  int _version = 0;

  void clearItems() {
    _currentListId = null;
    emit(const ShoppingItemLoaded(items: [], listId: '', version: 0));
  }

  void loadItems(String listId) {
    _currentListId = listId;
    try {
      final items = _repo.getByListId(listId);
      emit(
        ShoppingItemLoaded(items: items, listId: listId, version: ++_version),
      );
    } catch (e) {
      emit(ShoppingItemError(e.toString()));
    }
  }

  Future<void> addItem({
    required String listId,
    required String name,
    double quantity = 1,
    String unit = 'Stk.',
    required String categoryId,
    String? imagePath,
  }) async {
    final item = ShoppingItemModel(
      id: _uuid.v4(),
      listId: listId,
      name: name,
      quantity: quantity,
      unit: unit,
      categoryId: categoryId,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
    await _repo.add(item);
    unawaited(
      _sync.pushItem(item).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] pushItem error: $e\n$s');
      }),
    );
    if (_currentListId == listId) loadItems(listId);
  }

  Future<void> toggleChecked(String id) async {
    final state = this.state;
    if (state is! ShoppingItemLoaded) return;
    final item = state.items.firstWhere((i) => i.id == id);
    item.isChecked = !item.isChecked;
    await _repo.update(item);
    unawaited(
      _sync.pushItem(item).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] pushItem error: $e\n$s');
      }),
    );
    loadItems(state.listId);
  }

  Future<void> deleteItem(String id) async {
    final state = this.state;
    if (state is! ShoppingItemLoaded) return;
    await _repo.delete(id);
    unawaited(
      _sync.deleteItem(id).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] deleteItem error: $e\n$s');
      }),
    );
    loadItems(state.listId);
  }

  Future<void> updateItem(ShoppingItemModel item) async {
    await _repo.update(item);
    unawaited(
      _sync.pushItem(item).catchError((Object e, StackTrace s) {
        debugPrint('[SyncService] pushItem error: $e\n$s');
      }),
    );
    if (_currentListId != null) loadItems(_currentListId!);
  }
}
