import 'dart:math' as math; // 👈 AJOUTE CETTE LIGNE ICI D'AUTORITÉ !
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'alerte_flash_vendeur.dart';

class HubAlertesScreen extends StatefulWidget {
  final String idUtilisateur;
  final String nomMagasinLocal;

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

  // 🧠 LE ROBINET TEMPS RÉEL : On écoute toutes les lignes de la table Alertes
  final Stream<List<Map<String, dynamic>>> _hubStream = Supabase.instance.client
      .from('Alertes')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.grey[900], // Fond sombre premium style tableau de bord
      appBar: AppBar(
        title: Text(isEnglish ? 'SWINTEL - Market Hub' : 'SWINTEL - Hub Alertes'),
        backgroundColor: Colors.amber,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _hubStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                isEnglish ? '⚠️ Connection error' : '⚠️ Erreur de flux réseau',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          final List<Map<String, dynamic>> toutesLesAlertes = snapshot.data!;

          if (toutesLesAlertes.isEmpty) {
            return Center(
              child: Text(
                isEnglish ? '📡 No alert on the market yet' : '📡 Aucune alerte active sur le marché',
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: toutesLesAlertes.length,
            itemBuilder: (context, index) {
              final alerte = toutesLesAlertes[index];
              final String idAlerte = alerte['id']?.toString() ?? '';
              final String demandeurId = alerte['demandeur_id'] ?? 'Anonyme';
              final String statut = alerte['statut_alerte'] ?? 'en_attente';
              final String audioUrl = alerte['audio_url'] ?? '';
              
              // 🎯 SIGNATURE SÉMANTIQUE : Lecture directe des nouvelles colonnes Cloud
              final String marque = alerte['marque_concernee'] ?? 'Toutes marques';
              final String piece = alerte['piece_concernee'] ?? 'Pièce générale';

              // 🎨 LOGIQUE DES COULEURS DU MARCHÉ : Vert si résolu, ambre si ouvert, rouge si échec
              final bool estEnAttente = statut == 'en_attente';
              final Color couleurStatut = estEnAttente ? Colors.amber : Colors.green;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(estEnAttente ? Icons.radar : Icons.check_circle, color: couleurStatut),
                          const SizedBox(width: 10),
                          Text(
                            estEnAttente 
                                ? (isEnglish ? 'OPEN MISSION' : 'MISSION EN ATTENTE')
                                : (isEnglish ? 'DEAL CLOSED' : 'AFFAIRE CONCLUE'),
                            style: TextStyle(fontWeight: FontWeight.bold, color: couleurStatut, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            "ID: ${demandeurId.substring(math.max(0, demandeurId.length - 4))}", // 4 derniers chiffres du gérant
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      
                      // 🧠 AFFICHAGE EN CLAIR DU SOUHAIT DU CLIENT
                      Text(
                        "${piece.toUpperCase()} ➡️ ${marque.toUpperCase()}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 15),

                      // 🚀 BOUTON DE PRISE EN CHARGE INTERACTIVE
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // On propulse le gérant directement sur l'écran flash d'urgence
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AlerteFlashVendeurScreen(
                                  idAlerte: alerte['id'],
                                  idVendeur: demandeurId,
                                  nomMagasin: widget.nomMagasinLocal,
                                  audioUrl: audioUrl,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: estEnAttente ? Colors.amber : Colors.grey[300],
                            foregroundColor: estEnAttente ? Colors.black : Colors.grey[600],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(estEnAttente ? Icons.play_circle_fill : Icons.lock),
                          label: Text(
                            estEnAttente
                                ? (isEnglish ? 'STUDY / TAKE CHARGE' : 'ÉTUDIER / PRENDRE EN CHARGE')
                                : (isEnglish ? 'ARCHIVED DEAL' : 'AFFAIRE ARCHIVÉE')
                          ),
                        ),
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
