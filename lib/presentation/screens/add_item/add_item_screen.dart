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
  File? _pickedImageFile;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final categories = context.read<CategoryRepository>().getAll();
    if (categories.isNotEmpty) {
      _selectedCategoryId = categories.first.id;
    }
  }

  @override
  void dispose() {
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
    final categories = context.read<CategoryRepository>().getAll();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          // Expanded options
          if (_showMore) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.produktbild,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
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
                  const SizedBox(height: 16),
                  Text(context.l10n.einheit,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
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
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(context.l10n.kategorie,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(cat.colorValue),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(context.l10n.localizeCategory(cat.name)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_nameController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Text(
                context.l10n.produkttitelHinweis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }
}
