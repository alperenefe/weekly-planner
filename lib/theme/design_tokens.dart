import 'package:flutter/material.dart';

abstract final class DesignTokens {
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate400 = Color(0xFF94A3B8);
  static const slate200 = Color(0xFFE2E8F0);
  static const white = Color(0xFFFFFFFF);

  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);

  static const green500 = Color(0xFF22C55E);
  static const amber500 = Color(0xFFEAB308);

  static const orange400 = Color(0xFFFB923C);

  static const barTrack = slate800;
  static const barPlannedMuted = slate600;
  static const barDone = blue600;

  static const columnBg = Color(0x800F172A);
  static const cardBg = slate800;
  static const borderSubtle = slate700;

  static const topBarBlurTint = Color(0xE60F172A);

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;

  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionMedium = Duration(milliseconds: 240);
  static const Duration motionSlow = Duration(milliseconds: 320);

  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x400F172A),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const Color textMuted = Color(0xFFADB8C9);

  static const List<int> taskAccentArgb = <int>[
    0xFF2563EB,
    0xFF7C3AED,
    0xFFDB2777,
    0xFFEA580C,
    0xFF059669,
    0xFF0891B2,
    0xFFCA8A04,
    0xFF4F46E5,
  ];
}
