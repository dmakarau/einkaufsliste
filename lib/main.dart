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
          builder: (context, settings) => MultiBlocListener(
            listeners: [
              BlocListener<AuthCubit, AuthState>(
                // Only react to genuine auth transitions, not token refreshes
                // (which re-emit AuthAuthenticated without changing the state type).
                listenWhen: (previous, current) =>
                    previous.runtimeType != current.runtimeType,
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
                // Repeated FamilyHasGroup emissions (e.g. after inviteMember refreshes
                // the member list) must not tear down and re-subscribe the channel.
                listenWhen: (prev, curr) =>
                    (curr is FamilyHasGroup && prev is! FamilyHasGroup) ||
                    curr is FamilyNoGroup,
                listener: (context, state) {
                  final listCubit = context.read<ShoppingListCubit>();
                  if (state is FamilyHasGroup) {
                    listCubit.watchGroup(state.group.id);
                    listCubit.loadLists();
                  } else if (state is FamilyNoGroup) {
                    listCubit.stopWatching();
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
          ),
        ),
      ),
    );
  }
}
