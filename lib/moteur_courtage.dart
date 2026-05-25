import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; // Pour déclencher l'appel téléphonique

class MoteurCourtageScreen extends StatefulWidget {
  final String marqueRecherche; // Transmis depuis la dictée (Ex: Toyota)
  final String typeRecherche; // Transmis depuis la dictée (Ex: Amortisseur)
  final double latG1; // Latitude du gérant émetteur
  final double lngG1; // Longitude du gérant émetteur

  const MoteurCourtageScreen({
    super.key,
    required this.marqueRecherche,
    required this.typeRecherche,
    required this.latG1,
    required this.lngG1,
  });

  @override
  State<MoteurCourtageScreen> createState() => _MoteurCourtageScreenState();
}

class _MoteurCourtageScreenState extends State<MoteurCourtageScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _magasinsCorrespondants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rechercherEtCalculerCorrespondances();
  }

  // 🧮 Moteur Algorithmique : Recherche + Calcul de distance
  Future<void> _rechercherEtCalculerCorrespondances() async {
    try {
      // 🎯 LE FILTRE DU "ET" STRICT : Marque ET Type de pièce obligatoires
      final donnees = await _supabase
          .from('Magasins')
          .select()
          .ilike('specialite_marque', '%${widget.marqueRecherche}%')
          .ilike('specialite_type', '%${widget.typeRecherche}%');

      List<Map<String, dynamic>> listeFiltree = [];

      for (var magasin in donnees) {
        final double latTarget = (magasin['lat'] as num?)?.toDouble() ?? 0.0;
        final double lngTarget = (magasin['lng'] as num?)?.toDouble() ?? 0.0;

        // 2. Calcul de la distance en mètres entre G1 et le magasin cible
        double distanceEnMetres = Geolocator.distanceBetween(
            widget.latG1, widget.lngG1, latTarget, lngTarget);

        double distanceEnKm = distanceEnMetres / 1000;

        // On injecte la distance calculée dynamiquement dans l'objet magasin
        magasin['distance_calculee'] = distanceEnKm;
        listeFiltree.add(magasin);
      }

      // 3. Tri des magasins : du plus proche au plus lointain
      listeFiltree.sort((a, b) => (a['distance_calculee'] as double)
          .compareTo(b['distance_calculee'] as double));

      setState(() {
        _magasinsCorrespondants = listeFiltree;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur moteur de recherche : $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  // 📞 Action Courtage Direct : Appel Téléphonique Natif
  Future<void> _appelerMagasin(String telephone) async {
    // 1. Nettoyage du numéro (on enlève les espaces ou caractères parasites)
    final String numeroPropre = telephone.replaceAll(RegExp(r'\s+'), '');

    // 2. Configuration du protocole d'autorité Android 'tel:'
    final Uri launchUri = Uri(scheme: 'tel', path: numeroPropre);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw "Protocole tel non supporté";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("🚨 Impossible de lancer l'appel vers $telephone : $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🎁 L'INSERTION PURE DE 18H15 (Sans aucun paramètre de langue instable)
  Future<void> _attribuerBonusFiche(String nomMagasin) async {
    try {
      await _supabase.from('BonusCourtage').insert({
        'courtier_id': 'yabassi_rj_test',
        'magasin_cible_nom': nomMagasin,
        'points_gagnes': 10,
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("🎯 BONUS ATTRIBUÉ !"),
          content: Text(
              "Fiche envoyée à $nomMagasin. Votre coefficient de courtage a été augmenté !"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("D'ACCORD"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Erreur enregistrement bonus : $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEnglish ? 'SWINTEL - Match Broker' : 'SWINTEL - Courtage Match'),
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.black),
        // 🎯 FORCE LE DESSIN DE LA FLÈCHE ET L'ACTION DE RETOUR IMMÉDIATE
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _magasinsCorrespondants.isEmpty
              ? Center(
                  child: Text(isEnglish
                      ? '❌ No matching stores found.'
                      : '❌ Aucun magasin correspondant trouvé.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _magasinsCorrespondants.length,
                  itemBuilder: (context, index) {
                    final magasin = _magasinsCorrespondants[index];
                    final String nom = magasin['nom'] ?? 'Anonyme';
                    final String adresse =
                        magasin['adresse'] ?? 'Pas d\'adresse';
                    final String telephone = magasin['telephone'] ?? '';
                    final double dist = magasin['distance_calculee'] ?? 0.0;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nom,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 5),
                            Text('📍 $adresse',
                                style: const TextStyle(color: Colors.grey)),
                            Text(
                              isEnglish
                                  ? '📏 Distance: ${dist.toStringAsFixed(2)} km'
                                  : '📏 Distance : ${dist.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                // 🎁 BOUTON BONUS
                                ElevatedButton.icon(
                                  onPressed: () => _attribuerBonusFiche(
                                      nom), // 👈 Version de 18h15 simple !
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white),
                                  icon: const Icon(Icons.star),
                                  label: Text(isEnglish
                                      ? 'Send (Bonus)'
                                      : 'Envoyer (Bonus)'),
                                ),

                                const Spacer(),
                                // 📞 BOUTON APPEL COURTAGE
                                ElevatedButton.icon(
                                  onPressed: telephone.isEmpty
                                      ? null
                                      : () => _appelerMagasin(telephone),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white),
                                  icon: const Icon(Icons.phone),
                                  label: Text(isEnglish ? 'Call' : 'Appeler'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
