import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🧠 Persistance d'identité locale
import 'dashboard.dart';
import 'ecran_enregistrement.dart';

void main() async {
  // 🛡️ VERROU DE SÉCURITÉ : Assure l'ancrage matériel des liaisons d'OS mobiles
  WidgetsFlutterBinding.ensureInitialized();

  // 📡 CORRECTION CLOUD DIRECTE : Initialisation étanche sans scorie d'URL
  await Supabase.initialize(
    url: 'https://supabase.co', // Adresse sécurisée RJ sanctuarisée
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudnVqbGpnemhud3Fjb3VrdW5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTY4NDA4OTIsImV4cCI6MjAzMjQxNjg5Mn0.123456_fake_key_for_TP', // Clé anonyme d'acier
  );

  // 🗄️ PERSISTANCE FORENSIQUE : Vérification de la présence d'une puce gérant en mémoire flash
  final SharedPreferences memoireLocale = await SharedPreferences.getInstance();
  final String? telephoneIdentifie =
      memoireLocale.getString('telephone_gerant');

  runApp(SwintelBaseApp(telephoneIdentifie: telephoneIdentifie));
}

class SwintelBaseApp extends StatelessWidget {
  final String? telephoneIdentifie;

  const SwintelBaseApp({super.key, this.telephoneIdentifie});

  @override
  Widget build(BuildContext context) {
    // 🎨 DIRECTION DE L'ARCHITECTURE : Choix linguistique dynamique universel
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // Éjection des béquilles de laboratoire
      title: 'SWINTEL FLEET',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true, // Calibré pour le SDK Android 36
      ),

      // 🔄 ROUTAGE AUTOMATIQUE ASYNC SANS INTERMÉDIAIRE :
      // Si la puce téléphone est en flash ➔ Propulsion directe sur le Dashboard
      // Si la RAM disque est vierge ➔ Téléportation sur l'Écran d'Enregistrement Jaune
      home: telephoneIdentifie != null && telephoneIdentifie!.isNotEmpty
          ? DashboardScreen(idUtilisateur: telephoneIdentifie!)
          : const EcranEnregistrementScreen(),
    );
  }
}
