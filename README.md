# Haftalık Plan (`weekly_planner`)

Kişisel **haftalık plan** uygulaması: görevleri havuzda ve Pazartesi–Pazar sütunlarında yönetir; tamamlama, taşıma, düzenleme, geçen haftadan kopya, plan kaydırma, aylık hedefler, özet ve dışa aktarma sunar. **Tamamen çevrimdışı** çalışır; veriler cihazda **SQLite** (Drift) ile saklanır, özellik anahtarları **SharedPreferences** ile tutulur. Arayüz metinleri çoğunlukla **Türkçe**; mağaza / paket adı `weekly_planner`, görünen uygulama adı **Haftalık Plan**.

---

## Özellikler (özet)

| Alan | İçerik |
|------|--------|
| Plan tahtası | Havuz + 7 gün; hafta ileri/geri; ekleme; sürükle-bırak; arama (bayrak); “bugün” özeti; tekrarlayan şablonlar |
| Özet | Haftalık özet, trend, erteleme analizi, aylık hedef özeti |
| Geçmiş / dışa aktarma | Geçmiş haftalar; JSON / LLM metni; pano ve paylaşım |
| Aylık hedefler | Ay bazlı hedefler; haftaya görev bağlama |
| Haftalık şablonlar | Ön tanımlı hafta planları (Ayarlar altından şablon ekranları) |
| Ayarlar | Hakkında, özellik bayrakları, tüm veriyi sıfırla |

Özellik sekmeleri ve menü öğeleri **özellik bayrakları** ile açılıp kapanabilir (varsayılanlar açık). Ayrıntılı tablo ve dosya yolları için **[docs/UYGULAMA.md](docs/UYGULAMA.md)**.

---

## Gereksinimler

- **Flutter** sürümü, `pubspec.yaml` içindeki **Dart SDK** kısıtıyla uyumlu olmalı (`environment.sdk`, şu an `^3.10.8`).
- **Android** hedefi aktif geliştirilir; iOS launcher yapılandırması `pubspec` içinde kapalı.

---

## Hızlı başlangıç

Proje kökünde:

```bash
flutter pub get
flutter run
```

Kod üretimi (Drift / `build_runner` değiştiyse veya şema güncellendiyse):

```bash
dart run build_runner build --delete-conflicting-outputs
```

Statik analiz ve testler:

```bash
dart analyze
flutter test
```

---

## Derleme (Android)

```bash
flutter build apk
```

Yükleme (cihaz bağlıyken):

```bash
flutter install
```

---

## Launcher ikonu (Android)

Kaynak görsel: `assets/app_icon/app_icon_source.png`. İkonları yeniden ürettikten sonra adaptive ön planda **dar (3×4 hissi)** kalsın diye XML’in güncellenmesi gerekir:

```bash
dart run flutter_launcher_icons
dart run tool/apply_adaptive_icon_slim.dart
```

İkinci komut, `flutter_launcher_icons` paketinin `ic_launcher.xml` üzerinde yaptığı varsayılan geri yazmayı düzeltir; `foreground` tekrar `@drawable/ic_launcher_foreground_slim` kullanır.

---

## Dokümantasyon

| Dosya | Amaç |
|--------|------|
| [docs/UYGULAMA.md](docs/UYGULAMA.md) | Mimari, router, bayraklar, ekranlar, veri modeli, dosya haritası (ekip / LLM bağlamı) |
| [docs/senaryolar_gorev_akislari.md](docs/senaryolar_gorev_akislari.md) | Görev yaşam döngüsü senaryoları |
| [docs/senaryolar_plan_kaydir.md](docs/senaryolar_plan_kaydir.md) | Plan kaydırma senaryoları |

---

## Mimari (kısa)

- **Durum:** `provider` (`MultiProvider` kökte).
- **Yönlendirme:** `go_router`, `StatefulShellRoute.indexedStack` — dallar: plan, özet, geçmiş, hedefler, ayarlar (`/plan`, `/summary`, `/history`, `/goals`, `/settings`).
- **Veri:** Drift + `sqlite3_flutter_libs`; şema ve tablolar `lib/data/db/app_database.dart`.
- **Giriş:** `lib/main.dart` veritabanı ve servisleri kurar; `lib/app.dart` tema ve router’ı bağlar.

Tam yönlendirme kuralları, shell indeksleri ve bayrak tablosu için yine **UYGULAMA.md** kullanılır.

---

## Proje yapısı (özet)

```
lib/
  main.dart, app.dart
  router/app_router.dart
  config/planner_feature_flags.dart
  nav/planner_nav_spec.dart
  data/db/, data/repositories/
  services/
  screens/{weekly_plan,shell,summary,history_export,monthly_goals,settings,week_templates,recurring_templates}/
  widgets/, theme/, date/, models/
test/
assets/app_icon/
android/   # adaptive ikon + slim foreground drawable
tool/      # apply_adaptive_icon_slim.dart
```

---

## Bilinen sınırlamalar ve teknik borç

- **Geçen hafta kopyası + şablon:** Kopyadan önce `ensureWeekTasks` aynı şablondan havuza görev üretmişse, kopya sonrası aynı şablondan iki görev oluşabilir (MVP’de kullanıcı bilinçli kopya kullanır; ileride dedup veya kopya öncesi havuz temizliği düşünülebilir).
- **`_loadTasks`:** Manuel `setState` deseni — ileride reaktif akış (ör. stream tabanlı) tercih edilebilir.
- **`tomorrowIsoForMove`:** Havuzda `plannedDate` yokken takvim “yarını” kullanır — hafta bağlamıyla sıkılaştırılabilir.
- **`ensureWeekTasks`:** Birden çok şablon için ayrı sorgular — toplu sorguya indirilebilir.

---

## Lisans / yayın

`publish_to: 'none'` — özel / yerel paket; pub.dev’e yayınlanmaz.

---

*Detaylı davranış ve dosya satırı düzeyi referans için önce [docs/UYGULAMA.md](docs/UYGULAMA.md) okunmalıdır.*
