import 'package:flutter/foundation.dart';

import '../models/category_model.dart';
import '../models/shopping_item_model.dart';
import '../models/shopping_list_model.dart';
import '../repositories/category_repository.dart';
import '../repositories/shopping_item_repository.dart';
import '../repositories/shopping_list_repository.dart';

abstract interface class SyncService {
  bool get isAuthenticated;

  Future<void> pullAll({
    required ShoppingListRepository listRepo,
    required ShoppingItemRepository itemRepo,
    required CategoryRepository catRepo,
  });

  Future<void> pushList(ShoppingListModel list);
  Future<void> deleteList(String id);
  Future<void> pushItem(ShoppingItemModel item);
  Future<void> deleteItem(String id);
  Future<void> pushCategory(CategoryModel cat);
  Future<void> deleteCategory(String id);

  /// Updates family_group_id on a list to share it with a group.
  Future<void> shareList(String listId, String groupId);

  /// Clears family_group_id on a list to stop sharing.
  Future<void> unshareList(String listId);

  /// Subscribes to realtime changes on lists/items belonging to [groupId].
  void subscribeToGroupChanges(String groupId, VoidCallback onChanged);

  /// Cancels the active realtime subscription.
  void unsubscribeGroupChanges();
}
