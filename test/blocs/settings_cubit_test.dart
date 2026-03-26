import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shopping_list/core/constants/hive_boxes.dart';
import 'package:shopping_list/presentation/blocs/settings/settings_cubit.dart';
import 'package:shopping_list/presentation/blocs/settings/settings_state.dart';

void main() {
  late Directory tempDir;
  late SettingsCubit cubit;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_settings_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveBoxes.settings);
    cubit = SettingsCubit();
  });

  tearDown(() async {
    await cubit.close();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('initial state', () {
    test('defaults to brightness off and device locale', () {
      expect(cubit.state, const SettingsState());
      expect(cubit.state.useScreenBrightness, isFalse);
      expect(cubit.state.languageCode, isNull);
    });
  });

  group('toggleScreenBrightness', () {
    test('flips to true', () async {
      await cubit.toggleScreenBrightness();

      expect(cubit.state.useScreenBrightness, isTrue);
    });

    test('flips back to false on second toggle', () async {
      await cubit.toggleScreenBrightness();
      await cubit.toggleScreenBrightness();

      expect(cubit.state.useScreenBrightness, isFalse);
    });

    test('persists to Hive — new cubit reads saved value', () async {
      await cubit.toggleScreenBrightness();
      await cubit.close();

      final newCubit = SettingsCubit();
      expect(newCubit.state.useScreenBrightness, isTrue);
      await newCubit.close();
    });
  });

  group('setLanguage', () {
    test('sets explicit language code', () async {
      await cubit.setLanguage('de');

      expect(cubit.state.languageCode, 'de');
    });

    test('sets null to follow device locale', () async {
      await cubit.setLanguage('en');
      await cubit.setLanguage(null);

      expect(cubit.state.languageCode, isNull);
    });

    test('persists language to Hive — new cubit reads saved value', () async {
      await cubit.setLanguage('ru');
      await cubit.close();

      final newCubit = SettingsCubit();
      expect(newCubit.state.languageCode, 'ru');
      await newCubit.close();
    });

    test('null language stored as empty string, read back as null', () async {
      await cubit.setLanguage('en');
      await cubit.setLanguage(null);
      await cubit.close();

      final newCubit = SettingsCubit();
      expect(newCubit.state.languageCode, isNull);
      await newCubit.close();
    });
  });
}
