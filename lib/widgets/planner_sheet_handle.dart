import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Things 3 tarzı sheet tutamacı.
class PlannerSheetHandle extends StatelessWidget {
  const PlannerSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: DesignTokens.space3),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.slate600 : const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
