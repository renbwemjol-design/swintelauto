import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 📸 Piston matériel de capture photo
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🧠 Ancrage flash de la session
import 'dashboard.dart';

class EcranEnregistrementScreen extends StatefulWidget {
  const EcranEnregistrementScreen({super.key});

  @override
  State<EcranEnregistrementScreen> createState() =>
      _EcranEnregistrementScreenState();
}

class _EcranEnregistrementScreenState extends State<EcranEnregistrementScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _ctrlNom = TextEditingController();
  final TextEditingController _ctrlTel = TextEditingController();

  String _marqueChoisie = 'Toyota';
  String _pieceChoisie = 'Amortisseur';
  File? _imageSelectionnee;
  bool _isSaving = false;

  // 📸 COMMANDE MATÉRIELLE CAPTEUR : Capture avec compression agressive à la source à 50%
  Future<void> _capturerPhotoDevanture() async {
    try {
      final XFile? photoBrute = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality:
            50, // 🗜️ BRIDAGE MAXIMUM : Divise par 2 le poids du fichier pour Android Go
        maxWidth:
            800, // Fixation de la résolution pour détruire la surcharge RAM
      );

      if (photoBrute != null) {
        setState(() => _imageSelectionnee = File(photoBrute.path));
      }
    } catch (e) {
      _afficherSnackBar("🚨 Échec capteur photo : $e", Colors.red);
    }
  }

  // 🚀 PROPULSION DU PROFIL EN FLOTTE (Table 1 + Table 4)
  Future<void> _validerEtEnregistrerMagasin() async {
    final String nom = _ctrlNom.text.trim();
    final String tel = _ctrlTel.text.trim();

    if (nom.isEmpty || tel.isEmpty || _imageSelectionnee == null) {
      _afficherSnackBar(
          "⚠️ Formulaire incomplet (Nom, Téléphone et Photo obligatoires)",
          Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String nomFichierCloud =
          "facade_${tel}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      // 1. Propulsion du binaire de la photo compressée dans le Bucket public (Table 4)
      await _supabase.storage
          .from('photos_magasins')
          .upload('public/$nomFichierCloud', _imageSelectionnee!);
      final String urlPhotoPublique = _supabase.storage
          .from('photos_magasins')
          .getPublicUrl('public/$nomFichierCloud');

      // 🗺️ COORDONNÉES GÉOSPATIALES FIXES DE LABORATOIRE (Camp Yabassi, Douala)
      const double latFixeYabassi = 4.0494;
      const double lngFixeYabassi = 9.7042;

      // 2. Insertion atomique dans la table relationnelle Magasins (Table 1)
      await _supabase.from('Magasins').insert({
        'nom': nom,
        'telephone': tel,
        'specialite_marque': _marqueChoisie,
        'specialite_type': _pieceChoisie,
        'image_url': urlPhotoPublique,
        'lat': latFixeYabassi,
        'lng': lngFixeYabassi,
        'statut': 'actif',
      });

      // 3. ANCRAGE DE LA SESSION EN MÉMOIRE FLASH DISQUE
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('telephone_gerant', tel);
      await prefs.setString('nom_magasin', nom);

      if (mounted) {
        _afficherSnackBar("🎉 Boutique certifiée et enrôlée !", Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => DashboardScreen(idUtilisateur: tel)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _afficherSnackBar("🚨 Échec de certification cloud : $e", Colors.red);
      }
    }
  }

  void _afficherSnackBar(String msg, Color couleur) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  @override
  void dispose() {
    _ctrlNom.dispose();
    _ctrlTel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text('🏆 SWINTEL ENRÔLEMENT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          backgroundColor: Colors.amber,
          centerTitle: true),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                      controller: _ctrlNom,
                      decoration: const InputDecoration(
                          labelText: 'Nom du Magasin / Shop Name',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _ctrlTel,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Numéro WhatsApp (Identifiant Unique)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 16),

                  // Sélecteurs de Spécialités Métiers (Filtres Sémantiques)
                  DropdownButtonFormField<String>(
                      value: _marqueChoisie,
                      items: ['Toyota', 'Mercedes', 'Nissan']
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _marqueChoisie = v!),
                      decoration: const InputDecoration(
                          labelText: 'Marque Spécialiste')),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                      value: _pieceChoisie,
                      items: ['Amortisseur', 'Phare', 'Démarreur']
                          .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setState(() => _pieceChoisie = v!),
                      decoration: const InputDecoration(
                          labelText: 'Pièce Spécialiste')),
                  const SizedBox(height: 24),

                  // Déclencheur du Capteur Photo Matériel
                  ElevatedButton.icon(
                    onPressed: _capturerPhotoDevanture,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_imageSelectionnee == null
                        ? "Prendre Photo Devanture"
                        : "Photo Capturée ✔️"),
                  ),
                  if (_imageSelectionnee != null) ...[
                    const SizedBox(height: 10),
                    Container(
                        height: 120,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.amber, width: 2)),
                        child:
                            Image.file(_imageSelectionnee!, fit: BoxFit.cover))
                  ],
                  const SizedBox(height: 40),

                  // Bouton de Propulsion Final
                  ElevatedButton(
                    onPressed: _validerEtEnregistrerMagasin,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    child: const Text("CERTIFIER MON COMPTOIR",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
