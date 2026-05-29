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

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('telephone_local', telSaisi);
      await prefs.setString(
          'nom_magasin_local', magasinTrouve['nom'] ?? 'Spécialiste');

      if (mounted) {
        _afficherSucces(isEnglish
            ? "Access granted! Radar active."
            : "Accès accordé ! Radar activé.");

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

  // ⌨️ FIXATION DES TOUCHES : Taille fixe absolue sans Expanded pour interdire la disparition graphique
  Widget _creerToucheClavier(String texte) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        width:
            75, // Largeur fixe mathématique pour aligner 3 boutons sur le Samsung
        height: 48, // Hauteur fixe réglementaire Android
        child: ElevatedButton(
          onPressed: () => _ajouterChiffre(texte),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.withOpacity(0.2),
            foregroundColor: Colors.black,
            elevation: 1,
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(texte,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.radar, size: 50, color: Colors.orange),
              const SizedBox(height: 5),
              const Text(
                'SWINTEL',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3),
              ),
              const SizedBox(height: 15),

              Text(
                isEnglish
                    ? 'ENTER YOUR NETWORK PHONE NUMBER ...:'
                    : 'ENTREZ LE NUMÉRO DE TÉLÉPHONE DE VOTRE BOUTIQUE ??? :',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey),
              ),
              const SizedBox(height: 10),

              // 📳 CHAMP DE VISUALISATION SÉCURISÉ
              TextField(
                controller: _telController,
                readOnly:
                    true, // Bloque de force l'ouverture du clavier natif défaillant
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.orange),
                decoration: InputDecoration(
                  hintText: '6XXXXXXXX',
                  hintStyle:
                      const TextStyle(color: Colors.grey, letterSpacing: 1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              // 🎛️ GRILLE DE SAISIE TACTILE AUTONOME UNIVERSELLE
              Center(
                child: Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        _creerToucheClavier('1'),
                        _creerToucheClavier('2'),
                        _creerToucheClavier('3')
                      ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        _creerToucheClavier('4'),
                        _creerToucheClavier('5'),
                        _creerToucheClavier('6')
                      ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        _creerToucheClavier('7'),
                        _creerToucheClavier('8'),
                        _creerToucheClavier('9')
                      ]),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton retour rouge aligné
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SizedBox(
                              width: 75,
                              height: 48,
                              child: IconButton(
                                onPressed: _effacerDernierChiffre,
                                icon: const Icon(Icons.backspace,
                                    color: Colors.red, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                          ),
                          _creerToucheClavier('0'),
                          // Boîtier vide d'équilibrage graphique
                          const SizedBox(width: 83),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🚀 BOUTON DE VALIDATION CLOUD
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isVerifying ? null : _validerEtEnregistrerLeGerant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEnglish ? 'ACTIVATE MY RADAR' : 'ACTIVER MON RADAR',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
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
