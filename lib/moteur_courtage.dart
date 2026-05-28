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
  RealtimeChannel?
      _ecouteReponseChannel; // 👈 Le tuyau temps réel pour intercepter le YES

  List<Map<String, dynamic>> _magasinsQuiOntRepondu = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ecouterReponsesFlotteEnDirect();
    // Au départ, on affiche une liste vide en attendant le clic physique du spécialiste
    setState(() => _isLoading = false);
  }

  // 📡 Étape 3 : Branchement Realtime tolérant aux accents (réponse_ ou reponse_)
  void _ecouterReponsesFlotteEnDirect() {
    _ecouteReponseChannel =
        _supabase.channel('public:Alertes:Match').onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'Alertes',
              callback: (payload) {
                final String statutAlerte =
                    payload.newRecord['statut_alerte'] ?? '';

                // 🧠 DÉCODEUR UNIFIÉ : Gère 'reponse_' ET 'réponse_' pour le goudron
                if (statutAlerte.startsWith('reponse_') ||
                    statutAlerte.startsWith('réponse_')) {
                  // On nettoie le préfixe pour extraire le nom propre du magasin
                  final String magasinVolontaire = statutAlerte
                      .replaceFirst('reponse_', '')
                      .replaceFirst('réponse_', '');

                  if (magasinVolontaire.isNotEmpty) {
                    _chargerLeSpecialisteVolontaire(magasinVolontaire);
                  }
                }
              },
            );
    _ecouteReponseChannel?.subscribe();
  }

  // 🧮 Charge UNIQUEMENT le magasin exclusif qui a cliqué sur "YES"
  Future<void> _chargerLeSpecialisteVolontaire(
      String nomDuMagasinQuiARepondu) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 🎯 LA REQUÊTE SUR MESURE : Filtrage strict sur le nom extrait du statut
      final donnees = await _supabase
          .from('Magasins')
          .select()
          .eq('nom', nomDuMagasinQuiARepondu); // 👈 EXCLUSIVITÉ TOTALE !

      List<Map<String, dynamic>> listeFiltree = [];

      for (var magasin in donnees) {
        final String nomMagasin = magasin['nom'] ?? '';
        final double latTarget = (magasin['lat'] as num?)?.toDouble() ?? 0.0;
        final double lngTarget = (magasin['lng'] as num?)?.toDouble() ?? 0.0;

        // Calcul de la distance au goudron
        double distanceEnMetres = Geolocator.distanceBetween(
            widget.latG1, widget.lngG1, latTarget, lngTarget);
        magasin['distance_calculee'] = distanceEnMetres / 1000;

        // Calcul de sa fiabilité historique
        final reponseBonus = await _supabase
            .from('BonusCourtage')
            .select('points_gagnes')
            .eq('magasin_cible_nom', nomMagasin);

        int totalFiabilite = 0;
        if (reponseBonus != null) {
          for (var ligne in reponseBonus) {
            totalFiabilite += (ligne['points_gagnes'] as int? ?? 0);
          }
        }
        magasin['score_fiabilite'] = totalFiabilite;

        listeFiltree.add(magasin);
      }

      if (mounted) {
        setState(() {
          _magasinsQuiOntRepondu = listeFiltree;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur filtrage direct : $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // 💬 Action Courtage : Redirection instantanée et native vers l'application WhatsApp
  Future<void> _appelerMagasin(String telephone, String nomMagasin) async {
    String numeroPropre = telephone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');

    if (!numeroPropre.startsWith('237')) {
      numeroPropre = '237$numeroPropre';
    }

    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final String messageText = isEnglish
        ? "Hello $nomMagasin, I am contacting you via SWINTEL for a spare part deal!"
        : "Bonjour $nomMagasin, je vous contacte via SWINTEL pour une affaire de pièce détachée !";

    final String urlWhatsApp =
        "whatsapp://send?phone=$numeroPropre&text=${Uri.encodeComponent(messageText)}";
    final Uri launchUri = Uri.parse(urlWhatsApp);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        final Uri backupUri =
            Uri.parse("https://wa.me{Uri.encodeComponent(messageText)}");
        if (await canLaunchUrl(backupUri)) {
          await launchUrl(backupUri, mode: LaunchMode.externalApplication);
        } else {
          throw "WhatsApp is not installed";
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEnglish
                  ? "🚨 Cannot open WhatsApp: $e"
                  : "🚨 Impossible d'ouvrir WhatsApp : $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // 🎁 L'INSERTION PURE DE 18H15 (Avec le pop-up d'autorité "D'ACCORD")
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
  void dispose() {
    if (_ecouteReponseChannel != null) {
      _supabase.removeChannel(_ecouteReponseChannel!);
    }
    super.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _magasinsQuiOntRepondu.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      isEnglish
                          ? '📡 Waiting for targeted specialists to answer "YES"...'
                          : '📡 En attente de la réponse "J\'ai la pièce" des spécialistes ciblés...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _magasinsQuiOntRepondu.length,
                  itemBuilder: (context, index) {
                    final magasin = _magasinsQuiOntRepondu[index];
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

                            // 🌟 BADGE DE FIABILITÉ COMMERCIALE (Nouveau !)
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.verified_user,
                                    color: Colors.blue, size: 16),
                                const SizedBox(width: 5),
                                Text(
                                  isEnglish
                                      ? '🛡️ Reliability Score: ${magasin['score_fiabilite'] ?? 0} pts'
                                      : '🛡️ Score de Fiabilité : ${magasin['score_fiabilite'] ?? 0} pts',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          (magasin['score_fiabilite'] ?? 0) >= 0
                                              ? Colors.green
                                              : Colors.red),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _attribuerBonusFiche(nom),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white),
                                  icon: const Icon(Icons.star),
                                  label: Text(isEnglish
                                      ? 'Send (Bonus)'
                                      : 'Envoyer (Bonus)'),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: telephone.isEmpty
                                      ? null
                                      : () => _appelerMagasin(telephone, nom),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white),
                                  icon: const Icon(Icons.chat),
                                  label:
                                      Text(isEnglish ? 'WhatsApp' : 'WhatsApp'),
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
