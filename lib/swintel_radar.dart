import 'dart:async'; // 🧠 Infrastructure asynchrone des Streams
import 'dart:math'
    as math; // 👈 1. L'IMPORTATION GÉOSPATIALE CORRIGÉE ET POSITIONNÉE ICI !
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Indispensable pour injecter les bips physiques
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'dashboard.dart';
import 'alerte_flash_vendeur.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Le gérant des canaux
import 'main.dart'; // Crucial pour l'instance du plugin

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

  // 🧠 FONCTION MATHÉMATIQUE DE HAVERSINE : Calcule la distance exacte en kilomètres entre deux points GPS
  double _calculerDistanceHaversine(
      double lat1, double lng1, double lat2, double lng2) {
    const double rayonTerre = 6371.0; // Rayon moyen de la Terre en kilomètres

    double dLat = (lat2 - lat1) * math.pi / 180.0;
    double dLng = (lng2 - lng1) * math.pi / 180.0;

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return rayonTerre * c; // Retourne la distance en kilomètres
  }

  void _allumerRadarDeFlotte() {
    // 🧠 INFRASTRUCTURE DE FLUX SÉLECTIF : Écoute le Stream réel des alertes en attente
    _radarSubscription = _supabase
        .from('Alertes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> alertes) async {
          if (alertes.isEmpty) return;

          final alerte = alertes.first;
          final dynamic idAlerte = alerte['id'];
          final String audioUrl = alerte['audio_url'] ?? '';
          final String demandeurId = alerte['demandeur_id'] ?? '';
          final String statutAlerte = alerte['statut_alerte'] ?? '';

          // 🎯 NOUVELLES COUTURES SÉMANTIQUES : Extraction des filtres de l'alerte
          final String marqueRecherche = alerte['marque_concernee'] ?? '';
          final String pieceRecherche = alerte['piece_concernee'] ?? '';

          // Coordonnées GPS de l'émetteur G1 (à extraire de la table ou simulées)
          final double latG1 = alerte['lat_emetteur'] ?? 4.0510;
          final double lngG1 = alerte['lng_emetteur'] ?? 9.7679;

          if (statutAlerte != 'en_attente') return;
          if (demandeurId == widget.idUtilisateur) return;

          // ----------------------------------------------------------------------
          // 🏆 FILTRE 1 : LE FILTRE SÉMANTIQUE DU STOCK LOCAL
          // ----------------------------------------------------------------------
          bool estSpecialisteMarque = widget.nomMagasinLocal
                  .toLowerCase()
                  .contains(marqueRecherche.toLowerCase()) ||
              marqueRecherche.isEmpty;

          if (!estSpecialisteMarque) {
            return; // 🛑 Le magasin actuel n'a pas cette marque -> Le téléphone reste muet !
          }

          // ----------------------------------------------------------------------
          // 🏆 FILTRE 2 : LE FILTRE SPATIAL (La distance "raisonnable" de 5 KM)
          // ----------------------------------------------------------------------
          double latMagasinActuel = 4.0520;
          double lngMagasinActuel = 9.7685;

          double distanceDuDeal = _calculerDistanceHaversine(
              latG1, lngG1, latMagasinActuel, lngMagasinActuel);

          if (distanceDuDeal > 5.0) {
            return; // 🛑 Le magasin est trop loin -> On coupe le signal !
          }
          // ----------------------------------------------------------------------
          // SI TOUS LES FILTRES PASSENT AU VERT ➡️ LE SMARTPHONE GRONDE ET SURGIT !
          // ----------------------------------------------------------------------
          if (mounted) {
            // 📳 ACTION 1.A : RE-COUTURE DES ONDES DE CHOC DE VIBRATION (Intensité 255)
            if (await Vibration.hasVibrator() ?? false) {
              Vibration.vibrate(
                pattern: [0, 500, 200, 500, 200, 500, 200, 500, 200, 800],
                intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
              );
            }

             // 🔊 ACTION 1.B : DÉCLENCHEMENT DE LA SIRÈNE "STYLE FACEBOOK" (Vérification Syntaxe)
            try {
              const AndroidNotificationDetails androidNotificationDetails =
                  AndroidNotificationDetails(
                'swintel_urgent_channel', // ID du canal du main.dart
                '🚨 SWINTEL - ALERTES CRUCIALES',
                channelDescription: 'Canal d\'urgence prioritaire',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                sound: RawResourceAndroidNotificationSound('sirene'), // Cible sirene.ogg local
              );

              const NotificationDetails notificationDetails = NotificationDetails(
                android: androidNotificationDetails,
              );

              // 🎯 APPEL DE FORCE : Chaque argument porte son étiquette réglementaire
              await flutterLocalNotificationsPlugin.show(
                idAlerte.hashCode,
                '🔥 MISSION FLASH SWINTEL !',
                'Un gérant cherche une pièce ! Touchez pour ouvrir.',
                notificationDetails: notificationDetails,
              );
              print("📡 Signal sonore propulsé au canal Android !");
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
    _radarSubscription
        ?.cancel(); // 👈 Fermeture hermétique du robinet pour préserver la RAM
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Le radar tourne silencieusement en arrière-plan, mais affiche le Dashboard standard
    return DashboardScreen(idUtilisateur: widget.idUtilisateur);
  }
}
