import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/extensions/build_context_extensions.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(context.l10n.ueberProgramm),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.appName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300),
            ),
            const SizedBox(height: 24),
            const Text(
              AppStrings.appVersion,
              style: TextStyle(fontSize: 17, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
