import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🧠 Pour purger la session locale
import 'ecran_enregistrement.dart';
import 'swintel_radar.dart';
import 'hub_alertes.dart';
import 'creer_alerte.dart';
import 'ecran_admin.dart'; // 🛡️ Accès souverain dissimulé

class DashboardScreen extends StatefulWidget {
  final String idUtilisateur; // Le numéro WhatsApp du gérant connecté

  const DashboardScreen({super.key, required this.idUtilisateur});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _nomBoutiqueLocale = "Chargement...";

  @override
  void initState() {
    super.initState();
    _extraireIdentiteBoutique();
  }

  // 📡 CACHE LOCAL DIRECT : Extraction de la mémoire flash pour l'affichage immédiat
  Future<void> _extraireIdentiteBoutique() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _nomBoutiqueLocale = prefs.getString('nom_magasin') ?? "Boutique Active";
    });
  }

  // 🧽 PURGE DE PROTECTION : Déconnexion sécurisée et nettoyage de la RAM flash
  Future<void> _executerDeconnexion() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Destruction des clés d'identités anti-fraude
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const EcranEnregistrementScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // 🔒 INTERCEPTEUR DE PRIVILÈGES MASQUÉ (UE 207) : Un appui long secret sur le titre ouvre le portail admin
        title: GestureDetector(
          onLongPress: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EcranAdminScreen()));
          },
          child: Text(
            isEnglish
                ? 'SWINTEL PANEL - $_nomBoutiqueLocale'
                : 'PANNEAU SWINTEL - $_nomBoutiqueLocale',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
        ),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.red),
            onPressed: _executerDeconnexion,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📐 BLOC ADAPTATIF 1 : Bouton d'urgence - Émettre Alerte (G1)
            Expanded(
              child: Card(
                color: Colors.orange.shade100,
                elevation: 4,
                child: InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EcranCreerAlerte(
                              idGerant: widget.idUtilisateur))),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_alert,
                            size: 50, color: Colors.orange),
                        const SizedBox(height: 10),
                        Text(
                            isEnglish
                                ? "BROADCAST ALERT (G1)"
                                : "ÉMETTRE ALERTE (G1)",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📐 BLOC ADAPTATIF 2 : Bouton Radar Passif de Flotte (G2)
            Expanded(
              child: Card(
                color: Colors.blue.shade100,
                elevation: 4,
                child: InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SwintelRadarScreen(
                              idUtilisateur: widget.idUtilisateur))),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.radar, size: 50, color: Colors.blue),
                        const SizedBox(height: 10),
                        Text(
                            isEnglish
                                ? "ACTIVATE RADAR (G2)"
                                : "ACTIVER LE RADAR (G2)",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 📐 BLOC ADAPTATIF 3 : Bouton d'accès au Hub Réactif Tricolore
            Expanded(
              child: Card(
                color: Colors.amber.shade100,
                elevation: 4,
                child: InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HubAlertesScreen(
                              idUtilisateur: widget.idUtilisateur,
                              nomMagasinLocal: _nomBoutiqueLocale))),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.layers,
                            size: 50,
                            color: Colors
                                .amber), // 🛠️ CERTIFIÉ : Remplacement de l'icône de labo cassée
                        const SizedBox(height: 10),
                        Text(
                            isEnglish
                                ? "OPEN LIVE HUB"
                                : "OUVRIR LE FLUX DIRECT",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
