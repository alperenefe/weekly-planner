# Weekly Planner — Uygulama özeti (LLM / bağlam dosyası)

Bu dosya projeyi tek seferde anlatmak için tutulur: mimari, ekranlar, veri, bayraklar, yollar. Kod değiştikçe güncellenmeli.

---

## Ne bu uygulama?

- **Kişisel haftalık plan** (offline MVP): etkinlikler hafta bazında; havuz + Pazartesi–Pazar sütunları; tamamlama, taşıma, düzenleme, geçen haftadan kopya, plan kaydırma; aylık hedefler; özet ve dışa aktarma.
- **Dil:** arayüz metinleri çoğunlukla Türkçe.
- **Ağ yok:** yerel SQLite (Drift); özellik bayrakları `SharedPreferences` ile saklanır.

---

## Teknik yığın

| Alan | Seçim |
|------|--------|
| Framework | Flutter (Dart SDK `pubspec.yaml` içindeki sürüm) |
| Durum / DI | `provider` (`MultiProvider` kökte) |
| Router | `go_router` — `StatefulShellRoute.indexedStack` (5 dal: plan, özet, geçmiş, hedefler, ayarlar) |
| Veri | Drift + `sqlite3_flutter_libs`; şema `lib/data/db/app_database.dart` |
| Paylaşım | `share_plus` (export) |
| Sürüm satırı | `package_info_plus` (Ayarlar → Hakkında) |

---

## Giriş noktası ve sağlayıcılar

- `lib/main.dart`: `AppDatabase.open()`, `TaskRepository`, `RecurringTemplateRepository`, `MonthlyGoalRepository`, `MonthlyGoalService`, `WeekService`, `SummaryService`, `ExportService`, `PlannerFeatureFlagsStore`, `PlanDataRevision`; `runApp(MultiProvider(..., child: WeeklyPlannerApp()))`.
- `lib/app.dart`: `WeeklyPlannerApp` — `didChangeDependencies` içinde bir kez `AppRouter.createRouter(featureFlagsStore)`; `dispose`’da `GoRouter.dispose()`. `build` içinde `context.watch<PlannerFeatureFlagsStore>()` ile bayrak değişince router yenilenir.

---

## Yönlendirme ve URL’ler

- `lib/router/app_router.dart`: `GoRouter` `refreshListenable: PlannerFeatureFlagsStore`.
- **Yollar:** `/plan`, `/summary`, `/history`, `/goals`, `/settings` (hepsi aynı shell içinde).
- **Redirect:** `weekSummaryTabEnabled == false` ve yol `/summary` → `/plan`. `historyExportTabEnabled == false` ve yol `/history` → `/plan`. `monthlyGoalsEnabled == false` ve yol `/goals` → `/plan`.
- Shell: `lib/screens/shell/main_shell.dart` — gövde `navigationShell`, alt bar `PlannerBottomNav` + `buildPlannerNavSpec(flags)`.

---

## Alt navigasyon ve dal indeksleri

`lib/nav/planner_nav_spec.dart`: Shell dal sırası sabit — **0=Plan, 1=Özet, 2=Geçmiş, 3=Hedefler, 4=Ayarlar**. Özet / Geçmiş / Hedefler sekmeleri ilgili bayraklarla gizlenebilir; Ayarlar her zaman dal **4**. Alt barda görünen öğeler bayraklara göre filtrelenir; `PlannerNavSpec` görünür indeks ile `shellBranchIndex` arasında eşleme yapar.

---

## Özellik bayrakları

Sınıf: `lib/config/planner_feature_flags.dart`  
Depo: `lib/services/planner_feature_flags_store.dart` — anahtar `planner_feature_flags_v1` (JSON string, `SharedPreferences`).

| Bayrak | Varsayılan | Etki (kısa) |
|--------|------------|-------------|
| `copyLastWeekEnabled` | true | Plan ekranında “geçen haftayı kopyala” düğmesi |
| `scheduledBreaksEnabled` | true | Üst menüde “Planı kaydır” (`PlanShiftSheet`) |
| `weekSummaryTabEnabled` | true | Özet sekmesi + `/summary` |
| `historyExportTabEnabled` | true | Geçmiş sekmesi + `/history` |
| `planBoardSearchEnabled` | true | Plan ekranında arama ikonu / alanı |
| `monthlyGoalsEnabled` | true | Hedefler sekmesi + `/goals` |

Ayarlar ekranında her biri için `SwitchListTile` (test anahtarları: `settings_feature_*`).

---

## Ekranlar (yüksek seviye)

| Ekran | Dosya | Not |
|-------|--------|-----|
| Haftalık plan tahtası | `lib/screens/weekly_plan/weekly_plan_screen.dart` (+ `weekly_plan_*` yardımcıları) | Havuz + 7 gün sütunu; hafta ileri/geri; FAB ekleme; sürükle-bırak taşıma; arama (bayrak); “bugün” özeti satırı |
| Özet | `lib/screens/summary/summary_screen.dart` | `SummaryService.weekSummary` + `weekTrend` + `postponeAnalysis`; görev sayıları ızgarası, son 4 hafta tamamlanma çubuğu, aylık hedef özeti (`MonthlyGoalRepository`), erteleme analizi (`TaskRepository.getMostMovedTasks`); `/goals` kısayolu |
| Geçmiş / dışa aktarma | `lib/screens/history_export/history_export_screen.dart` | Geçmiş haftalar, JSON/LLM metin export, panoya kopya, paylaş |
| Aylık hedefler | `lib/screens/monthly_goals/monthly_goals_screen.dart` | `YYYY-MM` ay seçici; hedef listesi; haftaya görev ekleme (`MonthlyGoalService` + `PlanDataRevision`) |
| Ayarlar | `lib/screens/settings/settings_screen.dart` | Hakkında, özellik anahtarları, tüm veriyi sıfırla |

**Ortak UI:** `PlannerTopBar`, `WeekNavigationBar`, `BoardColumn`, `TaskCard`, `AddTaskSheet`, `EditTaskSheet`, `PlanShiftSheet`, `PlannerBottomNav`.

---

## Haftalık plan davranışı

- Hafta Pazartesi ISO tarihi (`week_calendar`) ile kimlenir; `WeekService.ensureWeekTasks` şablonlardan havuz görevleri üretir.
- Veri yenileme: `PlanDataRevision` dinleyicileri ile plan ekranı / özet / geçmiş senkron kalır; bazı akışlarda `bump()` çağrılır.
- Görev yaşam döngüsü ve senaryolar: `docs/senaryolar_gorev_akislari.md`, test: `test/scenarios/task_lifecycle_scenarios_test.dart`.
- Plan kaydır: `docs/senaryolar_plan_kaydir.md`, test: `test/scenarios/plan_kaydir_scenarios_test.dart`.

---

## Veri modeli (Drift tabloları)

- **`tasks`:** başlık, süre, başlangıç dakikası, notlar, `status`, `week_start`, `planned_date`, `original_planned_date`, `moved_count`, `recurrence_template_id`, zaman damgaları, `completed_at`.
- **`task_history`:** görev olay geçmişi (`event_type`, from/to, not).
- **`week_meta`:** hafta bazında `copy_from_previous_applied` (geçen hafta kopyası işareti).
- **`recurring_templates`:** tekrarlayan şablonlar (`RecurringTemplateRepository`).
- **`monthly_goals`:** (şema sürümü 5) `title`, `month` (`YYYY-MM`), `order_index`, `status` (`active`/`done`), `created_at`, `updated_at` — ham SQL + `MonthlyGoalRepository`.
- **`week_templates` / `week_template_tasks`:** (şema 6) haftalık ön tanımlı plan şablonları; `WeekTemplateRepository`, `WeekTemplateService`, ekran: `lib/screens/week_templates/`, rota: `/settings/templates`, `/settings/templates/:templateId`.

İş kuralları ve sorgular: `lib/data/repositories/task_repository.dart`, `monthly_goal_repository.dart`, `week_template_repository.dart`, `week_service.dart`, `summary_service.dart`, `export_service.dart`, `monthly_goal_service.dart`.

---

## Tema

- `lib/theme/app_theme.dart`, `design_tokens.dart` — koyu slate / mavi vurgu.

---

## Testler

- Komut: proje kökünde `flutter test`.
- Widget / senaryo testleri `test/` altında; çoğu uygulama ağacı `test/test_support.dart` içindeki `plannerAppWithDb(db, featureFlags: ...)` ile kurulur.

---

## Dosya haritası (lib özeti)

```
lib/main.dart, app.dart
lib/router/app_router.dart
lib/config/planner_feature_flags.dart
lib/nav/planner_nav_spec.dart
lib/plan_data_revision.dart, plan_day_labels.dart
lib/date/week_calendar.dart, turkish_date.dart
lib/data/db/app_database.dart (+ .g.dart)
lib/data/repositories/task_repository.dart, recurring_template_repository.dart, monthly_goal_repository.dart, week_template_repository.dart
lib/services/*.dart
lib/screens/{weekly_plan,shell,summary,history_export,monthly_goals,settings,week_templates}/
lib/widgets/*.dart
lib/theme/*.dart
lib/models/week_summary.dart, monthly_goal.dart
```

---

## Bu dosyayı LLM’e nasıl verirsin?

1. Sohbet veya bağlam penceresine **`docs/UYGULAMA.md` tamamını** yapıştır; gerekirse ilgili **tek** ekran dosyasını veya repository’yi ekle.
2. Davranış detayı için ek olarak `docs/senaryolar_*.md` veya ilgili `test/scenarios/*.dart` özetini ekle.

---

*Son güncelleme notu: dosya elle senkronize edilir; commit mesajında veya burada tarih tutulabilir.*
