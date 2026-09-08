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

  static const String _languageKey = 'structflow_language';

  AppLanguage _language = AppLanguage.english;

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

    final savedLanguage = preferences.getString(_languageKey);

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

    await preferences.setString(_languageKey, value);

    notifyListeners();
  }
}