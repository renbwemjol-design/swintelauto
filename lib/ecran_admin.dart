import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart'; // 👈 1. ALIGNEMENT MULTIMÉDIA UNIQUE ET ÉTANCHE !

class EcranAdminSecret extends StatefulWidget {
  const EcranAdminSecret({super.key});

  @override
  State<EcranAdminSecret> createState() => _EcranAdminSecretState();
}

class _EcranAdminSecretState extends State<EcranAdminSecret> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // 👈 Utilise désormais le moteur just_audio unifié

  List<dynamic> _tousLesMagasins = [];
  bool _isLoading = true;
  String? _idAudioEnCours; // Pour traquer la ligne vocale active

  @override
  void initState() {
    super.initState();
    _recupererTouteLaFlotte();
  }

  // 🔍 SCAN UNIFIÉ : L'administrateur charge toute la flotte pour surveiller l'état réel des 35 magasins
  Future<void> _recupererTouteLaFlotte() async {
    setState(() => _isLoading = true);
    try {
      final List<dynamic> data = await _supabase
          .from('Magasins')
          .select(
              '*') // Force la réception de toutes les colonnes sémantiques et spatiales
          .order('nom', ascending: true);

      setState(() {
        _tousLesMagasins = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _afficherMessage("Erreur chargement flotte : $e", Colors.red);
    }
  }

  // ✅ CERTIFICATION DE CONFIANCE : Mutation du statut en base de données
  Future<void> _validerMagasin(
      String id, String nom, String statutActuel) async {
    // Si le magasin est déjà certifié, l'admin peut le repasser en actif simple (Basculeur)
    final String nouveauStatut =
        statutActuel == 'certifie' ? 'actif' : 'certifie';
    try {
      await _supabase
          .from('Magasins')
          .update({'statut': nouveauStatut}).eq('id', id);

      _afficherMessage(
          nouveauStatut == 'certifie'
              ? "🎉 $nom est désormais Certifié SWINTEL !"
              : "⚡ $nom est repassé en statut Actif standard",
          Colors.green);
      _recupererTouteLaFlotte(); // Rafraîchissement automatique instantané
    } catch (e) {
      _afficherMessage("Erreur mise à jour statut : $e", Colors.red);
    }
  }

  // 🎧 LECTURE TEMPS RÉEL : Décodeur unifié just_audio pour le goudron (Zéro interférence)
  Future<void> _gererAudio(String id, String? urlAudio) async {
    if (urlAudio == null || urlAudio.isEmpty) {
      _afficherMessage(
          "Aucun repère vocal sémantique pour ce magasin", Colors.orange);
      return;
    }

    try {
      if (_idAudioEnCours == id) {
        await _audioPlayer
            .stop(); // 🎯 Arrêt d'autorité si on reclique sur la même ligne
        setState(() => _idAudioEnCours = null);
      } else {
        await _audioPlayer
            .setUrl(urlAudio); // 🎯 Chargement direct du flux brut
        _audioPlayer.play();
        setState(() => _idAudioEnCours = id);

        // Filet de sécurité : Quand l'audio se termine, on libère l'icône graphiquement
        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            if (mounted) setState(() => _idAudioEnCours = null);
          }
        });
      }
    } catch (e) {
      _afficherMessage("Impossible de lire le vocal Cloud : $e", Colors.red);
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
    _audioPlayer
        .dispose(); // 👈 Libération indispensable des puces audio du Samsung A10 !
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('SWINTEL - Centre de Contrôle',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _recupererTouteLaFlotte,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _tousLesMagasins.isEmpty
              ? const Center(
                  child:
                      Text('Aucun magasin répertorié dans la flotte SWINTEL.'))
              : ListView.builder(
                  itemCount: _tousLesMagasins.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final magasin = _tousLesMagasins[index];
                    final String id = magasin['id'].toString();
                    final String nom = magasin['nom'] ?? 'Boutique Anonyme';
                    final String tel = magasin['telephone'] ?? 'Pas de numéro';
                    final String? audioUrl = magasin['audio_url'];
                    final String statut = magasin['statut'] ?? 'actif';

                    final bool estCertifie = statut == 'certifie';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Row(
                          children: [
                            Text(nom,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const Spacer(),
                            // Badge d'autorité visuel de la flotte
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: estCertifie
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                estCertifie ? "CERTIFIÉ" : "ACTIF",
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: estCertifie
                                        ? Colors.green
                                        : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        // 🎯 RECTIFICATION SYNTAXE DIRECTE : Utilisation de .only pour caler le haut !
                        subtitle: Padding(
                          padding: const EdgeInsets.only(
                              top: 6.0), // 👈 CORRIGÉ ICI D'AUTORITÉ !
                          child: Text(
                            "📞 WhatsApp : $tel\n📍 GPS : [${magasin['lat']}, ${magasin['lng']}]\n🛠️ Stock : ${magasin['specialite_marque']} (${magasin['specialite_type']})",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black87),
                          ),
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 🎧 ÉCOUTE DU REPÈRE VOCAL DE LA BOUTIQUE
                            IconButton(
                              icon: Icon(
                                _idAudioEnCours == id
                                    ? Icons.stop_circle
                                    : Icons.play_circle,
                                color: _idAudioEnCours == id
                                    ? Colors.red
                                    : Colors.indigo,
                                size: 34,
                              ),
                              onPressed: () => _gererAudio(id, audioUrl),
                            ),
                            const SizedBox(width: 5),

                            // 🦾 ACTIONNEUR DOUBLE ÉTAT : CERTIFIER OU ACTIVER DIRECTEMENT
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: estCertifie
                                    ? Colors.blueGrey
                                    : Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                              ),
                              onPressed: () => _validerMagasin(id, nom, statut),
                              child: Text(
                                estCertifie ? 'ANNULER' : 'CERTIFIER',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
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
