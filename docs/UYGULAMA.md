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
| Veri | Drift + `sqlite3_flutter_libs`; şema v9 `lib/data/db/app_database.dart` (indeksler + `reminder_*` sütunları) |
| Bildirimler | `flutter_local_notifications` + `timezone`; odak süresi + hatırlatıcı kanalı (`lib/services/planner_local_notifications.dart`) |
| Paylaşım | `share_plus` (export) |
| Sürüm satırı | `package_info_plus` (Ayarlar → Hakkında) |

---

## Giriş noktası ve sağlayıcılar

- `lib/main.dart`: DB + repolar + `PlannerLocalNotifications`, `ReminderSettingsStore`, `ReminderSchedulerService` (`PlanDataRevision` dinleyerek `syncAll`), `PlannerFeatureFlagsStore`, odak süresi; `runApp(MultiProvider(...))`.
- `lib/app.dart`: `WeeklyPlannerApp` — `didChangeDependencies` içinde bir kez `AppRouter.createRouter(featureFlagsStore)`; `dispose`’da `GoRouter.dispose()`. `build` içinde `context.watch<PlannerFeatureFlagsStore>()` ile bayrak değişince router yenilenir.

---

## Yönlendirme ve URL’ler

- `lib/router/app_router.dart`: `GoRouter` `refreshListenable: PlannerFeatureFlagsStore`.
- **Yollar:** `/plan`, `/summary`, `/history`, `/goals`, `/settings` (hepsi aynı shell içinde).
- **Redirect:** `weekSummaryTabEnabled == false` ve yol `/summary` → `/plan`. `historyExportTabEnabled == false` ve yol `/history` → `/plan`. `monthlyGoalsEnabled == false` ve yol `/goals` → `/plan`. `recurringTemplatesEnabled == false` ve `/settings/recurring-templates` → `/settings`. `weekTemplatesEnabled == false` ve `/settings/templates` → `/settings`.
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
| `scheduledBreaksEnabled` | true | Üst menüde “Günlük planı kaydır” (`PlanShiftSheet`) |
| `weekSummaryTabEnabled` | true | Özet sekmesi + `/summary` |
| `historyExportTabEnabled` | true | Geçmiş sekmesi + `/history` |
| `planBoardSearchEnabled` | true | Plan ekranında arama ikonu / alanı |
| `recurringTemplatesEnabled` | true | Her hafta otomatik görev kuralları (`WeekService.ensureWeekTasks`) ve Ayarlar → Planlama girişi |
| `monthlyGoalsEnabled` | true | Hedefler sekmesi + `/goals` |
| `weekTemplatesEnabled` | true | Plan ekranında kayıtlı hafta planını uygula düğmesi |

Ayarlar ekranında her biri için `SwitchListTile` (test anahtarları: `settings_feature_*`).

---

## Ekranlar (yüksek seviye)

| Ekran | Dosya | Not |
|-------|--------|-----|
| Haftalık plan tahtası | `lib/screens/weekly_plan/weekly_plan_screen.dart` (+ `weekly_plan_*` yardımcıları) | Havuz + 7 gün; sürükle-bırak; **gün pill şeridi** (`weekly_plan_today_pill.dart`); sütun **mini ilerleme çubuğu**; kartta **Taşı** (`quick_move_sheet.dart`), **Atla** (`markSkipped`); odak **“X dk odak”** rozeti |
| Özet | `lib/screens/summary/summary_screen.dart` | Hero’da **duygusal başlık** (`summary_hero_copy.dart`); trend, erteleme, aylık hedef özeti |
| Geçmiş / dışa aktarma | `lib/screens/history_export/history_export_screen.dart` | Geçmiş haftalar; export öncesi **önizleme kartı**; JSON/LLM, paylaş |
| Aylık hedefler | `lib/screens/monthly_goals/monthly_goals_screen.dart` | Üstte **sürekli inline** hedef ekleme satırı; haftaya görev ekleme |
| Ayarlar | `lib/screens/settings/settings_screen.dart` | Hatırlatıcılar; planlama; **Örnek veri yükle** (`demo_data_seeder.dart`); sıfırla |
| İlk açılış | `lib/widgets/onboarding_dialog.dart` | 3 slayt onboarding (`OnboardingStore`); testlerde otomatik tamamlanmış sayılır |

**Ortak UI:** `PlannerTopBar`, `WeekNavigationBar`, `BoardColumn`, `TaskCard`, `AddTaskSheet`, `EditTaskSheet`, `PlanShiftSheet`, `PlannerBottomNav`.

---

## Haftalık plan davranışı

- Hafta Pazartesi ISO tarihi (`week_calendar`, yerel gün) ile kimlenir; `WeekService.ensureWeekTasks` **otomatik görev kurallarından** (`recurring_templates`) havuza görev üretir.
- `planned_date` bu haftanın günlerinde değilse görev **havuzda** listelenir (kartta uyarı); üst sol ikon → takvimden hafta seçimi.
- Taşıma sayacı (`moved_count`, 🔥): sürükle-bırak ile gün/havuz değişince +1; 3+ taşımada “sık taşınıyor” snackbar. Alternatif: kart **Taşı** → `QuickMoveSheet` (gün/havuz chip).
- **Atla:** planlı görev `skipped`; turuncu ikon; tekrar dokununca `planned` (`unmarkSkipped`).
- Alt navigasyon: sekme değişiminde kısa **fade + scale** (`main_shell.dart`).
- Veri yenileme: `PlanDataRevision` dinleyicileri ile plan ekranı / özet / geçmiş senkron kalır; bazı akışlarda `bump()` çağrılır.
- Görev yaşam döngüsü ve senaryolar: `docs/senaryolar_gorev_akislari.md`, test: `test/scenarios/task_lifecycle_scenarios_test.dart`.
- Plan kaydır: `docs/senaryolar_plan_kaydir.md`, test: `test/scenarios/plan_kaydir_scenarios_test.dart`.

---

## Veri modeli (Drift tabloları)

- **`tasks`:** … + `reminder_enabled`, `reminder_minutes` (v9; etkinlik sheet’inde “Hatırlatıcı”).
- **`task_history`:** görev olay geçmişi (`event_type`, from/to, not).
- **`week_meta`:** hafta bazında `copy_from_previous_applied` (geçen hafta kopyası işareti).
- **`recurring_templates`:** her hafta otomatik eklenecek **tek etkinlik kuralları** (`RecurringTemplateRepository`); arayüz: “Her hafta otomatik görevler”.
- **`monthly_goals`:** … + `reminder_enabled`, `reminder_weekday` (1=Pzt…7=Paz), `reminder_minutes` (v9; hedef satırında çan ikonu).
- **`week_templates` / `week_template_tasks`:** (şema 6) **kayıtlı hafta planı** (çoklu görev); manuel uygulama `WeekTemplateService.applyTemplate`; `WeekTemplateRepository`, ekran: `lib/screens/week_templates/`, rota: `/settings/templates`, `/settings/templates/:templateId`.

İş kuralları ve sorgular: `lib/data/repositories/task_repository.dart`, `monthly_goal_repository.dart`, …

**Hatırlatıcılar (v9):** `ReminderSettingsStore` (SP: ana anahtar, günlük özet açık/saat). `ReminderSchedulerService` plan revizyonunda tüm zamanlamaları yeniler; tamamlanan/silinen görevlerin bildirimleri iptal edilir. Etkinlik: havuz + günlük sütun sheet’lerinde toggle+saat. Ayarlar: “Hatırlatıcılar”, “Günlük özet” (ör. her gün 08:00 bugünün işleri).

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
