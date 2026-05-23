import 'dart:io';

void main() {
  // Assemblage chirurgical vérifié caractère par caractère
  final String brique1 = "http://"; // 7 caractères
  final String brique2 = "schemas."; // 8 caractères
  final String brique3 = "android.com/"; // 12 caractères
  final String brique4 = "apk/res/"; // 8 caractères
  final String brique5 = "android"; // 7 caractères

  final String urlOfficielleVeritable =
      "$brique1$brique2$brique3$brique4$brique5";

  final List<String> lignes = [
    '<?xml version="1.0" encoding="utf-8"?>',
    '<manifest xmlns:android="$urlOfficielleVeritable">', // 👈 INJECTION BINAIRE SANS TRANSIT RÉSEAU
    '    <uses-permission android:name="android.permission.INTERNET"/>',
    '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>',
    '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>',
    '    <uses-permission android:name="android.permission.CAMERA"/>',
    '    <uses-permission android:name="android.permission.RECORD_AUDIO"/>',
    '    <application android:label="Reseau Pieces" android:icon="@mipmap/ic_launcher" android:name="\${applicationName}">',
    '        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop" android:theme="@style/LaunchTheme" android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|screenLayout|density|uiMode" android:hardwareAccelerated="true" android:windowSoftInputMode="adjustResize">',
    '            <intent-filter>',
    '                <action android:name="android.intent.action.MAIN"/>',
    '                <category android:name="android.intent.category.LAUNCHER"/>',
    '            </intent-filter>',
    '        </activity>',
    '        <meta-data android:name="flutterEmbedding" android:value="2"/>',
    '    </application>',
    '</manifest>'
  ];

  final fichier = File('android/app/src/main/AndroidManifest.xml');
  fichier.writeAsStringSync(lignes.join('\n'));
  print(
      '🎯 SÉCURITÉ MAXIMALE : L\'URL officielle a été assemblée en RAM et gravée !');
}
