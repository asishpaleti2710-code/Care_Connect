import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CareConnect Design Tokens matching frontend/src/index.css
class AppColors {
  // Backgrounds
  static const Color bgPrimary = Color(0xFF0F172A); // Slate 900
  static const Color bgSecondary = Color(0xFF1E293B); // Slate 800
  static const Color bgCard = Color(0xBF1E293B); // rgba(30, 41, 59, 0.75)
  static const Color bgCardHover = Color(0xD9334155); // rgba(51, 65, 85, 0.85)
  static const Color bgDarkInput = Color(0x990F172A); // rgba(15, 23, 42, 0.6)

  // Light theme backgrounds
  static const Color bgPrimaryLight = Color(0xFFF1F5F9); // Slate 100
  static const Color bgSecondaryLight = Color(0xFFFFFFFF);
  static const Color bgCardLight = Color(0xCCFFFFFF);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF334155);

  // Accents
  static const Color accentTeal = Color(0xFF14B8A6); // Teal 500
  static const Color accentTealDark = Color(0xFF0D9488); // Teal 600
  static const Color accentTealGlow = Color(0x4014B8A6); // rgba(20, 184, 166, 0.25)
  static const Color accentBlue = Color(0xFF3B82F6); // Blue 500
  static const Color accentPurple = Color(0xFF8B5CF6); // Purple 500
  static const Color accentPurpleDark = Color(0xFF6D28D9);

  // Status Colors
  static const Color statusSafe = Color(0xFF10B981); // Emerald 500
  static const Color statusSafeBg = Color(0x2610B981); // rgba(16, 185, 129, 0.15)
  static const Color statusAlert = Color(0xFFF59E0B); // Amber 500
  static const Color statusAlertBg = Color(0x26F59E0B); // rgba(245, 158, 11, 0.15)
  static const Color statusEmergency = Color(0xFFEF4444); // Red 500
  static const Color statusEmergencyDark = Color(0xFFDC2626); // Red 600
  static const Color statusEmergencyBg = Color(0x33EF4444); // rgba(239, 68, 68, 0.2)

  // Borders
  static const Color border = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.1)
  static const Color glassBorder = Color(0x1FFFFFFF); // rgba(255, 255, 255, 0.12)
  static const Color borderLight = Color(0x140F172A);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sosPulseGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Glassmorphism & UI Component Decorations matching web styles
class AppGlass {
  static BoxDecoration cardDecoration({
    Color? color,
    Color? borderColor,
    double radius = 16.0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.bgCard,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppColors.glassBorder,
        width: 1.0,
      ),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
    );
  }

  static BoxDecoration panelDecoration({
    double radius = 14.0,
    Color? color,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color ?? const Color(0x990F172A),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppColors.border,
        width: 1.0,
      ),
    );
  }

  static InputDecoration inputDecoration({
    required String hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.bgDarkInput,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accentTeal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.statusEmergency),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.statusEmergency, width: 1.5),
      ),
    );
  }
}

class AppTheme {
  // Heading font style helper using Outfit font from website
  static TextStyle heading({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double letterSpacing = -0.3,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Dark Theme (Default CareConnect Experience)
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      primaryColor: AppColors.accentTeal,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentTeal,
        secondary: AppColors.statusEmergency,
        surface: AppColors.bgSecondary,
        error: AppColors.statusEmergency,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xF20F172A), // 95% opacity
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  // Light Theme Configuration
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgPrimaryLight,
      primaryColor: AppColors.accentTeal,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentTeal,
        secondary: AppColors.statusEmergency,
        surface: AppColors.bgSecondaryLight,
        error: AppColors.statusEmergency,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCardLight,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
    );
  }
}
