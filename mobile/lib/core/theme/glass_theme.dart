import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassTheme {
  // Brand Accents
  static const Color snapYellow = Color(0xFFFFFC00);
  static const Color iosBlue = Color(0xFF007AFF);
  static const Color iosPurple = Color(0xFFAF52DE);
  static const Color iosPink = Color(0xFFFF2D55);
  static const Color neonCyan = Color(0xFF00F0FF);

  // Background Aurora Gradients
  static const List<Color> darkMesh = [
    Color(0xFF090A0F),
    Color(0xFF141226),
    Color(0xFF1A142B),
    Color(0xFF0A1224),
  ];

  static const List<Color> lightMesh = [
    Color(0xFFF0F4FF),
    Color(0xFFF9F0FF),
    Color(0xFFEBF7FF),
    Color(0xFFF5F5FA),
  ];

  // Glass Specular Borders (Light coming from top-left)
  static LinearGradient specularBorder(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.02),
              Colors.white.withValues(alpha: 0.12),
            ]
          : [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.40),
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.50),
            ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );
  }

  // Glass Container Background Fill
  static Color glassColor(bool isDark, {double opacityMultiplier = 1.0}) {
    return isDark
        ? Colors.white.withValues(alpha: 0.08 * opacityMultiplier)
        : Colors.white.withValues(alpha: 0.60 * opacityMultiplier);
  }

  // Shadow for 3D Floating Glass depth
  static List<BoxShadow> glassShadow(bool isDark) {
    return [
      BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.06),
        blurRadius: 28,
        spreadRadius: -4,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: isDark ? Colors.black.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.03),
        blurRadius: 10,
        spreadRadius: -2,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // Typography - SF Pro feel using Plus Jakarta Sans
  static TextStyle headline({bool isDark = true, FontWeight weight = FontWeight.w700}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 28,
      fontWeight: weight,
      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
      letterSpacing: -0.5,
    );
  }

  static TextStyle title({bool isDark = true, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 20,
      fontWeight: weight,
      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
      letterSpacing: -0.3,
    );
  }

  static TextStyle body({bool isDark = true, FontWeight weight = FontWeight.w400}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: weight,
      color: isDark ? Colors.white.withValues(alpha: 0.88) : const Color(0xFF3A3A3C),
      letterSpacing: -0.2,
      height: 1.35,
    );
  }

  static TextStyle caption({bool isDark = true}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF8E8E93),
      letterSpacing: -0.1,
    );
  }
}
