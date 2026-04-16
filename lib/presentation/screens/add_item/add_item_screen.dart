import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/app_localizations_extensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';
import '../../blocs/shopping_item/shopping_item_cubit.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, required this.listId});

  final String listId;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  String _selectedUnit = 'Stk.';
  String? _selectedCategoryId;
  bool _showMore = false;
  bool _categoryPickerOpen = false;
  File? _pickedImageFile;
  bool _isPickingImage = false;

  List<CategoryModel> _categories = [];
  StreamSubscription<void>? _catSubscription;
  final _categoryRepo = CategoryRepository();

  @override
  void initState() {
    super.initState();
    _reloadCategories();
    // Watch the Hive box so chips appear if seeding completes after the sheet opens.
    _catSubscription = _categoryRepo.watch().listen((_) => _reloadCategories());
  }

  void _reloadCategories() {
    final cats = _categoryRepo.getAll();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (_selectedCategoryId == null && cats.isNotEmpty) {
        _selectedCategoryId = cats.first.id;
      }
    });
  }

  @override
  void dispose() {
    _catSubscription?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;
      final docsDir = await getApplicationDocumentsDirectory();
      final destPath = p.join(
        docsDir.path,
        'item_images',
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await Directory(p.dirname(destPath)).create(recursive: true);
      final saved = await File(picked.path).copy(destPath);
      setState(() => _pickedImageFile = saved);
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.bildAusGalerie),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.l10n.fotoAufnehmen),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final selected = _categories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _categoryPickerOpen = !_categoryPickerOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(4),
                topRight: const Radius.circular(4),
                bottomLeft: Radius.circular(_categoryPickerOpen ? 0 : 4),
                bottomRight: Radius.circular(_categoryPickerOpen ? 0 : 4),
              ),
            ),
            child: Row(
              children: [
                if (selected != null) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(selected.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(context.l10n.localizeCategory(selected.name)),
                  ),
                ] else
                  const Expanded(child: Text('')),
                Icon(
                  _categoryPickerOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_categoryPickerOpen)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: NotificationListener<ScrollNotification>(
              onNotification: (_) => true,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final cat in _categories)
                      ListTile(
                        dense: true,
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(cat.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          context.l10n.localizeCategory(cat.name),
                          style: TextStyle(
                            fontWeight: cat.id == _selectedCategoryId
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: cat.id == _selectedCategoryId
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () => setState(() {
                          _selectedCategoryId = cat.id;
                          _categoryPickerOpen = false;
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedCategoryId == null) return;
    final qty = double.tryParse(_quantityController.text) ?? 1;
    await context.read<ShoppingItemCubit>().addItem(
      listId: widget.listId,
      name: name,
      quantity: qty,
      unit: _selectedUnit,
      categoryId: _selectedCategoryId!,
      imagePath: _pickedImageFile?.path,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    context.l10n.jetztSpeichern,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          // Name + quantity row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: context.l10n.produkttitelHinweis,
                      border: const UnderlineInputBorder(),
                      enabledBorder: const UnderlineInputBorder(),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _save(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':', style: TextStyle(fontSize: 20)),
                ),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _showMore = !_showMore),
                  child: Text(
                    context.l10n.mehrOptionen,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          // Category — always visible
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.kategorie,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                if (_categories.isEmpty)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _buildCategoryDropdown(),
              ],
            ),
          ),
          // Expanded options (unit + image)
          if (_showMore) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.einheit,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AppStrings.units.map((unit) {
                      final selected = unit == _selectedUnit;
                      return ChoiceChip(
                        label: Text(context.l10n.localizeUnit(unit)),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedUnit = unit),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.produktbild,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.catAndere.withValues(alpha: 0.15),
                        border: Border.all(color: AppColors.checkboxBorder),
                      ),
                      child: _isPickingImage
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _pickedImageFile != null
                          ? ClipOval(
                              child: Image.file(
                                _pickedImageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.textSecondary,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_nameController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              child: Text(
                context.l10n.produkttitelHinweis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
