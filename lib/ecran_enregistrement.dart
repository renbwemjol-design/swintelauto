import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart'; // 👈 IMPORTATION DU CAPTEUR SATELLITAIRE DE BASE
import 'package:shared_preferences/shared_preferences.dart'; // Pour figer la session locale
import 'dashboard.dart';
import 'ecran_admin.dart'; // 👈 POUR LE COMMUTATEUR DIRECTEUR SECRET

class EcranEnregistrementScreen extends StatefulWidget {
  const EcranEnregistrementScreen({super.key});

  @override
  State<EcranEnregistrementScreen> createState() =>
      _EcranEnregistrementScreenState();
}

class _EcranEnregistrementScreenState extends State<EcranEnregistrementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🪛 LES ENCRES DE TEXTE PROFESSIONNELLES
  final _nomBoutiqueController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _marqueController = TextEditingController(); // Ex: Toyota, Range Rover
  final _pieceController = TextEditingController(); // Ex: Amortisseur, Cardan
  final _adresseController = TextEditingController();

  double? _latMagasin;
  double? _lngMagasin;
  bool _isLocating = false;
  bool _isSaving = false;

  // 🎯 ARCHITECTURE DES RÔLES DÉFINITIVE : Traque du profil sélectionné à l'écran
  String _roleSaisi = 'gerant'; // Valeurs possibles : 'gerant' ou 'prospecteur'

  // 🧠 CAPTURE GPS DE SÉCURITÉ DE LA BOUTIQUE AVEC TIMEOUT IMMUNE
  Future<void> _capturerPositionMagasin() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _afficherMessage("📍 Permission GPS requise pour localiser la boutique",
            Colors.orange);
        setState(() => _isLocating = false);
        return;
      }

      // On accorde un maximum de 3 secondes à la puce pour accrocher le satellite
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit:
            const Duration(seconds: 3), // 👈 FILET DE SÉCURITÉ ANTI-FREEZE
      );

      setState(() {
        _latMagasin = position.latitude;
        _lngMagasin = position.longitude;
        _isLocating = false;
      });
      _afficherMessage("📍 Emplacement du magasin capturé !", Colors.green);
    } catch (e) {
      setState(() {
        _latMagasin = 4.0510; // Repli d'autorité sur Camp Yabassi
        _lngMagasin = 9.7679;
        _isLocating = false;
      });
      _afficherMessage(
          "⚠️ Signal satellite faible. Coordonnées de Camp Yabassi appliquées",
          Colors.blueGrey);
    }
  }

  // 🚀 INTERCONNEXION SUPABASE : Inscription de la boutique dans le réseau mondial
  Future<void> _activerMonMagasin() async {
    final String nom = _nomBoutiqueController.text.trim();
    final String tel = _telephoneController.text.trim();
    final String marque = _marqueController.text.trim();
    final String piece = _pieceController.text.trim();
    final String adresse = _adresseController.text.trim();

    if (nom.isEmpty || tel.isEmpty || marque.isEmpty || piece.isEmpty) {
      _afficherMessage("⚠️ Veuillez remplir tous les champs obligatoires (*)",
          Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. SÉCURITÉ GPS : Si le gérant n'a pas cliqué sur le bouton GPS, on force le repli
      final double latitudeFinale = _latMagasin ?? 4.0510;
      final double longitudeFinale = _lngMagasin ?? 9.7679;

      // 2. INCORPORATION CLOUD : Insertion chirurgicale dans la table Magasins
      await _supabase.from('Magasins').insert({
        'nom': nom,
        'specialite_marque': marque,
        'specialite_type': piece,
        'telephone': tel,
        'adresse': adresse.isEmpty ? "Camp Yabassi, Douala" : adresse,
        'lat': latitudeFinale,
        'lng': longitudeFinale,
        'statut': 'actif', // Le magasin entre immédiatement en service actif !
      });

      // 3. ENREGISTREMENT LOCAL & CONFIGURATION SUR MESURE DU RÔLE SÉLECTIONNÉ
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'swintel_role', _roleSaisi); // Fige le rôle choisi définitivement

      // On ne fige la session permanente du terminal que si l'utilisateur est un vrai gérant indépendant
      if (_roleSaisi == 'gerant') {
        await prefs.setString('telephone_local', tel);
        await prefs.setString('nom_magasin_local', nom);
      }

      _afficherMessage("🎉 Activation Swintel réussie ! Bienvenue au goudron.",
          Colors.green);

      if (mounted) {
        setState(() => _isSaving = false);

        // 🎯 AIGUILLAGE CHIRURGICAL ET DÉFINITIF DU FLUX DE TERRAIN
        if (_roleSaisi == 'prospecteur') {
          // PROSPECTEUR : Boucle infinie. On purge l'affichage pour le magasin suivant.
          _nomBoutiqueController.clear();
          _telephoneController.clear();
          _marqueController.clear();
          _pieceController.clear();
          _adresseController.clear();
          setState(() {
            _latMagasin = null;
            _lngMagasin = null;
          });
          _afficherMessage(
              "🔄 Nettoyage ok. Prêt pour enrôler la boutique suivante !",
              Colors.indigo);
// 1111111
        } else {
          // 🏆 GÉRANT STANDARD : VERROUILLAGE ET SALLE D'ATTENTE RÉGLEMENTAIRE
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.lock_clock, color: Colors.orange),
                  SizedBox(width: 10),
                  Text("Dossier en Examen",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Text(
                "Félicitations $nom !\n\nVotre boutique a été pré-enregistrée au statut ACTIF.\n\nL'administration de SWINTEL procède à la certification de vos coordonnées GPS et de vos stocks. Vous aurez accès au tableau de bord dès validation.",
                style: const TextStyle(fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _nomBoutiqueController.clear();
                    _telephoneController.clear();
                    _marqueController.clear();
                    _pieceController.clear();
                    _adresseController.clear();
                  },
                  child: const Text("COMPRIS, J'ATTENDS LA VALIDATION",
                      style: TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }

        //2222222222
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _afficherMessage(
            "🚨 Erreur d'activation : ${e.toString().split('\n').first}",
            Colors.red);
        debugPrint("Détail crash enregistrement : $e");
      }
    }
  }

  void _afficherMessage(String msg, Color couleur) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: couleur,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomBoutiqueController.dispose();
    _telephoneController.dispose();
    _marqueController.dispose();
    _pieceController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () {
            // 🎯 INTERRUPTEUR TEXTUEL SECRET DU DIRECTEUR : Ouverture d'autorité !
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EcranAdminSecret()),
            );
          },
          child: const Text(
            '🔥 SWINTEL - ACTIVATION DU RÉSEAU',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        backgroundColor: Colors.amber,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // 🎯 Écran d'accueil obligatoire, pas de retour en arrière !
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête d'accueil du Goudron
                  Card(
                    color: Colors.amber.withOpacity(0.1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.amber, width: 1.5),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Text(
                        "Bienvenue sur l'APK officielle SWINTEL. Sélectionnez votre profil puis enregistrez la boutique.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🎯 L'INTERFACE DÉFINITIVE DE SÉLECTION DES RÔLES
                  const Text(
                    "Choisissez votre profil d'utilisation :",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Bouton Profil Gérant Independant
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _roleSaisi = 'gerant'),
                          icon: const Icon(Icons.store_mall_directory),
                          label: const Text("GÉRANT"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _roleSaisi == 'gerant'
                                ? Colors.amber
                                : Colors.grey[200],
                            foregroundColor: _roleSaisi == 'gerant'
                                ? Colors.black
                                : Colors.grey[600],
                            elevation: _roleSaisi == 'gerant' ? 4 : 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bouton Profil Agent / Prospecteur de Flotte
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _roleSaisi = 'prospecteur'),
                          icon: const Icon(Icons.person_search),
                          label: const Text("AGENT"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _roleSaisi == 'prospecteur'
                                ? Colors.indigo
                                : Colors.grey[200],
                            foregroundColor: _roleSaisi == 'prospecteur'
                                ? Colors.white
                                : Colors.grey[600],
                            elevation: _roleSaisi == 'prospecteur' ? 4 : 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // FORMULAIRE CHIRURGICAL D'IDENTITÉ
                  TextField(
                    controller: _nomBoutiqueController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la Boutique *',
                      prefixIcon: Icon(Icons.store, color: Colors.orange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de Téléphone (Identifiant) *',
                      prefixIcon: Icon(Icons.phone, color: Colors.orange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _marqueController,
                    decoration: const InputDecoration(
                      labelText: 'Vos Marques (Séparées par des virgules) *',
                      hintText: 'Ex: Toyota, Range Rover, Mercedes',
                      prefixIcon:
                          Icon(Icons.directions_car, color: Colors.orange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _pieceController,
                    decoration: const InputDecoration(
                      labelText: 'Vos Pièces (Séparées par des virgules) *',
                      hintText: 'Ex: Amortisseur, Cardan, Boite, Phare',
                      prefixIcon: Icon(Icons.build, color: Colors.orange),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),
                  TextField(
                    controller: _adresseController,
                    decoration: const InputDecoration(
                      labelText: 'Localisation / Adresse (Optionnel)',
                      prefixIcon: Icon(Icons.map, color: Colors.orange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 📍 BOUTON DE CAPTURE GPS DE LA BOUTIQUE
                  ElevatedButton.icon(
                    onPressed: _isLocating ? null : _capturerPositionMagasin,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.location_on),
                    label: Text(_isLocating
                        ? 'Recherche Satellite...'
                        : 'LIER MA POSITION GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Témoin visuel des coordonnées GPS
                  if (_latMagasin != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      "📍 Coordonnées figées : Lat ${_latMagasin!.toStringAsFixed(4)}, Lng ${_lngMagasin!.toStringAsFixed(4)}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // 🚀 LE GRAND LEVIER : BOUTON D'ACTIVATION ET DE COMMANDE DU RÉSEAU
                  ElevatedButton(
                    onPressed: _activerMonMagasin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      '🦾 ACTIVER MON MAGASIN & ENTRER EN FLOTTE',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
