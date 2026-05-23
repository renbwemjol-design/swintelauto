import 'package:flutter/material.dart';
import 'creer_alerte.dart';
import 'hub_alertes.dart';
import 'moteur_courtage.dart'; // 👈 On importe le cerveau de courtage

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
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo Card
            const Card(
              color: Colors.amber,
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Icon(Icons.directions_car, size: 40, color: Colors.black),
                    SizedBox(height: 5),
                    Text('RÉSEAU PIÈCES AFRIQUE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 15),

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
                    const Icon(Icons.radar, size: 35),
                    const SizedBox(height: 5),
                    Text(isEnglish ? 'SEND AN ALERT' : 'ÉMETTRE UNE ALERTE',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                        isEnglish
                            ? 'Record voice (WhatsApp style)'
                            : 'Enregistrer un vocal (Style WhatsApp)',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

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
                    const Icon(Icons.forum_outlined, size: 35),
                    const SizedBox(height: 5),
                    Text(isEnglish ? 'OPEN ALERT HUB' : 'OUVRIR LE FLUX DIRECT',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                        isEnglish
                            ? 'Check live requests'
                            : 'Consulter le flux en direct',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 🧮 BOUTON 3 : SIMULATION DU MOTEUR DE COURTAGE (Nouveau !)
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MoteurCourtageScreen(
                        marqueRecherche: "Toyota",
                        typeRecherche: "Amortisseur",
                        latG1: 4.0510, // Coordonnées de test de G1 (Douala)
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
                    const Icon(Icons.calculate, size: 35),
                    const SizedBox(height: 5),
                    Text(
                        isEnglish
                            ? 'SIMULATE BROKERAGE'
                            : 'SIMULER LE COURTAGE',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                        isEnglish
                            ? 'Test math match & distance'
                            : 'Tester le calcul et les distances',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70)),
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
