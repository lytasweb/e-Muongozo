import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontSize { small, medium, large }

extension AppFontSizeX on AppFontSize {
  double get scale {
    switch (this) {
      case AppFontSize.small:
        return 0.9;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.2;
    }
  }
}

class SettingsState {
  final ThemeMode themeMode;
  final AppFontSize fontSize;
  final bool wifiOnly;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.fontSize = AppFontSize.medium,
    this.wifiOnly = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppFontSize? fontSize,
    bool? wifiOnly,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      wifiOnly: wifiOnly ?? this.wifiOnly,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme') ?? 'system';
    final fontName = prefs.getString('fontSize') ?? 'medium';
    final wifi = prefs.getBool('wifiOnly') ?? false;

    state = SettingsState(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      fontSize: AppFontSize.values.firstWhere(
        (f) => f.name == fontName,
        orElse: () => AppFontSize.medium,
      ),
      wifiOnly: wifi,
    );
  }

  Future<void> setTheme(ThemeMode m) async {
    state = state.copyWith(themeMode: m);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', m.name);
  }

  Future<void> setFontSize(AppFontSize f) async {
    state = state.copyWith(fontSize: f);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontSize', f.name);
  }

  Future<void> setWifiOnly(bool v) async {
    state = state.copyWith(wifiOnly: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wifiOnly', v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);