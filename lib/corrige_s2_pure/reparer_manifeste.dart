import 'dart:io'; // 🧠 INDISPENSABLE : Accès direct aux disques physiques du Chromebook

void main() {
  print(
      "🛠️ SWINTEL MAINTENANCE — AMORÇAGE DU PIPELINE DE SÉCURITÉ DU MANIFESTE...");

  // 🎯 RECTIFICATION DIRECTE : Utilisation exclusive du chemin relatif d'arborescence universel
  final String cheminManifeste = 'android/app/src/main/AndroidManifest.xml';
  final File fichierManifeste = File(cheminManifeste);

  // 🛡️ VERROU DE SÉCURITÉ : Vérification de la présence matérielle du fichier cible
  if (!fichierManifeste.existsSync()) {
    print(
        "❌ CRITICAL ERROR : Le fichier système AndroidManifest.xml est introuvable à l'adresse spécifiée.");
    print(
        "💡 VIGILANCE APPRENANT : Assurez-vous d'exécuter ce script à la racine de votre projet Google IDX.");
    exit(1); // Arrêt immédiat du processus de build avec code d'erreur matériel
  }

  try {
    // 🩻 SCAN FORENSIQUE : Lecture brute de l'intégralité du fichier XML en RAM
    String contenuOriginal = fichierManifeste.readAsStringSync();
    String contenuModifie = contenuOriginal;

    print(
        "🔍 ANALYSE DES COMPOSANTS MATÉRIELS ET INJECTEURS DE PERMISSIONS...");

    // 🏆 INJECTION COUTURE PERMISSION 1 : Le capteur satellitaire GPS (UE 203 / UE 204)
    if (!contenuOriginal.contains('android.permission.ACCESS_FINE_LOCATION')) {
      print(
          "➕ Injection de la permission : ACCESS_FINE_LOCATION (Filet GPS)...");
      contenuModifie = contenuModifie.replaceFirst(
        '<manifest',
        '<manifest\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>',
      );
    }

    // 🏆 INJECTION COUTURE PERMISSION 2 : La bobine vibrante maximale 255 (UE 204 / UE 205)
    if (!contenuOriginal.contains('android.permission.VIBRATE')) {
      print("➕ Injection de la permission : VIBRATE (Moteur haptique)...");
      contenuModifie = contenuModifie.replaceFirst(
        '<manifest',
        '<manifest\n    <uses-permission android:name="android.permission.VIBRATE"/>',
      );
    }

    // 🏆 INJECTION COUTURE PERMISSION 3 : Le microphone de dictée vocale AAC (UE 209)
    if (!contenuOriginal.contains('android.permission.RECORD_AUDIO')) {
      print("➕ Injection de la permission : RECORD_AUDIO (Capture micro)...");
      contenuModifie = contenuModifie.replaceFirst(
        '<manifest',
        '<manifest\n    <uses-permission android:name="android.permission.RECORD_AUDIO"/>',
      );
    }

    // ⚙️ BRIDAGE MATÉRIEL APPLICATION ANDROID GO CORES (Optimisation Android SDK 36)
    if (!contenuOriginal.contains('android:usesCleartextTraffic="true"')) {
      print("⚙️ Sécurisation des vannes de trafic internet Supabase Cloud...");
      contenuModifie = contenuModifie.replaceFirst(
        '<application',
        '<application\n        android:usesCleartextTraffic="true"',
      );
    }

    // 💥 SOUDURE FINALE ATOMIQUE : Écriture sur le disque physique du Chromebook
    if (contenuModifie != contenuOriginal) {
      fichierManifeste.writeAsStringSync(contenuModifie);
      print(
          "💾 RECONSTRUCTION DU MANIFESTE ACHEVÉE : Fichier XML stabilisé avec succès ✔️");
    } else {
      print(
          "🛡️ AUCUNE ANOMALIE DÉTECTÉE : Le fichier AndroidManifest.xml possède déjà toutes ses armures ✔️");
    }
  } catch (e) {
    print("🚨 FATAL UNEXPECTED ERROR DURANT LA FORGE DU MANIFESTE : $e");
    exit(1);
  }
}
