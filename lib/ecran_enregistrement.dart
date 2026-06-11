import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart'; // 👈 IMPORTATION DU CAPTEUR SATELLITAIRE DE BASE
import 'package:shared_preferences/shared_preferences.dart'; // Pour figer la session locale
import 'dashboard.dart';

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
        _latMagasin =
            4.0510; // Repli d'autorité sur le point central de Camp Yabassi
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

      // 3. ENREGISTREMENT LOCAL (RAM & MEMOIRE FLASH DU SMARTPHONE)
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('telephone_local', tel);
      await prefs.setString('nom_magasin_local', nom);

      _afficherMessage("🎉 Activation Swintel réussie ! Bienvenue au goudron.",
          Colors.green);

      if (mounted) {
        setState(() => _isSaving = false);
        // On propulse le gérant directement sur son Tableau de Bord tout neuf
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(idUtilisateur: tel),
          ),
        );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '🔥 SWINTEL - ACTIVATION DU RÉSEAU',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
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
                        "Bienvenue sur l'APK officielle SWINTEL. Enregistrez votre boutique pour recevoir les alertes ciblées de Camp Yabassi.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                  // 🎯 RECTIFICATION DIRECTE : Intégration des guides multi-marques
                  TextField(
                    controller: _marqueController,
                    decoration: const InputDecoration(
                      labelText: 'Vos Marques (Séparées par des virgules) *',
                      hintText:
                          'Ex: Toyota, Range Rover, Mercedes', // 👈 GUIDE VISUEL APPLIQUÉ
                      prefixIcon:
                          Icon(Icons.directions_car, color: Colors.orange),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 🎯 RECTIFICATION DIRECTE : Intégration des guides multi-pièces
                  TextField(
                    controller: _pieceController,
                    decoration: const InputDecoration(
                      labelText: 'Vos Pièces (Séparées par des virgules) *',
                      hintText:
                          'Ex: Amortisseur, Cardan, Boite, Phare', // 👈 GUIDE VISUEL APPLIQUÉ
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
