import 'package:flutter/material.dart';

/// Ported from src/index.css `@theme` tokens (web app is a black/grey/white palette).
class AppColors {
  AppColors._();

  static const grayBg = Color(0xFFF8F9FA);
  static const grayBorder = Color(0xFFE5E7EB);
  static const gray100 = Color(0xFFF1F5F9);

  static const text900 = Color(0xFF111827);
  static const text600 = Color(0xFF4B5563);
  static const text400 = Color(0xFF9CA3AF);

  static const primary600 = Color(0xFF111827);
  static const primary700 = Color(0xFF000000);

  static const white = Color(0xFFFFFFFF);

  static const shadowCard = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const shadowFloat = [
    BoxShadow(color: Color(0x1A101828), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.grayBg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary600,
    primary: AppColors.primary600,
    surface: AppColors.white,
  ),
  // Pretendard isn't bundled (no font asset in the repo); Flutter web falls
  // back to the platform's default sans-serif, which renders Korean fine.
  textTheme: const TextTheme().apply(
    bodyColor: AppColors.text900,
    displayColor: AppColors.text900,
  ),
  dividerColor: AppColors.grayBorder,
  inputDecorationTheme: InputDecorationTheme(
    filled: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grayBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grayBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.grayBorder),
    ),
  ),
);
