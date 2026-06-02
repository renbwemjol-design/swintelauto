import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 AJOUTE CETTE LIGNE DE FORCE ICI !
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
              // 📳 ACTION 1.A : DOUBLE ONDE DE CHOC DE VIBRATION (Intensité 255)
              if (await Vibration.hasVibrator() ?? false) {
                Vibration.vibrate(
                  pattern: [0, 500, 200, 500, 200, 500, 200, 500, 200, 800],
                  intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
                );
              }

              // 🔊 ACTION 1.B : ACCENTUATION SONORE SYSTEM (Double bip d'urgence inratable)
              await SystemSound.play(SystemSoundType.click);
              await Future.delayed(const Duration(milliseconds: 150));
              await SystemSound.play(SystemSoundType.click);

              // 🚀 ACTION 2 : L'écran de mission Flash surgit de force !
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AlerteFlashVendeurScreen(
                    idAlerte: idAlerte,
                    idVendeur:
                        demandeurId, // 👈 RECOUTURE : On transmet l'ID du vrai courtier émetteur !
                    nomMagasin: widget
                        .nomMagasinLocal, // C'est la boutique réceptrice actuelle (ORNY AUTO)
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
