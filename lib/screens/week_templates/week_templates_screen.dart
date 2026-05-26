import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/week_template_repository.dart';
import '../../data/repositories/week_template_tasks_companion.dart';
import '../../models/week_template.dart';
import '../../plan_day_labels.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/planner_dialogs.dart';
import 'week_template_detail_board.dart';

class WeekTemplatesScreen extends StatefulWidget {
  const WeekTemplatesScreen({super.key});

  @override
  State<WeekTemplatesScreen> createState() => _WeekTemplatesScreenState();
}

class _WeekTemplatesScreenState extends State<WeekTemplatesScreen> {
  List<WeekTemplate> _templates = [];
  final Map<int, List<WeekTemplateTask>> _tasksByTemplate = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final repo = context.read<WeekTemplateRepository>();
    final list = await repo.getTemplates();
    final map = <int, List<WeekTemplateTask>>{};
    for (final t in list) {
      final d = await repo.getTemplateWithTasks(t.id);
      map[t.id] = d.tasks;
    }
    if (!mounted) return;
    setState(() {
      _templates = list;
      _tasksByTemplate
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  String _weekdayLabel(int? tw) {
    if (tw == null || tw < 1 || tw > 7) return 'Havuz';
    return kPlanDayLabels[tw];
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
    await _reload();
    if (mounted) {
      context.push('/settings/templates/$id');
    }
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

  Future<void> _renameTemplate(WeekTemplate t) async {
    final name = await PlannerDialogs.promptText(
      context,
      title: 'İsim değiştir',
      initialValue: t.name,
    );
    if (name == null || name.isEmpty || !mounted) return;
    await context.read<WeekTemplateRepository>().updateTemplateName(t.id, name);
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              key: const Key('week_templates_new_btn'),
              onPressed: _createTemplate,
              icon: const Icon(Icons.add),
              label: const Text('Yeni kayıtlı plan'),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _templates.isEmpty
                    ? Center(
                        child: Text(
                          'Henüz kayıtlı plan yok',
                          key: const Key('week_templates_empty'),
                          style: TextStyle(
                            color: DesignTokens.slate500,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _templates.length,
                        itemBuilder: (context, i) {
                          final t = _templates[i];
                          final tasks = _tasksByTemplate[t.id] ?? [];
                          return ExpansionTile(
                            key: Key('week_template_row_${t.id}'),
                            title: Text(
                              t.name,
                              style: const TextStyle(
                                color: DesignTokens.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${t.taskCount} görev',
                              style: const TextStyle(color: DesignTokens.slate400),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: DesignTokens.blue400,
                                  ),
                                  onPressed: () => unawaited(_renameTemplate(t)),
                                ),
                                IconButton(
                                  key: Key('week_template_delete_${t.id}'),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFEF4444),
                                  ),
                                  onPressed: () => unawaited(_deleteTemplate(t)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  color: DesignTokens.slate400,
                                  onPressed: () =>
                                      context.push('/settings/templates/${t.id}'),
                                ),
                              ],
                            ),
                            children: [
                              if (tasks.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text(
                                    'Görev yok',
                                    style: TextStyle(color: DesignTokens.slate500),
                                  ),
                                )
                              else
                                ...tasks.map(
                                  (task) => ListTile(
                                    dense: true,
                                    title: Text(
                                      task.title,
                                      style: const TextStyle(
                                        color: DesignTokens.slate200,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _weekdayLabel(task.targetWeekday),
                                      style: const TextStyle(
                                        color: DesignTokens.slate500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
  bool _loading = true;
  bool _showAdd = false;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _durCtrl = TextEditingController();
  final Set<int> _selectedTemplateDays = {0};
  final ScrollController _boardScrollController = ScrollController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _durCtrl.dispose();
    _boardScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = context.read<WeekTemplateRepository>();
    final d = await repo.getTemplateWithTasks(widget.templateId);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _loading = false;
    });
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

  Future<void> _submitTask() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    int? dur;
    final ds = _durCtrl.text.trim();
    if (ds.isNotEmpty) {
      dur = int.tryParse(ds);
    }
    final repo = context.read<WeekTemplateRepository>();
    final Iterable<int?> targets;
    if (_selectedTemplateDays.contains(0)) {
      targets = [null];
    } else {
      final sorted = _selectedTemplateDays.toList()..sort();
      targets = sorted;
    }
    for (final tw in targets) {
      await repo.insertTemplateTask(
        WeekTemplateTasksCompanion.insert(
          templateId: widget.templateId,
          title: title,
          durationMinutes: dur == null ? const Value.absent() : Value(dur),
          targetWeekday: Value(tw),
        ),
      );
    }
    if (!mounted) return;
    _titleCtrl.clear();
    _durCtrl.clear();
    setState(() {
      _showAdd = false;
      _selectedTemplateDays
        ..clear()
        ..add(0);
    });
    await _load();
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
            icon: const Icon(Icons.edit),
            onPressed: _loading ? null : _renameTemplate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('week_template_detail_fab'),
        onPressed: () => setState(() => _showAdd = !_showAdd),
        backgroundColor: DesignTokens.blue600,
        child: Icon(_showAdd ? Icons.close : Icons.add),
      ),
      body: _loading || _detail == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _showAdd
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: DesignTokens.slate900,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DesignTokens.slate800),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    key: const Key('week_tpl_task_title'),
                                    controller: _titleCtrl,
                                    style: const TextStyle(color: DesignTokens.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Başlık',
                                      labelStyle: TextStyle(color: DesignTokens.slate400),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    key: const Key('week_tpl_task_duration'),
                                    controller: _durCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: DesignTokens.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Süre (dk, isteğe bağlı)',
                                      labelStyle: TextStyle(color: DesignTokens.slate400),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      for (var i = 0; i < kPlanDayLabels.length; i++)
                                        FilterChip(
                                          label: Text(kPlanDayLabels[i]),
                                          selected: _selectedTemplateDays.contains(i),
                                          onSelected: (selected) {
                                            setState(() {
                                              if (i == 0) {
                                                _selectedTemplateDays
                                                  ..clear()
                                                  ..add(0);
                                                return;
                                              }
                                              _selectedTemplateDays.remove(0);
                                              if (selected) {
                                                _selectedTemplateDays.add(i);
                                              } else {
                                                _selectedTemplateDays.remove(i);
                                              }
                                              if (_selectedTemplateDays.isEmpty) {
                                                _selectedTemplateDays.add(0);
                                              }
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton(
                                      key: const Key('week_tpl_task_add_btn'),
                                      onPressed: _submitTask,
                                      child: const Text('Ekle'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: WeekTemplatePlanBoard(
                      tasks: _detail!.tasks,
                      controller: _boardScrollController,
                      onDropTask: _onDropTemplateTask,
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
