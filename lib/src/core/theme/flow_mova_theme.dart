import 'package:flutter/material.dart';

import 'flow_mova_colors.dart';
import 'flow_mova_radii.dart';

abstract final class FlowMovaTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: FlowMovaColors.primaryAqua,
          brightness: Brightness.light,
        ).copyWith(
          primary: FlowMovaColors.primaryAqua,
          secondary: FlowMovaColors.leafGreen,
          tertiary: FlowMovaColors.softApricot,
          error: FlowMovaColors.error,
          surface: FlowMovaColors.white,
          onSurface: FlowMovaColors.ink,
        );

    final baseTextTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
    ).textTheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: colorScheme,
      scaffoldBackgroundColor: FlowMovaColors.cloud,
      textTheme: baseTextTheme.apply(
        bodyColor: FlowMovaColors.ink,
        displayColor: FlowMovaColors.logoInk,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: FlowMovaColors.cloud,
        foregroundColor: FlowMovaColors.logoInk,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: FlowMovaColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlowMovaRadii.small),
          side: const BorderSide(color: FlowMovaColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FlowMovaColors.primaryAqua,
          foregroundColor: FlowMovaColors.white,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FlowMovaColors.ink,
          side: const BorderSide(color: Color(0xFFD8E3EA)),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FlowMovaColors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
          borderSide: const BorderSide(color: FlowMovaColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
          borderSide: const BorderSide(color: FlowMovaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
          borderSide: const BorderSide(
            color: FlowMovaColors.primaryAqua,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FlowMovaRadii.medium),
          borderSide: const BorderSide(color: FlowMovaColors.error),
        ),
      ),
    );
  }
}
