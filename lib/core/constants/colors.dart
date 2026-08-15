// ============================================
// 1. CORE CONSTANTS - COLORS (بدون أي تكرار)
// ============================================

// lib/core/constants/colors.dart
import 'package:flutter/material.dart';

class PwfColors {
  PwfColors._();

  // Primary Palette
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color royalRed = Color(0xFFB22222);

  // Aliases (to support legacy usages across the codebase)
  static const Color blue = primaryBlue;
  static const Color gold = primaryGold;
  static const Color red = royalRed;

  // Semantic Colors
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Neutral
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color onSurface = Color(0xFF1E293B);
  static const Color outline = Color(0xFFE2E8F0);

  // Dark Mode
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
}
