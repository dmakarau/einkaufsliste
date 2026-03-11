import 'package:equatable/equatable.dart';

final class SettingsState extends Equatable {
  final bool useScreenBrightness;

  /// null = follow device locale; 'de', 'en', 'ru' = explicit override
  final String? languageCode;

  const SettingsState({
    this.useScreenBrightness = false,
    this.languageCode,
  });

  SettingsState copyWith({
    bool? useScreenBrightness,
    Object? languageCode = _sentinel,
  }) {
    return SettingsState(
      useScreenBrightness: useScreenBrightness ?? this.useScreenBrightness,
      languageCode: languageCode == _sentinel
          ? this.languageCode
          : languageCode as String?,
    );
  }

  @override
  List<Object?> get props => [useScreenBrightness, languageCode];
}

// Sentinel to distinguish "not passed" from explicit null in copyWith
const Object _sentinel = Object();
