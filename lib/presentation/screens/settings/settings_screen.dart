import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../blocs/settings/settings_cubit.dart';
import '../../blocs/settings/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.einstellungenTitle),
        backgroundColor: AppColors.background,
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => Column(
          children: [
            const SizedBox(height: 8),
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.format_list_bulleted, size: 28),
                    title: Text(context.l10n.listsTile),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => context.push('/listen'),
                  ),
                  const Divider(indent: 56, height: 0),
                  ListTile(
                    leading: const Icon(Icons.folder_outlined, size: 28),
                    title: Text(context.l10n.kategorienTitle),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => context.push('/mehr/settings/categories'),
                  ),
                  const Divider(indent: 56, height: 0),
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined, size: 28),
                    title: Text(context.l10n.woerterbuch),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () {},
                  ),
                  const Divider(indent: 56, height: 0),
                  ListTile(
                    leading: const Icon(Icons.language, size: 28),
                    title: Text(context.l10n.language),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _languageLabel(context, state.languageCode),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                    onTap: () =>
                        _showLanguagePicker(context, state.languageCode),
                  ),
                  const Divider(indent: 56, height: 0),
                  SwitchListTile(
                    secondary: const Icon(
                      Icons.brightness_6_outlined,
                      size: 28,
                    ),
                    title: Text(context.l10n.bildschirmhelligkeit),
                    value: state.useScreenBrightness,
                    activeThumbColor: AppColors.primary,
                    onChanged: (_) =>
                        context.read<SettingsCubit>().toggleScreenBrightness(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _languageLabel(BuildContext context, String? code) {
    switch (code) {
      case 'de':
        return context.l10n.languageDe;
      case 'en':
        return context.l10n.languageEn;
      case 'ru':
        return context.l10n.languageRu;
      default:
        return context.l10n.languageSystem;
    }
  }

  void _showLanguagePicker(BuildContext context, String? current) {
    final options = [
      (null, '🌐', context.l10n.languageSystem),
      ('de', '🇩🇪', context.l10n.languageDe),
      ('en', '🇬🇧', context.l10n.languageEn),
      ('ru', '🇷🇺', context.l10n.languageRu),
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(context.l10n.language),
        children: options.map(((String?, String, String) opt) {
          final (code, flag, label) = opt;
          return SimpleDialogOption(
            onPressed: () {
              context.read<SettingsCubit>().setLanguage(code);
              Navigator.of(ctx).pop();
            },
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Text(label, style: const TextStyle(fontSize: 16)),
                const Spacer(),
                if (current == code)
                  const Icon(Icons.check, color: AppColors.primary, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
