import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF0D1B2A);
  static const Color primaryLight = Color(0xFF1A2E44);
  static const Color primaryDark = Color(0xFF060D14);

  // Accent / electric blue
  static const Color accent = Color(0xFF00B4D8);
  static const Color accentLight = Color(0xFF48CAE4);
  static const Color accentDark = Color(0xFF0096B7);

  // Background layers
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF0F1724);
  static const Color surfaceElevated = Color(0xFF162030);
  static const Color cardBackground = Color(0xFF131C2B);

  // Dividers / borders
  static const Color divider = Color(0xFF1E2D40);
  static const Color border = Color(0xFF243447);

  // Semantic
  static const Color success = Color(0xFF2ED573);
  static const Color warning = Color(0xFFFFA502);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF00B4D8);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8FA3B1);
  static const Color textMuted = Color(0xFF4A5C6A);
  static const Color textAccent = Color(0xFF00B4D8);

  // Vehicle status colours
  static const Color statusMoving = Color(0xFF2ED573);
  static const Color statusStopped = Color(0xFFFFA502);
  static const Color statusOffline = Color(0xFF4A5C6A);
  static const Color statusIdle = Color(0xFF48CAE4);

  // Alert severity
  static const Color severityCritical = Color(0xFFFF4757);
  static const Color severityHigh = Color(0xFFFF6B35);
  static const Color severityMedium = Color(0xFFFFA502);
  static const Color severityLow = Color(0xFF2ED573);
  static const Color severityInfo = Color(0xFF00B4D8);

  // ── Light theme palette ──────────────────────────────────────────────────
  static const Color lightBackground     = Color(0xFFF4F7FB);
  static const Color lightSurface        = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated= Color(0xFFEDF1F7);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightBorder         = Color(0xFFD0DBE6);
  static const Color lightDivider        = Color(0xFFE2EAF0);

  static const Color lightTextPrimary    = Color(0xFF0D1B2A);
  static const Color lightTextSecondary  = Color(0xFF3D5570);
  static const Color lightTextMuted      = Color(0xFF7A93A8);

  static const LinearGradient lightPrimaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFEDF1F7)],
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF4F7FB)],
  );

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1B2A), Color(0xFF162030)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00B4D8), Color(0xFF0096B7)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF131C2B), Color(0xFF0F1724)],
  );
}
