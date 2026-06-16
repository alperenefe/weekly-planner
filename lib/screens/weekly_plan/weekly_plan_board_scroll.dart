import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

class WeeklyPlanEmptyColumnPlaceholder extends StatelessWidget {
  const WeeklyPlanEmptyColumnPlaceholder({
    super.key,
    required this.label,
    required this.testKey,
  });

  final String label;
  final String testKey;

  bool get _showCaption => label.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final body = Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: WeeklyPlanDashedRRectPainter(
                color: DesignTokens.slate700,
                strokeWidth: 2,
                borderRadius: 8,
              ),
            ),
            if (_showCaption)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        label == 'Boş'
                            ? Icons.inbox_outlined
                            : Icons.event_note_outlined,
                        size: 32,
                        color: DesignTokens.slate600,
                      ),
                      SizedBox(height: DesignTokens.space2),
                      Text(
                        label,
                        key: Key(testKey),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DesignTokens.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(key: Key(testKey)),
          ],
        );
        return body;
      },
    );
  }
}

class WeeklyPlanDashedRRectPainter extends CustomPainter {
  WeeklyPlanDashedRRectPainter({
    required this.color,
    this.strokeWidth = 2,
    this.borderRadius = 8,
  });

  static const double _dashLength = 6;
  static const double _gapLength = 4;

  final Color color;
  final double strokeWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final len = math.min(_dashLength, metric.length - d);
        canvas.drawPath(metric.extractPath(d, len), paint);
        d += _dashLength + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyPlanDashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.borderRadius != borderRadius;
}

class WeeklyPlanHorizontalBoardScroll extends StatelessWidget {
  const WeeklyPlanHorizontalBoardScroll({
    super.key,
    required this.controller,
    required this.minHeight,
    required this.child,
  });

  final ScrollController controller;
  final double minHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(
          DesignTokens.space3,
          0,
          DesignTokens.space3,
          DesignTokens.space4,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: child,
        ),
      ),
    );
  }
}
