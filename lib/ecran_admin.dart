import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

class EcranAdminSecret extends StatefulWidget {
  const EcranAdminSecret({super.key});

  @override
  State<EcranAdminSecret> createState() => _EcranAdminSecretState();
}

class _EcranAdminSecretState extends State<EcranAdminSecret> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<dynamic> _magasinsEnAttente = [];
  bool _isLoading = true;
  String? _idAudioEnCours; // Pour savoir quelle ligne est en train d'être jouée

  @override
  void initState() {
    super.initState();
    _recupererCandidatures();
  }

  // 🔍 1. Scan de la table pour trouver UNIQUEMENT les 'en_attente'
  // 🔍 Scan de la table pour trouver UNIQUEMENT les 'en_attente'
  Future<void> _recupererCandidatures() async {
    setState(() => _isLoading = true);
    try {
      // ✅ CORRECTION SEUR : On force la sélection explicite de toutes les colonnes
      final List<dynamic> data = await _supabase
          .from('Magasins')
          .select(
              '*') // 👈 Le '*' force Supabase à envoyer toutes les nouvelles colonnes
          .eq('statut', 'en_attente');

      setState(() {
        _magasinsEnAttente = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _afficherMessage("Erreur chargement : $e", Colors.red);
    }
  }

  // ✅ 2. Le bouton de certification "Sawa"
  Future<void> _validerMagasin(String id, String nom) async {
    try {
      await _supabase
          .from('Magasins')
          .update({'statut': 'certifie'}) // Passe le statut au vert
          .eq('id', id); // 'id' ou la clé unique de ta table

      _afficherMessage(
          "🎉 $nom est désormais Certifié SWINTEL !", Colors.green);
      _recupererCandidatures(); // Rafraîchit la liste automatiquement
    } catch (e) {
      _afficherMessage("Erreur validation : $e", Colors.red);
    }
  }

  // 🎧 3. Écouter le repère vocal sémantique (.webm)
  Future<void> _gererAudio(String id, String? urlAudio) async {
    if (urlAudio == null || urlAudio.isEmpty) {
      _afficherMessage("Aucun repère vocal pour ce magasin", Colors.orange);
      return;
    }

    try {
      if (_idAudioEnCours == id) {
        // Si on clique sur le même audio en cours, on l'arrête
        await _audioPlayer.stop();
        setState(() => _idAudioEnCours = null);
      } else {
        // Sinon, on joue le nouvel audio directement depuis l'URL internet
        await _audioPlayer.play(UrlSource(urlAudio));
        setState(() => _idAudioEnCours = id);
      }
    } catch (e) {
      _afficherMessage("Impossible de lire l'audio : $e", Colors.red);
    }
  }

  void _afficherMessage(String msg, Color couleur) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: couleur),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('SWINTEL - Centre de Contrôle'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recupererCandidatures,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _magasinsEnAttente.isEmpty
              ? const Center(
                  child: Text('Aucune inscription en attente de validation.'))
              : ListView.builder(
                  itemCount: _magasinsEnAttente.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final magasin = _magasinsEnAttente[index];
                    final String id = magasin['id'].toString();
                    final String nom = magasin['nom'] ?? 'Inconnu';
                    final String tel = magasin['telephone'] ?? 'Pas de numéro';
                    final String? audioUrl = magasin['audio_url'];

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(nom,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            "WhatsApp : $tel\nPosition : [${magasin['lat']}, ${magasin['lng']}]"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bouton d'écoute audio 🎧
                            IconButton(
                              icon: Icon(
                                _idAudioEnCours == id
                                    ? Icons.stop_circle
                                    : Icons.play_circle,
                                color: _idAudioEnCours == id
                                    ? Colors.red
                                    : Colors.indigo,
                                size: 32,
                              ),
                              onPressed: () => _gererAudio(id, audioUrl),
                            ),
                            const SizedBox(width: 10),
                            // Bouton Valider ✅
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              onPressed: () => _validerMagasin(id, nom),
                              child: const Text('VALIDER',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
