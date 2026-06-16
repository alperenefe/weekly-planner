import 'package:flutter/material.dart';

import '../data/db/app_database.dart';
import '../theme/design_tokens.dart';

/// Gün sütununda etkinlikler için ince, tıklanınca genişleyen şerit.
class DayEventsCollapsibleStrip extends StatefulWidget {
  const DayEventsCollapsibleStrip({
    super.key,
    required this.events,
    required this.columnKeySuffix,
    required this.itemBuilder,
  });

  final List<Task> events;
  final String columnKeySuffix;
  final Widget Function(Task task) itemBuilder;

  @override
  State<DayEventsCollapsibleStrip> createState() =>
      _DayEventsCollapsibleStripState();
}

class _DayEventsCollapsibleStripState extends State<DayEventsCollapsibleStrip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.events.length;
    if (count == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    const accent = DesignTokens.green500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('day_events_strip_${widget.columnKeySuffix}'),
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: DesignTokens.motionMedium,
              curve: Curves.easeOutCubic,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: accent.withValues(alpha: 0.14),
                border: Border.all(
                  color: accent.withValues(alpha: 0.55),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    decoration: const BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.event_available_outlined,
                    size: 14,
                    color: accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Etkinlikler · $count',
                      key: Key(
                        'day_events_strip_label_${widget.columnKeySuffix}',
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: DesignTokens.slate500,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: DesignTokens.motionMedium,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: DesignTokens.space2),
                    for (var i = 0; i < widget.events.length; i++) ...[
                      if (i > 0) SizedBox(height: DesignTokens.space2),
                      widget.itemBuilder(widget.events[i]),
                    ],
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
