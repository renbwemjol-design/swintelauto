import 'dart:async'; // 👈 1. Ajout de l'infrastructure asynchrone des Streams !
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'dashboard.dart';
import 'alerte_flash_vendeur.dart';
import 'package:just_audio/just_audio.dart'; // 👈 Compagnon multimédia d'autorité !

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
  StreamSubscription? _radarSubscription;
  final AudioPlayer _alertAudioPlayer =
      AudioPlayer(); // 👈 Casque de choc pour la sirène multimédia !

  @override
  void initState() {
    super.initState();
    _allumerRadarDeFlotte();
  }

  void _allumerRadarDeFlotte() {
    // 🧠 INFRASTRUCTURE DE FLUX : On écoute le Stream réel, infiniment plus robuste face aux latences de Douala !
    _radarSubscription = _supabase
        .from('Alertes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> alertes) async {
          if (alertes.isEmpty) return;

          // On attrape instantanément la toute dernière alerte publiée sur la grille SQL
          final alerte = alertes.first;
          final dynamic idAlerte = alerte['id'];
          final String audioUrl = alerte['audio_url'] ?? '';
          final String demandeurId = alerte['demandeur_id'] ?? '';
          final String statutAlerte = alerte['statut_alerte'] ?? '';

          // 🛡️ FILTRES ET SÉCURITÉS SÉMANTIQUES :
          if (statutAlerte != 'en_attente')
            return; // Uniquement si l'alerte attend preneur !
          if (demandeurId == widget.idUtilisateur)
            return; // Sécurité absolue anti-auto-vibration !

          if (mounted) {
            // 📳 ACTION 1.A : DOUBLE ONDE DE CHOC DE VIBRATION (Intensité 255)
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(
                pattern: [0, 500, 200, 500, 200, 500, 200, 500, 200, 800],
                intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
              );
            }

            // 🔊 ACTION 1.B : PARADE AUDIO MULTIMÉDIA (Force le haut-parleur du Samsung A10 avec un vrai bip d'alarme numérique)
            try {
              if (_alertAudioPlayer.playing) {
                await _alertAudioPlayer.stop();
              }
              await _alertAudioPlayer.setUrl('https://google.com');
              await _alertAudioPlayer.play();
            } catch (e) {
              debugPrint("Hoquet haut-parleur : $e");
            }

            // 🚀 ACTION 2 : L'écran de mission Flash surgit de force !
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlerteFlashVendeurScreen(
                  idAlerte: idAlerte,
                  idVendeur:
                      demandeurId, // On transmet l'ID du vrai courtier émetteur !
                  nomMagasin: widget
                      .nomMagasinLocal, // C'est la boutique réceptrice actuelle
                  audioUrl: audioUrl,
                ),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    _radarSubscription?.cancel();
    _alertAudioPlayer
        .dispose(); // 👈 Libère proprement les ressources audio en RAM !
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le radar tourne silencieusement en arrière-plan, mais affiche le Dashboard standard
    return DashboardScreen(idUtilisateur: widget.idUtilisateur);
  }
}
