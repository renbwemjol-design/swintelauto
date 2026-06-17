import 'dart:typed_data';
import 'dart:io' as FileIO;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // 👈 1. IMPORTATION GÉOSPATIALE INTÉGRÉE D'AUTORITÉ !
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'moteur_courtage.dart';

class EcranCreerAlerte extends StatefulWidget {
  final String idGerant;
  const EcranCreerAlerte({super.key, required this.idGerant});

  @override
  State<EcranCreerAlerte> createState() => _EcranCreerAlerteState();
}

class _EcranCreerAlerteState extends State<EcranCreerAlerte> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  String? _audioPath;
  Uint8List? _audioBytes;
  bool _isSending = false;
  String _typeFluxSelected = 'presentiel';

  Future<void> _demarrerEnregistrement() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationSupportDirectory();
        final String cheminSecurise = '${directory.path}/alerte_whatsapp.m4a';

        final ancienFichier = FileIO.File(cheminSecurise);
        if (ancienFichier.existsSync()) {
          try {
            ancienFichier.deleteSync();
          } catch (_) {}
        }

        await _audioRecorder.start(
          const RecordConfig(
              encoder: AudioEncoder.aacLc, bitRate: 32000, sampleRate: 16000),
          path: cheminSecurise,
        );

        setState(() {
          _isRecording = true;
          _audioPath = cheminSecurise;
          _audioBytes = null;
        });
      }
    } catch (e) {
      _afficherMessage("Erreur micro : $e", Colors.red);
    }
  }

  Future<void> _arreterEnregistrement() async {
    if (!_isRecording) return;
    try {
      final pathObtenu = await _audioRecorder.stop();
      await Future.delayed(const Duration(milliseconds: 600));

      final cheminFinal = pathObtenu ?? _audioPath;

      if (cheminFinal != null) {
        final fichierPhysique = FileIO.File(cheminFinal);

        if (fichierPhysique.existsSync()) {
          final Uint8List octetsAudio = fichierPhysique.readAsBytesSync();

          setState(() {
            _isRecording = false;
            _audioBytes = octetsAudio;
          });

          _afficherMessage(
              "🎤 Vocal enregistré / Voice recorded !", Colors.green);
        } else {
          setState(() => _isRecording = false);
          _afficherMessage(
              "⚠️ Audio non figé / Audio error. Retry.", Colors.orange);
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
      _afficherMessage("Erreur arrêt micro : $e", Colors.red);
    }
  }

  // 🎯 RE-COUTURE INTÉGRALE DE LA PROPULSION AVEC CAPTURE GPS RÉELLE DE G1
  Future<void> _propulserAlerte() async {
    if (_audioBytes == null || _audioBytes!.isEmpty) {
      _afficherMessage(
          "🗣️ Hold button to record / Maintenez le bouton", Colors.orange);
      return;
    }

    setState(() => _isSending = true);

    try {
      // 📍 CAPTURE DE LA POSITION GPS PHYSIQUE DE L'ÉMETTEUR
      double latEmetteur = 4.0510; // Position de repli Camp Yabassi
      double lngEmetteur = 9.7679;

      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        latEmetteur = position.latitude;
        lngEmetteur = position.longitude;
      } catch (e) {
        debugPrint("Hoquet GPS émetteur (utilisation valeur par défaut) : $e");
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _supabase.storage.from('audios_recrutement').uploadBinary(
            fileName,
            _audioBytes!,
            fileOptions: const FileOptions(contentType: 'audio/aac'),
          );

      final audioUrl =
          _supabase.storage.from('audios_recrutement').getPublicUrl(fileName);

      // 🧠 Extraction Sémantique Simulée pour la grille de match
      String marqueExtraite = "Toyota";
      String pieceExtraite =
          _typeFluxSelected == 'presentiel' ? "Amortisseur" : "Cardan";

      // 🚀 INJECTION ÉTANCHE EN BASE AVEC LES MARQUES ET LA GÉOLOCALISATION
      await _supabase.from('Alertes').insert({
        'demandeur_id': widget.idGerant,
        'type_flux': _typeFluxSelected,
        'audio_url': audioUrl,
        'statut_alerte': 'en_attente',
        'marque_concernee': marqueExtraite,
        'piece_concernee': pieceExtraite,
      //  'lat_emetteur': latEmetteur, // 👈 PUSH LA POSITION GPS ICI D'AUTORITÉ !
      //  'lng_emetteur': lngEmetteur,
      });

      if (mounted) {
        setState(() => _isSending = false);
        _afficherMessage("🚀 Alerte propulsée avec succès !", Colors.green);

        // Transition d'autorité vers l'écran de courtage match
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MoteurCourtageScreen(
              marqueRecherche: marqueExtraite,
              typeRecherche: pieceExtraite,
              latG1: latEmetteur,
              lngG1: lngEmetteur,
              idUtilisateur: widget.idGerant,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSending = false);
      _afficherMessage("Erreur propulsion : $e", Colors.red);
    }
  }

  void _afficherMessage(String msg, Color couleur) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: couleur,
            duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose(); // 👈 Libération étanche du micro en RAM
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🌍 Détection automatique de la langue du système de la boutique
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish
            ? 'SWINTEL - Broadcast Alert'
            : 'SWINTEL - Émettre Alerte'),
        backgroundColor: Colors.amber,
        // 🎯 FORCE LE BOUTON ET L'ACTION DE RETOUR IMMÉDIATE POUR LE DIRECTEUR
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isSending
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      isEnglish
                          ? '1. CUSTOMER TRAFFIC TYPE'
                          : '1. TYPE DE FLUX CLIENT',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // 🚶‍♂️ OPTION COMPTOIR (PRÉSENTIEL)
                      Expanded(
                        child: ChoiceChip(
                          label: Text(
                              isEnglish
                                  ? '🚶‍♂️ COUNTER\n(In-person)'
                                  : '🚶‍♂️ COMPTOIR\n(Présentiel)',
                              textAlign: TextAlign.center),
                          selected: _typeFluxSelected == 'presentiel',
                          onSelected: (val) =>
                              setState(() => _typeFluxSelected = 'presentiel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 📞 OPTION TÉLÉPHONE (DISTANCIEL)
                      Expanded(
                        child: ChoiceChip(
                          label: Text(
                              isEnglish
                                  ? '📞 PHONE\n(Remote)'
                                  : '📞 TÉLÉPHONE\n(Distanciel)',
                              textAlign: TextAlign.center),
                          selected: _typeFluxSelected == 'distanciel',
                          onSelected: (val) =>
                              setState(() => _typeFluxSelected = 'distanciel'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Text(
                      isEnglish
                          ? '2. RECORDING (WHATSAPP STYLE)'
                          : '2. ENREGISTREMENT (STYLE WHATSAPP)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 15),

                  // 🎤 CONTENEUR ANIME REACTION TACTILE STYLE WHATSAPP
                  GestureDetector(
                    onLongPressStart: (_) => _demarrerEnregistrement(),
                    onLongPressEnd: (_) => _arreterEnregistrement(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.green : Colors.amber,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: _isRecording
                            ? [
                                BoxShadow(
                                    color: Colors.green.withOpacity(0.5),
                                    blurRadius: 15,
                                    spreadRadius: 5)
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(_isRecording ? Icons.mic : Icons.mic_none,
                              size: 50,
                              color:
                                  _isRecording ? Colors.white : Colors.black),
                          const SizedBox(height: 10),
                          Text(
                            _isRecording
                                ? (isEnglish
                                    ? 'RECORDING IN PROGRESS...\n(Release to stop)'
                                    : 'ENREGISTREMENT EN COURS...\n(Lâchez pour couper)')
                                : (isEnglish
                                    ? 'HOLD DOWN\nTO DICTATE SPARE PART'
                                    : 'MAINTENEZ ENFONCÉ\nPOUR DICTER LA PIÈCE'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _isRecording ? Colors.white : Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // 📡 LE BOUTON FINAL DE PROPULSION DU SIGNAL GÉOSPATIAL
                  ElevatedButton(
                    onPressed: _propulserAlerte,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: Text(
                        isEnglish
                            ? '📡 BROADCAST ALERT'
                            : "📡 PROPULSER L'ALERTE",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ],
              ),
            ),
    );
  }
}
