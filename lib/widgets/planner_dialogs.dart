import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Koyu tema: dialog, onay ve SnackBar yardımcıları.
abstract final class PlannerDialogs {
  static const deleteRed = Color(0xFFEF4444);

  static const TextStyle _titleStyle = TextStyle(
    color: DesignTokens.white,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle _bodyStyle = TextStyle(
    color: DesignTokens.slate400,
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle bodyTextStyle = _bodyStyle;

  static Widget titleText(String text) => Text(text, style: _titleStyle);

  static Widget bodyText(String text) => Text(text, style: _bodyStyle);

  static AlertDialog build({
    required Widget title,
    Widget? content,
    List<Widget>? actions,
    EdgeInsets? actionsPadding,
  }) {
    return AlertDialog(
      backgroundColor: DesignTokens.slate900,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: DesignTokens.slate800),
      ),
      title: DefaultTextStyle(style: _titleStyle, child: title),
      content: content == null
          ? null
          : DefaultTextStyle(style: _bodyStyle, child: content),
      actions: actions,
      actionsPadding: actionsPadding ??
          const EdgeInsets.fromLTRB(16, 0, 16, 12),
    );
  }

  static TextButton cancelAction(
    BuildContext ctx, {
    VoidCallback? onPressed,
    String label = 'İptal',
  }) {
    return TextButton(
      onPressed: onPressed ?? () => Navigator.of(ctx).pop(),
      child: Text(label, style: const TextStyle(color: DesignTokens.slate400)),
    );
  }

  static TextButton deleteAction(
    BuildContext ctx, {
    required VoidCallback onPressed,
    String label = 'Sil',
    Key? key,
  }) {
    return TextButton(
      key: key,
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: deleteRed),
      child: Text(label),
    );
  }

  static FilledButton confirmAction(
    BuildContext ctx, {
    required VoidCallback onPressed,
    String label = 'Devam',
    Key? key,
  }) {
    return FilledButton(
      key: key,
      style: FilledButton.styleFrom(
        backgroundColor: DesignTokens.blue600,
        foregroundColor: DesignTokens.white,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  static InputDecoration fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: DesignTokens.slate400,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      hintStyle: TextStyle(color: DesignTokens.slate600.withValues(alpha: 0.8)),
      filled: true,
      fillColor: DesignTokens.slate950,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DesignTokens.slate800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DesignTokens.slate800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: DesignTokens.blue500, width: 1.5),
      ),
    );
  }

  static TextStyle get dialogFieldTextStyle =>
      const TextStyle(color: DesignTokens.white);

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget Function(BuildContext ctx) builder,
    bool barrierDismissible = true,
    bool useRootNavigator = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      useRootNavigator: useRootNavigator,
      builder: builder,
    );
  }

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'İptal',
    String confirmLabel = 'Devam',
  }) {
    return show<bool>(
      context,
      builder: (ctx) => build(
        title: titleText(title),
        content: bodyText(message),
        actions: [
          cancelAction(
            ctx,
            label: cancelLabel,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          confirmAction(
            ctx,
            label: confirmLabel,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  static Future<bool?> confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'İptal',
    String deleteLabel = 'Sil',
    Key? confirmKey,
  }) {
    return show<bool>(
      context,
      builder: (ctx) => build(
        title: titleText(title),
        content: bodyText(message),
        actions: [
          cancelAction(
            ctx,
            label: cancelLabel,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          deleteAction(
            ctx,
            key: confirmKey,
            label: deleteLabel,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }

  static Future<String?> promptText(
    BuildContext context, {
    required String title,
    String? initialValue,
    String labelText = 'İsim',
    String cancelLabel = 'İptal',
    String confirmLabel = 'Kaydet',
    bool autofocus = false,
  }) async {
    final ctrl = TextEditingController(text: initialValue);
    final result = await show<String>(
      context,
      builder: (ctx) => build(
        title: titleText(title),
        content: TextField(
          autofocus: autofocus,
          controller: ctrl,
          style: dialogFieldTextStyle,
          cursorColor: DesignTokens.blue400,
          decoration: fieldDecoration(labelText),
        ),
        actions: [
          cancelAction(ctx, onPressed: () => Navigator.of(ctx).pop()),
          confirmAction(
            ctx,
            label: confirmLabel,
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }
}

void showPlannerSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: DesignTokens.white),
      ),
      backgroundColor: DesignTokens.slate900,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

void showPlannerErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: DesignTokens.white),
      ),
      backgroundColor: DesignTokens.slate900,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: PlannerDialogs.deleteRed),
      ),
    ),
  );
}
