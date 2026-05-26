import 'package:flutter/material.dart';

import '../services/onboarding_store.dart';
import '../theme/design_tokens.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int _slide = 0;

  static const _slides = [
    (
      Icons.inbox_outlined,
      'Plansız görev havuzu',
      'Aklına gelen işleri önce Havuz\'a ekle; zamanı gelince gün sütunlarına taşı.',
    ),
    (
      Icons.view_week_outlined,
      '8 sütunlu hafta tahtası',
      'Havuz + Pazartesi–Pazar tek bakışta. Sürükle-bırak veya taşı düğmesi ile planla.',
    ),
    (
      Icons.insights_outlined,
      'Özet, hedefler ve hatırlatıcılar',
      'Haftalık ilerleme, aylık hedefler, günlük özet bildirimi ve odak süresi.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, body) = _slides[_slide];

    return Dialog(
      key: const Key('onboarding_dialog'),
      backgroundColor: DesignTokens.slate950,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: DesignTokens.slate800),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HAFTALIK PLAN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DesignTokens.slate500,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${_slide + 1} / ${_slides.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: DesignTokens.blue400,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Icon(icon, size: 48, color: DesignTokens.blue400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: DesignTokens.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DesignTokens.slate400,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
                  Container(
                    width: i == _slide ? 12 : 8,
                    height: i == _slide ? 12 : 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: i == _slide
                          ? DesignTokens.blue500
                          : DesignTokens.slate800,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  key: const Key('onboarding_skip'),
                  onPressed: () async {
                    await OnboardingStore.markCompleted();
                    widget.onComplete();
                  },
                  child: const Text('Atla'),
                ),
                FilledButton(
                  key: Key(
                    _slide < _slides.length - 1
                        ? 'onboarding_next'
                        : 'onboarding_done',
                  ),
                  onPressed: () async {
                    if (_slide < _slides.length - 1) {
                      setState(() => _slide++);
                    } else {
                      await OnboardingStore.markCompleted();
                      widget.onComplete();
                    }
                  },
                  child: Text(
                    _slide < _slides.length - 1 ? 'İleri' : 'Başla',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// İlk açılışta onboarding gösterir.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _show;

  @override
  void initState() {
    super.initState();
    OnboardingStore.shouldShow().then((v) {
      if (mounted) setState(() => _show = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_show == null) {
      return const ColoredBox(
        color: DesignTokens.slate950,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Stack(
      children: [
        widget.child,
        if (_show!)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: OnboardingDialog(
                    onComplete: () => setState(() => _show = false),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
