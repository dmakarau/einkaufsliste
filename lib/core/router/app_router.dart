import 'package:go_router/go_router.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/allgemein/allgemein_screen.dart';
import '../../presentation/screens/listen/listen_screen.dart';
import '../../presentation/screens/listen/list_detail_screen.dart';
import '../../presentation/screens/familie/familie_screen.dart';
import '../../presentation/screens/mehr/mehr_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/categories/categories_screen.dart';
import '../../presentation/screens/about/about_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/allgemein',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/allgemein',
              builder: (context, state) => const AllgemeinScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/listen',
              builder: (context, state) => const ListenScreen(),
              routes: [
                GoRoute(
                  path: ':listId',
                  builder: (context, state) =>
                      ListDetailScreen(listId: state.pathParameters['listId']!),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/familie',
              builder: (context, state) => const FamilieScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mehr',
              builder: (context, state) => const MehrScreen(),
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      path: 'categories',
                      builder: (context, state) => const CategoriesScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'info',
                  builder: (context, state) => const AboutScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
