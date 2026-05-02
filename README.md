# weekly_planner

A new Flutter project.

## MVP plan notları

- **copyLastWeekTasks / şablon:** `copyLastWeekTasks` çalışmadan önce `ensureWeekTasks` aynı şablon için havuza görev üretmişse, kopyalama sonrası aynı şablondan iki görev olabilir. MVP’de kullanıcı bilinçli kopya basıyor, kabul edilebilir. **İleride:** kopya öncesi şablon kaynaklı havuz görevlerini sil veya dedup.

## Teknik borç listesi (şu an)

- `_loadTasks` manuel `setState` pattern — Riverpod stream’e geçilmeli
- `tomorrowIsoForMove` havuzda `null` `plannedDate` için takvim yarını kullanıyor — mevcut haftayla ilişkilendirilmeli
- Kategori alanı yok — kart şeridi durum rengi proxy’si
- `ensureWeekTasks` N şablon için N ayrı sorgu — toplu sorguya çevrilebilir
- Kopya + `ensureWeekTasks` aynı şablondan iki görev üretebilir

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
