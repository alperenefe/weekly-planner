import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/task_repository.dart';
import '../../plan_data_revision.dart';
import '../../services/planner_feature_flags_store.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/app_brand_mark.dart';
import '../../widgets/planner_top_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  Future<void> _onResetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm veriyi sıfırla'),
        content: const Text(
          'Tüm etkinlikler, geçmiş ve şablonlar silinecek. Emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = context.read<TaskRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await repo.resetAllData();
    if (!mounted) return;
    context.read<PlanDataRevision>().bump();
    messenger.showSnackBar(
      const SnackBar(content: Text('Tüm veriler silindi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionLine = _packageInfo == null
        ? '…'
        : '${_packageInfo!.version} (${_packageInfo!.buildNumber})';

    return Scaffold(
      key: const Key('settings_screen'),
      backgroundColor: DesignTokens.slate950,
      appBar: const PlannerTopBar(title: 'Ayarlar'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Uygulama',
            style: theme.textTheme.labelSmall?.copyWith(
              color: DesignTokens.slate500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('settings_about_row'),
            leading: const AppBrandMark(slot: 48, borderRadius: 10),
            tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: DesignTokens.slate800),
            ),
            title: Text(
              'Hakkında',
              style: theme.textTheme.titleSmall?.copyWith(
                color: DesignTokens.slate200,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Haftalık Plan · $versionLine',
              style: theme.textTheme.bodySmall?.copyWith(
                color: DesignTokens.slate400,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Planlama',
            style: theme.textTheme.labelSmall?.copyWith(
              color: DesignTokens.slate500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('settings_recurring_templates_row'),
            leading: const Icon(
              Icons.repeat,
              color: DesignTokens.blue400,
            ),
            tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: DesignTokens.slate800),
            ),
            title: Text(
              'Tekrarlayan görevler',
              style: theme.textTheme.titleSmall?.copyWith(
                color: DesignTokens.slate200,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Her hafta otomatik eklenen şablonlar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: DesignTokens.slate400,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: DesignTokens.slate500),
            onTap: () => context.push('/settings/recurring-templates'),
          ),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('settings_week_templates_row'),
            leading: const Icon(
              Icons.dashboard_customize_outlined,
              color: DesignTokens.blue400,
            ),
            tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: DesignTokens.slate800),
            ),
            title: Text(
              'Haftalık Şablonlar',
              style: theme.textTheme.titleSmall?.copyWith(
                color: DesignTokens.slate200,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Önceden tanımlı görev setleri',
              style: theme.textTheme.bodySmall?.copyWith(
                color: DesignTokens.slate400,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: DesignTokens.slate500),
            onTap: () => context.push('/settings/templates'),
          ),
          const SizedBox(height: 24),
          Text(
            'Özellikler',
            style: theme.textTheme.labelSmall?.copyWith(
              color: DesignTokens.slate500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<PlannerFeatureFlagsStore>(
            builder: (context, store, _) {
              final f = store.flags;
              final tileShape = RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: DesignTokens.slate800),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    key: const Key('settings_feature_copy_last_week'),
                    tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                    shape: tileShape,
                    title: Text(
                      'Geçen haftayı kopyala',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Hafta görünümündeki kopyalama düğmesi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                    ),
                    value: f.copyLastWeekEnabled,
                    onChanged: (v) {
                      unawaited(
                        store.setFlags(f.copyWith(copyLastWeekEnabled: v)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('settings_feature_plan_shift'),
                    tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                    shape: tileShape,
                    title: Text(
                      'Planı kaydır',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Üç nokta menüsünden gün ve çapa seçerek saatli etkinlikleri ileri al',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                    ),
                    value: f.scheduledBreaksEnabled,
                    onChanged: (v) {
                      unawaited(
                        store.setFlags(
                          f.copyWith(scheduledBreaksEnabled: v),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('settings_feature_summary_tab'),
                    tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                    shape: tileShape,
                    title: Text(
                      'Özet sekmesi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Alt gezinmede Özet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                    ),
                    value: f.weekSummaryTabEnabled,
                    onChanged: (v) {
                      unawaited(
                        store.setFlags(f.copyWith(weekSummaryTabEnabled: v)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('settings_feature_history_tab'),
                    tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                    shape: tileShape,
                    title: Text(
                      'Geçmiş sekmesi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Alt gezinmede Geçmiş ve dışa aktarma',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                    ),
                    value: f.historyExportTabEnabled,
                    onChanged: (v) {
                      unawaited(
                        store.setFlags(
                          f.copyWith(historyExportTabEnabled: v),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('settings_feature_plan_search'),
                    tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                    shape: tileShape,
                    title: Text(
                      'Plan ekranında arama',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Üst çubukta arama simgesi ve arama alanı',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                    ),
                    value: f.planBoardSearchEnabled,
                    onChanged: (v) {
                      unawaited(
                        store.setFlags(
                          f.copyWith(planBoardSearchEnabled: v),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('settings_feature_monthly_goals'),
                    tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                    shape: tileShape,
                    title: Text(
                      'Aylık hedefler sekmesi',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Alt gezinmede Hedefler',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                    ),
                    value: f.monthlyGoalsEnabled,
                    onChanged: (v) {
                      unawaited(
                        store.setFlags(
                          f.copyWith(monthlyGoalsEnabled: v),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('settings_feature_week_templates'),
                    tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                    shape: tileShape,
                    title: Text(
                      'Haftalık şablonlar',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Hafta başlığında şablon uygula düğmesi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                    ),
                    value: f.weekTemplatesEnabled,
                    onChanged: (v) {
                      unawaited(
                        store.setFlags(
                          f.copyWith(weekTemplatesEnabled: v),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Veri',
            style: theme.textTheme.labelSmall?.copyWith(
              color: DesignTokens.slate500,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('settings_reset_all_row'),
            leading: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
            ),
            tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: DesignTokens.slate800),
            ),
            title: Text(
              'Tüm veriyi sıfırla',
              style: theme.textTheme.titleSmall?.copyWith(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: _onResetAllData,
          ),
        ],
      ),
    );
  }
}
