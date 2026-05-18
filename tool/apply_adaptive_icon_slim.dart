import 'dart:io';

void main() {
  const path = 'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml';
  File(path).writeAsStringSync(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '  <background android:drawable="@color/ic_launcher_background"/>\n'
    '  <foreground android:drawable="@drawable/ic_launcher_foreground_slim"/>\n'
    '</adaptive-icon>\n',
  );
}
