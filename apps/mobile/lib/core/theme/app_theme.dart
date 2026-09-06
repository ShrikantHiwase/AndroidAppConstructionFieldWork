import 'package:flutter/material.dart';

/// Field-first theme: high contrast for sunlight, large tap targets,
/// Noto Sans with Devanagari fallback so Hinglish renders consistently.
abstract final class AppTheme {
  static const _seed = Color(0xFF1B4D3E);

  static const _fontFamily = 'NotoSans';
  static const _fontFallback = ['NotoSansDevanagari'];

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFallback,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: const DialogThemeData(
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }
}
