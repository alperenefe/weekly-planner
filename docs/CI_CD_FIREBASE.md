# CI/CD: GitHub Actions → Firebase App Distribution

**Repo:** [alperenefe/weekly-planner](https://github.com/alperenefe/weekly-planner)  
**Android paket adı:** `com.weeklyplanner.weekly_planner`

Müzik Teorisi ile aynı akış: `deploy-remote.ps1` veya `[apk]` push → CI → Firebase.

## Uygulama içi güncelleme

Release APK açılışta güncellemeyi kontrol eder. **Ayarlar** ekranında «Güncellemeyi kontrol et». İlk seferde tester Google girişi; `GOOGLE_SERVICES_JSON` CI secret veya yerel `google-services.json` gerekir.

---

## Müzik Teorisi’nden ne tekrarlanır?

Firebase projesi: **`weekly-p`** (Müzik Teorisi’nden ayrı — kendi service account gerekir).

| Secret | Değer |
|--------|--------|
| `FIREBASE_ANDROID_APP_ID` | `1:348633660665:android:5ade7e4950bb2b9da7f628` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | **weekly-p** GCP projesinde oluşturulan SA JSON (Müzik’teki değil) |
| `FIREBASE_TESTER_GROUPS` | örn. `testers` |
| `GOOGLE_SERVICES_JSON` | İsteğe bağlı — `android/app/google-services.json` içeriği |

**Firebase App Testers API** → Google Cloud, proje **weekly-p** üzerinde etkin olmalı.

**Pipeline «Failed to authenticate»:** `weekly-p` → IAM → `firebase-adminsdk-fbsvc@...` (veya `github-firebase-distribute`) → rol **Firebase App Distribution Admin** ekle; APIs → **Firebase App Distribution API** etkin.

---

## Firebase (bir kez — bu uygulama)

1. [Firebase Console](https://console.firebase.google.com/) → **music trainer** (veya yeni proje).
2. **Add app** → Android → paket: `com.weeklyplanner.weekly_planner`.
3. **App Distribution** → bu uygulama için dağıtımı etkinleştir.
4. **Project settings → General** → Weekly Planner satırındaki **App ID** (`1:…:android:…`).
5. GitHub → [weekly-planner/settings/secrets/actions](https://github.com/alperenefe/weekly-planner/settings/secrets/actions) → secret’ları ekle.

---

## GitHub secret’ları

| Secret | Zorunlu |
|--------|---------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Evet |
| `FIREBASE_ANDROID_APP_ID` | Evet (bu uygulamaya özel) |
| `FIREBASE_TESTER_GROUPS` veya `FIREBASE_TESTER_EMAILS` | Biri |
| `GOOGLE_SERVICES_JSON` | Hayır |
| `ANDROID_KEYSTORE_*` | Hayır (debug imza ile başlar) |

---

## Dağıtım

| İstek | Komut |
|--------|--------|
| Sadece kod | `git push` veya `.\scripts\git-push.ps1` |
| Kod + APK | `.\scripts\git-push.ps1 -Deploy` |
| Commit ile APK | `git commit -m "… [apk]"` + `git push` |

~10–15 dk sonra Firebase maili / link → **Kur**.

Sürüm: `versionName` = `pubspec.yaml`; `versionCode` = workflow run numarası.

---

## Yerel hızlı kurulum

```powershell
cd c:\cursorProjects\weekly_planner
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```
