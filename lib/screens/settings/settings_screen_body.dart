part of 'settings_screen.dart';

class _SettingsScrollBody extends StatelessWidget {
  const _SettingsScrollBody(this.state);

  final _SettingsScreenState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final versionLine = state._packageInfo == null
        ? '…'
        : '${state._packageInfo!.version} (${state._packageInfo!.buildNumber})';

    return ListView(
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
        const SizedBox(height: 8),
        ListTile(
          key: const Key('settings_demo_data_row'),
          leading: const Icon(
            Icons.science_outlined,
            color: DesignTokens.blue400,
          ),
          tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: DesignTokens.slate800),
          ),
          title: Text(
            'Örnek veri yükle',
            style: theme.textTheme.titleSmall?.copyWith(
              color: DesignTokens.slate200,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Bu hafta boşsa demo görev, hedef ve şablon ekler',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DesignTokens.slate400,
            ),
          ),
          onTap: () => unawaited(state._seedDemoData()),
        ),
        const SizedBox(height: 8),
        const AppUpdateCard(),
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
        Consumer<PlannerFeatureFlagsStore>(
          builder: (context, store, _) {
            if (!store.flags.recurringTemplatesEnabled) {
              return const SizedBox.shrink();
            }
            return ListTile(
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
                'Her hafta otomatik görevler',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: DesignTokens.slate200,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Eklediğin kural her yeni haftada bir kez plana yazılır (tek etkinlik)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.slate400,
                ),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: DesignTokens.slate500),
              onTap: () => context.push('/settings/recurring-templates'),
            );
          },
        ),
        const SizedBox(height: 8),
        Consumer<PlannerFeatureFlagsStore>(
          builder: (context, store, _) {
            if (!store.flags.weekTemplatesEnabled) {
              return const SizedBox.shrink();
            }
            return ListTile(
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
                'Kayıtlı hafta planları',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: DesignTokens.slate200,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Birden çok etkinlik kaydedersin; istediğin haftaya tek düğmeyle uygularsın',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DesignTokens.slate400,
                ),
              ),
              trailing:
                  const Icon(Icons.chevron_right, color: DesignTokens.slate500),
              onTap: () => context.push('/settings/templates'),
            );
          },
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
                    'Günlük planı kaydır',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: DesignTokens.slate200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Menüden bir gün seç; o gündeki saatli etkinlikleri dakika kadar ileri al',
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
                  key: const Key('settings_feature_recurring_templates'),
                  tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                  shape: tileShape,
                  title: Text(
                    'Her hafta otomatik görev kuralları',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: DesignTokens.slate200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Kapalıyken yeni haftaya otomatik görev eklenmez; Planlama girişi gizlenir',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DesignTokens.slate400,
                    ),
                  ),
                  value: f.recurringTemplatesEnabled,
                  onChanged: (v) {
                    unawaited(
                      store.setFlags(
                        f.copyWith(recurringTemplatesEnabled: v),
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
                    'Plan ekranında kayıtlı plan düğmesi',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: DesignTokens.slate200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Üst barda seçtiğin haftaya kayıtlı hafta planını uygulama',
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
          'Hatırlatıcılar',
          style: theme.textTheme.labelSmall?.copyWith(
            color: DesignTokens.slate500,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Consumer<ReminderSettingsStore>(
          builder: (context, rs, _) {
            final tileShape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: DesignTokens.slate800),
            );
            return Column(
              children: [
                SwitchListTile(
                  key: const Key('settings_reminders_master'),
                  tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                  shape: tileShape,
                  title: Text(
                    'Hatırlatıcılar',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: DesignTokens.slate200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Kapalıyken günlük özet ve etkinlik bildirimleri gönderilmez',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DesignTokens.slate400,
                    ),
                  ),
                  value: rs.remindersEnabled,
                  onChanged: (v) => unawaited(state._onRemindersMasterChanged(v)),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  key: const Key('settings_daily_summary'),
                  tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                  shape: tileShape,
                  title: Text(
                    'Günlük özet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: DesignTokens.slate200,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    rs.dailySummaryEnabled
                        ? 'Her gün ${formatClockMinutes(rs.dailySummaryMinutes)} — bugünün işleri'
                        : 'Kapalı',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: DesignTokens.slate400,
                    ),
                  ),
                  value: rs.dailySummaryEnabled,
                  onChanged: rs.remindersEnabled
                      ? (v) => unawaited(state._onDailySummaryChanged(v))
                      : null,
                ),
                if (rs.dailySummaryEnabled && rs.remindersEnabled)
                  ListTile(
                    key: const Key('settings_daily_summary_time'),
                    tileColor: DesignTokens.slate900.withValues(alpha: 0.6),
                    shape: tileShape,
                    leading: const Icon(
                      Icons.schedule,
                      color: DesignTokens.blue400,
                    ),
                    title: Text(
                      'Özet saati',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DesignTokens.slate200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      formatClockMinutes(rs.dailySummaryMinutes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: DesignTokens.slate500,
                    ),
                    onTap: () => unawaited(state._pickDailySummaryTime()),
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
          onTap: state._onResetAllData,
        ),
      ],
    );
  }
}
