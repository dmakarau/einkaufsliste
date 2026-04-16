import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/shopping_item_repository.dart';
import '../repositories/shopping_list_repository.dart';
import 'sync_service.dart';

class SupabaseSyncService implements SyncService {
  SupabaseSyncService(this._client);

  final SupabaseClient _client;
  RealtimeChannel? _groupChannel;

  String? get _uid => _client.auth.currentUser?.id;

  @override
  bool get isAuthenticated => _uid != null;

  // ---------------------------------------------------------------------------
  // Pull-all: called on sign-in.
  // Supabase is the source of truth — local offline data is discarded.
  // RLS handles access control: returns own lists + group-shared lists.
  // ---------------------------------------------------------------------------
  @override
  Future<void> pullAll({
    required ShoppingListRepository listRepo,
    required ShoppingItemRepository itemRepo,
    required CategoryRepository catRepo,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    // Lists and items: no owner_id filter — RLS returns own + group-accessible rows.
    final listsData = await _client.from('shopping_lists').select();
    final itemsData = await _client.from('shopping_items').select();
    // Categories are not shared; keep owner filter.
    final catsData = await _client
        .from('categories')
        .select()
        .eq('owner_id', uid);

    // Parse all rows into models BEFORE touching Hive.
    // If any row is malformed this throws here and nothing is cleared.
    final newLists = listsData.map(_listFromRow).toList();
    final newItems = itemsData.map(_itemFromRow).toList();
    final newCats = catsData.map(_catFromRow).toList();

    await listRepo.clearAll();
    for (final m in newLists) {
      await listRepo.add(m);
    }

    await itemRepo.clearAll();
    for (final m in newItems) {
      await itemRepo.add(m);
    }

    // Only replace local categories if Supabase actually has some.
    // If Supabase returns 0 (fresh account), keep the locally seeded defaults
    // so the category picker is never empty.
    if (newCats.isNotEmpty) {
      await catRepo.clearAll();
      for (final m in newCats) {
        await catRepo.add(m);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Individual push methods — called fire-and-forget after each local mutation.
  // ---------------------------------------------------------------------------

  @override
  Future<void> pushList(ShoppingListModel list) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('shopping_lists').upsert({
      'id': list.id,
      'owner_id': uid,
      'family_group_id': list.familyGroupId,
      'name': list.name,
      'is_default': list.isDefault,
      'created_at': list.createdAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteList(String id) async {
    if (!isAuthenticated) return;
    await _client.from('shopping_lists').delete().eq('id', id);
    // Items are cascade-deleted by the FK constraint in Supabase.
  }

  @override
  Future<void> pushItem(ShoppingItemModel item) async {
    final uid = _uid;
    if (uid == null) return;

    String? imageUrl = item.imagePath;
    if (imageUrl != null && !imageUrl.startsWith('http')) {
      final file = File(imageUrl);
      if (await file.exists()) {
        final storagePath = '$uid/${item.id}.jpg';
        await _client.storage
            .from('shopping-item-images')
            .upload(
              storagePath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
        imageUrl = _client.storage
            .from('shopping-item-images')
            .getPublicUrl(storagePath);
      } else {
        imageUrl = null;
      }
    }

    await _client.from('shopping_items').upsert({
      'id': item.id,
      'list_id': item.listId,
      'owner_id': uid,
      'name': item.name,
      'quantity': item.quantity,
      'unit': item.unit,
      'category_id': item.categoryId,
      'is_checked': item.isChecked,
      'image_path': imageUrl,
      'created_at': item.createdAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteItem(String id) async {
    if (!isAuthenticated) return;
    await _client.from('shopping_items').delete().eq('id', id);
  }

  @override
  Future<void> pushCategory(CategoryModel cat) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('categories').upsert({
      'id': cat.id,
      'owner_id': uid,
      'name': cat.name,
      'color_value': cat.colorValue,
      'sort_order': cat.sortOrder,
      'is_default': cat.isDefault,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (!isAuthenticated) return;
    await _client.from('categories').delete().eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // Family group sharing
  // ---------------------------------------------------------------------------

  @override
  Future<void> shareList(String listId, String groupId) async {
    if (!isAuthenticated) return;
    await _client
        .from('shopping_lists')
        .update({'family_group_id': groupId})
        .eq('id', listId);
  }

  @override
  Future<void> unshareList(String listId) async {
    if (!isAuthenticated) return;
    await _client
        .from('shopping_lists')
        .update({'family_group_id': null})
        .eq('id', listId);
  }

  // ---------------------------------------------------------------------------
  // Realtime subscription for group changes
  // ---------------------------------------------------------------------------

  @override
  void subscribeToGroupChanges(String groupId, VoidCallback onChanged) {
    unsubscribeGroupChanges();
    _groupChannel = _client
        .channel('group_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shopping_lists',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'family_group_id',
            value: groupId,
          ),
          callback: (_) => onChanged(),
        )
        // shopping_items has no family_group_id column so no column filter is
        // possible here. Any item change triggers onChanged(); RLS limits what
        // pullAll() actually fetches.
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'shopping_items',
          callback: (_) => onChanged(),
        )
        .subscribe();
  }

  @override
  void unsubscribeGroupChanges() {
    if (_groupChannel != null) {
      _client.removeChannel(_groupChannel!);
      _groupChannel = null;
    }
  }

  // ---------------------------------------------------------------------------
  // JSON → model helpers
  // ---------------------------------------------------------------------------

  ShoppingListModel _listFromRow(Map<String, dynamic> row) {
    return ShoppingListModel(
      id: row['id'] as String,
      name: row['name'] as String,
      isDefault: row['is_default'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
      familyGroupId: row['family_group_id'] as String?,
    );
  }

  ShoppingItemModel _itemFromRow(Map<String, dynamic> row) {
    return ShoppingItemModel(
      id: row['id'] as String,
      listId: row['list_id'] as String,
      name: row['name'] as String,
      quantity: (row['quantity'] as num).toDouble(),
      unit: row['unit'] as String,
      categoryId: row['category_id'] as String,
      isChecked: row['is_checked'] as bool,
      imagePath: row['image_path'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  CategoryModel _catFromRow(Map<String, dynamic> row) {
    return CategoryModel(
      id: row['id'] as String,
      name: row['name'] as String,
      colorValue: (row['color_value'] as num).toInt(),
      sortOrder: row['sort_order'] as int,
      isDefault: row['is_default'] as bool,
    );
  }
}
