# CI/CD: GitHub Actions → Firebase App Distribution

**Repo:** [alperenefe/weekly-planner](https://github.com/alperenefe/weekly-planner)  
**Android paket adı:** `com.weeklyplanner.weekly_planner`

Müzik Teorisi ile aynı akış: yalnızca **Actions → Run workflow** ile APK derlenir ve Firebase’e gider.

---

## Müzik Teorisi’nden ne tekrarlanır?

Aynı Firebase projesini (`music-trainer-90e39`) kullanabilirsin:

| Secret | Bu repo için |
|--------|----------------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | **Aynı JSON** (music_theory_trainer’daki gibi) |
| `FIREBASE_TESTER_GROUPS` | **Aynı** — örn. `testers` |
| `FIREBASE_ANDROID_APP_ID` | **Farklı** — Weekly Planner Android uygulamasının App ID’si |
| `GOOGLE_SERVICES_JSON` | İsteğe bağlı; bu uygulama için indirdiğin `google-services.json` |

Service account ve **Firebase App Testers API** bir kez açıldıysa tekrar gerekmez.

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

1. `git push` — otomatik APK **yok**.
2. Actions → **Android Firebase Distribute** → **Run workflow** (~10–15 dk).
3. Telefonda Firebase maili / link → **Kur**.

Sürüm: `versionName` = `pubspec.yaml`; `versionCode` = workflow run numarası.

---

## Yerel hızlı kurulum

```powershell
cd c:\cursorProjects\weekly_planner
flutter build apk --release
adb install -r build\app\outputs\flutter-apk\app-release.apk
```
