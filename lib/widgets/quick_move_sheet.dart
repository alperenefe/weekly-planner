import 'package:flutter/material.dart';

import '../data/db/app_database.dart';
import '../plan_day_labels.dart';
import '../theme/design_tokens.dart';

/// Sürükle-bırak alternatifi: görevi başka güne/havuza taşı.
Future<void> showQuickMoveSheet({
  required BuildContext context,
  required Task task,
  required Future<void> Function(int dayIndex) onMoveToDayIndex,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: DesignTokens.slate950,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Taşı',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      color: DesignTokens.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                task.title,
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: DesignTokens.slate400,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < kPlanDayLabels.length; i++)
                    ActionChip(
                      key: Key('quick_move_day_${kPlanDayLabels[i]}'),
                      label: Text(kPlanDayLabels[i]),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await onMoveToDayIndex(i);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
