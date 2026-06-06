import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 AJOUTE CETTE LIGNE DE FORCE ICI !
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // 🔊 SIRENE DE PREMIER PLAN : Dès que l'écran rouge surgit, on force le bip système !
    Future.delayed(Duration.zero, () async {
      try {
        await SystemSound.play(SystemSoundType.alert);
        await Future.delayed(const Duration(milliseconds: 300));
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  // 🎵 1. Moteur d'écoute accéléré (Pré-chargement pour contrer les lenteurs réseau)
  Future<void> _gererLecture() async {
    if (widget.audioUrl.isEmpty) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        setState(() => _isPlaying = true);

        // 🎯 ANTIDOTE LATENCE : On ordonne au lecteur de mettre en cache agressivement l'audio
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

  // 🟢 2. Action positive : "J'AI LA PIÈCE" (+10 pts) (VERSION VERROUILLÉE ET RAPIDE)
  // 🟢 ACTION POSITIVE : "J'AI LA PIÈCE" (VRAI ALIGNEMENT DES RÔLES EN BASE DE DONNÉES)
  Future<void> _repondreOui() async {
    setState(() => _isProcessing = true);
    try {
      // 🧠 COUTURE TEMPS RÉEL : On écrit d'abord la signature pour libérer l'émetteur instantanément
      await _supabase.from('Alertes').update({
        'statut_alerte':
            'reponse_${widget.nomMagasin}', // Exemple: reponse_ORNY AUTO
      }).eq('id', widget.idAlerte);

      // 🏆 DISTRIBUTION DES POINTS : Le courtier_id reçoit l'ID de l'émetteur et le nom reçoit la cible
      await _supabase.from('BonusCourtage').insert({
        'courtier_id': widget
            .idVendeur, // 👈 C'est l'idUtilisateur/demandeurId transmis (Le vrai courtier !)
        'magasin_cible_nom': widget
            .nomMagasin, // 👈 C'est la boutique qui clique (ORNY AUTO ou MAMBENI AUTO)
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

  // 🔴 3. Action négative : "JE N'AI PAS" (-5 pts malus)
  Future<void> _repondreNon() async {
    setState(() => _isProcessing = true);
    try {
      // Écriture du malus de fiabilité pour refus de collaboration
      await _supabase.from('BonusCourtage').insert({
        'courtier_id': widget.idVendeur,
        'magasin_cible_nom': widget.nomMagasin,
        'points_gagnes': -5, // -5 points de malus
      });

      if (mounted) {
        _afficherMessage(
            "⚠️ Refusal logged. -5 pts reliability score", Colors.orange);
        Navigator.pop(context); // Ferme l'écran instantanément
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _afficherMessage("Erreur : $e", Colors.red);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish
            ? '🔥 SWINTEL - FLASH MISSION'
            : '🔥 SWINTEL - MISSION FLASH'),
        backgroundColor: Colors.redAccent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close,
              color: Colors.black), // Croix d'autorité pour balayer
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor:
          Colors.black87, // Fond sombre pour accentuer le mode d'urgence
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête d'alerte contextuel
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
