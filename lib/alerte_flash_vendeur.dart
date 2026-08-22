import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart'; // 🧠 Intercepteur acoustique anti-latence 4G
import 'moteur_courtage.dart';

class AlerteFlashVendeurScreen extends StatefulWidget {
  final dynamic idAlerte;
  final String idVendeur;
  final String nomMagasin;
  final String audioUrl;

  const AlerteFlashVendeurScreen({
    super.key,
    required this.idAlerte,
    required this.idVendeur,
    required this.nomMagasin,
    required this.audioUrl,
  });

  @override
  State<AlerteFlashVendeurScreen> createState() =>
      _AlerteFlashVendeurScreenState();
}

class _AlerteFlashVendeurScreenState extends State<AlerteFlashVendeurScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late AudioPlayer _playerAudioHub;
  bool _isPlaying = false;
  bool _isActionneurBloque = false;

  @override
  void initState() {
    super.initState();
    _playerAudioHub = AudioPlayer();
    _amorcerEtPrechargerAudioGoudron();
  }

  // 🎵 ANTIDOTE AUX LATENCES : Pré-chargement agressif du binaire audio en RAM tampon
  Future<void> _amorcerEtPrechargerAudioGoudron() async {
    if (widget.audioUrl.isEmpty) return;
    try {
      // Le flux se charge en tâche de fond avant même que le gérant ne clique sur écouter
      await _playerAudioHub.setUrl(widget.audioUrl, preload: true);

      _playerAudioHub.playerStateStream.listen((etat) {
        if (mounted) {
          setState(() {
            _isPlaying = etat.playing;
          });
        }
      });
    } catch (e) {
      debugPrint("🚨 Échec pré-chargement audio cache : $e");
    }
  }

  Future<void> _basculerLectureAudio() async {
    try {
      if (_isPlaying) {
        await _playerAudioHub.pause();
      } else {
        await _playerAudioHub.play();
      }
    } catch (e) {
      _afficherSnackBar("🚨 Échec lecture : $e", Colors.red);
    }
  }

  // 🚀 TRANSACTION D'URGENCE (Prendre l'affaire - Mutation Table 2)
  Future<void> _capturerAffaireDuComptoir() async {
    setState(() => _isActionneurBloque = true);

    try {
      // 🎨 ARBORESCENCE TRICOLORE : Mutation sémantique stricte du statut (LIKE 'reponse_%')
      final String nouveauStatutReglementaire = "reponse_${widget.nomMagasin}";

      // Mise à jour atomique dans PostgreSQL Supabase
      await _supabase.from('Alertes').update({
        'statut_alerte': nouveauStatutReglementaire,
      }).eq('id', widget.idAlerte);

      // Récupération instantanée de la position fixe du vendeur (Table 1) pour le Moteur de Courtage
      final positionVendeur = await _supabase
          .from('Magasins')
          .select('lat, lng, specialite_marque, specialite_type')
          .eq('telephone', widget.idVendeur)
          .single();

      if (mounted) {
        await _playerAudioHub.stop();
        _afficherSnackBar("🎉 Affaire verrouillée au comptoir !", Colors.green);

        // Propulsion immédiate vers le Moteur de Courtage (Pièce 7)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MoteurCourtageScreen(
              marqueRecherche: positionVendeur['specialite_marque'] ?? '',
              typeRecherche: positionVendeur['specialite_type'] ?? '',
              latG1: (positionVendeur['lat'] as num).toDouble(),
              lngG1: (positionVendeur['lng'] as num).toDouble(),
              idUtilisateur: widget.idVendeur,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionneurBloque = false);
        _afficherSnackBar("🚨 Erreur de verrouillage du deal : $e", Colors.red);
      }
    }
  }

  void _afficherSnackBar(String msg, Color couleur) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  @override
  void dispose() {
    _playerAudioHub.dispose(); // 🧽 Libération stricte de la puce son
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.red.shade900, // Alerte flash maximale visuelle
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 90, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                isEnglish
                    ? "⚡ EMERGENCY REQUEST INBOUND ! ⚡"
                    : "⚡ DEMANDE D'URGENCE COMPTOIR ! ⚡",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Bouton d'interception acoustique immédiat
              ElevatedButton.icon(
                onPressed: _isActionneurBloque ? null : _basculerLectureAudio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon:
                    Icon(_isPlaying ? Icons.pause : Icons.volume_up, size: 24),
                label: Text(
                  _isPlaying
                      ? (isEnglish ? "PAUSE DISPATCH" : "PAUSE LA DICTÉE")
                      : (isEnglish
                          ? "LISTEN TO REQUEST"
                          : "ÉCOUTER LA DEMANDE"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Bouton de prise en charge et de clôture du deal
              ElevatedButton.icon(
                onPressed:
                    _isActionneurBloque ? null : _capturerAffaireDuComptoir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 24),
                label: Text(
                  isEnglish ? "TAKE REPAIR DEAL" : "PRENDRE L'AFFAIRE",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
