import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  final String currencyCode;

  AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ru'),
    this.currencyCode = 'USD',
  });

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale, String? currencyCode}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings());

  void toggleTheme() {
    final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = state.copyWith(themeMode: newMode);
  }

  void setLocale(Locale cx) {
    state = state.copyWith(locale: cx);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
