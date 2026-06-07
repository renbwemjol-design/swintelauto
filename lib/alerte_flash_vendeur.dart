import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 1. Importation matérielle pour les services système !
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class AlerteFlashVendeurScreen extends StatefulWidget {
  final dynamic idAlerte; // ID UUID de l'alerte de G1
  final String idVendeur; // ID du gérant local (Ex: Ornella / Alyona)
  final String nomMagasin; // Nom du magasin local
  final String audioUrl; // Lien du vocal dicté par G1

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
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Pour la note vocale du client
  final AudioPlayer _sirenePlayer =
      AudioPlayer(); // 👈 2. Le nouveau haut-parleur dédié à la sirène !
  bool _isPlaying = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // 🔊 SIRENE DE PREMIER PLAN MULTIMÉDIA : Version locale d'autorité Android (Zéro Internet)
    Future.delayed(Duration.zero, () async {
      try {
        // On percute les canaux physiques d'autorité du système Android pour forcer deux retours secs
        await HapticFeedback.vibrate();
        await SystemChannels.platform.invokeMethod('HapticFeedback.vibrate');

        // On force le haut-parleur interne à biper en mode 'alert' (Niveau d'urgence max !)
        for (int i = 0; i < 4; i++) {
          await SystemSound.play(SystemSoundType
              .alert); // 👈 BIP NATIVE D'URGENCENCE LOGÉ DANS LE SAMSUNG !
          await Future.delayed(const Duration(milliseconds: 250));
        }
      } catch (e) {
        debugPrint("Hoquet haut-parleur alerte : $e");
      }
    });

    // Écouteur pour réinitialiser le bouton à la fin de la lecture du vocal client
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  // 🎵 Moteur d'écoute accéléré (Pré-chargement pour contrer les lenteurs réseau)
  Future<void> _gererLecture() async {
    if (widget.audioUrl.isEmpty) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        setState(() => _isPlaying = true);

        // 🎯 ANTIDOTE LATENCE : Mise en cache agressive de l'audio client
        if (_audioPlayer.duration == null) {
          await _audioPlayer.setUrl(widget.audioUrl, preload: true);
        }

        await _audioPlayer.play();
      }
    } catch (e) {
      setState(() => _isPlaying = false);
      _afficherMessage("Audio error (Network latency) : $e", Colors.red);
    }
  }

  // 🟢 ACTION POSITIVE : "J'AI LA PIÈCE" (+10 pts) (RÔLES STABLES EN BASE)
  Future<void> _repondreOui() async {
    setState(() => _isProcessing = true);
    try {
      // 🔊 EXTINCTION DE FORCE : On coupe immédiatement la sirène d'alarme !
      await _sirenePlayer.stop();

      // Couture temps réel pour libérer l'émetteur instantanément
      await _supabase.from('Alertes').update({
        'statut_alerte':
            'reponse_${widget.nomMagasin}', // Exemple: reponse_ORNY AUTO
      }).eq('id', widget.idAlerte);

      // Distribution chirurgicale des points dans la table de suivi
      await _supabase.from('BonusCourtage').insert({
        'courtier_id': widget.idVendeur, // Le vrai gérant émetteur
        'magasin_cible_nom':
            widget.nomMagasin, // La boutique réceptrice qui clique
        'points_gagnes': 10,
      });

      if (mounted) {
        _afficherMessage(
            "🎯 Part confirmed! +10 pts reliability score", Colors.green);
        Navigator.pop(context); // Ferme proprement l'écran flash
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _afficherMessage("Erreur : $e", Colors.red);
      }
    }
  }

  // 🔴 ACTION NÉGATIVE : "JE N'AI PAS" (-5 pts malus)
  Future<void> _repondreNon() async {
    setState(() => _isProcessing = true);
    try {
      // 🔊 EXTINCTION DE FORCE : On coupe immédiatement la sirène d'alarme !
      await _sirenePlayer.stop();

      // Écriture du malus de fiabilité pour refus de collaboration
      await _supabase.from('BonusCourtage').insert({
        'courtier_id': widget.idVendeur,
        'magasin_cible_nom': widget.nomMagasin,
        'points_gagnes': -5,
      });

      if (mounted) {
        _afficherMessage(
            "⚠️ Refusal logged. -5 pts reliability score", Colors.orange);
        Navigator.pop(context); // Ferme l'écran instantanément
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _afficherMessage("Erreur : $e", Colors.red);
      }
    }
  }

  void _afficherMessage(String msg, Color couleur) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: couleur,
            duration: const Duration(seconds: 3)),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _sirenePlayer
        .dispose(); // 👈 3. Libération étanche du haut-parleur de sirène !
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.black87, // Fond sombre d'urgence
      appBar: AppBar(
        title: Text(isEnglish
            ? '🔥 SWINTEL - FLASH MISSION'
            : '🔥 SWINTEL - MISSION FLASH'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () async {
            await _sirenePlayer.stop(); // Sécurité au balayage par la croix
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.redAccent.withOpacity(0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        isEnglish
                            ? "🚨 NEW SPARE PART REQUEST TARGETED TO YOUR STOCK!"
                            : "🚨 NOUVELLE DEMANDE DE PIÈCE CIBLÉE SUR VOTRE STOCK !",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // 🎵 GROS BOUTON CENTRAL : ÉCOUTER LA DEMANDE DU GÉRANT
                  ElevatedButton(
                    onPressed: _gererLecture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying ? Colors.red : Colors.amber,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(50),
                      elevation: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 60, color: Colors.black),
                        const SizedBox(height: 10),
                        Text(
                          _isPlaying
                              ? "PAUSE"
                              : (isEnglish
                                  ? "LISTEN ALERT"
                                  : "ÉCOUTER L'ALERTE"),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // ZONE DES GROS BOUTONS MÉTIERS DU BAS
                  Row(
                    children: [
                      // 🟢 GROS BOUTON VERT : J'AI LA PIÈCE
                      Expanded(
                        child: SizedBox(
                          height: 100,
                          child: ElevatedButton(
                            onPressed: _repondreOui,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, size: 30),
                                const SizedBox(height: 5),
                                Text(
                                    isEnglish
                                        ? "YES / I HAVE IT"
                                        : "YES / J'AI LA PIÈCE",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),

                      // 🔴 GROS BOUTON ROUGE : JE N'AI PAS LA PIÈCE
                      Expanded(
                        child: SizedBox(
                          height: 100,
                          child: ElevatedButton(
                            onPressed: _repondreNon,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cancel, size: 30),
                                const SizedBox(height: 5),
                                Text(
                                    isEnglish
                                        ? "NO / I DON'T"
                                        : "NO / JE N'AI PAS",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
