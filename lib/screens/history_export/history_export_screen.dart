import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/task_repository.dart';
import '../../date/week_calendar.dart';
import '../../models/week_summary.dart';
import '../../plan_data_revision.dart';
import '../../services/export_service.dart';
import '../../services/summary_service.dart';
import '../../theme/design_tokens.dart';
import '../../date/turkish_date.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_top_bar.dart';
import '../../widgets/week_navigation_bar.dart';

class HistoryExportScreen extends StatefulWidget {
  const HistoryExportScreen({super.key});

  @override
  State<HistoryExportScreen> createState() => _HistoryExportScreenState();
}

class _HistoryExportScreenState extends State<HistoryExportScreen> {
  late String _anchorMonday;
  late String _exportWeekMonday;
  List<String> _pastWeeks = [];
  String? _expandedWeek;
  final Map<String, WeekSummary> _pastSummaryCache = {};
  PlanDataRevision? _planRevision;
  String? _exportPreview;
  bool _exportPreviewLoading = false;

  @override
  void initState() {
    super.initState();
    _anchorMonday = mondayIsoContaining(DateTime.now());
    _exportWeekMonday = _anchorMonday;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = context.read<PlanDataRevision>();
      _planRevision = r;
      r.addListener(_onPlanDataChanged);
      _loadPastWeeks();
      _loadExportPreview();
    });
  }

  Future<void> _loadExportPreview() async {
    setState(() => _exportPreviewLoading = true);
    final export = context.read<ExportService>();
    final text = await export.exportLlmText(_exportWeekMonday);
    if (!mounted) return;
    final trimmed = text.trim();
    final preview = trimmed.length > 480
        ? '${trimmed.substring(0, 480)}…'
        : trimmed;
    setState(() {
      _exportPreview = preview.isEmpty ? null : preview;
      _exportPreviewLoading = false;
    });
  }

  @override
  void dispose() {
    _planRevision?.removeListener(_onPlanDataChanged);
    super.dispose();
  }

  void _onPlanDataChanged() {
    _loadPastWeeks();
  }

  Future<void> _loadPastWeeks() async {
    final repo = context.read<TaskRepository>();
    final svc = context.read<SummaryService>();
    final w = await repo.getPastWeeks(_anchorMonday);
    final cache = <String, WeekSummary>{};
    for (final week in w) {
      cache[week] = await svc.weekSummary(week);
    }
    if (!mounted) return;
    setState(() {
      _pastWeeks = w;
      _pastSummaryCache
        ..clear()
        ..addAll(cache);
    });
  }

  Future<bool> _confirmDataSharing(String actionLabel) async {
    final ok = await PlannerDialogs.confirm(
      context,
      title: 'Veri paylaşımı',
      message:
          'Dışa aktarılan içerikte etkinlik başlıkları, notlar ve geçmiş '
          'bilgiler yer alır. $actionLabel işlemine devam edilsin mi?',
    );
    return ok == true;
  }

  Future<void> _exportJson() async {
    if (!await _confirmDataSharing('Paylaşım')) return;
    if (!mounted) return;
    final export = context.read<ExportService>();
    final json = await export.exportJson(_exportWeekMonday);
    final bytes = Uint8List.fromList(utf8.encode(json));
    final file = XFile.fromData(
      bytes,
      mimeType: 'application/json',
      name: 'hafta_$_exportWeekMonday.json',
    );
    await Share.shareXFiles([file]);
  }

  Future<void> _copyLlm() async {
    if (!await _confirmDataSharing('Panoya kopyalama')) return;
    if (!mounted) return;
    final export = context.read<ExportService>();
    final text = await export.exportLlmText(_exportWeekMonday);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showPlannerSnackBar(context, 'Kopyalandı');
    }
  }

  void _shiftExportWeek(int d) {
    setState(() {
      _exportWeekMonday = addDaysIso(_exportWeekMonday, d);
    });
    unawaited(_loadExportPreview());
  }

  void _onPastRowTap(String week) {
    setState(() {
      _expandedWeek = _expandedWeek == week ? null : week;
    });
  }

  Future<void> _deleteAllPastWeeks() async {
    if (_pastWeeks.isEmpty) {
      showPlannerSnackBar(context, 'Silinecek geçmiş hafta yok');
      return;
    }
    final ok = await PlannerDialogs.confirmDelete(
      context,
      title: 'Tüm geçmişi sil',
      message:
          '${_pastWeeks.length} geçmiş haftanın tüm etkinlik ve iş kayıtları '
          'kalıcı olarak silinecek. Bu hafta etkilenmez.',
      confirmKey: const Key('confirm_delete_all_history'),
    );
    if (ok != true || !mounted) return;
    final deleted = await context
        .read<TaskRepository>()
        .deletePastWeeksBefore(_anchorMonday);
    if (!mounted) return;
    context.read<PlanDataRevision>().bump();
    await _loadPastWeeks();
    if (!mounted) return;
    showPlannerSnackBar(
      context,
      deleted == 0 ? 'Silinecek kayıt yoktu' : '$deleted kayıt silindi',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('history_export_screen'),
      backgroundColor: DesignTokens.slate950,
      appBar: const PlannerTopBar(),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Geçmiş ve Dışa Aktar',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    height: 1.25,
                    color: DesignTokens.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.history, color: DesignTokens.slate400, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Geçmiş Haftalar',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.white,
                        ),
                      ),
                    ),
                    if (_pastWeeks.isNotEmpty)
                      TextButton.icon(
                        key: const Key('history_delete_all'),
                        onPressed: _deleteAllPastWeeks,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: PlannerDialogs.deleteRed,
                        ),
                        label: Text(
                          'Tümünü sil',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: PlannerDialogs.deleteRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_pastWeeks.isEmpty)
                  Text(
                    'Henüz geçmiş hafta yok.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: DesignTokens.slate400,
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _pastWeeks.length,
                    itemBuilder: (context, index) {
                      final w = _pastWeeks[index];
                      return _PastWeekTile(
                        weekStart: w,
                        expanded: _expandedWeek == w,
                        summary: _pastSummaryCache[w]!,
                        stripeColor: index == 0
                            ? DesignTokens.blue500
                            : DesignTokens.slate500,
                        onTap: () => _onPastRowTap(w),
                      );
                    },
                  ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Icon(Icons.ios_share, color: DesignTokens.slate400, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Veriyi Dışa Aktar',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                WeekNavigationBar(
                  label: 'Hafta: $_exportWeekMonday',
                  onPrevious: () => _shiftExportWeek(-7),
                  onNext: () => _shiftExportWeek(7),
                ),
                const SizedBox(height: 12),
                DecoratedBox(
                  key: const Key('export_preview_card'),
                  decoration: BoxDecoration(
                    color: DesignTokens.slate900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DesignTokens.slate800),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Önizleme',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: DesignTokens.slate200,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_exportPreviewLoading)
                          const LinearProgressIndicator(minHeight: 2)
                        else if (_exportPreview == null)
                          Text(
                            'Bu hafta için dışa aktarılacak içerik yok.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: DesignTokens.slate500,
                            ),
                          )
                        else
                          Text(
                            _exportPreview!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: DesignTokens.slate400,
                              fontFamily: 'monospace',
                              height: 1.45,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final cross = c.maxWidth >= 600 ? 2 : 1;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: cross,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: cross == 2 ? 1.15 : 1.35,
                      children: [
                        _ExportActionCard(
                          title: 'JSON Format',
                          subtitle:
                              'Geliştirici dostu yapılandırılmış veri aktarımı.',
                          icon: Icons.data_object,
                          filled: true,
                          buttonLabel: 'Dışa Aktar',
                          onPressed: _exportJson,
                        ),
                        _ExportActionCard(
                          title: 'LLM Analiz Metni',
                          subtitle:
                              'Yapay zeka asistanlarına yapıştırmak için düz metin özeti.',
                          icon: Icons.document_scanner_outlined,
                          filled: false,
                          buttonLabel: 'Metni Kopyala',
                          onPressed: _copyLlm,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PastWeekTile extends StatelessWidget {
  const _PastWeekTile({
    required this.weekStart,
    required this.expanded,
    required this.summary,
    required this.stripeColor,
    required this.onTap,
  });

  final String weekStart;
  final bool expanded;
  final WeekSummary summary;
  final Color stripeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pctLabel =
        '%${summary.plannedMinutes == 0 ? 0 : summary.completionPercent.round()}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(
        color: DesignTokens.slate900,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: stripeColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                trWeekRangeFromMonday(weekStart),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: DesignTokens.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              pctLabel,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: DesignTokens.blue400,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              expanded ? Icons.expand_less : Icons.expand_more,
                              color: DesignTokens.slate400,
                            ),
                          ],
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Planlanan: ${summary.plannedMinutes} dk · Tamamlanan: ${summary.completedMinutes} dk · Havuz: ${summary.poolMinutes} dk',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: DesignTokens.slate400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportActionCard extends StatelessWidget {
  const _ExportActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.filled,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool filled;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled
            ? DesignTokens.blue600.withValues(alpha: 0.25)
            : DesignTokens.slate900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: filled
              ? DesignTokens.blue600.withValues(alpha: 0.35)
              : DesignTokens.slate800,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: filled ? DesignTokens.blue600 : DesignTokens.slate800,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  icon,
                  color: DesignTokens.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: filled
                    ? DesignTokens.slate200.withValues(alpha: 0.85)
                    : DesignTokens.slate400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor:
                    filled ? DesignTokens.blue600 : DesignTokens.slate800,
                foregroundColor: DesignTokens.white,
              ),
              icon: Icon(
                filled ? Icons.download : Icons.content_copy,
                size: 18,
              ),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
