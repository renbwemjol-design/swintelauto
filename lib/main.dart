import 'dart:async'; // 🧠 Infrastructure asynchrone des Streams
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io'; // Pour manipuler le fichier image
import 'package:image_picker/image_picker.dart';
import 'ecran_admin.dart';
import 'creer_alerte.dart';
import 'hub_alertes.dart';
import 'dashboard.dart';
import 'swintel_radar.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 Pour lire la mémoire physique
import 'ecran_enregistrement.dart'; // 👈 Pour appeler l'écran d'activation
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // 👈 Le gestionnaire de canaux d'élite !

  // 🧠 1. DÉCLARATION DU CAPITAINE DES CANAUX AUDIO
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 INITIALISATION SUPABASE CLOUD SÉCURISÉE
  await Supabase.initialize(
    url: 'https://knvujljgzhnwqcoukuni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudnVqbGpnemhud3Fjb3VrdW5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MjkzNjksImV4cCI6MjA5MzIwNTM2OX0.1zRseAK5IbjiYdQYju7a-Vn4yGKxeTkzKsVeV7KrYl4',
  );

  // 🧠 2. CONFIGURATION DES DROITS ET PARAMÈTRES POUR ANDROID
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // 🎯 RECTIFICATION SYNTAXE EXACTE : L'argument reste positionnel brut pour initialize !
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );


  // 🧠 3. CRÉATION DU CANAL D'URGENCE "STYLE FACEBOOK" (Zéro Internet)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'swintel_urgent_channel',
    '🚨 SWINTEL - ALERTES CRUCIALES',
    description: 'Canal d\'urgence prioritaire pour les missions flash de pièces détachées',
    importance: Importance.max, // 👈 FORCE LE HAUT-PARLEUR DU SAMSUNG A10
    playSound: true,
    sound: RawResourceAndroidNotificationSound('sirene'), // 👈 ATTACHE NOTRE FICHIER LOCAL !
    enableVibration: true,
  );

  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    await androidImplementation.createNotificationChannel(channel);
  }

  // 🎯 ALIGNEMENT DU NOM DE CLASSE : Appelle directement ton vrai widget principal du bas !
  runApp(const ReseauPiecesApp());
}

class ReseauPiecesApp extends StatelessWidget {
  const ReseauPiecesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Réseau Pièces Afrique',
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      supportedLocales: const [
        Locale('fr', ''),
        Locale('en', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
                body: Center(
                    child: CircularProgressIndicator(color: Colors.orange)));
          }

          final SharedPreferences prefs = snapshot.data!;
          final String? telephoneLocal = prefs.getString('telephone_local');
          final String nomBoutique =
              prefs.getString('nom_magasin_local') ?? 'Magasin';

          if (telephoneLocal != null && telephoneLocal.isNotEmpty) {
            return SwintelRadarGate(
              idUtilisateur: telephoneLocal,
              nomMagasinLocal: nomBoutique,
            );
          } else {
            return const EcranEnregistrementScreen();
          }
        },
      ),
    );
  }
}

class FormulaireMagasin extends StatefulWidget {
  const FormulaireMagasin({super.key});

  @override
  State<FormulaireMagasin> createState() => _FormulaireMagasinState();
}

class _FormulaireMagasinState extends State<FormulaireMagasin> {
  final _nomController = TextEditingController();
  final _marqueController = TextEditingController();
  final _speController = TextEditingController();
  final _telController = TextEditingController();
  final _adrController = TextEditingController();
  double? _currentLat;
  double? _currentLng;
  bool _isLocating = false;
  XFile? _imageFile; // Pour stocker la photo temporairement
  // Ajoute cette variable en haut de ta classe _FormulaireMagasinState
  File? _imagePreview;

  Future<void> _capturerPosition() async {
    setState(() => _isLocating = true);
    print("Bouton cliqué !");
    try {
      // Demande la permission
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;

      // Récupère la position réelle
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _isLocating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📍 Position capturée !')),
      );
    } catch (e) {
      setState(() => _isLocating = false);
      debugPrint(e.toString());
    }
  }

  Future<void> _prendrePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    if (image != null) {
      setState(() {
        _imageFile = image;
        _imagePreview =
            File(image.path); // Pour afficher la miniature sur l'écran
      });

      // Le message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📸 Photo capturée avec succès !')),
        );
      }
    }
  }

  // On crée un "Tuyau" (Stream) qui écoute la table Magasins
  final Stream<List<Map<String, dynamic>>> _magasinsStream =
      Supabase.instance.client.from('Magasins').stream(primaryKey: ['id']);

  Future<void> _envoyerAuReseau() async {
    if (_nomController.text.isEmpty) return;

    try {
      String? imageUrl;

      // 1. SI UNE PHOTO EXISTE, ON L'ENVOIE D'ABORD
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'public/$fileName';

        await Supabase.instance.client.storage
            .from('photos_magasins')
            .uploadBinary(path, bytes);

        // On récupère l'adresse publique de la photo
        imageUrl = Supabase.instance.client.storage
            .from('photos_magasins')
            .getPublicUrl(path);
      }

      // 2. ON ENREGISTRE TOUT DANS LA TABLE
      await Supabase.instance.client.from('Magasins').insert({
        'nom': _nomController.text,
        'specialite_marque': _marqueController.text,
        'specialite_type': _speController.text,
        'telephone': _telController.text,
        'adresse': _adrController.text,
        'lat': _currentLat ?? 0.0,
        'lng': _currentLng ?? 0.0,
        'image_url': imageUrl, // On ajoute le lien de la photo ici
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Magasin et Photo enregistrés !')));

        // On vide tout pour le suivant
        setState(() {
          _nomController.clear();
          _marqueController.clear();
          _speController.clear();
          _telController.clear();
          _adrController.clear();
          _currentLat = null;
          _currentLng = null;
          _imageFile = null;
          _imagePreview = null;
        });
      }
    } catch (e) {
      debugPrint("Erreur d'envoi : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
// ✅ LE NOUVEAU BLOC À METTRE TOUT EN HAUT :
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EcranAdminSecret()),
            );
          },
          child: const Text('Réseau Pièces'),
        ),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.podcasts, color: Colors.white, size: 28),
            tooltip: 'Lancer une alerte',
            onPressed: () async {
              // 🧠 SÉCURITÉ IDENTITÉ : On va lire le vrai numéro en RAM avant de propulser l'écran
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              final String telephoneActuel =
                  prefs.getString('telephone_local') ?? 'G1_PILOTE';

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EcranCreerAlerte(
                        idGerant:
                            telephoneActuel), // 👈 BRANCHÉ SUR LA RAM D'AUTORITÉ !
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: Column(
        children: [
          // PARTIE 1 : LE FORMULAIRE
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                TextField(
                    controller: _nomController,
                    decoration: const InputDecoration(labelText: 'Boutique')),
                TextField(
                    controller: _marqueController,
                    decoration: const InputDecoration(labelText: 'Marque')),
                TextField(
                    controller: _speController,
                    decoration: const InputDecoration(labelText: 'Spécialité')),
                const SizedBox(height: 10),
                TextField(
                    controller: _telController,
                    decoration: const InputDecoration(labelText: 'Téléphone')),
                TextField(
                    controller: _adrController,
                    decoration: const InputDecoration(
                        labelText: 'Localisation/Adresse')),
                ElevatedButton.icon(
                  onPressed: _prendrePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_imageFile == null
                      ? 'PRENDRE UNE PHOTO'
                      : '✅ PHOTO CAPTURÉE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _imageFile == null ? Colors.blueGrey : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLocating ? null : _capturerPosition,
                  icon: _isLocating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.location_on),
                  label: Text(_isLocating
                      ? 'Recherche GPS...'
                      : 'CAPTURER MA POSITION GPS'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white),
                ),
                const SizedBox(height: 10),
                if (_currentLat != null)
                  Text(
                      "📍 Lat: ${_currentLat!.toStringAsFixed(4)}, Lng: ${_currentLng!.toStringAsFixed(4)}",
                      style:
                          const TextStyle(fontSize: 12, color: Colors.green)),
// 1. Ton bouton classique d'ajout de magasin
                ElevatedButton(
                    onPressed: _envoyerAuReseau, child: const Text('AJOUTER')),
              ],
            ),
          ),
          const Divider(), // Une ligne de séparation

          // PARTIE 2 : LA LISTE EN TEMPS RÉEL
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _magasinsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final magasins = snapshot.data!;
                return ListView.separated(
                  itemCount: magasins.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Colors.grey), // La ligne
                  itemBuilder: (context, index) {
                    final m = magasins[index];
                    return ListTile(
                      // 1. Affichage de la photo ou de l'icône par défaut
                      leading: m['image_url'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                m['image_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                // Petite roue pendant le téléchargement
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2));
                                },
                                // Icône de secours si le lien est mort
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image,
                                        color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.store, color: Colors.orange),

                      // 2. Texte de la boutique
                      title: Text(m['nom'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),

                      // 3. Infos complémentaires
                      subtitle: Text(
                          "${m['specialite_marque']} - ${m['telephone'] ?? ''}"),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
