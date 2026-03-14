import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/shopping_item_repository.dart';
import '../repositories/shopping_list_repository.dart';
import 'sync_service.dart';

class SupabaseSyncService implements SyncService {
  const SupabaseSyncService(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  @override
  bool get isAuthenticated => _uid != null;

  // ---------------------------------------------------------------------------
  // Pull-all: called on sign-in.
  // Supabase is the source of truth — local offline data is discarded.
  // Fetch all user data from Supabase and replace Hive contents.
  // ---------------------------------------------------------------------------
  @override
  Future<void> pullAll({
    required ShoppingListRepository listRepo,
    required ShoppingItemRepository itemRepo,
    required CategoryRepository catRepo,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    // Fetch from Supabase
    final listsData = await _client
        .from('shopping_lists')
        .select()
        .eq('owner_id', uid) as List<dynamic>;

    final itemsData = await _client
        .from('shopping_items')
        .select()
        .eq('owner_id', uid) as List<dynamic>;

    final catsData = await _client
        .from('categories')
        .select()
        .eq('owner_id', uid) as List<dynamic>;

    // 3. Replace Hive contents
    await listRepo.clearAll();
    for (final row in listsData) {
      await listRepo.add(_listFromRow(row as Map<String, dynamic>));
    }

    await itemRepo.clearAll();
    for (final row in itemsData) {
      await itemRepo.add(_itemFromRow(row as Map<String, dynamic>));
    }

    await catRepo.clearAll();
    for (final row in catsData) {
      await catRepo.add(_catFromRow(row as Map<String, dynamic>));
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
            .upload(storagePath, file, fileOptions: const FileOptions(upsert: true));
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
  // JSON → model helpers
  // ---------------------------------------------------------------------------

  ShoppingListModel _listFromRow(Map<String, dynamic> row) {
    return ShoppingListModel(
      id: row['id'] as String,
      name: row['name'] as String,
      isDefault: row['is_default'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
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
