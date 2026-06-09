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

          // 🎯 EXTRACTION SÉMANTIQUES : Extraction des filtres de l'alerte
          final String marqueRecherche = alerte['marque_concernee'] ?? '';
          final String pieceRecherche = alerte['piece_concernee'] ?? '';

          // Coordonnées GPS de l'émetteur G1 (Lues en base ou repli Camp Yabassi)
          final double latG1 = alerte['lat_emetteur'] ?? 4.0510;
          final double lngG1 = alerte['lng_emetteur'] ?? 9.7679;

          if (statutAlerte != 'en_attente') return;
          if (demandeurId == widget.idUtilisateur)
            return; // Anti-auto-vibration

          try {
            // ----------------------------------------------------------------------
            // 🏆 FILTRE 1 : CORRÉLATION SÉMANTIQUE DU STOCK DE LA BOUTIQUE ACTUELLE
            // ----------------------------------------------------------------------
            // Le téléphone va interroger la table Magasins pour vérifier ses propres spécialités
            final boutiqueData = await _supabase
                .from('Magasins')
                .select('specialite_marque, specialite_type, lat, lng')
                .eq('telephone', widget.idUtilisateur)
                .maybeSingle();

            if (boutiqueData == null) return;

            final String maMarque = boutiqueData['specialite_marque'] ?? '';
            final String monTypePiece = boutiqueData['specialite_type'] ?? '';
            final double maLat =
                (boutiqueData['lat'] as num?)?.toDouble() ?? 0.0;
            final double maLng =
                (boutiqueData['lng'] as num?)?.toDouble() ?? 0.0;

            // Logique de filtrage sémantique tolérante aux minuscules/majuscules
            bool marqueCompatible = maMarque
                    .toLowerCase()
                    .contains(marqueRecherche.toLowerCase()) ||
                marqueRecherche.isEmpty;
            bool pieceCompatible = monTypePiece
                    .toLowerCase()
                    .contains(pieceRecherche.toLowerCase()) ||
                pieceRecherche.isEmpty;

            // Si le magasin n'a pas la spécialité demandée, on coupe instantanément le signal !
            if (!marqueCompatible || !pieceCompatible) {
              return; // 🛑 Boutique non qualifiée. Le téléphone reste totalement muet !
            }

            // ----------------------------------------------------------------------
            // 🏆 FILTRE 2 : LE CALCUL GÉOSPATIAL (Formule de Haversine)
            // ----------------------------------------------------------------------
            double distanceDuDeal =
                _calculerDistanceHaversine(latG1, lngG1, maLat, maLng);

            if (distanceDuDeal > 5.0) {
              return; // 🛑 Trop loin du goudron de G1 (supérieur à 5 km) -> On coupe !
            }
            // ----------------------------------------------------------------------
            // SI TOUS LES FILTRES PASSENT AU VERT ➡️ LE SMARTPHONE GRONDE ET SURGIT !
            // ----------------------------------------------------------------------
            if (mounted) {
              // 📳 ACTION 1.A : DOUBLE ONDE DE CHOC DE VIBRATION (Intensité 255)
              if (await Vibration.hasVibrator() ?? false) {
                Vibration.vibrate(
                  pattern: [0, 500, 200, 500, 200, 500, 200, 500, 200, 800],
                  intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
                );
              }

              // 🔊 ACTION 1.B : DÉCLENCHEMENT DE LA SIRÈNE "STYLE FACEBOOK"
              try {
                const AndroidNotificationDetails androidNotificationDetails =
                    AndroidNotificationDetails(
                  'swintel_sirene_force',
                  '🚨 SWINTEL - SIRENE D\'URGENCE',
                  channelDescription: 'Canal d\'urgence prioritaire',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                  sound: RawResourceAndroidNotificationSound('sirene'),
                );

                const NotificationDetails notificationDetails =
                    NotificationDetails(
                  android: androidNotificationDetails,
                );

                // Syntaxe 2026 : Chaque argument est nommé sans exception !
                await flutterLocalNotificationsPlugin.show(
                  id: idAlerte.hashCode,
                  title: '🔥 MISSION FLASH SWINTEL !',
                  body:
                      'Une pièce compatible ($marqueRecherche) est recherchée à ${distanceDuDeal.toStringAsFixed(1)} km !',
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
          } catch (e) {
            debugPrint("Hoquet filtres sémantiques : $e");
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
