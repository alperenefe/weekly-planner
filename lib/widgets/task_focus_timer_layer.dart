import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/task_repository.dart';
import '../plan_data_revision.dart';
import '../services/task_focus_timer_controller.dart';
import '../theme/design_tokens.dart';

String _formatMmSs(Duration d) {
  final t = d.inSeconds.clamp(0, 86400);
  final m = t ~/ 60;
  final s = t % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class TaskFocusTimerLayer extends StatefulWidget {
  const TaskFocusTimerLayer({super.key, required this.child});

  final Widget child;

  @override
  State<TaskFocusTimerLayer> createState() => _TaskFocusTimerLayerState();
}

class _TaskFocusTimerLayerState extends State<TaskFocusTimerLayer> {
  TaskFocusTimerController? _ctrl;
  TaskFocusTimerPhase _prevPhase = TaskFocusTimerPhase.idle;
  bool _alarmDialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<TaskFocusTimerController>();
    if (!identical(next, _ctrl)) {
      _ctrl?.removeListener(_onController);
      _ctrl = next;
      _ctrl!.addListener(_onController);
      _prevPhase = _ctrl!.phase;
      if (_ctrl!.phase == TaskFocusTimerPhase.alarming) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            unawaited(_showAlarmDialog(_ctrl!));
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.removeListener(_onController);
    super.dispose();
  }

  void _onController() {
    if (!mounted) return;
    final c = _ctrl!;
    final enteredAlarm = _prevPhase != TaskFocusTimerPhase.alarming &&
        c.phase == TaskFocusTimerPhase.alarming;
    _prevPhase = c.phase;
    if (enteredAlarm && !_alarmDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_showAlarmDialog(c));
        }
      });
    }
  }

  Future<void> _markFocusTaskDone(TaskFocusTimerController c) async {
    final id = c.activeTaskId;
    if (id <= 0) return;
    await context.read<TaskRepository>().markDone(id);
    if (mounted) context.read<PlanDataRevision>().bump();
    await c.clearPersistedAndSilenceAfterDone(id);
  }

  Future<void> _showAlarmDialog(TaskFocusTimerController c) async {
    if (!mounted || c.phase != TaskFocusTimerPhase.alarming || _alarmDialogOpen) {
      return;
    }
    _alarmDialogOpen = true;
    final title = c.activeTitle.isEmpty ? 'Etkinlik' : c.activeTitle;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Süre doldu'),
          content: Text(title),
          actions: [
            TextButton(
              onPressed: () async {
                await _markFocusTaskDone(c);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Tamamlandı'),
            ),
            FilledButton(
              onPressed: () async {
                await c.acknowledgeAlarm();
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
    if (mounted) {
      setState(() {
        _alarmDialogOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<TaskFocusTimerController>();

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (c.phase == TaskFocusTimerPhase.running)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 16,
              color: DesignTokens.slate900,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              c.activeTitle.isEmpty ? 'Odak' : c.activeTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DesignTokens.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Kalan ${_formatMmSs(c.remainingNow())}',
                              style: const TextStyle(
                                color: DesignTokens.blue400,
                                fontWeight: FontWeight.w800,
                                fontSize: 30,
                                height: 1.1,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          foregroundColor: DesignTokens.green500,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => unawaited(_markFocusTaskDone(c)),
                        child: const Text('Tamamlandı'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          foregroundColor: DesignTokens.blue400,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => unawaited(c.pauseSession()),
                        child: const Text('Durdur'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                          foregroundColor: DesignTokens.slate400,
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => unawaited(c.resetGoalAndStop()),
                        child: const Text('Sıfırla'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
