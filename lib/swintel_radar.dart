import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'dashboard.dart';
import 'alerte_flash_vendeur.dart'; // Écran d'urgence à gros boutons YES/NO

class SwintelRadarGate extends StatefulWidget {
  final String idUtilisateur;
  final String nomMagasinLocal;

  const SwintelRadarGate({
    super.key,
    required this.idUtilisateur,
    required this.nomMagasinLocal,
  });

  @override
  State<SwintelRadarGate> createState() => _SwintelRadarGateState();
}

class _SwintelRadarGateState extends State<SwintelRadarGate> {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _allumerRadarDeFlotte();
  }

  void _allumerRadarDeFlotte() {
    // 🧠 ÉCOUTE EN TEMPS RÉEL INTERNE DE LA TABLE ALERTES
    _supabase
        .channel('public:Alertes')
        .onPostgresChanges(
          event: PostgresChangeEvent
              .insert, // Uniquement sur les NOUVELLES demandes
          schema: 'public',
          table: 'Alertes',
          callback: (payload) async {
            final alerte = payload.newRecord;
            final dynamic idAlerte = alerte['id'];
            final String audioUrl = alerte['audio_url'] ?? '';
            final String demandeurId = alerte['demandeur_id'] ?? '';

            // Sécurité absolue : On ne s'envoie pas une alerte à soi-même
            if (demandeurId == widget.idUtilisateur) return;

            if (mounted) {
              // 📳 ACTION 1 : Déclenchement de la vibration physique (Pattern Saccadé d'urgence)
              if (await Vibration.hasVibrator() ?? false) {
                // 500ms vibration, 200ms pause, 500ms vibration... Intensité maximale (255) !
                Vibration.vibrate(
                  pattern: [0, 500, 200, 500, 200, 500, 200, 500, 200, 800],
                  intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
                );
              }

              // 🚀 ACTION 2 : L'écran de mission Flash surgit de force !
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlerteFlashVendeurScreen(
                    idAlerte: idAlerte,
                    idVendeur: widget.idUtilisateur,
                    nomMagasin: widget
                        .nomMagasinLocal, // CHARGE LE VRAI NOM EN RAM DYNAMIQUE !
                    audioUrl: audioUrl,
                  ),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    // Le radar tourne silencieusement en arrière-plan, mais affiche le Dashboard standard
    return DashboardScreen(idUtilisateur: widget.idUtilisateur);
  }
}
