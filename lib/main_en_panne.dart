import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtudnVqbGpnemhud3Fjb3VrdW5pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MjkzNjksImV4cCI6MjA5MzIwNTM2OX0.1zRseAK5IbjiYdQYju7a-Vn4yGKxeTkzKsVeV7KrYl4',
  );
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, home: SaisieRattrapage()));
}

class SaisieRattrapage extends StatefulWidget {
  const SaisieRattrapage({super.key});
  @override
  State<SaisieRattrapage> createState() => _SaisieRattrapageState();
}

class _SaisieRattrapageState extends State<SaisieRattrapage> {
  final _nom = TextEditingController();
  final _marque = TextEditingController();
  final _spe = TextEditingController();
  final _tel = TextEditingController();
  final _adr = TextEditingController();

  Future<void> _sauvegarder() async {
    if (_nom.text.isEmpty) return;
    try {
      await Supabase.instance.client.from('Magasins').insert({
        'nom': _nom.text,
        'specialite_marque': _marque.text,
        'specialite_type': _spe.text,
        'telephone': _tel.text,
        'adresse': _adr.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ Enregistré !')));
        _nom.clear();
        _marque.clear();
        _spe.clear();
        _tel.clear();
        _adr.clear();
      }
    } catch (e) {
      print("Erreur : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Rattrapage Camp Yabassi'),
          backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _nom,
                decoration: const InputDecoration(
                    labelText: 'Nom du vendeur / Enseigne')),
            TextField(
                controller: _marque,
                decoration: const InputDecoration(
                    labelText: 'Marques (ex: Mercedes, BMW)')),
            TextField(
                controller: _spe,
                decoration: const InputDecoration(
                    labelText: 'Pièces fortes (ex: Moteur occasion, Phares)')),
            TextField(
                controller: _tel,
                decoration:
                    const InputDecoration(labelText: 'Téléphone (WhatsApp?)')),
            TextField(
                controller: _adr,
                decoration: const InputDecoration(
                    labelText: 'Localisation (Ruelle / Point de repère)')),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _sauvegarder,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text('ENREGISTRER DANS LE CLOUD'),
            ),
          ],
        ),
      ),
    );
  }
}
