import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class WhisperService {
  /// Point de terminaison direct de notre Edge Function sur Supabase
  static const String _functionUrl =
      'https://knvujljgzhnwqcoukuni.supabase.co/functions/v1/whisper-transcribe';

  /// Clé anonyme publique du projet (Passe-droit obligatoire pour la douane Supabase)
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudnVqbGpnemhud3Fjb3VrdW5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MjkzNjksImV4cCI6MjA5MzIwNTM2OX0.1zRseAK5IbjiYdQYju7a-Vn4yGKxeTkzKsVeV7KrYl4';

  /// Expédie l'audio via un canal HTTP Multipart standardisé
  static Future<String> transcrireAudio(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return "Erreur : Le fichier audio est introuvable.";
    }

    try {
      // 1. Montage du conteneur de transport réseau avec la clé anonyme intégrée
      final request = http.MultipartRequest('POST', Uri.parse(_functionUrl))
        ..headers['Authorization'] = 'Bearer $_supabaseAnonKey'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      // 2. Propulsion et attente du retour de vol
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 3. Décodage du texte brut
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['text'] ?? "Transcription vide.";
      } else {
        return "Erreur Edge Function (Code ${response.statusCode}) : ${response.body}";
      }
    } catch (e) {
      return "Échec de la liaison réseau : $e";
    }
  }
}
