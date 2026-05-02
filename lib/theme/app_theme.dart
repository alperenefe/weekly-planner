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
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
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
    );
  }
}
