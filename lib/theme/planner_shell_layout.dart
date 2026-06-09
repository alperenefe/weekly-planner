import 'package:flutter/material.dart';

/// [MainShell] `extendBody: true` iken alt [NavigationBar] üstünde FAB boşluğu.
double plannerShellFabBottomPadding(BuildContext context) {
  final mq = MediaQuery.of(context);
  final systemBottom =
      mq.viewPadding.bottom > mq.padding.bottom
          ? mq.viewPadding.bottom
          : mq.padding.bottom;
  return kBottomNavigationBarHeight + systemBottom + 24;
}
