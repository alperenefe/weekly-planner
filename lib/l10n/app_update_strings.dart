/// Uzaktan guncelleme — PC kablosuz adb (telefonda indirme yok).
abstract final class AppUpdateStrings {
  static const section = 'Uzaktan güncelleme';
  static const hint =
      'Telefonda indir/kur yok. Ev PC\'de (Tailscale):\n'
      'fast-phone.ps1 -Project weekly -Wireless\n'
      'İlk kurulum: phone-adb-setup.ps1 (USB bir kez).';
}
