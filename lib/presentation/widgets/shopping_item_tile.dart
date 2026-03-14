import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/app_localizations_extensions.dart';
import '../../core/extensions/build_context_extensions.dart';
import '../../data/models/category_model.dart';
import '../../data/models/shopping_item_model.dart';

class ShoppingItemTile extends StatelessWidget {
  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.category,
    required this.onToggle,
    required this.onTap,
  });

  final ShoppingItemModel item;
  final CategoryModel? category;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final categoryColor = category != null
        ? Color(category!.colorValue)
        : AppColors.catAndere;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        child: Row(
          children: [
            // Category color strip
            Container(
              width: 4,
              height: 64,
              color: categoryColor,
            ),
            // Checkbox
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: item.isChecked
                          ? AppColors.primary
                          : AppColors.checkboxBorder,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    color: item.isChecked ? AppColors.primary : Colors.transparent,
                  ),
                  child: item.isChecked
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
            // Item image circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: categoryColor.withValues(alpha: 0.15),
              ),
              child: item.imagePath != null
                  ? ClipOval(child: _itemImage(item.imagePath!, categoryColor))
                  : _CategoryIcon(color: categoryColor),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 17,
                  color: item.isChecked
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  decoration:
                      item.isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            // Quantity + unit
            Text(
              '${_formatQuantity(item.quantity)} ${context.l10n.localizeUnit(item.unit)}',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _itemImage(String path, Color fallbackColor) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
        errorWidget: (_, _, _) => _CategoryIcon(color: fallbackColor),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _CategoryIcon(color: fallbackColor),
    );
  }

  String _formatQuantity(double q) =>
      q == q.truncateToDouble() ? q.toInt().toString() : q.toString();
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.shopping_basket_outlined, color: color, size: 22);
  }
}
