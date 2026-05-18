import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

final class AppTheme {
  AppTheme._();

  static const Color _surface = DesignTokens.slate950;
  static const Color _surfaceContainer = DesignTokens.slate800;
  static const Color _primary = DesignTokens.blue600;

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      surface: _surface,
      primary: _primary,
      onPrimary: Colors.white,
      onSurface: const Color(0xFFE2E8F0),
      outline: const Color(0xFF475569),
      surfaceContainerHighest: _surfaceContainer,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _surface,
    );
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: -0.35,
          color: const Color(0xFFE2E8F0),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: const Color(0xFFE2E8F0),
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: const Color(0xFFCBD5E1),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: const Color(0xFFE2E8F0),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: const Color(0xFFCBD5E1),
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.35,
          letterSpacing: 0.15,
          color: const Color(0xFF94A3B8),
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.35,
          letterSpacing: 0.4,
          color: const Color(0xFF94A3B8),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: const Color(0xFFADB8C9),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _surfaceContainer.withValues(alpha: 0.95),
        indicatorColor: _primary.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? _primary
                : const Color(0xFF94A3B8),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        modalBarrierColor: Colors.black.withValues(alpha: 0.52),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}
