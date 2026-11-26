import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Accents
  static const Color purple = Color(0xFF7C5CFF);
  static const Color blue = Color(0xFF3D8BFF);

  // Dark palette (deep charcoal)
  static const Color darkBackground = Color(0xFF121214);
  static const Color darkSurface = Color(0xFF1C1C21);
  static const Color darkSurfaceHigh = Color(0xFF26262D);
  static const Color darkText = Color(0xFFF2F2F7);
  static const Color darkTextMuted = Color(0xFF9A9AA8);

  // Light palette
  static const Color lightBackground = Color(0xFFF6F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceHigh = Color(0xFFECECF3);
  static const Color lightText = Color(0xFF16161A);
  static const Color lightTextMuted = Color(0xFF6B6B7B);

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [purple, blue],
  );
}
