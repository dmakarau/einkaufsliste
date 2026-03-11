import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/hive_boxes.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _load();
  }

  Box get _box => Hive.box(HiveBoxes.settings);

  void _load() {
    final brightness = _box.get('useScreenBrightness', defaultValue: false) as bool;
    final langCode = _box.get('languageCode', defaultValue: '') as String;
    emit(SettingsState(
      useScreenBrightness: brightness,
      languageCode: langCode.isEmpty ? null : langCode,
    ));
  }

  Future<void> toggleScreenBrightness() async {
    final newValue = !state.useScreenBrightness;
    await _box.put('useScreenBrightness', newValue);
    emit(state.copyWith(useScreenBrightness: newValue));
  }

  /// Pass null to follow device locale; pass 'de', 'en', or 'ru' to override.
  Future<void> setLanguage(String? code) async {
    await _box.put('languageCode', code ?? '');
    emit(state.copyWith(languageCode: code));
  }
}
