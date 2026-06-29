import 'dart:async'; // 🧠 Infrastructure asynchrone des Streams
import 'dart:math' as math; // 👈 L'IMPORTATION GÉOSPATIALE VECTORISÉE
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Indispensable pour injecter les bips physiques
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart'; // 🚀 LE NOUVEAU LEVIER ACOUSTIQUE DIRECT
import 'dashboard.dart';
import 'alerte_flash_vendeur.dart';
import 'main.dart';

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
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // 🔊 INSTANCE UNIQUE POUR L'ACADÉMIE

  @override
  void initState() {
    super.initState();
    // 🚀 NETTOYAGE EN LIGNE DROITE : Zéro paramètre complexe, Gradle passe au vert d'autorité !
    _allumerRadarDeFlotte();
  }

  // 🧠 FONCTION MATHÉMATIQUE DE HAVERSINE : Calcule la distance exacte en kilomètres entre deux points GPS
  double _calculerDistanceHaversine(
      double lat1, double lng1, double lat2, double lng2) {
    const double rayonTerre = 6371.0;
    double dLat = (lat2 - lat1) * math.pi / 180.0;
    double dLng = (lng2 - lng1) * math.pi / 180.0;
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return rayonTerre * c;
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

          if (statutAlerte != 'en_attente') return;
          // if (demandeurId == widget.idUtilisateur) return; // Anti-auto-vibration gelé pour le laboratoire

          try {
            // ----------------------------------------------------------------------
            // 🛰️ COUPLAGE GÉOMÉTRIQUE : Extraction de la position FIXE de l'émetteur G1 depuis Magasins
            // ----------------------------------------------------------------------
            final emetteurData = await _supabase
                .from('Magasins')
                .select('lat, lng')
                .eq('telephone', demandeurId)
                .maybeSingle();

            final double latG1 =
                (emetteurData?['lat'] as num?)?.toDouble() ?? 4.0510;
            final double lngG1 =
                (emetteurData?['lng'] as num?)?.toDouble() ?? 9.7679;

            // ----------------------------------------------------------------------
            // 🏆 FILTRE 1 : CORRÉLATION SÉMANTIQUE DU STOCK DE LA BOUTIQUE ACTUELLE (RÉCEPTEUR)
            // ----------------------------------------------------------------------
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

            bool marqueCompatible = maMarque
                    .toLowerCase()
                    .contains(marqueRecherche.toLowerCase()) ||
                marqueRecherche.isEmpty;
            bool pieceCompatible = monTypePiece
                    .toLowerCase()
                    .contains(pieceRecherche.toLowerCase()) ||
                pieceRecherche.isEmpty;

            if (!marqueCompatible || !pieceCompatible) return;

            // ----------------------------------------------------------------------
            // 🏆 FILTRE 2 : LE CALCUL GÉOSPATIAL (Ancrage sur les Comptoirs Fixes)
            // ----------------------------------------------------------------------
            double distanceDuDeal =
                _calculerDistanceHaversine(latG1, lngG1, maLat, maLng);

            if (distanceDuDeal > 500.0)
              return; // Barrière laboratoire élastique

            // ----------------------------------------------------------------------
            // SI TOUS LES FILTRES PASSENT AU VERT ➡️ LE SMARTPHONE GRONDE ET HURLE DE FORCE !
            // ----------------------------------------------------------------------
            if (mounted) {
              // 📳 ACTION 1.A : DOUBLE ONDE DE CHOC DE VIBRATION (Intensité 255)
              if (await Vibration.hasVibrator() ?? false) {
                Vibration.vibrate(
                  pattern: [0, 500, 200, 500, 200, 500, 200, 500, 200, 800],
                  intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
                );
              }

              // 🔊 ACTION 1.B : LE COURT-CIRCUIT AUDIO DIRECT DE RJ RECTIFIÉ DU LUNDI MIDI
              try {
                await _audioPlayer.stop();
                // Utilisation de la syntaxe de source certifiée v6
                await _audioPlayer.play(AssetSource('sirene.ogg'));
                print(
                    "📡 Sirène d'urgence .ogg propulsée sur le haut-parleur natif !");
              } catch (audioError) {
                debugPrint("Hoquet acoustique direct : $audioError");
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
            debugPrint("Hoquet critique filtres sémantiques/géospatiaux : $e");
          }
        });
  }

  @override
  void dispose() {
    _radarSubscription
        ?.cancel(); // 🧽 Fermeture hermétique du robinet pour préserver la RAM
    _audioPlayer.dispose(); // 🧽 Libération du processeur audio
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(idUtilisateur: widget.idUtilisateur);
  }
}
