import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🧠 Persistance d'identité locale
import 'package:record/record.dart'; // 👈 Connecteur Micro
import 'package:path_provider/path_provider.dart'; // 👈 Accès Stockage Temporaire
import 'services/whisper_service.dart'; // 👈 Pipeline Whisper Edge
import 'dashboard.dart';

void main() async {
  // 🛡️ VERROU DE SÉCURITÉ : Assure l'ancrage matériel des liaisons d'OS mobiles
  WidgetsFlutterBinding.ensureInitialized();

  // 📡 CORRECTION CLOUD DIRECTE : Initialisation étanche sans scorie d'URL
  await Supabase.initialize(
    url:
        'https://knvujljgzhnwqcoukuni.supabase.co', // 👈 TON ADRESSE RÉASSEMBLÉE ET PROPRE
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudnVqbGpnemhud3Fjb3VrdW5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MjkzNjksImV4cCI6MjA5MzIwNTM2OX0.1zRseAK5IbjiYdQYju7a-Vn4yGKxeTkzKsVeV7KrYl4', // Clé anonyme d'acier
  );

  // 🗄️ PERSISTANCE FORENSIQUE : Vérification de la présence d'une puce gérant en mémoire flash
  final SharedPreferences memoireLocale = await SharedPreferences.getInstance();
  final String? telephoneIdentifie =
      memoireLocale.getString('telephone_gerant');

  runApp(SwintelBaseApp(telephoneIdentifie: telephoneIdentifie));
}

class SwintelBaseApp extends StatelessWidget {
  final String? telephoneIdentifie;

  const SwintelBaseApp({super.key, this.telephoneIdentifie});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner:
          false, // Éjection des béquilles de laboratoire
      title: 'SWINTEL FLEET',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true, // Calibré pour le SDK Android 36
      ),

      // 🔄 ROUTAGE RECALIBRÉ :
      // Si identifié ➔ Dashboard. Si vierge ➔ Micro d'enregistrement direct !
      home: telephoneIdentifie != null && telephoneIdentifie!.isNotEmpty
          ? DashboardScreen(idUtilisateur: telephoneIdentifie!)
          : const EnregistreurAtelier(),
    );
  }
}

// =============================================================================
// 🎙️ SOUTE TECHNIQUE II : L'INTERFACE DE CAPTURE AUDIO ET DE TRANSCRIPTION
// =============================================================================
class EnregistreurAtelier extends StatefulWidget {
  const EnregistreurAtelier({super.key});

  @override
  State<EnregistreurAtelier> createState() => _EnregistreurAtelierState();
}

class _EnregistreurAtelierState extends State<EnregistreurAtelier> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isProcessing = false;
  String _transcriptionResult = "Appuyez sur le micro pour parler...";

  @override
  void dispose() {
    _audioRecorder.dispose(); // Libération de la RAM du Samsung A10
    super.dispose();
  }

  Future<void> _basculerEnregistrement() async {
    if (_isRecording) {
      await _arreterEtTranscrire();
    } else {
      await _demarrerEnregistrement();
    }
  }

  Future<void> _demarrerEnregistrement() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/audio_atelier.m4a';

        // Encodage AAC basse consommation (32 kbps) idéal pour le réseau de Douala
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 32000),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _transcriptionResult = "Enregistrement en cours... Parlez.";
        });
      } else {
        setState(() => _transcriptionResult = "Accès au micro refusé.");
      }
    } catch (e) {
      setState(() => _transcriptionResult = "Erreur micro : $e");
    }
  }

  Future<void> _arreterEtTranscrire() async {
    try {
      final filePath = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _isProcessing = true;
        _transcriptionResult =
            "Transmission de l'audio 'Chap-Chap' vers Supabase...";
      });

      if (filePath != null) {
        // Envoi au décodeur réseau
        final texteTranscrit = await WhisperService.transcrireAudio(filePath);
        setState(() {
          _transcriptionResult = texteTranscrit;
        });
      }
    } catch (e) {
      setState(() => _transcriptionResult = "Erreur traitement : $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Atelier - Swintel"),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300, width: 2),
              ),
              child: Text(
                _transcriptionResult,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),
            _isProcessing
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber))
                : FloatingActionButton.large(
                    onPressed: _basculerEnregistrement,
                    backgroundColor: _isRecording ? Colors.red : Colors.amber,
                    child: Icon(_isRecording ? Icons.stop : Icons.mic,
                        size: 40, color: Colors.white),
                  ),
          ],
        ),
      ),
    );
  }
}
