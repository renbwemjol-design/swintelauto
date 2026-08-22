import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HubAlertesScreen extends StatefulWidget {
  final String idUtilisateur; // Le numéro de téléphone du gérant connecté
  final String nomMagasinLocal; // Le nom de la boutique active extrait du cache

  const HubAlertesScreen({
    super.key,
    required this.idUtilisateur,
    required this.nomMagasinLocal,
  });

  @override
  State<HubAlertesScreen> createState() => _HubAlertesScreenState();
}

class _HubAlertesScreenState extends State<HubAlertesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🎨 ARCHITECTURE DES NUANCES : Calcul dynamique de la couleur de la carte (UE 208)
  Color _calculerNuanceCarte(String statutAlerte) {
    if (statutAlerte == 'en_attente') {
      return Colors.red.shade50; // 🔥 Urgent, ouvert au marché
    } else if (statutAlerte == 'brouillon') {
      return Colors.grey.shade100; // ⚙️ En cours de forge locale
    } else if (statutAlerte.startsWith('reponse_')) {
      // Si la réponse vient de notre propre boutique ➔ Vert d'acier
      if (statutAlerte == "reponse_${widget.nomMagasinLocal}") {
        return Colors.green.shade50;
      }
      return Colors.orange.shade50; // 🟧 Pris par un spécialiste concurrent
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEnglish ? 'SWINTEL LIVE HUB' : 'BOURSE EN DIRECT SWINTEL',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: Colors.amber,
      ),
      // 🧠 LIAISON RÉACTIVE DIRECTE : Écoute passive par flux des 20 dernières alertes de production
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('Alertes')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false)
            .limit(20),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("🚨 Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }

          final alertesBourse = snapshot.data!;

          if (alertesBourse.isEmpty) {
            return Center(
              child: Text(
                isEnglish
                    ? "No alerts on market."
                    : "Le marché est calme. Zéro alerte.",
                style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alertesBourse.length,
            itemBuilder: (context, index) {
              final alerte = alertesBourse[index];
              final String statut = alerte['statut_alerte'] ?? 'en_attente';
              final String marque = alerte['marque_concernee'] ?? 'Toutes';
              final String piece = alerte['piece_concernee'] ?? 'Générale';
              final String demandeur = alerte['demandeur_id'] ?? 'Anonyme';

              return Card(
                color: _calculerNuanceCarte(
                    statut), // Injection immédiate de la nuance tricolore
                elevation: 2,
                margin: const EdgeInsets.only(
                    bottom:
                        12), // 🛠️ CERTIFIÉ : Marges d'usine dures redressées sans erreur de constructeur
                child: ListTile(
                  leading: Icon(
                    statut == 'en_attente'
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    color: statut == 'en_attente' ? Colors.red : Colors.green,
                    size: 28,
                  ),
                  title: Text(
                    "$marque — $piece",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                          "📞 ${isEnglish ? "Sender:" : "Émetteur :"} $demandeur",
                          style: const TextStyle(
                              fontSize: 11, fontFamily: 'monospace')),
                      const SizedBox(height: 2),
                      Text(
                        statut == 'en_attente'
                            ? (isEnglish
                                ? "🛑 AVAILABLE"
                                : "🛑 DISPONIBLE (OUVERT)")
                            : (statut == "reponse_${widget.nomMagasinLocal}"
                                ? (isEnglish
                                    ? "✅ SIGNED BY YOU"
                                    : "✅ ADJUGÉ À MON COMPTOIR")
                                : (isEnglish
                                    ? "🟧 TAKEN"
                                    : "🟧 CLOS (PRIS PAR CONCURRENT)")),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
