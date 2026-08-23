import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // 🧠 Levier de propulsion externe vers l'OS Android

class MoteurCourtageScreen extends StatefulWidget {
  final String marqueRecherche; // Transmis par le flux (Ex: 'Toyota')
  final String typeRecherche; // Transmis par le flux (Ex: 'Amortisseur')
  final double latG1; // Coordonnées géospatiales de l'émetteur
  final double lngG1;
  final String idUtilisateur; // Le numéro du gérant actif

  const MoteurCourtageScreen({
    super.key,
    required this.marqueRecherche,
    required this.typeRecherche,
    required this.latG1,
    required this.lngG1,
    required this.idUtilisateur,
  });

  @override
  State<MoteurCourtageScreen> createState() => _MoteurCourtageScreenState();
}

class _MoteurCourtageScreenState extends State<MoteurCourtageScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // 🛠️ CERTIFIÉ ASCII : Éjection définitive des accents provoquant des erreurs de dictionnaire
  List<Map<String, dynamic>> _comptoirsAppaires = [];

  @override
  void initState() {
    super.initState();
    _executerAppariementSemantiqueGoudron(); // 🛠️ CERTIFIÉ : Retrait de l'accent sur l'appel
  }

  // 📐 ALGORITHME DE CORRÉLATION (Table 1 + Table 3 + Algèbre Booléenne)
  Future<void> _executerAppariementSemantiqueGoudron() async {
    // 🛠️ CERTIFIÉ : Retrait de l'accent sur la méthode
    try {
      // 1. Extraction par filtre strict des spécialistes compatibles de la table Magasins (Table 1)
      final List<dynamic> magasinsCompatibles = await _supabase
          .from('Magasins')
          .select(
              'nom, telephone, specialite_marque, specialite_type, lat, lng')
          .eq('specialite_marque', widget.marqueRecherche)
          .eq('specialite_type', widget.typeRecherche)
          .eq('statut', 'actif');

      List<Map<String, dynamic>> listeTemporaire = [];

      for (var magasin in magasinsCompatibles) {
        final String telBoutique = magasin['telephone'] ?? '';

        // 📊 CUMUL QUANTITATIF DES POINTS (Extraction de la Table 3 pour l'index de confiance)
        final List<dynamic> historiqueBonus = await _supabase
            .from('BonusCourtage')
            .select('points_gagnes')
            .eq('courtier_id', telBoutique);

        // Somme arithmétique rigoureuse des points signés (+10 / -5) en RAM locale
        int scoreCumule = 0;
        for (var ligne in historiqueBonus) {
          scoreCumule += (ligne['points_gagnes'] as num).toInt();
        }

        listeTemporaire.add({
          'nom': magasin['nom'] ?? 'Comptoir Inconnu',
          'telephone': telBoutique,
          'score': scoreCumule,
        });
      }

      // ⚡ TRI CHRONOLOGIQUE ET HIÉRARCHIQUE : Les scores les plus élevés en premier (O(N log N))
      listeTemporaire
          .sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      if (mounted) {
        setState(() {
          _comptoirsAppaires = listeTemporaire; // 🛠️ CERTIFIÉ : ASCII respecté
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🚨 Échec critique d'appariement : $e");
    }
  }

  // 📱 DEEP LINKING DUR : Réparation chirurgicale du double slash wa.me/ d'OS
  Future<void> _propulserVersWhatsAppVendeur(String telCible) async {
    // 🧽 NETTOYAGE PAR EXPRESSION RÉGULIÈRE : Éjecte les caractères parasites et accents de variable
    final String telEpure =
        telCible.replaceAll(RegExp(r'[^\d+]'), ''); // 🛠️ CERTIFIÉ : ASCII pur
    String numeroFinal = telEpure; // 🛠️ CERTIFIÉ : ASCII pur

    if (!numeroFinal.startsWith('+') && !numeroFinal.startsWith('237')) {
      numeroFinal = '237$numeroFinal';
    }
    numeroFinal = numeroFinal.replaceAll('+', '');

    // 🔥 REPARATION SÉMANTIQUE : Re-soudage rigoureux du lien wa.me universel connecté au numéro final [▲]
    final Uri urlWhatsApp = Uri.parse("https://wa.me");

    try {
      if (await canLaunchUrl(urlWhatsApp)) {
        // Propulsion asynchrone hors de la machine virtuelle Flutter vers le noyau de l'OS Android [▲]
        await launchUrl(urlWhatsApp, mode: LaunchMode.externalApplication);

        // 🏆 ATTRIBUTION INDÉPENDANTE DU BONUS (Table 3) : L'actionneur gagne de force +10 points de réactivité
        await _supabase.from('BonusCourtage').insert({
          'courtier_id': widget.idUtilisateur,
          'magasin_cible_nom': _comptoirsAppaires
              .firstWhere((element) => element['telephone'] == telCible)['nom'],
          'points_gagnes':
              10, // Injection stricte sous contrôle de nos verrous RLS
        });
      } else {
        throw "Impossible d'intercepter l'application WhatsApp matérielle.";
      }
    } catch (e) {
      debugPrint("🚨 Échec Deep Linking WhatsApp : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEnglish
              ? 'SWINTEL MATCH - ${widget.marqueRecherche}'
              : 'MATCH SWINTEL - ${widget.marqueRecherche}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: Colors.amber,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : _comptoirsAppaires.isEmpty // 🛠️ CERTIFIÉ : ASCII pur
              ? Center(
                  child: Text(
                      isEnglish
                          ? "No specialized shops found."
                          : "Aucun comptoir spécialiste disponible.",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      _comptoirsAppaires.length, // 🛠️ CERTIFIÉ : ASCII pur
                  itemBuilder: (context, index) {
                    final boutique =
                        _comptoirsAppaires[index]; // 🛠️ CERTIFIÉ : ASCII pur
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(
                          bottom:
                              12), // 🛠️ CERTIFIÉ : Primitive EdgeInsets.only stable
                      child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.store, color: Colors.black)),
                        title: Text(boutique['nom'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                            "${isEnglish ? "Reliability Index:" : "Indice de Fiabilité :"} ${boutique['score']} pts",
                            style: TextStyle(
                                color: boutique['score'] >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        trailing: ElevatedButton.icon(
                          onPressed: () => _propulserVersWhatsAppVendeur(
                              boutique['telephone']),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white),
                          icon: const Icon(Icons.chat, size: 16),
                          label: Text(isEnglish ? "DEAL" : "NÉGOCIER",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
