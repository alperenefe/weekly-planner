# Plan kaydır — test ve kabul senaryoları

Bu dosya **Günlük planı kaydır** (mola / kaydırma) akışı için ön koşul, adım ve beklenen sonuçları tanımlar. Geliştirme veya manuel QA sırasında referans olarak kullanılabilir.

---

## S1 — Menüden sheet açılması

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Ayarlarda “Günlük planı kaydır” açık. Haftalık plan ekranı görünür. |
| **Adımlar** | 1) Üç nokta menüsüne dokun. 2) “Günlük planı kaydır” öğesine dokun. |
| **Beklenen** | Alt sheet açılır; başlık “Günlük planı kaydır”; gün chip’leri (Pzt–Paz) görünür. |

---

## S2 — Bugün cumartesi, öğleden sonra; sabah etkinlikleri çapa olarak görünür

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Görüntülenen hafta içinde **bugün** cumartesi. O gün için 09:00, 10:00, 11:00 başlangıçlı saatli etkinlikler var. Cihaz saati öğleden sonra (ör. 16:09). |
| **Adımlar** | 1) Günlük planı kaydır sheet’ini aç. 2) Gün olarak **Cmt** seçili olsun (varsayılan bugün ise dokunma gerekmez). |
| **Beklenen** | Çapa alanında **09:00, 10:00, 11:00** chip’leri görünür. “Bu gün için uygun çapa yok…” metni **görünmez**. **Uygula** etkindir (dakika > 0 iken). |

---

## S3 — Gün değiştirince çapalar o güne göre yenilenir

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Aynı haftada Salı ve Perşembe günleri için farklı başlangıç saatli etkinlikler var. |
| **Adımlar** | 1) Sheet’i aç. 2) **Sal** chip’ine dokun. 3) Çapaları not al. 4) **Per** chip’ine dokun. |
| **Beklenen** | Her seçimde çapa listesi yalnızca **seçilen günün** etkinlik `startMinutes` değerlerine göre güncellenir; başka günün saatleri görünmez. |

---

## S4 — Aynı başlangıç saatinde birden fazla etkinlik

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Bir günde iki etkinlik aynı başlangıç saatinde (ör. ikisi de 10:00). |
| **Adımlar** | O günü seç; çapa listesine bak. |
| **Beklenen** | **10:00** yalnızca **bir** chip olarak görünür. |

---

## S5 — Saatli etkinlik yok

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Seçilen günde planlı etkinlik yok veya hepsinin `startMinutes` değeri yok. |
| **Adımlar** | O günü seç. |
| **Beklenen** | “Bu gün için uygun çapa yok…” bilgisi görünür. **Uygula** kapalıdır. |

---

## S6 — Takvimde geçmiş gün (chip seçilemez)

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Görüntülenen haftada bugünden önceki günler var (ör. bugün cuma; pzt–per geçmiş). |
| **Adımlar** | Sheet’te **Pzt** chip’ine dokunmayı dene. |
| **Beklenen** | Geçmiş gün chip’leri seçilemez (pasif). Yalnızca bugün ve gelecek günler seçilebilir. |

---

## S7 — Uygula: kaydırma sayısı ve tahta yenilenmesi

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Seçilen günde çapa C ve dakika D (ör. 30) ile en az bir etkinlik `startMinutes >= C` olacak şekilde planlı. |
| **Adımlar** | 1) Çapa ve dakikayı seç. 2) **Uygula**’ya dokun. |
| **Beklenen** | Sheet kapanır; snackbar’da kaydırılan etkinlik sayısı uygun metinle gösterilir; haftalık plandaki ilgili gün sütunu güncellenir (başlangıç saatleri D kadar ileri). |

---

## S8 — Kaydırılacak etkinlik yok

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Seçilen günde tüm saatli etkinlikler çapadan **önce** başlıyor (hepsi `startMinutes < çapa`). |
| **Adımlar** | Çapa ve dakikayı seç; **Uygula**. |
| **Beklenen** | “Kaydırılacak etkinlik yok” benzeri geri bildirim; veri tutarlı kalır. |

---

## S9 — Özellik kapalı

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Ayarlarda “Günlük planı kaydır” kapalı. |
| **Adımlar** | Üç nokta menüsünü aç. |
| **Beklenen** | Menüde **“Günlük planı kaydır”** görünmez; **“Listeyi yenile”** görünmeye devam edebilir. |

---

## S10 — Listeyi yenile (menü)

| Alan | İçerik |
|------|--------|
| **Ön koşul** | Haftalık plan ekranı. |
| **Adımlar** | Üç nokta → **Listeyi yenile**. |
| **Beklenen** | Hafta verisi yeniden yüklenir (tahta/görev listesi güncel kaynaktan gelir). |

---

## Otomasyon eşlemesi

Tüm senaryolar için otomatik testler: **`test/scenarios/plan_kaydir_scenarios_test.dart`**

| Senaryo | Test adı (özet) |
|---------|------------------|
| S1 | `S1 menüden sheet açılır…` |
| S2 | `S2 cumartesi öğleden sonra…` |
| S3 | `S3 Sal ve Per seçilince…` |
| S4 | `S4 aynı başlangıç saatinde…` |
| S5 | `S5 saatli görev yoksa…` |
| S6 | `S6 geçmiş gün chip’i…` |
| S7 | `S7 Uygula snackbar ve veritabanında…` |
| S8 | `S8 (repo)` grubu — çapa sonrası görev yoksa 0 |
| S9 | `S9 özellik kapalıyken…` |
| S10 | `S10 Listeyi yenile…` |

Ek repo kapsamı: `test/data/task_repository_test.dart` içinde `shiftPlannedDayTasksAfterAnchor`.

---

## Versiyon

- Dosya, plan kaydır sheet’inin **görev başlangıçlarından çapa** ve **gün seçimi** davranışına göre yazılmıştır. Ürün kuralları değişirse senaryolar güncellenmelidir.
