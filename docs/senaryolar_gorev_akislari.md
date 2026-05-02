# Görev akışları — test ve kabul senaryoları

Plan ekranında **ekleme**, **taşıma (sürükle)**, **tamamlandı işareti**, **geri alma**, **düzenle / sil** akışları. Otomasyon: `test/scenarios/task_lifecycle_scenarios_test.dart`.

---

## T1 — FAB ile etkinlik ekleme

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Haftalık plan sekmesi açık. |
| **Adımlar** | FAB → başlık gir → (gerekirse kaydır) Kaydet. |
| **Beklenen** | Sheet kapanır; “Etkinlik eklendi”; havuzda veya planda başlık görünür. |

---

## T2 — Planlı etkinliği sürükleyerek Havuz’a taşıma

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Bir günde planlı etkinlik var. |
| **Adımlar** | Kartı uzun basıp **Havuz** sütununa bırak. |
| **Beklenen** | “Etkinlik taşındı”; `planned_date` boş, görev havuzda. |

---

## T3 — Planlı etkinliği tamamlandı işaretleme

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Gün sütununda `planned` etkinlik. |
| **Adımlar** | Karttaki daire (checkbox) alanına dokun. |
| **Beklenen** | Durum `done`; yeşil tamamlandı ikonu / geri al alanı görünür. |

---

## T4 — Tamamlandıyı geri alma

| Alan | İçerik |
|------|--------|
| **Ön koşul** | T3 sonrası aynı etkinlik `done`. |
| **Adımlar** | Tamamlandı ikonuna (geri al) dokun. |
| **Beklenen** | Durum yeniden `planned`; checkbox tekrar görünür. |

---

## T5 — Tamamlandıktan sonra düzenleme sayfasından silme

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Planlı etkinlik `done` (T3). |
| **Adımlar** | Başlığa dokun → düzenleme sheet → Sil → onay **Sil**. |
| **Beklenen** | “Etkinlik silindi”; görev veritabanından yok; listede yok. |

---

## T6 — Havuz etkinliğini düzenleme sayfasından silme

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Havuzda `planned` etkinlik. |
| **Adımlar** | Başlığa dokun → Sil → onay. |
| **Beklenen** | Görev silinir; başlık kaybolur. |

---

## Otomasyon eşlemesi

| Senaryo | Test (özet ad) |
|---------|----------------|
| T1 | `T1 FAB ile etkinlik ekleme` |
| T2 | `T2 planlı etkinliği Havuza sürükleyerek taşıma` |
| T3 | `T3 planlı etkinlikte tamamlandı işareti` |
| T4 | `T4 tamamlandı geri alınır` |
| T5 | `T5 tamamlandı sonra düzenlemeden silme` |
| T6 | `T6 havuz etkinliği düzenlemeden silme` |

İzole `TaskCard` davranışı: `test/widgets/task_card_test.dart`. Repo: `test/data/task_repository_test.dart`.
