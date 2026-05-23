import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // Cette ligne est OBLIGATOIRE pour éviter un écran noir
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://knvujljgzhnwqcoukuni.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudnVqbGpnemhud3Fjb3VrdW5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MjkzNjksImV4cCI6MjA5MzIwNTM2OX0.1zRseAK5IbjiYdQYju7a-Vn4yGKxeTkzKsVeV7KrYl4',
  );
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
      home: const FormulaireMagasin(),
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

  // On crée un "Tuyau" (Stream) qui écoute la table Magasins
  final Stream<List<Map<String, dynamic>>> _magasinsStream =
      Supabase.instance.client.from('Magasins').stream(primaryKey: ['id']);

  Future<void> _envoyerAuReseau() async {
    final nom = _nomController.text;
    final marque = _marqueController.text;
    final spe = _speController.text;
    if (nom.isEmpty) return;

    try {
      await Supabase.instance.client.from('Magasins').insert({
        'nom': nom,
        'specialite_marque': marque,
        'specialite_type': spe,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ Enregistré !')));
        _nomController.clear();
        _marqueController.clear();
        _speController.clear();
      }
    } catch (e) {
      debugPrint("Erreur : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Réseau Pièces'), backgroundColor: Colors.orange),
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
                return ListView.builder(
                  itemCount: magasins.length,
                  itemBuilder: (context, index) {
                    final m = magasins[index];
                    return ListTile(
                      leading: const Icon(Icons.store, color: Colors.orange),
                      title: Text(m['nom'] ?? ''),
                      subtitle: Text(
                          "${m['specialite_marque']} - ${m['specialite_type']}"),
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
