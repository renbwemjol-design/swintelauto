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

  @override
  void dispose() {
    _telController.dispose();
    super.dispose();
  }

  // 🧠 MECANISME CLAVIER TACTILE : Écrit le chiffre sur l'écran
  void _ajouterChiffre(String chiffre) {
    if (_telController.text.length < 9) {
      // Limite stricte à 9 chiffres pour Camp Yabassi
      setState(() {
        _telController.text += chiffre;
      });
    }
  }

  // 🧼 TOUCHE RETOUR : Efface le dernier caractère saisi
  void _effacerDernierChiffre() {
    if (_telController.text.isNotEmpty) {
      setState(() {
        _telController.text =
            _telController.text.substring(0, _telController.text.length - 1);
      });
    }
  }

  // 🎯 REQUÊTE D'AUTORITÉ : On cherche si le numéro existe dans ton dictionnaire Magasins
  Future<void> _validerEtEnregistrerLeGerant() async {
    final String telSaisi = _telController.text.trim();
    if (telSaisi.isEmpty) return;

    setState(() => _isVerifying = true);
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    try {
      // 🎯 REQUÊTE UNIFIÉE : On interroge ta table Magasins sécurisée
      final magasinTrouve = await _supabase
          .from('Magasins')
          .select('nom, telephone')
          .eq('telephone', telSaisi)
          .maybeSingle();

      if (magasinTrouve == null) {
        setState(() => _isVerifying = false);
        _afficherErreur(isEnglish
            ? "🚨 Number not recognized in SWINTEL network!"
            : "🚨 Numéro non reconnu dans le réseau SWINTEL !");
        return;
      }

      // 💾 ANCRAGE EN MÉMOIRE PHYSIQUE : Gravé de manière permanente dans l'appareil
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('telephone_local', telSaisi);
      await prefs.setString(
          'nom_magasin_local', magasinTrouve['nom'] ?? 'Spécialiste');

      if (mounted) {
        _afficherSucces(isEnglish
            ? "✅ Access granted! Radar active."
            : "✅ Accès accordé ! Radar activé.");

        // 🚀 PROPULSION : On bascule vers le radar de flotte universel durable
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

  // ⌨️ CONSTRUCTEUR VISUEL DES TOUCHES DE LA GRILLE TACTILE
  Widget _creerToucheClavier(String texte) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => _ajouterChiffre(texte),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black,
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(texte,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🚗 LOGO INDUSTRIEL SWINTEL
            const Icon(Icons.radar, size: 60, color: Colors.orange),
            const SizedBox(height: 5),
            const Text(
              'SWINTEL',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
            const SizedBox(height: 20),

            Text(
              isEnglish
                  ? 'ENTER YOUR NETWORK PHONE NUMBER :'
                  : 'ENTREZ LE NUMÉRO DE TÉLÉPHONE DE VOTRE BOUTIQUE :',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),

            // 📳 ZONE DE VISUALISATION (Désactivée en écriture pour bloquer le pavé gris Android)
            TextField(
              controller: _telController,
              readOnly:
                  true, // 👈 VERROU ABSOLU : Empêche Android d'ouvrir sa fenêtre fantôme !
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.orange),
              decoration: InputDecoration(
                hintText: '6XXXXXXXX',
                hintStyle:
                    const TextStyle(color: Colors.grey, letterSpacing: 1),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 15),

            // 🎛️ LE CLAVIER TACTILE MAISON DE SWINTEL (INFAILLIBLE ET UNIVERSEL)
            Column(
              children: [
                Row(children: [
                  _creerToucheClavier('1'),
                  _creerToucheClavier('2'),
                  _creerToucheClavier('3')
                ]),
                Row(children: [
                  _creerToucheClavier('4'),
                  _creerToucheClavier('5'),
                  _creerToucheClavier('6')
                ]),
                Row(children: [
                  _creerToucheClavier('7'),
                  _creerToucheClavier('8'),
                  _creerToucheClavier('9')
                ]),
                Row(
                  children: [
                    // Touche d'effacement à gauche
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: SizedBox(
                          height: 50,
                          child: IconButton(
                            onPressed: _effacerDernierChiffre,
                            icon:
                                const Icon(Icons.backspace, color: Colors.red),
                            style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[200]),
                          ),
                        ),
                      ),
                    ),
                    _creerToucheClavier('0'),
                    // Espace vide symétrique à droite
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 🚀 BOUTON DE PROPULSION ET D'ACTIVATION
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _validerEtEnregistrerLeGerant,
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
    );
  }
}
