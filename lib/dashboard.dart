import 'package:flutter/material.dart';
import 'creer_alerte.dart';
import 'hub_alertes.dart';
import 'moteur_courtage.dart';
import 'alerte_flash_vendeur.dart'; // 👈 On importe notre nouvel écran d'urgence flash

class DashboardScreen extends StatelessWidget {
  final String idUtilisateur;
  const DashboardScreen({super.key, required this.idUtilisateur});

  @override
  Widget build(BuildContext context) {
    final String codeLangue = Localizations.localeOf(context).languageCode;
    final bool isEnglish = codeLangue == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEnglish ? 'SWINTEL - Dashboard' : 'SWINTEL - Tableau de Bord',
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
                        builder: (context) =>
                            EcranCreerAlerte(idGerant: idUtilisateur))),
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
                        builder: (context) =>
                            HubAlertesScreen(idUtilisateur: idUtilisateur))),
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

            // 🔥 BOUTON 4 : SIMULER LA RECEPTION D'UNE ALERTE FLASH (La nouvelle brique !)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AlerteFlashVendeurScreen(
                        idAlerte:
                            "alerte-test-uuid-12345", // UUID fictif pour simulation
                        idVendeur:
                            "vendeur_test_fille", // ID de la fille de test
                        nomMagasin:
                            "Magasin Ornella/Alyona", // Nom du stock de test
                        audioUrl:
                            "https://supabase.co", // Lien audio de test valide ou vide
                      ),
                    ),
                  );
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
                            ? 'Test Yes/No buttons & reliability score'
                            : 'Tester les boutons Oui/Non et les scores',
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
