import 'dart:async';
import 'dart:math'
    as math; // 📐 Indispensable pour la trigonométrie sphérique dure
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart'; // 🦾 Piston du moteur haptique maximal 255
import 'package:just_audio/just_audio.dart'; // 🎵 Intercepteur acoustique en cache local
import 'alerte_flash_vendeur.dart';

class SwintelRadarScreen extends StatefulWidget {
  final String idUtilisateur; // Le numéro WhatsApp de la boutique G2 réceptrice

  const SwintelRadarScreen({super.key, required this.idUtilisateur});

  @override
  State<SwintelRadarScreen> createState() => _SwintelRadarScreenState();
}

class _SwintelRadarScreenState extends State<SwintelRadarScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late AudioPlayer _audioPlayer; // Cache acoustique d'écurie

  double _latG2 = 0.0;
  double _lngG2 = 0.0;
  String _marqueG2 = '';
  String _pieceG2 = '';
  bool _isInitializing = true;
  String? _derniereAlerteTraiteeId; // Verrou anti-hoquet de répétition

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _chargerProfilEtAmorcerRadar();
  }

  // 🗜️ EXTRACTION DU CADRE DE VÉRITÉ : Lecture du profil G2 pour calibrer les filtres
  Future<void> _chargerProfilEtAmorcerRadar() async {
    try {
      final profil = await _supabase
          .from('Magasins')
          .select('lat, lng, specialite_marque, specialite_type')
          .eq('telephone', widget.idUtilisateur)
          .maybeSingle();
      if (profil != null && mounted) {
        setState(() {
          _latG2 = (profil['lat'] as num).toDouble();
          _lngG2 = (profil['lng'] as num).toDouble();
          _marqueG2 = profil['specialite_marque'] ?? '';
          _pieceG2 = profil['specialite_type'] ?? '';
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint("🚨 Erreur amorçage profil radar : $e");
    }
  }

  // 📐 FORMULE MATHEMATIQUE DE HAVERSINE : Calcul de distance sphérique non linéaire sur float8
  double _calculerDistanceHaversine(
      double lat1, double lon1, double lat2, double lon2) {
    const double rayonTerreKm = 6371.0;
    final double dLat = _convertirEnRadians(lat2 - lat1);
    final double dLon = _convertirEnRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_convertirEnRadians(lat1)) *
            math.cos(_convertirEnRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return rayonTerreKm * c; // Distance géométrique ultra-precise au centimètre
  }

  double _convertirEnRadians(double degres) => degres * (math.pi / 180);

  // 💥 COMMANDE PHYSIQUE DES COMPOSANTS (Intensité 255 + Sirène)
  void _declencherAlertePhysiqueMaximale() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1500, amplitude: 255);
    }
    try {
      await _audioPlayer.setAsset('assets/son/sirene_urgence.ogg');
      _audioPlayer.play();
    } catch (e) {
      debugPrint("🚨 Erreur lecture sirène : $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer
        .dispose(); // 🧽 Libération de la puce audio pour interdire les fuites de RAM
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    if (_isInitializing) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.blue)));
    }

    return Scaffold(
      backgroundColor: Colors.black, // Mode furtif de surveillance nocturne
      appBar: AppBar(
        title: Text(
            isEnglish ? 'SWINTEL RADAR - ACTIVE' : 'RADAR SWINTEL - ACTIF',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white)),
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 🧠 PIPELINE COMPLET FLUX SANS EQ : Le flux réseau capte toutes les alertes ouvertes, et le tri se fait en RAM locale
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('Alertes').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.radar, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                      isEnglish
                          ? "Scanning market..."
                          : "Balayage sémantique du marché...",
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          // 🎯 LE VERROU SÉMANTIQUE COMPLET EN RAM : Tri simultané de l'état, de la marque et de la pièce d'usine !
          final alertesBrutesDuReseau = snapshot.data!;
          final alertesDuFlux = alertesBrutesDuReseau.where((alerte) {
            return alerte['statut_alerte'] == 'en_attente' &&
                alerte['marque_concernee'] == _marqueG2 &&
                alerte['piece_concernee'] == _pieceG2;
          }).toList();

          // Si aucune alerte en cours ne correspond strictly à notre profil de spécialiste
          if (alertesDuFlux.isEmpty) {
            return Center(
              child: Text(
                  isEnglish
                      ? "No matching parts..."
                      : "Aucune pièce correspondante...",
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            );
          }

          // 🔎 ANALYSE GÉOSPATIALE DE LA TOUTE DERNIÈRE REQUÊTE FILTRÉE (MARQUE + PIECE CORRÉLÉES)
          final derniereAlerte = alertesDuFlux.first;
          final String idAlerte = derniereAlerte['id'];
          final String demandeurId = derniereAlerte['demandeur_id'] ?? '';
          final String urlAudio = derniereAlerte['audio_url'] ?? '';

          // 🔄 APPEL ASYNC POUR RÉCUPÉRER LA POSITION FIXE DE G1 DEPUIS LA TABLE MAGASINS
          return FutureBuilder<Map<String, dynamic>?>(
            future: _supabase
                .from('Magasins')
                .select('lat, lng')
                .eq('telephone', demandeurId)
                .maybeSingle(),
            builder: (context, geoSnapshot) {
              if (!geoSnapshot.hasData || geoSnapshot.data == null)
                return const SizedBox.shrink();

              final double latG1 = (geoSnapshot.data!['lat'] as num).toDouble();
              final double lngG1 = (geoSnapshot.data!['lng'] as num).toDouble();

              // CALCUL DE LA DISTANCE RÉELLE VIA HAVERSINE
              final double distanceKm =
                  _calculerDistanceHaversine(_latG2, _lngG2, latG1, lngG1);

              // 🎯 BRIDAGE MAXIMUM DU RADAR : Le signal percute strictly si distance ≤ 5.0 km
              if (distanceKm <= 5.0) {
                if (_derniereAlerteTraiteeId != idAlerte) {
                  _derniereAlerteTraiteeId = idAlerte;

                  // Déclenchement instantané des composants physiques (Intensité 255 + Sirène)
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _declencherAlertePhysiqueMaximale();

                    // Propulsion tactile immédiate vers l'écran d'urgence rouge (UE 205)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlerteFlashVendeurScreen(
                          idAlerte: idAlerte,
                          idVendeur: widget.idUtilisateur,
                          nomMagasin: "Mon Comptoir",
                          audioUrl: urlAudio,
                        ),
                      ),
                    );
                  });
                }
              }

              return Center(
                child: Text(
                  isEnglish
                      ? "⚠️ DANGER ZONE: Request within radius!"
                      : "⚠️ COMPTOIR CIBLE DETECTÉ DANS LE RAYON !",
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
