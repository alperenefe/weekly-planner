import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/week_template_repository.dart';
import '../../data/repositories/week_template_tasks_companion.dart';
import '../../models/week_template.dart';
import '../../theme/design_tokens.dart';
import '../../theme/planner_shell_layout.dart';
import '../../widgets/planner_dialogs.dart';
import '../../widgets/planner_empty_state.dart';
import 'week_template_detail_board.dart';
import 'week_template_task_editor_sheet.dart';

class WeekTemplatesScreen extends StatefulWidget {
  const WeekTemplatesScreen({super.key});

  @override
  State<WeekTemplatesScreen> createState() => _WeekTemplatesScreenState();
}

class _WeekTemplatesScreenState extends State<WeekTemplatesScreen> {
  List<WeekTemplate> _templates = [];
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  Future<void> _reload() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repo = context.read<WeekTemplateRepository>();
      final list = await repo.getTemplates();
      if (!mounted) return;
      setState(() {
        _templates = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _createTemplate() async {
    final name = await PlannerDialogs.promptText(
      context,
      title: 'Yeni kayıtlı plan',
      labelText: 'İsim',
      confirmLabel: 'Oluştur',
      autofocus: true,
    );
    if (name == null || name.isEmpty || !mounted) return;
    final id = await context.read<WeekTemplateRepository>().insertTemplate(name);
    if (!mounted) return;
    context.push('/settings/templates/$id');
    unawaited(_reload());
  }

  Future<void> _deleteTemplate(WeekTemplate t) async {
    final ok = await PlannerDialogs.confirmDelete(
      context,
      title: 'Kayıtlı planı sil',
      message: 'Bu kayıtlı hafta planı silinecek. Emin misin?',
    );
    if (ok != true || !mounted) return;
    await context.read<WeekTemplateRepository>().deleteTemplate(t.id);
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('week_templates_screen'),
      backgroundColor: DesignTokens.slate950,
      appBar: AppBar(
        backgroundColor: DesignTokens.slate950,
        foregroundColor: DesignTokens.white,
        title: const Text('Kayıtlı hafta planları'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: DesignTokens.slate900,
              color: DesignTokens.blue500,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const Key('week_templates_new_btn'),
              onPressed: () => unawaited(_createTemplate()),
              icon: const Icon(Icons.add),
              label: const Text('Yeni kayıtlı plan'),
            ),
          ),
          Expanded(
            child: _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Planlar yüklenemedi.\n$_loadError',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: DesignTokens.slate500),
                      ),
                    ),
                  )
                : _templates.isEmpty && !_loading
                    ? Center(
                        child: PlannerEmptyState(
                          testKey: const Key('week_templates_empty'),
                          icon: Icons.dashboard_customize_outlined,
                          title: 'Henüz kayıtlı plan yok',
                          subtitle:
                              'Haftalık rutinini bir kez kur; sonra Plan ekranından '
                              'tek dokunuşla uygula.',
                          actionLabel: 'Yeni kayıtlı plan',
                          onAction: () => unawaited(_createTemplate()),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _templates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, i) {
                          final t = _templates[i];
                          return Material(
                            key: Key('week_template_row_${t.id}'),
                            color: DesignTokens.slate900,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              key: Key('week_template_tile_${t.id}'),
                              onTap: () => context.push(
                                '/settings/templates/${t.id}',
                              ),
                              title: Text(
                                t.name,
                                style: const TextStyle(
                                  color: DesignTokens.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                t.taskCount == 0
                                    ? 'Henüz görev yok — dokun, haftayı düzenle'
                                    : '${t.taskCount} görev',
                                style: const TextStyle(
                                  color: DesignTokens.slate400,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    key: Key('week_template_delete_${t.id}'),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFEF4444),
                                    ),
                                    onPressed: () =>
                                        unawaited(_deleteTemplate(t)),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: DesignTokens.slate500,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class WeekTemplateDetailScreen extends StatefulWidget {
  const WeekTemplateDetailScreen({super.key, required this.templateId});

  final int templateId;

  @override
  State<WeekTemplateDetailScreen> createState() => _WeekTemplateDetailScreenState();
}

class _WeekTemplateDetailScreenState extends State<WeekTemplateDetailScreen> {
  WeekTemplateDetail? _detail;
  bool _loading = false;
  String? _loadError;
  final ScrollController _boardScrollController = ScrollController();

  @override
  void dispose() {
    _boardScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final repo = context.read<WeekTemplateRepository>();
      final d = await repo.getTemplateWithTasks(widget.templateId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _autoScrollBoardDuringDrag(DragUpdateDetails details) {
    if (!_boardScrollController.hasClients) return;
    final padding = MediaQuery.paddingOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final dx = details.globalPosition.dx;
    const edge = 72.0;
    const step = 10.0;
    final position = _boardScrollController.position;
    final maxExtent = position.maxScrollExtent;
    var offset = position.pixels;
    if (dx < padding.left + edge) {
      offset = (offset - step).clamp(0.0, maxExtent);
      if (offset != position.pixels) {
        _boardScrollController.jumpTo(offset);
      }
    } else if (dx > width - padding.right - edge) {
      offset = (offset + step).clamp(0.0, maxExtent);
      if (offset != position.pixels) {
        _boardScrollController.jumpTo(offset);
      }
    }
  }

  Future<void> _onDropTemplateTask(WeekTemplateTask task, int? newTargetWeekday) async {
    final cur = task.targetWeekday;
    final same =
        (cur == null && newTargetWeekday == null) || (cur == newTargetWeekday);
    if (same) return;
    await context.read<WeekTemplateRepository>().updateTemplateTaskTargetWeekday(
          task.id,
          newTargetWeekday,
        );
    if (mounted) await _load();
  }

  Future<void> _openTaskEditor({WeekTemplateTask? existing}) async {
    final initial = existing == null
        ? null
        : WeekTemplateTaskEditorResult(
            title: existing.title,
            durationMinutes: existing.durationMinutes,
            notes: existing.notes,
            targetWeekday: existing.targetWeekday,
          );
    final result = await showWeekTemplateTaskEditorSheet(
      context: context,
      initial: initial,
    );
    if (result == null || !mounted) return;
    final repo = context.read<WeekTemplateRepository>();
    if (existing == null) {
      await repo.insertTemplateTask(
        WeekTemplateTasksCompanion.insert(
          templateId: widget.templateId,
          title: result.title,
          durationMinutes: result.durationMinutes == null
              ? const Value.absent()
              : Value(result.durationMinutes),
          notes: result.notes == null
              ? const Value.absent()
              : Value(result.notes),
          targetWeekday: Value(result.targetWeekday),
        ),
      );
    } else {
      await repo.updateTemplateTask(
        existing.id,
        title: result.title,
        durationMinutes: result.durationMinutes,
        notes: result.notes,
        targetWeekday: result.targetWeekday,
      );
    }
    if (mounted) await _load();
  }

  Future<void> _deleteTask(WeekTemplateTask t) async {
    await context.read<WeekTemplateRepository>().deleteTemplateTask(t.id);
    if (mounted) await _load();
  }

  Future<void> _renameTemplate() async {
    if (_detail == null) return;
    final name = await PlannerDialogs.promptText(
      context,
      title: 'Kayıtlı plan adı',
      initialValue: _detail!.template.name,
    );
    if (name == null || name.isEmpty || !mounted) return;
    await context.read<WeekTemplateRepository>().updateTemplateName(
          widget.templateId,
          name,
        );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.slate950,
      appBar: AppBar(
        backgroundColor: DesignTokens.slate950,
        foregroundColor: DesignTokens.white,
        title: Text(_detail?.template.name ?? '…'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            key: const Key('week_template_rename_btn'),
            tooltip: 'Plan adını değiştir',
            icon: const Icon(Icons.drive_file_rename_outline),
            onPressed: _loading ? null : _renameTemplate,
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: plannerShellFabBottomPadding(context),
        ),
        child: FloatingActionButton.extended(
          key: const Key('week_template_detail_fab'),
          onPressed: () => unawaited(_openTaskEditor()),
          backgroundColor: DesignTokens.blue600,
          foregroundColor: DesignTokens.white,
          icon: const Icon(Icons.add),
          label: const Text('Görev ekle'),
        ),
      ),
      body: _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Plan yüklenemedi.\n$_loadError',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: DesignTokens.slate500),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => unawaited(_load()),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            )
          : _detail == null && _loading
              ? const Center(child: CircularProgressIndicator())
              : _detail == null
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_loading)
                          const LinearProgressIndicator(
                            minHeight: 2,
                            backgroundColor: DesignTokens.slate900,
                            color: DesignTokens.blue500,
                          ),
                        if (_detail!.tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Text(
                              'Hafta görünümünde görev ekle; sürükleyerek günlere taşı.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: DesignTokens.slate500),
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: WeekTemplatePlanBoard(
                              tasks: _detail!.tasks,
                              controller: _boardScrollController,
                              onDropTask: _onDropTemplateTask,
                              onEditTask: (t) => _openTaskEditor(existing: t),
                              onDeleteTask: _deleteTask,
                              onDragUpdate: _autoScrollBoardDuringDrag,
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
