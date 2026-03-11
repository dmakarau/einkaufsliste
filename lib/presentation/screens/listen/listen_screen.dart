import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../data/repositories/shopping_item_repository.dart';
import '../../blocs/shopping_item/shopping_item_cubit.dart';
import '../../blocs/shopping_item/shopping_item_state.dart';
import '../../blocs/shopping_list/shopping_list_cubit.dart';
import '../../blocs/shopping_list/shopping_list_state.dart';
import '../../widgets/shopping_list_tile.dart';

class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  bool _isEditing = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ShoppingListCubit>().loadLists();
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
            : Text(context.l10n.listen),
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _stopSearch,
              )
            : IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _isSearching = true),
              ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(
              _isEditing ? context.l10n.fertig : context.l10n.bearbeiten,
              style: const TextStyle(color: AppColors.primary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddListDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<ShoppingListCubit, ShoppingListState>(
        builder: (context, state) {
          if (state is ShoppingListLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShoppingListError) {
            return Center(child: Text(state.message));
          }
          if (state is ShoppingListLoaded) {
            final lists = _searchQuery.isEmpty
                ? state.lists
                : state.lists
                    .where((l) => l.name
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();
            final itemRepo = context.read<ShoppingItemRepository>();
            // BlocBuilder on ShoppingItemCubit so item counts refresh
            // whenever an item is added, toggled, or deleted.
            return BlocBuilder<ShoppingItemCubit, ShoppingItemState>(
              builder: (context, _) => ListView.separated(
                itemCount: lists.length,
                separatorBuilder: (_, _) => const Divider(indent: 16),
                itemBuilder: (context, index) {
                  final list = lists[index];
                  final count = itemRepo.getByListId(list.id).length;
                  return ShoppingListTile(
                    list: list,
                    itemCount: count,
                    isEditing: _isEditing && !list.isDefault,
                    onTap: () => context.push('/listen/${list.id}'),
                    onDelete: () =>
                        context.read<ShoppingListCubit>().deleteList(list.id),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddListDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.neueListeHinzufuegen),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: context.l10n.listenname),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.abbrechen),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<ShoppingListCubit>().addList(name);
              }
              Navigator.of(ctx).pop();
            },
            child: Text(context.l10n.hinzufuegen),
          ),
        ],
      ),
    );
  }
}
