import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:just_audio/just_audio.dart';

class HubAlertesScreen extends StatefulWidget {
  final String idUtilisateur;
  const HubAlertesScreen({super.key, required this.idUtilisateur});

  @override
  State<HubAlertesScreen> createState() => _HubAlertesScreenState();
}

class _HubAlertesScreenState extends State<HubAlertesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Map<String, dynamic>> _alertes = [];
  bool _isLoading = true;
  String? _audioEnCoursUrl;

  @override
  void initState() {
    super.initState();
    _recupererAlertesInitiales();
    _activerEcouteTempsReel();
  }

  Future<void> _recupererAlertesInitiales() async {
    try {
      final donnees = await _supabase
          .from('Alertes')
          .select()
          .order('id', ascending: false);

      setState(() {
        _alertes = List<Map<String, dynamic>>.from(donnees);
        _isLoading = false;
      });
    } catch (e) {
      _afficherErreur("Erreur : $e");
    }
  }

  void _activerEcouteTempsReel() {
    _supabase
        .channel('public:Alertes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'Alertes',
          callback: (payload) {
            _recupererAlertesInitiales();
          },
        )
        .subscribe();
  }

  Future<void> _gererLectureAudio(String url) async {
    try {
      if (_audioEnCoursUrl == url && _audioPlayer.playing) {
        await _audioPlayer.pause();
        setState(() => _audioEnCoursUrl = null);
      } else {
        setState(() => _audioEnCoursUrl = url);
        await _audioPlayer.setUrl(url);
        await _audioPlayer.play();
        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() => _audioEnCoursUrl = null);
          }
        });
      }
    } catch (e) {
      _afficherErreur("Audio error : $e");
      setState(() => _audioEnCoursUrl = null);
    }
  }

  Future<void> _prendreEnChargeAlerte(dynamic idAlerte) async {
    try {
      await _supabase.from('Alertes').update({
        'statut_alerte': 'traite',
      }).eq('id', idAlerte);

      final bool isEnglish =
          Localizations.localeOf(context).languageCode == 'en';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEnglish
                ? '⚡ Alert taken in charge!'
                : '⚡ Vous avez pris en charge cette alerte !'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      _afficherErreur("Erreur : $e");
    }
  }

  void _afficherErreur(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
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
    // 🌍 Détection automatique de la langue du système
    final bool isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      appBar: AppBar(
        title:
            Text(isEnglish ? 'SWINTEL - Alerts Hub' : 'SWINTEL - Hub Alertes'),
        backgroundColor: Colors.amber,
        // 🎯 FORCE LE BOUTON ET L'ACTION DE RETOUR IMMÉDIATE
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recupererAlertesInitiales,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alertes.isEmpty
              ? Center(
                  child: Text(isEnglish
                      ? '📡 No alerts on the network.'
                      : '📡 Aucune alerte sur le réseau.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _alertes.length,
                  itemBuilder: (context, index) {
                    final alerte = _alertes[index];
                    final dynamic id = alerte['id'];
                    final String typeFlux = alerte['type_flux'] ?? 'Inconnu';
                    final String audioUrl = alerte['audio_url'] ?? '';
                    final String statut = alerte['statut_alerte'] ?? 'en_cours';
                    final bool isPlaying = _audioEnCoursUrl == audioUrl;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    typeFlux == 'presentiel'
                                        ? (isEnglish
                                            ? '🚶 COUNTER'
                                            : '🚶 COMPTOIR')
                                        : (isEnglish
                                            ? '📞 PHONE'
                                            : '📞 TÉLÉPHONE'),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: typeFlux == 'presentiel'
                                      ? Colors.blue.withOpacity(0.2)
                                      : Colors.purple.withOpacity(0.2),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statut == 'en_cours'
                                        ? Colors.orange.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statut == 'en_cours'
                                        ? (isEnglish ? 'Pending' : 'En attente')
                                        : (isEnglish
                                            ? 'Claimed'
                                            : 'Pris en charge'),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: statut == 'en_cours'
                                            ? Colors.orange
                                            : Colors.green),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: audioUrl.isEmpty
                                      ? null
                                      : () => _gererLectureAudio(audioUrl),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isPlaying ? Colors.red : Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: Icon(isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  label: Text(isPlaying
                                      ? 'Pause'
                                      : (isEnglish
                                          ? 'Listen request'
                                          : 'Écouter la pièce')),
                                ),
                                const Spacer(),
                                if (statut == 'en_cours')
                                  ElevatedButton(
                                    onPressed: () => _prendreEnChargeAlerte(id),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black),
                                    child: Text(isEnglish
                                        ? "I'll handle it"
                                        : "Je m'en occupe"),
                                  ),
                              ],
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
