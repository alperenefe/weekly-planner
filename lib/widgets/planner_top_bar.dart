import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_brand_mark.dart';
import '../theme/design_tokens.dart';

class PlannerTopBar extends StatelessWidget implements PreferredSizeWidget {
  const PlannerTopBar({
    super.key,
    this.title = 'Haftalık Plan',
    this.onCalendarTap,
    this.onMoreTap,
    this.moreMenuBuilder,
    this.onMoreMenuSelected,
    this.extraActions,
  });

  final String title;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onMoreTap;
  final List<PopupMenuEntry<String>> Function(BuildContext context)?
      moreMenuBuilder;
  final ValueChanged<String>? onMoreMenuSelected;
  final List<Widget>? extraActions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final useMenu =
        moreMenuBuilder != null && onMoreMenuSelected != null;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      iconTheme: const IconThemeData(color: DesignTokens.blue500),
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: DesignTokens.white,
            letterSpacing: -0.2,
          ),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: DesignTokens.topBarBlurTint,
              border: const Border(
                bottom: BorderSide(color: DesignTokens.slate800),
              ),
            ),
          ),
        ),
      ),
      title: Text(title),
      leading: IconButton(
        key: const Key('top_bar_calendar'),
        tooltip: 'Haftalık Plan',
        onPressed: onCalendarTap,
        icon: const AppBrandMark(slot: 32, borderRadius: 8),
      ),
      actions: [
        if (extraActions != null) ...extraActions!,
        if (useMenu)
          PopupMenuButton<String>(
            key: const Key('top_bar_more'),
            icon: const Icon(Icons.more_vert, color: DesignTokens.blue500),
            onSelected: onMoreMenuSelected,
            itemBuilder: moreMenuBuilder!,
          )
        else
          IconButton(
            key: const Key('top_bar_more'),
            icon: const Icon(Icons.more_vert),
            color: DesignTokens.blue500,
            onPressed: onMoreTap,
          ),
      ],
    );
  }
}
