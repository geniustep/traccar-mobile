import 'package:flutter/material.dart';

// ignore_for_file: use_build_context_synchronously
class AppColors {
  AppColors._();

  // ── Primary palette (deep navy — Elmo GPS dark background) ────────────────
  static const Color primary = Color(0xFF0A1628);
  static const Color primaryLight = Color(0xFF172540);
  static const Color primaryDark = Color(0xFF040B14);

  // ── Accent / electric blue (matches Elmo GPS brand) ────────────────────────
  static const Color accent = Color(0xFF0096FF);
  static const Color accentLight = Color(0xFF38B6FF);
  static const Color accentDark = Color(0xFF0073CC);

  // ── Purple / analytics accent ──────────────────────────────────────────────
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleLight = Color(0xFFA78BFA);
  static const Color purpleDark = Color(0xFF5B21B6);

  // ── Amber / trips accent ───────────────────────────────────────────────────
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberDark = Color(0xFFD97706);

  // ── Emerald / success accent ───────────────────────────────────────────────
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldDark = Color(0xFF059669);

  // ── Rose / critical accent ─────────────────────────────────────────────────
  static const Color rose = Color(0xFFF43F5E);
  static const Color roseLight = Color(0xFFFB7185);
  static const Color roseDark = Color(0xFFE11D48);

  // ── Background layers (deep navy dark theme) ───────────────────────────────
  static const Color background = Color(0xFF060D1A);
  static const Color surface = Color(0xFF0B1628);
  static const Color surfaceElevated = Color(0xFF122035);
  static const Color cardBackground = Color(0xFF0F1C2E);

  // ── Glass / overlay ────────────────────────────────────────────────────────
  static const Color glassLight = Color(0x14FFFFFF);
  static const Color glassDark = Color(0x0AFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // ── Dividers / borders ─────────────────────────────────────────────────────
  static const Color divider = Color(0xFF182436);
  static const Color border = Color(0xFF1C2D42);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF0096FF);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8FA3B1);
  static const Color textMuted = Color(0xFF4A5C6A);
  static const Color textAccent = Color(0xFF0096FF);

  // ── Vehicle status ─────────────────────────────────────────────────────────
  static const Color statusMoving = Color(0xFF10B981);
  static const Color statusStopped = Color(0xFFF59E0B);
  static const Color statusOffline = Color(0xFF4A5C6A);
  static const Color statusIdle = Color(0xFF38B6FF);

  // ── Alert severity ─────────────────────────────────────────────────────────
  static const Color severityCritical = Color(0xFFFF4757);
  static const Color severityHigh = Color(0xFFFF6B35);
  static const Color severityMedium = Color(0xFFF59E0B);
  static const Color severityLow = Color(0xFF10B981);
  static const Color severityInfo = Color(0xFF0096FF);

  // ── Light theme palette ────────────────────────────────────────────────────
  static const Color lightBackground     = Color(0xFFF0F4F8);
  static const Color lightSurface        = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated= Color(0xFFE8EEF5);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightBorder         = Color(0xFFCDD8E3);
  static const Color lightDivider        = Color(0xFFDDE6EF);
  static const Color lightTextPrimary    = Color(0xFF0D1B2A);
  static const Color lightTextSecondary  = Color(0xFF3D5570);
  static const Color lightTextMuted      = Color(0xFF7A93A8);

  // ── Dark gradients ─────────────────────────────────────────────────────────

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1628), Color(0xFF132238)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0096FF), Color(0xFF0073CC)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F1C2E), Color(0xFF0A1424)],
  );

  /// Ocean: electric blue → deep navy — used for map / live tracking
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0096FF), Color(0xFF0A1628)],
  );

  /// Aurora: purple → electric blue — used for analytics / insights
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF0096FF)],
  );

  /// Sunset: amber → rose — used for alerts / warnings
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
  );

  /// Forest: emerald → teal — used for moving / active states
  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF0E9488)],
  );

  /// Midnight: deep navy — hero background
  static const LinearGradient midnightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF060D1A), Color(0xFF0B1628)],
  );

  /// Glow: accent glow overlay for cards
  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1A0096FF), Color(0x050096FF)],
  );

  // ── Light gradients ────────────────────────────────────────────────────────

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

  static const LinearGradient lightOceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
  );

  static const LinearGradient lightAuroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
  );

  static const LinearGradient lightSunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
  );

  static const LinearGradient lightForestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
  );

  // ── Radial glow helpers ────────────────────────────────────────────────────

  static const RadialGradient accentRadialGlow = RadialGradient(
    colors: [Color(0x330096FF), Color(0x000096FF)],
    radius: 0.8,
  );

  static const RadialGradient purpleRadialGlow = RadialGradient(
    colors: [Color(0x337C3AED), Color(0x007C3AED)],
    radius: 0.8,
  );

  // ── Theme-aware helpers ────────────────────────────────────────────────────

  static Color backgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? background
        : lightBackground;
  }

  static Color surfaceOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surface
        : lightSurface;
  }

  static Color surfaceElevatedOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceElevated
        : lightSurfaceElevated;
  }

  static Color cardBackgroundOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardBackground
        : lightCardBackground;
  }

  static Color borderOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? border
        : lightBorder;
  }

  static Color dividerOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? divider
        : lightDivider;
  }

  static Color textPrimaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimary
        : lightTextPrimary;
  }

  static Color textSecondaryOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondary
        : lightTextSecondary;
  }

  static Color textMutedOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textMuted
        : lightTextMuted;
  }

  static LinearGradient cardGradientOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardGradient
        : lightCardGradient;
  }
}
