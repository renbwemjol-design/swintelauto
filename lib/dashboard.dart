import 'package:flutter/material.dart';
import 'creer_alerte.dart';
import 'hub_alertes.dart';
import 'moteur_courtage.dart';
import 'alerte_flash_vendeur.dart'; // 👈 On importe notre nouvel écran d'urgence flash
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  final String idUtilisateur;
  const DashboardScreen({super.key, required this.idUtilisateur});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _nomBoutiqueLocale =
      "..."; // 👈 La variable d'ancrage visuel est ici !

  @override
  void initState() {
    super.initState();
    _chargerNomBoutiqueLocale(); // 👈 On réveille la mémoire flash au démarrage
  }

  Future<void> _chargerNomBoutiqueLocale() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Lit le vrai nom ou prend l'ID par défaut
      _nomBoutiqueLocale =
          prefs.getString('nom_magasin_local') ?? widget.idUtilisateur;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String codeLangue = Localizations.localeOf(context).languageCode;
    final bool isEnglish = codeLangue == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEnglish
                ? 'SWINTEL - $_nomBoutiqueLocale'
                : 'SWINTEL - $_nomBoutiqueLocale', // 👈 Le vrai nom surgit ici !
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 10.0), // Légère réduction pour faire tenir 4 boutons
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo Card
            const Card(
              color: Colors.amber,
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Icon(Icons.directions_car, size: 35, color: Colors.black),
                    SizedBox(height: 5),
                    Text('RÉSEAU PIÈCES AFRIQUE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              isEnglish
                  ? 'CHOOSE YOUR ACTION / CHOISISSEZ'
                  : 'CHOISISSEZ VOTRE ACTION / CHOOSE',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey),
            ),
            const SizedBox(height: 10),

            // 📡 BOUTON 1 : ÉMISSION ALERTE
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EcranCreerAlerte(
                            idGerant:
                                widget.idUtilisateur))), // 👈 Ajout de widget.

                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.radar, size: 30),
                    const SizedBox(height: 5),
                    Text(isEnglish ? 'SEND AN ALERT' : 'ÉMETTRE UNE ALERTE',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                        isEnglish
                            ? 'Record voice (WhatsApp style)'
                            : 'Enregistrer un vocal (Style WhatsApp)',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 📥 BOUTON 2 : HUB RECEPTION
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    
                    MaterialPageRoute(
                      builder: (context) => HubAlertesScreen(
                          idUtilisateur: widget.idUtilisateur), // 👈 Modifié ici !
                    ),
                       
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.forum_outlined, size: 30),
                    const SizedBox(height: 5),
                    Text(isEnglish ? 'OPEN ALERT HUB' : 'OUVRIR LE FLUX DIRECT',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                        isEnglish
                            ? 'Check live requests'
                            : 'Consulter le flux en direct',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 🧮 BOUTON 3 : SIMULATION DU MOTEUR DE COURTAGE
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MoteurCourtageScreen(
                        marqueRecherche: "Toyota",
                        typeRecherche: "Amortisseur",
                        latG1: 4.0510,
                        lngG1: 9.7679,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calculate, size: 30),
                    const SizedBox(height: 5),
                    Text(
                        isEnglish
                            ? 'SIMULATE BROKERAGE'
                            : 'SIMULER LE COURTAGE',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                        isEnglish
                            ? 'Test math match & distance'
                            : 'Tester le calcul et les distances',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

                        // 🔥 BOUTON 4 : SIMULER LA RÉCEPTION FLASH AVEC LE VRAI DERNIER VOCAL
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // 🧠 On interroge Supabase pour attraper la toute dernière alerte vocale publiée sur le réseau
                    final derniereAlerte = await Supabase.instance.client
                        .from('Alertes')
                        .select('id, audio_url')
                        .order('created_at', ascending: false)
                        .limit(1)
                        .single();

                    final dynamic idAlerteReel = derniereAlerte['id'];
                    final String audioUrlReel = derniereAlerte['audio_url'] ?? '';

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AlerteFlashVendeurScreen(
                            idAlerte: idAlerteReel, // 👈 Utilise le vrai ID récupéré !
                            idVendeur: widget.idUtilisateur, // 👈 Ton vrai numéro en RAM !
                            nomMagasin: _nomBoutiqueLocale,  // 👈 Le vrai nom extrait de Supabase !
                            audioUrl: audioUrlReel, // 👈 Utilise le vrai lien audio Cloud !
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("🚨 Aucune alerte trouvée en base : $e"),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flash_on, size: 30),
                    const SizedBox(height: 5),
                    Text(
                        isEnglish
                            ? 'SIMULATE FLASH RECEPTION'
                            : "SIMULER LA RÉCEPTION FLASH",
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                        isEnglish
                            ? 'Test with real last voice request'
                            : 'Tester avec le vrai dernier vocal',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
