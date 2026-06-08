import 'dart:async'; // 🧠 Infrastructure asynchrone des Streams
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 Indispensable pour injecter les bips physiques
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'dashboard.dart';
import 'alerte_flash_vendeur.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 👈 Le gestionnaire de canaux d'élite !
import 'main.dart'; // 👈 Crucial pour capter l'instance globale du plugin !

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
  StreamSubscription? _radarSubscription; // 👈 Filet de sécurité asynchrone

  @override
  void initState() {
    super.initState();
    _allumerRadarDeFlotte();
  }

  void _allumerRadarDeFlotte() {
    // 🧠 INFRASTRUCTURE DE FLUX IMMUNE : Écoute le Stream réel des lignes 'en_attente'
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

          // 🛡️ SÉCURITÉS SÉMANTIQUES :
          if (statutAlerte != 'en_attente') return; // Uniquement si l'alerte attend preneur
          if (demandeurId == widget.idUtilisateur) return; // Anti-auto-vibration

          if (mounted) {
            // 📳 ACTION 1.A : DOUBLE ONDE DE CHOC DE VIBRATION (Intensité 255)
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(
                pattern: [0, 500, 200, 500, 200, 500, 200, 500, 200, 800],
                intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
              );
            }

            // 🔊 ACTION 1.B : DÉCLENCHEMENT DE LA SIRÈNE "STYLE FACEBOOK" (Arguments 100% Nommés)
            try {
              const AndroidNotificationDetails androidNotificationDetails =
                  AndroidNotificationDetails(
                'swintel_urgent_channel',
                '🚨 SWINTEL - ALERTES CRUCIALES',
                channelDescription: 'Canal d\'urgence prioritaire',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                sound: RawResourceAndroidNotificationSound('sirene'),
              );

              const NotificationDetails notificationDetails = NotificationDetails(
                android: androidNotificationDetails,
              );

               // 🎯 RECTIFICATION PARFAITE 2026 : Chaque argument est nommé sans exception !
              await flutterLocalNotificationsPlugin.show(
                id: idAlerte.hashCode, // 👈 L'identifiant unique de notification
                title: '🔥 MISSION FLASH SWINTEL !', // 👈 AJOUTE L'ÉTIQUETTE TITLE: ICI !
                body: 'Un gérant cherche une pièce ! Touchez pour ouvrir.', // 👈 AJOUTE L'ÉTIQUETTE BODY: ICI !
                notificationDetails: notificationDetails, // Le canal d'urgence
              );
            } catch (e) {
              debugPrint("Hoquet sirène Facebook : $e");
            }

            // 🚀 ACTION 2 : L'écran de mission Flash surgit de force sur les pixels !
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlerteFlashVendeurScreen(
                  idAlerte: idAlerte,
                  idVendeur: demandeurId,
                  nomMagasin: widget.nomMagasinLocal,
                  audioUrl: audioUrl,
                ),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    _radarSubscription?.cancel(); // 👈 Fermeture hermétique du robinet pour préserver la RAM
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le radar tourne silencieusement en arrière-plan, mais affiche le Dashboard standard
    return DashboardScreen(idUtilisateur: widget.idUtilisateur);
  }
}
