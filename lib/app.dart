import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:structflow/config/app_theme.dart';
import 'package:structflow/core/localization/app_localizations.dart';
import 'package:structflow/core/routing/app_router.dart';
import 'package:structflow/core/settings/app_settings.dart';

class StructFlowApp extends StatefulWidget {
  const StructFlowApp({super.key});

  @override
  State<StructFlowApp> createState() => _StructFlowAppState();
}

class _StructFlowAppState extends State<StructFlowApp> {
  final AppSettings _settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();

    _settings.addListener(_settingsChanged);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.load();
  }

  void _settingsChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _settings.removeListener(_settingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      title: 'StructFlow',

      // Theme ثابت مؤقتًا على Light.
      // مفيش Dark Theme ولا ThemeMode دلوقتي.
      theme: AppTheme.lightTheme,

      // اللغة الحالية.
      locale: _settings.locale,

      // اللغات المدعومة.
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
        Locale('zh'),
      ],

      // Flutter built-in localization.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      routerConfig: appRouter,
    );
  }
}