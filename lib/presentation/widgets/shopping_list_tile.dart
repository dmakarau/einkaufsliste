import 'package:flutter/material.dart';
import '../../data/models/shopping_list_model.dart';
import '../../core/constants/app_colors.dart';

class ShoppingListTile extends StatelessWidget {
  const ShoppingListTile({
    super.key,
    required this.list,
    required this.itemCount,
    required this.onTap,
    this.onDelete,
    this.isEditing = false,
  });

  final ShoppingListModel list;
  final int itemCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: list.isDefault
          ? const Icon(Icons.star_border, color: AppColors.textSecondary)
          : isEditing
          ? GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.remove_circle, color: Colors.red),
            )
          : null,
      title: Text(list.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEditing)
            Text(
              '$itemCount',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
