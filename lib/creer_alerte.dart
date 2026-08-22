import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart'; // 🧠 Pilotage de bas niveau de la bobine du microphone
import 'package:supabase_flutter/supabase_flutter.dart';
import 'moteur_courtage.dart';

class EcranCreerAlerte extends StatefulWidget {
  final String idGerant; // Le numéro WhatsApp de la boutique émettrice G1

  const EcranCreerAlerte({super.key, required this.idGerant});

  @override
  State<EcranCreerAlerte> createState() => _EcranCreerAlerteState();
}

class _EcranCreerAlerteState extends State<EcranCreerAlerte> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final AudioRecorder _enregistreurMicro; // Le piston matériel acoustique

  String? _pathAudioLocal;
  bool _isRecording = false;
  bool _isUploading = false;
  String _canalTraficClient = 'COMPTOIR'; // Option 'COMPTOIR' ou 'TELEPHONE'

  @override
  void initState() {
    super.initState();
    _enregistreurMicro = AudioRecorder();
  }

  // 🎤 CAPTATION ACOUSTIQUE HARDWARE : Configuration agressive anti-saturation de RAM
  Future<void> _demarrerEnregistrementVocal() async {
    try {
      if (await _enregistreurMicro.hasPermission()) {
        final Directory repertoireTemporaire = Directory.systemTemp;
        final String cheminFichier =
            '${repertoireTemporaire.path}/vocal_brut.aac';

        // 🔥 BRIDAGE COUTURE SÉMANTIQUE : Configuration matérielle AAC-LC à 32 kbps d'usine
        const RecordConfig configurationAudio = RecordConfig(
          encoder: AudioEncoder.aacLc, // Codec de crête universel
          sampleRate:
              16000, // Fréquence native calibrée pour l'IA Whisper du S3
          bitRate: 32000, // Compresse de force le flux à 32 kbps (Ultra-léger)
        );

        await _enregistreurMicro.start(configurationAudio, path: cheminFichier);
        setState(() {
          _isRecording = true;
          _pathAudioLocal = cheminFichier;
        });
      }
    } catch (e) {
      _afficherSnackBar("🚨 Échec d'activation du microphone : $e", Colors.red);
    }
  }

  Future<void> _arreterEnregistrementVocal() async {
    try {
      final String? cheminFinal = await _enregistreurMicro.stop();
      if (cheminFinal != null) {
        setState(() {
          _isRecording = false;
          _pathAudioLocal = cheminFinal;
        });
      }
    } catch (e) {
      debugPrint("🚨 Erreur arrêt micro : $e");
    }
  }

  // 🚀 PROPULSION ASYNCHRONE DE L'ALERTE EN FLOTTE (Table 2 + Table 4)
  // 🚀 INJECTION DE L'OREILLE NEURONALE : Fin des simulations, place au goudron réel !
  Future<void> _propulserAlerteEnFlotte() async {
    if (_pathAudioLocal == null || _pathAudioLocal!.isEmpty) {
      _afficherSnackBar(
          "⚠️ Veuillez d'abord enregistrer un message vocal", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final File fichierAudio = File(_pathAudioLocal!);
      // Génération de l'identifiant unique avec obfuscation sémantique temporelle [▲]
      final String nomFichierCloud =
          "vocal_${widget.idGerant}_${DateTime.now().millisecondsSinceEpoch}.aac";

      // 1. PROPULSION STORAGE (Table 4) : Envoi direct du binaire compressé à la source
      await _supabase.storage
          .from('alertes_audio')
          .upload('public/$nomFichierCloud', fichierAudio);
      final String urlAudioPublique = _supabase.storage
          .from('alertes_audio')
          .getPublicUrl('public/$nomFichierCloud');

      _afficherSnackBar(
          "🧠 Analyse sémantique trilingue par Whisper en cours...",
          Colors.blue);

      // 🤖 INTERCEPTION PAR L'OREILLE NEURONALE : Invocation de la Edge Function Swintel
      final responseIA = await _supabase.functions.invoke(
        'swintel-whisper-extractor',
        body: {'audio_url': urlAudioPublique},
      );

      // Dépaquetage du JSON d'acier calculé par Groq Whisper en moins de 200ms
      final dataIA = responseIA.data as Map<String, dynamic>;
      final String marqueExtraite =
          dataIA['marque'] ?? 'Toutes'; // Extrait par l'IA (Ex: 'Toyota')
      final String pieceExtraite =
          dataIA['piece'] ?? 'Générale'; // Extrait par l'IA (Ex: 'Amortisseur')

      // Extraction immédiate de la position fixe de G1 (Table 1) pour le routage
      final boutiqueG1 = await _supabase
          .from('Magasins')
          .select('lat, lng')
          .eq('telephone', widget.idGerant)
          .single();
      final double latG1 = (boutiqueG1['lat'] as num).toDouble();
      final double lngG1 = (boutiqueG1['lng'] as num).toDouble();

      // 2. INSERTION RELATIONNELLE ATOMIQUE (Table 2) : Mutation sous contrôle des verrous RLS [▲]
      await _supabase.from('Alertes').insert({
        'demandeur_id': widget.idGerant,
        'audio_url': urlAudioPublique,
        'canal_client': _canalTraficClient,
        'marque_concernee': marqueExtraite,
        'piece_concernee': pieceExtraite,
        'statut_alerte':
            'en_attente', // Allume instantanément le WebSocket réactif ! [▲]
      });

      if (mounted) {
        _afficherSnackBar(
            "🚀 Alerte décodée par Whisper et diffusée au marché !",
            Colors.green);

        // Propulsion immédiate vers l'entonnoir du Moteur de Courtage (Pièce 7)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MoteurCourtageScreen(
              marqueRecherche: marqueExtraite,
              typeRecherche: pieceExtraite,
              latG1: latG1,
              lngG1: lngG1,
              idUtilisateur: widget.idGerant,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        _afficherSnackBar(
            "🚨 Échec critique du pipeline IA Whisper : $e", Colors.red);
      }
    }
  }

  void _afficherSnackBar(String msg, Color couleur) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  @override
  void dispose() {
    _enregistreurMicro
        .dispose(); // 🧽 Libération atomique de la bobine matérielle du micro
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Text(isEnglish ? 'BROADCAST ALERT' : 'DIFFUSER UNE ALERTE',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          backgroundColor: Colors.amber,
          centerTitle: true),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // SÉLECTEUR DE SÉMANTIQUE COMMERCIALE (Canal)
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                          value: 'COMPTOIR',
                          label: Text(
                              isEnglish ? 'Walk-in Client' : 'Client Comptoir'),
                          icon: const Icon(Icons.store)),
                      ButtonSegment(
                          value: 'TELEPHONE',
                          label:
                              Text(isEnglish ? 'Phone Client' : 'Client Appel'),
                          icon: const Icon(Icons.phone)),
                    ],
                    selected: {_canalTraficClient},
                    onSelectionChanged: (v) =>
                        setState(() => _canalTraficClient = v.first),
                    style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: Colors.amber),
                  ),
                  const SizedBox(height: 60),

                  // INTERRUPTEUR MATÉRIEL DU CAPTEUR MICROPHONE
                  GestureDetector(
                    onLongPressStart: (_) => _demarrerEnregistrementVocal(),
                    onLongPressEnd: (_) => _arreterEnregistrementVocal(),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          _isRecording ? Colors.red : Colors.orange,
                      child: Icon(_isRecording ? Icons.mic : Icons.mic_none,
                          size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording
                        ? (isEnglish
                            ? "Recording at 32 kbps..."
                            : "Enregistrement en cours (32 kbps)...")
                        : (isEnglish
                            ? "Hold down to speak"
                            : "Maintenez enfoncé pour parler"),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isRecording ? Colors.red : Colors.grey,
                        fontSize: 13),
                  ),
                  const SizedBox(height: 60),

                  // BOUTON DE PROPULSION FINALE
                  ElevatedButton.icon(
                    onPressed: _pathAudioLocal == null || _isRecording
                        ? null
                        : _propulserAlerteEnFlotte,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.send),
                    label: Text(
                        isEnglish
                            ? "PROPEL TO FLEET RADARS"
                            : "PROPULSER AUX RADARS",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
    );
  }
}
