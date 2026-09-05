import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.light,

      primaryColor: AppColors.primary,

      scaffoldBackgroundColor:
          AppColors.background,

      colorScheme:
          ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),

      appBarTheme:
          const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              Colors.white,
        ),
      ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,
        fillColor:
            const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
            width: 1.5,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),

      dividerTheme:
          const DividerThemeData(
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      brightness: Brightness.dark,

      primaryColor:
          AppColors.primary,

      scaffoldBackgroundColor:
          const Color(0xFF0F172A),

      colorScheme:
          ColorScheme.fromSeed(
        seedColor:
            AppColors.primary,
        brightness:
            Brightness.dark,
      ),

      appBarTheme:
          const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            Color(0xFF111827),
        foregroundColor:
            Colors.white,
      ),

      elevatedButtonTheme:
          ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.primary,
          foregroundColor:
              Colors.white,
        ),
      ),

      inputDecorationTheme:
          InputDecorationTheme(
        filled: true,
        fillColor:
            const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              BorderSide.none,
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),
          borderSide:
              const BorderSide(
            color:
                AppColors.secondary,
            width: 1.5,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color:
            const Color(0xFF1E293B),
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(16),
        ),
      ),

      dividerTheme:
          DividerThemeData(
        color:
            Colors.white.withValues(
          alpha: 0.10,
        ),
        space: 1,
      ),
    );
  }
}