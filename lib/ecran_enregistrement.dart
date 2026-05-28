import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'swintel_radar.dart'; // Pour propulser le gérant sur le radar après validation

class EcranEnregistrementScreen extends StatefulWidget {
  const EcranEnregistrementScreen({super.key});

  @override
  State<EcranEnregistrementScreen> createState() =>
      _EcranEnregistrementScreenState();
}

class _EcranEnregistrementScreenState extends State<EcranEnregistrementScreen> {
  final _telController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isVerifying = false;

  // 🧠 LE COEUR INDUSTRIEL : Vérifie le numéro sur la table Magasins et l'ancre en RAM
  Future<void> _validerEtEnregistrerLeGerant() async {
    final String telSaisi = _telController.text.trim();
    if (telSaisi.isEmpty) return;

    setState(() => _isVerifying = true);
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    try {
      // 🎯 REQUÊTE D'AUTORITÉ : On cherche si le numéro existe dans ton dictionnaire Magasins
      final magasinTrouve = await _supabase
          .from('Magasins')
          .select('nom, telephone')
          .eq('telephone', telSaisi)
          .maybeSingle();

      if (magasinTrouve == null) {
        // Si le numéro n'est pas enregistré par l'admin dans la base
        setState(() => _isVerifying = false);
        _afficherErreur(isEnglish
            ? "🚨 Number not recognized in SWINTEL network!"
            : "🚨 Numéro non reconnu dans le réseau SWINTEL !");
        return;
      }

      // 💾 ANCRAGE PHYSIQUE : Le numéro et le nom de la boutique sont gravés dans le smartphone
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('telephone_local', telSaisi);
      await prefs.setString(
          'nom_magasin_local', magasinTrouve['nom'] ?? 'Spécialiste');

      if (mounted) {
        _afficherSucces(isEnglish
            ? "✅ Access granted! Radar active."
            : "✅ Accès accordé ! Radar activé.");

        // 🚀 PROPULSION : On bascule d'autorité vers le radar de flotte universel
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => SwintelRadarGate(idUtilisateur: telSaisi)),
        );
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      _afficherErreur("Erreur réseau Cloud : $e");
    }
  }

  void _afficherErreur(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _afficherSucces(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🚗 LOGO INDUSTRIEL SWINTEL
              const Icon(Icons.radar, size: 80, color: Colors.orange),
              const SizedBox(height: 15),
              const Text(
                'SWINTEL',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3),
              ),
              Text(
                isEnglish ? 'Réseau Pièces Afrique' : 'Réseau Pièces Afrique',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // CHRECONNAISSANCE DU GÉRANT
              Text(
                isEnglish
                    ? 'ENTER YOUR NETWORK PHONE NUMBER :'
                    : 'ENTREZ LE NUMÉRO DE TÉLÉPHONE DE VOTRE BOUTIQUE :',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey),
              ),
              const SizedBox(height: 15),

              // 📳 CHAMP DE SAISIE DU NUMÉRO DE FLOTTE
              TextField(
                controller: _telController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: '6XXXXXXXX',
                  hintStyle:
                      const TextStyle(color: Colors.grey, letterSpacing: 1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🚀 BOUTON DE PROPULSION ET D'ACTIVATION
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed:
                      _isVerifying ? null : _validerEtEnregistrerLeGerant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEnglish ? 'ACTIVATE MY RADAR' : 'ACTIVER MON RADAR',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
