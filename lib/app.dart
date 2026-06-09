import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'services/planner_feature_flags_store.dart';
import 'services/task_focus_timer_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/onboarding_dialog.dart';
import 'widgets/task_focus_timer_layer.dart';

class WeeklyPlannerApp extends StatefulWidget {
  const WeeklyPlannerApp({super.key});

  @override
  State<WeeklyPlannerApp> createState() => _WeeklyPlannerAppState();
}

class _WeeklyPlannerAppState extends State<WeeklyPlannerApp>
    with WidgetsBindingObserver {
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        final ctx = AppRouter.rootNavigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ctx.read<TaskFocusTimerController>().onAppLifecyclePaused();
        }
        break;
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = AppRouter.rootNavigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            unawaited(
              ctx.read<TaskFocusTimerController>().onAppLifecycleResumed(),
            );
          }
        });
        break;
      default:
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _router ??= AppRouter.createRouter(
      context.read<PlannerFeatureFlagsStore>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PlannerFeatureFlagsStore>();
    return MaterialApp.router(
      title: 'Haftalık Plan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router!,
      builder: (context, child) {
        return OnboardingGate(
          child: TaskFocusTimerLayer(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
