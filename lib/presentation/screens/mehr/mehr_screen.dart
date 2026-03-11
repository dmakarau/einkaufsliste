import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/build_context_extensions.dart';

class MehrScreen extends StatelessWidget {
  const MehrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.l10n.mehr),
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            color: AppColors.surface,
            child: ListTile(
              leading: const Icon(Icons.campaign_outlined, size: 28),
              title: Text(context.l10n.appBewerten),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_outlined, size: 28),
                  title: Text(context.l10n.einstellungen),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: () => context.push('/mehr/settings'),
                ),
                const Divider(indent: 56, height: 0),
                ListTile(
                  leading: const Icon(Icons.info_outline, size: 28),
                  title: Text(context.l10n.information),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: () => context.push('/mehr/info'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
