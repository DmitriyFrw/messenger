import 'package:flutter/material.dart';

import 'dialog_colors.dart';

abstract final class DialogTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: DialogColors.sageDark,
      onPrimary: DialogColors.textPrimary,
      secondary: DialogColors.sage,
      onSecondary: DialogColors.textPrimary,
      surface: DialogColors.surface,
      onSurface: DialogColors.textPrimary,
      error: Color(0xFFB85C5C),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: DialogColors.background,
      fontFamily: 'SF Pro Display',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: DialogColors.textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: DialogColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DialogColors.textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: DialogColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: DialogColors.textSecondary),
        bodySmall: TextStyle(fontSize: 12, color: DialogColors.textMuted),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: DialogColors.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DialogColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DialogColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DialogColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DialogColors.sageDark, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: DialogColors.textMuted),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return DialogColors.sageDark;
          return DialogColors.surface;
        }),
        side: const BorderSide(color: DialogColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      dividerTheme: const DividerThemeData(color: DialogColors.border, thickness: 1),
    );
  }

  static ThemeData dark() {
    return light().copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF2A2824),
      colorScheme: const ColorScheme.dark(
        primary: DialogColors.sage,
        surface: Color(0xFF35322E),
        onSurface: Color(0xFFF0EBE3),
      ),
    );
  }
}
