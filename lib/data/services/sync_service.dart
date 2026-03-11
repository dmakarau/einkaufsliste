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
}
