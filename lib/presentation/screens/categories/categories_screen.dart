import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/app_localizations_extensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../data/repositories/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final categories = context.read<CategoryRepository>().getAll();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.kategorienTitle),
        backgroundColor: AppColors.background,
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
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: categories.length,
        separatorBuilder: (_, _) => const Divider(indent: 16, height: 0),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final color = Color(cat.colorValue);
          return Container(
            color: AppColors.surface,
            child: ListTile(
              leading: Container(
                width: 6,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              title: Text(context.l10n.localizeCategory(cat.name)),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
