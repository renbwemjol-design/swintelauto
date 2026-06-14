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
  Widget build(BuildContext context) {
    return const Placeholder();
  }

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

  // 🎯 ARCHITECTURE DES RÔLES : Traque du profil sélectionné à l'écran
  String _roleSaisi = 'gerant'; // Valeurs possibles : 'gerant' ou 'prospecteur'

  // 🧽 NETTOYAGE CHIRURGICAL DES CASES DU FORMULAIRE
  void _viderFormulaire() {
    _nomBoutiqueController.clear();
    _telephoneController.clear();
    _marqueController.clear();
    _pieceController.clear();
    _adresseController.clear();
    setState(() {
      _latMagasin = null;
      _lngMagasin = null;
    });
  }

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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 3), // 👈 FILET DE SÉCURITÉ ANTI-FREEZE
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
      final double latitudeFinale = _latMagasin ?? 4.0510;
      final double longitudeFinale = _lngMagasin ?? 9.7679;

      // Incorporation Cloud au statut actif
      await _supabase.from('Magasins').insert({
        'nom': nom,
        'specialite_marque': marque,
        'specialite_type': piece,
        'telephone': tel,
        'adresse': adresse.isEmpty ? "Camp Yabassi, Douala" : adresse,
        'lat': latitudeFinale,
        'lng': longitudeFinale,
        'statut': 'actif', 
      });

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('swintel_role', _roleSaisi); 

      if (_roleSaisi == 'gerant') {
        await prefs.setString('telephone_local', tel);
        await prefs.setString('nom_magasin_local', nom);
      }

      _afficherMessage("🎉 Activation Swintel réussie ! Bienvenue au goudron.",
          Colors.green);

      if (mounted) {
        setState(() => _isSaving = false);
        
        if (_roleSaisi == 'prospecteur') {
          _viderFormulaire(); // 🧽 Purge immédiate pour l'agent
          _afficherMessage("🔄 Nettoyage ok. Prêt pour enrôler la boutique suivante !", Colors.indigo);
        } else {
          _afficherDialogueExamen(nom);
        }
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

  // 🎯 PASSERELLE ASSOCIEE : Reconnexion instantanée des 35 gérants déjà certifiés sur Supabase
  Future<void> _connexionMagasinExistant() async {
    final String tel = _telephoneController.text.trim();

    if (tel.isEmpty) {
      _afficherMessage("⚠️ Saisissez votre Numéro de Téléphone pour vous connecter", Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = await _supabase
          .from('Magasins')
          .select('nom, statut')
          .eq('telephone', tel)
          .maybeSingle();

      setState(() => _isSaving = false);

      if (data == null) {
        _afficherMessage("❌ Ce numéro n'est pas répertorié dans la flotte SWINTEL", Colors.red);
        return;
      }

      final String nom = data['nom'] ?? 'Magasin';
      final String statut = data['statut'] ?? 'actif';

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('swintel_role', 'gerant');

      if (statut == 'certifie') {
        await prefs.setString('telephone_local', tel);
        await prefs.setString('nom_magasin_local', nom);

        _afficherMessage("🎉 Bon retour au goudron, $nom !", Colors.green);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(idUtilisateur: tel),
            ),
          );
        }
      } else {
        if (mounted) _afficherDialogueExamen(nom);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _afficherMessage("🚨 Erreur réseau : ${e.toString().split('\n').first}", Colors.red);
    }
  }

  void _afficherDialogueExamen(String nom) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock, color: Colors.orange),
            SizedBox(width: 10),
            Text("Dossier en Examen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          "Félicitations $nom !\n\nVotre boutique est bien répertoriée au statut ACTIF.\n\nL'administration de SWINTEL procède à la validation de vos accès. Vous entrerez sur le marché dès certification.",
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viderFormulaire(); // 👈 RECTIFICATION : On purge tout au clic sur le bouton "Compris" !
            },
            child: const Text("COMPRIS", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _afficherMessage(String msg, Color couleur) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: couleur, duration: const Duration(seconds: 3)),
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
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        backgroundColor: Colors.amber,
        centerTitle: true,
        automaticallyImplyLeading: false, // Écran obligatoire
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0), // 👈 AÉRATION : Marges réduites
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête compacté pour gagner de la place sur le A10
                  Card(
                    color: Colors.amber.withOpacity(0.08),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.amber, width: 1),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0), // 👈 Plus fin
                      child: Text(
                        "Enregistrez votre boutique ou connectez-vous pour recevoir les alertes de Camp Yabassi.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10), // 👈 Espacement réduit

                  // 🎯 LE RETOUR DU SÉLECTEUR DE RÔLE HAUTE VISIBILITÉ
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _roleSaisi = 'gerant'),
                          icon: Icon(Icons.store_mall_directory, color: _roleSaisi == 'gerant' ? Colors.black : Colors.grey),
                          label: const Text("PROFIL GÉRANT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _roleSaisi == 'gerant' ? Colors.amber : Colors.white,
                            foregroundColor: _roleSaisi == 'gerant' ? Colors.black : Colors.grey[600],
                            side: BorderSide(color: _roleSaisi == 'gerant' ? Colors.orange : Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _roleSaisi = 'prospecteur'),
                          icon: Icon(Icons.person_search, color: _roleSaisi == 'prospecteur' ? Colors.white : Colors.grey),
                          label: const Text("PROFIL AGENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _roleSaisi == 'prospecteur' ? Colors.indigo : Colors.white,
                            foregroundColor: _roleSaisi == 'prospecteur' ? Colors.white : Colors.grey[600],
                            side: BorderSide(color: _roleSaisi == 'prospecteur' ? Colors.darkBlue : Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // FORMULAIRE D'IDENTITÉ
                  TextField(
                    controller: _nomBoutiqueController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la Boutique *',
                      prefixIcon: Icon(Icons.store, color: Colors.orange),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 🎯 REPOSITIONNEMENT ERGONOMIQUE DU BLOC TÉLÉPHONE + RECONNEXION
                  TextField(
                    controller: _telephoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de Téléphone (Identifiant) *',
                      prefixIcon: Icon(Icons.phone, color: Colors.orange),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    ),
                  ),
                  const SizedBox(height: 5), // 👈 Collé au champ !
                  
                  // 🎯 LA DOUANE RECONDUITE : Le lien bleu s'implante juste ici !
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _connexionMagasinExistant,
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                      child: const Text(
                        "Déjà inscrit ? Connecter mon poste au réseau",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _marqueController,
                    decoration: const InputDecoration(
                      labelText: 'Vos Marques (Séparées par des virgules) *',
                      hintText: 'Ex: Toyota, Range Rover, Mercedes',
                      prefixIcon: Icon(Icons.directions_car, color: Colors.orange),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _pieceController,
                    decoration: const InputDecoration(
                      labelText: 'Vos Pièces (Séparées par des virgules) *',
                      hintText: 'Ex: Amortisseur, Cardan, Boite, Phare',
                      prefixIcon: Icon(Icons.build, color: Colors.orange),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _adresseController,
                    decoration: const InputDecoration(
                      labelText: 'Localisation / Adresse (Optionnel)',
                      prefixIcon: Icon(Icons.map, color: Colors.orange),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 📍 BOUTON DE CAPTURE GPS COMPACTÉ
                  ElevatedButton.icon(
                    onPressed: _isLocating ? null : _capturerPositionMagasin,
                    icon: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.location_on, size: 18),
                    label: Text(_isLocating ? 'Recherche Satellite...' : 'LIER MA POSITION GPS', style: const TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  // Témoin visuel des coordonnées GPS
                  if (_latMagasin != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      "📍 Coordonnées : [${_latMagasin!.toStringAsFixed(4)}, ${_lngMagasin!.toStringAsFixed(4)}]",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.green,超fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // 🚀 LE GRAND LEVIER DE FLOTTE
                  ElevatedButton(
                    onPressed: _activerMonMagasin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      '🦾 ACTIVER MON MAGASIN & ENTRER EN FLOTTE',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
