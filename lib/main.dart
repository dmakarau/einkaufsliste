import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:uuid/uuid.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/hive_boxes.dart';
import 'core/constants/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/models/category_model.dart';
import 'data/models/shopping_item_model.dart';
import 'data/models/shopping_list_model.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/family_group_repository.dart';
import 'data/repositories/shopping_item_repository.dart';
import 'data/repositories/shopping_list_repository.dart';
import 'data/services/supabase_sync_service.dart';
import 'l10n/app_localizations.dart';
import 'presentation/blocs/auth/auth_cubit.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/family/family_cubit.dart';
import 'presentation/blocs/settings/settings_cubit.dart';
import 'presentation/blocs/settings/settings_state.dart';
import 'presentation/blocs/shopping_item/shopping_item_cubit.dart';
import 'presentation/blocs/shopping_list/shopping_list_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await AuthRepository.initialize();

  await Hive.initFlutter();
  Hive.registerAdapter(ShoppingListModelAdapter());
  Hive.registerAdapter(ShoppingItemModelAdapter());
  Hive.registerAdapter(CategoryModelAdapter());

  await Hive.openBox<ShoppingListModel>(HiveBoxes.shoppingLists);
  await Hive.openBox<ShoppingItemModel>(HiveBoxes.shoppingItems);
  await Hive.openBox<CategoryModel>(HiveBoxes.categories);
  await Hive.openBox(HiveBoxes.settings);

  await _seedDefaultData();

  runApp(const EinkaufslisteApp());
}

Future<void> _seedDefaultData() async {
  const uuid = Uuid();

  final listRepo = ShoppingListRepository();
  if (listRepo.isEmpty()) {
    await listRepo.add(
      ShoppingListModel(
        id: uuid.v4(),
        name: AppStrings.allgemeineListe,
        isDefault: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  final catRepo = CategoryRepository();
  if (catRepo.isEmpty()) {
    final categories = [
      (AppStrings.catObstGemuese, AppColors.catObstGemuese),
      (AppStrings.catFleisch, AppColors.catFleisch),
      (AppStrings.catFischMeeresfruchte, AppColors.catFischMeeresfruchte),
      (AppStrings.catMilchEier, AppColors.catMilchEier),
      (AppStrings.catTiefkuehlkost, AppColors.catTiefkuehlkost),
      (AppStrings.catMuesli, AppColors.catMuesli),
      (AppStrings.catBaeckereien, AppColors.catBaeckereien),
      (AppStrings.catAndere, AppColors.catAndere),
      (AppStrings.catGetraenke, AppColors.catGetraenke),
      (AppStrings.catKonserven, AppColors.catKonserven),
      (AppStrings.catSaucen, AppColors.catSaucen),
      (AppStrings.catSnacks, AppColors.catSnacks),
      (AppStrings.catOel, AppColors.catOel),
    ];

    for (var (index, (name, color)) in categories.indexed) {
      await catRepo.add(
        CategoryModel(
          id: uuid.v4(),
          name: name,
          colorValue: color.toARGB32(),
          sortOrder: index,
          isDefault: true,
        ),
      );
    }
  }
}

class EinkaufslisteApp extends StatelessWidget {
  const EinkaufslisteApp({super.key});

  @override
  Widget build(BuildContext context) {
    final listRepo = ShoppingListRepository();
    final itemRepo = ShoppingItemRepository();
    final catRepo = CategoryRepository();
    final client = Supabase.instance.client;
    final authRepo = AuthRepository(client);
    final syncService = SupabaseSyncService(client);
    final familyGroupRepo = FamilyGroupRepository(client);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: listRepo),
        RepositoryProvider.value(value: itemRepo),
        RepositoryProvider.value(value: catRepo),
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: syncService),
        RepositoryProvider.value(value: familyGroupRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(
              authRepository: authRepo,
              syncService: syncService,
              listRepository: listRepo,
              itemRepository: itemRepo,
              categoryRepository: catRepo,
            )..checkAuthStatus(),
          ),
          BlocProvider(
            create: (_) => FamilyCubit(
              familyGroupRepository: familyGroupRepo,
              authRepository: authRepo,
            ),
          ),
          BlocProvider(
            create: (_) => ShoppingListCubit(
              listRepository: listRepo,
              itemRepository: itemRepo,
              categoryRepository: catRepo,
              syncService: syncService,
            )..loadLists(),
          ),
          BlocProvider(
            create: (_) => ShoppingItemCubit(
              itemRepository: itemRepo,
              syncService: syncService,
            ),
          ),
          BlocProvider(create: (_) => SettingsCubit()),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) => _AppContent(settings: settings),
        ),
      ),
    );
  }
}

class _AppContent extends StatefulWidget {
  const _AppContent({required this.settings});

  final SettingsState settings;

  @override
  State<_AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<_AppContent> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ShoppingListCubit>().syncFromRemote();
      // Guard: don't call loadGroupStatus during the OAuth redirect window
      // (resumed fires before the session is established, causing a stale-JWT
      // query that throws FamilyGroupRepositoryException → FamilyError).
      if (context.read<AuthCubit>().state is AuthAuthenticated) {
        context.read<FamilyCubit>().loadGroupStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          // React to genuine auth transitions (type changes) and to the
          // Google cold-start case where TOKEN_REFRESHED fires after
          // checkAuthStatus already emitted AuthAuthenticated(isSynced:false):
          // pullAll() completes and emits AuthAuthenticated(isSynced:true),
          // which has the same runtimeType but different props — so we must
          // also check the isSynced transition to call loadLists() with
          // fresh Hive data.
          listenWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType ||
              (previous is AuthAuthenticated &&
                  !previous.isSynced &&
                  current is AuthAuthenticated &&
                  current.isSynced),
          listener: (context, state) async {
            final listCubit = context.read<ShoppingListCubit>();
            final itemCubit = context.read<ShoppingItemCubit>();
            final familyCubit = context.read<FamilyCubit>();
            if (state is AuthUnauthenticated) {
              // Restore default local data so the app works offline.
              await _seedDefaultData();
              listCubit.stopWatching();
            }
            if (state is AuthAuthenticated) {
              // pullAll() may have cleared categories if Supabase had none
              // (e.g. fresh install — seeded defaults were never pushed up).
              // Re-seed only if the box is empty; safe to call anytime.
              await _seedDefaultData();
              familyCubit.loadGroupStatus();
            }
            if (state is AuthAuthenticated || state is AuthUnauthenticated) {
              listCubit.loadLists();
              itemCubit.clearItems();
            }
          },
        ),
        BlocListener<FamilyCubit, FamilyState>(
          // Only wire up watchGroup on the first transition into FamilyHasGroup.
          // Repeated FamilyHasGroup emissions (e.g. after _refreshMembers fires)
          // must not tear down and re-subscribe the Realtime channel.
          listenWhen: (prev, curr) =>
              curr is FamilyHasGroup && prev is! FamilyHasGroup,
          listener: (context, state) {
            if (state is FamilyHasGroup) {
              context.read<ShoppingListCubit>().watchGroup(state.group.id);
            }
          },
        ),
        BlocListener<FamilyCubit, FamilyState>(
          // Sync lists on every FamilyHasGroup emission — this covers both the
          // initial group entry and _refreshMembers() calls (e.g. when a member
          // leaves, _refreshMembers emits FamilyHasGroup→FamilyHasGroup directly
          // with no FamilyLoading in between, so the watchGroup listener above
          // would not fire for it).
          // Also sync when leaving the group (FamilyNoGroup), guarded by auth
          // check to avoid a stale-JWT call during sign-out.
          listenWhen: (prev, curr) =>
              curr is FamilyHasGroup ||
              (curr is FamilyNoGroup && prev is! FamilyNoGroup),
          listener: (context, state) {
            final listCubit = context.read<ShoppingListCubit>();
            if (state is FamilyHasGroup) {
              unawaited(listCubit.syncFromRemote());
            } else if (state is FamilyNoGroup) {
              listCubit.stopWatching();
              // Guard against sign-out: FamilyNoGroup also fires when the user
              // signs out, but by then the session may already be invalid.
              if (context.read<AuthCubit>().state is AuthAuthenticated) {
                unawaited(listCubit.syncFromRemote());
              }
            }
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Einkaufsliste',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        locale: settings.languageCode != null
            ? Locale(settings.languageCode!)
            : null,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
