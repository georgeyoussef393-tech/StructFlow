import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english,
  arabic,
  french,
  chinese,
}

class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  static const String _themeKey = 'structflow_theme_mode';
  static const String _languageKey = 'structflow_language';

  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.english;

  ThemeMode get themeMode => _themeMode;

  AppLanguage get language => _language;

  Locale get locale {
    switch (_language) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.arabic:
        return const Locale('ar');
      case AppLanguage.french:
        return const Locale('fr');
      case AppLanguage.chinese:
        return const Locale('zh');
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isArabic => _language == AppLanguage.arabic;

  String get languageName {
    switch (_language) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.arabic:
        return 'العربية';
      case AppLanguage.french:
        return 'Français';
      case AppLanguage.chinese:
        return '中文';
    }
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();

    final savedTheme = preferences.getString(_themeKey);
    final savedLanguage = preferences.getString(_languageKey);

    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }

    switch (savedLanguage) {
      case 'ar':
        _language = AppLanguage.arabic;
        break;

      case 'fr':
        _language = AppLanguage.french;
        break;

      case 'zh':
        _language = AppLanguage.chinese;
        break;

      case 'en':
      default:
        _language = AppLanguage.english;
        break;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _themeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    await setThemeMode(
      isDarkMode ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }

    _language = language;

    final preferences = await SharedPreferences.getInstance();

    String value;

    switch (language) {
      case AppLanguage.english:
        value = 'en';
        break;

      case AppLanguage.arabic:
        value = 'ar';
        break;

      case AppLanguage.french:
        value = 'fr';
        break;

      case AppLanguage.chinese:
        value = 'zh';
        break;
    }

    await preferences.setString(
      _languageKey,
      value,
    );

    notifyListeners();
  }
}