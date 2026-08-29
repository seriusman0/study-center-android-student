/// Design tokens — UI/UX Improvement Specification.
///
/// Single source of truth for spacing, colors, radius, elevation. Use these
/// constants instead of hardcoded values so screens stay consistent.
library;

import 'package:flutter/material.dart';

// ─── Spacing (8-pt grid) ─────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double screenPadding = 16;
}

// ─── Colors (mapped to web palette) ──────────────────────────────────────────
class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF0F766E);     // Deep Teal 700
  static const Color primaryDark = Color(0xFF00695C); // Deeper Teal (CTA)
  static const Color primaryLight = Color(0xFF14B8A6);

  // Neutrals
  static const Color background = Color(0xFFF8FAFC);   // Slate 50
  static const Color surface = Colors.white;           // Card surface
  static const Color border = Color(0xFFE2E8F0);       // Slate 200
  static const Color borderStrong = Color(0xFFCBD5E1); // Slate 300
  static const Color divider = Color(0xFFF1F5F9);      // Slate 100

  // Text
  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8);     // Slate 400

  // Status
  static const Color danger = Color(0xFFDC2626);       // Red 600
  static const Color dangerSoft = Color(0xFFEF4444);   // Red 500
  static const Color success = Color(0xFF059669);       // Emerald 600
  static const Color warning = Color(0xFFF59E0B);       // Amber 500
}

// ─── Radius ──────────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static const double card = 12;
  static const double button = 10;
  static const double input = 12;
  static const double chip = 16; // pill
}

// ─── Elevation ───────────────────────────────────────────────────────────────
class AppShadow {
  AppShadow._();
  static List<BoxShadow> get low => const [
        BoxShadow(
          color: Color(0x14000000), // 8% black
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ];
  static List<BoxShadow> get medium => const [
        BoxShadow(
          color: Color(0x1F000000), // 12% black
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];
}