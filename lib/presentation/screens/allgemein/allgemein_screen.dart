import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/shopping_list_repository.dart';
import '../../blocs/shopping_item/shopping_item_cubit.dart';
import '../../blocs/shopping_item/shopping_item_state.dart';
import '../../blocs/shopping_list/shopping_list_cubit.dart';
import '../../blocs/shopping_list/shopping_list_state.dart';
import '../add_item/add_item_screen.dart';
import '../../widgets/shopping_item_tile.dart';

class AllgemeinScreen extends StatefulWidget {
  const AllgemeinScreen({super.key});

  @override
  State<AllgemeinScreen> createState() => _AllgemeinScreenState();
}

class _AllgemeinScreenState extends State<AllgemeinScreen> {
  String? _defaultListId;
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefault();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _loadDefault() {
    final list = context.read<ShoppingListRepository>().getDefault();
    if (list != null) {
      _defaultListId = list.id;
      context.read<ShoppingItemCubit>().loadItems(list.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n.searchHint,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(context.l10n.allgemeineListe),
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _stopSearch,
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                ),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddItem(context),
          ),
        ],
      ),
      body: BlocListener<ShoppingListCubit, ShoppingListState>(
        listener: (context, state) {
          if (state is ShoppingListLoaded) {
            final def = state.lists.where((l) => l.isDefault).firstOrNull;
            if (def != null && def.id != _defaultListId) {
              _defaultListId = def.id;
              context.read<ShoppingItemCubit>().loadItems(def.id);
            }
          }
        },
        child: BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
          builder: (context, state) {
            if (state is ShoppingItemLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ShoppingItemError) {
              return Center(child: Text(state.message));
            }
            if (state is ShoppingItemLoaded) {
              final items = _searchQuery.isEmpty
                  ? state.items
                  : state.items
                        .where(
                          (i) => i.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    context.l10n.noItems,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              final categoryRepo = context.read<CategoryRepository>();
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(indent: 72),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final category = categoryRepo.getById(item.categoryId);
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (_) =>
                        context.read<ShoppingItemCubit>().deleteItem(item.id),
                    child: ShoppingItemTile(
                      item: item,
                      category: category,
                      onToggle: () => context
                          .read<ShoppingItemCubit>()
                          .toggleChecked(item.id),
                      onTap: () {},
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showAddItem(BuildContext context) {
    if (_defaultListId == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddItemScreen(listId: _defaultListId!),
    );
  }
}
