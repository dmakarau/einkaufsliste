import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/build_context_extensions.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.star_border),
            activeIcon: const Icon(Icons.star),
            label: context.l10n.navAllgemein,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.format_list_bulleted),
            label: context.l10n.navListen,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            label: context.l10n.navFamilie,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.more_horiz),
            label: context.l10n.navMehr,
          ),
        ],
      ),
    );
  }
}
