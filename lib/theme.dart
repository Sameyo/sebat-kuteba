import 'package:flutter/material.dart';

const Color pine = Color(0xFF1B4332);
const Color sage = Color(0xFF74C69D);
const Color cream = Color(0xFFF4F1E8);
const Color parchment = Color(0xFFEFEADC);
const Color rust = Color(0xFFB5563A);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: pine,
    brightness: Brightness.light,
  ).copyWith(
    primary: pine,
    onPrimary: cream,
    secondary: sage,
    surface: cream,
    onSurface: pine,
    error: rust,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: cream,
  );
}
