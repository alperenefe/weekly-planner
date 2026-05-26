# Eksik ama önemli testler

Mevcut kapsam: repo/servis unit testleri, görev yaşam döngüsü (T1–T6), plan kaydır (S1–S7), widget smoke, kısmi integration smoke (`integration_test/app_smoke_test.dart`).

Aşağıdakiler **henüz yok** veya **yetersiz**; öncelik üstten alta.

---

## P0 — Veri bütünlüğü / kayıp riski

| # | Senaryo | Tür | Beklenen |
|---|---------|-----|----------|
| 1 | **Şema v2→v8 sıralı upgrade** | Unit | Her ara sürüm fixture’ı (v2, v3, … v7) açılınca veri + tablolar korunur |
| 2 | **Prod DB dosyasından upgrade** | Integration (manuel/CI) | Gerçek `weekly_planner.sqlite` yedeği ile açılış |
| 3 | **`resetAllData` sonrası** tüm tablolar (monthly_goals, week_templates, recurring) | Unit | Zaten kısmen var; week_template_tasks satırları da boş |
| 4 | **`applyTemplate` iki kez** | Unit/Widget | Görev sayısı 2×; kullanıcı uyarısı sonrası onay |
| 5 | **Görev silinince `task_history`** | Unit | Orphan history kalmamalı (mevcut delete test genişlet) |
| 6 | **Odak: uygulama kill → yeniden aç** | Integration (cihaz) | Aktif oturum + kısmi süre devam |
| 7 | **Odak: alarm süresi dolunca** | Unit/Widget | alarming → acknowledge → remaining=0 |

---

## P1 — Ürün davranışı / bayraklar

| # | Senaryo | Tür | Beklenen |
|---|---------|-----|----------|
| 8 | **Router redirect** tüm bayraklar | Widget | summary/history/goals/recurring/templates kapalı → `/plan` veya `/settings` |
| 9 | **`weekTemplatesEnabled` kapalı** planda düğme + ayarlar satırı | Widget | Gizli (kısmen eklendi) |
| 10 | **`copyLastWeekEnabled` kapalı** | Widget/Servis | Kopyala snackbar/aksiyon yok |
| 11 | **`planShiftEnabled` kapalı** | Widget | Menüde kaydır yok |
| 12 | **`planBoardSearchEnabled` kapalı** | Widget | Arama UI sıfırlanır |
| 13 | **Boş hafta** | Widget | Havuz placeholder, FAB çalışır |
| 14 | **Hafta sınırı** (Pazar→Pazartesi nav) | Unit | `week_start` ve görevler doğru haftada |
| 15 | **`planned_date` hafta dışı** | Unit | `chipIndexForPlannedDate` havuza düşmez (ürün kararı) |
| 16 | **Geçen haftayı kopyala — ikinci kez** | Unit/Widget | İkinci kopya yok / snackbar |
| 17 | **Tekrarlayan kural: aynı hafta iki kez** | Unit | `hasTaskForRecurrenceInWeek` |
| 18 | **Tekrarlayan kural: pasif** | Unit | Yeni haftada üretilmez |
| 19 | **Export JSON içeriği** | Unit | tasks + history + meta alanları |
| 20 | **Export LLM metin** | Unit | Türkçe özet, boş hafta |
| 21 | **Özet ekranı** boş / dolu hafta | Widget | Stat grid, trend |
| 22 | **Aylık hedefler** ekle/tamamla/sil | Widget | order_index, özet kartı |

---

## P1 — Odak süresi (görev bazlı)

| # | Senaryo | Tür | Beklenen |
|---|---------|-----|----------|
| 23 | **Kartta "X dk kaldı" chip** | Widget | `task_focus_remaining_{id}` |
| 24 | **Düzenleme: Devam et (X dk kaldı)** | Widget | Seed prefs (kısmen var) |
| 25 | **Çalışırken alt bar** | Widget | Kalan + Durdur |
| 26 | **Başka göreve geçince** önceki duraklar | Unit | pause + yeni start |
| 27 | **`done` görevde odak başlamaz** | Unit | start() erken çıkış |
| 28 | **Testlerde `pumpAndSettle` takılması** | Altyapı | Bounded pump / ticker kapalı (kısmen) |

---

## P2 — UX / kenar

| # | Senaryo | Tür | Beklenen |
|---|---------|-----|----------|
| 29 | **3. taşıma snackbar** | Widget | moved_count ≥ 3 |
| 30 | **Plan kaydır S2–S7** | Widget | `plan_kaydir_scenarios` tamamı yeşil |
| 31 | **Sürükle-bırak günler arası** | Widget | planned_date güncellenir |
| 32 | **Düzenle: gün/saat/süre/renk** | Widget | DB persist |
| 33 | **Hafta şablonu detay tahta** | Widget | Havuz/gün sürükle |
| 34 | **Bildirim izni reddedildi** | Integration | Odak yine çalışır (graceful) |
| 35 | **Google Fonts offline** | Widget | Fallback font |
| 36 | **Çok görevli hafta (200+)** | Perf | Yükleme < eşik (manuel benchmark) |

---

## Integration / E2E (cihaz veya `integration_test`)

| # | Senaryo | Not |
|---|---------|-----|
| I1 | Soğuk açılış plan | Var (1) |
| I2 | FAB ekleme | Var (2) |
| I3 | Bayraklar UI | Var (3, 3b) — week_templates satırı eklendi |
| I4 | Tekrarlayan yeni hafta | Var (4) |
| I5 | Şablon uygula | Var (5) |
| I6 | Geçmiş sekmesi | Var (6) |
| I7 | Odak duraklat/devam | Var (7) — cihazda doğrula |
| I8 | **Hafta ileri/geri + kopyala** | Eksik |
| I9 | **Tamamla → geri al → sil** | Eksik |
| I10 | **Sıfırla onay** | Eksik |
| I11 | **Paylaşım / export** | Eksik (platform channel) |
| I12 | **Deep link `/settings/templates/:id`** | Eksik |

---

## Önerilen dosya yerleşimi

| Alan | Dosya önerisi |
|------|----------------|
| Migration | `test/data/app_database_migration_test.dart` (v1→v8 başladı) |
| Router/bayrak | `test/router/app_router_redirect_test.dart` |
| Odak | `test/widgets/task_focus_flow_test.dart` |
| Export | `test/services/export_service_test.dart` (genişlet) |
| E2E | `integration_test/app_smoke_test.dart` (8–12 ekle) |

---

## Manuel checklist (otomasyon dışı)

- Gece yarısı hafta değişimi (yerel saat)
- DST günü
- Release APK: `adb install -r` veri koruma
- Mağaza: bildirim + export gizlilik metni
