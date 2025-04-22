import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class EvocazionePage extends StatefulWidget {
  const EvocazionePage({super.key});

  @override
  State<EvocazionePage> createState() => _EvocazionePageState();
}

class _EvocazionePageState extends State<EvocazionePage>
    with SingleTickerProviderStateMixin {
  bool _isEvocando = false;
  Map<String, dynamic>? _personaggioEstratto;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  Future<void> _evoca() async {
    setState(() => _isEvocando = true);
    _controller.repeat();

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('utenti').doc(uid);
    final userData = (await userDoc.get()).data()!;

    int disponibili = userData['evocazioni_disponibili'] ?? 0;
    if (disponibili <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nessuna evocazione disponibile.")),
      );
      setState(() => _isEvocando = false);
      return;
    }

    // Scarica tutti i personaggi
    final snapshot = await FirebaseFirestore.instance.collection('personaggi').get();
    final tutti = snapshot.docs;

    // Logica di rarità con pesi
    List<DocumentSnapshot> pool = [];
    for (var doc in tutti) {
      final r = (doc['rarita'] ?? '').toLowerCase();
      if (r == 'comune') pool.addAll(List.filled(55, doc));
      if (r == 'raro') pool.addAll(List.filled(25, doc));
      if (r == 'epico') pool.addAll(List.filled(15, doc));
      if (r == 'leggendario') pool.addAll(List.filled(5, doc));
    }

    final casuale = pool[Random().nextInt(pool.length)];
    final data = casuale.data() as Map<String, dynamic>;
    final id = casuale.id;

    // Salva nella collezione dell'utente
    await userDoc.update({
      'evocazioni_disponibili': disponibili - 1,
      'collezione': FieldValue.arrayUnion([id])
    });

    await Future.delayed(const Duration(seconds: 2));
    _controller.stop();

    setState(() {
      _personaggioEstratto = data;
      _isEvocando = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Evocazione")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isEvocando) ...[
                RotationTransition(
                  turns: _controller,
                  child: const Icon(Icons.auto_awesome, size: 100, color: Colors.purple),
                ),
                const SizedBox(height: 20),
                const Text("Evocando...", style: TextStyle(fontSize: 18))
              ] else if (_personaggioEstratto != null) ...[
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Image.network(_personaggioEstratto!['immagine'], height: 120, fit: BoxFit.cover),
                        const SizedBox(height: 10),
                        Text(
                          _personaggioEstratto!['nome'],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(_personaggioEstratto!['descrizione'], textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text("🗡 ${_personaggioEstratto!['attacco']} (${_personaggioEstratto!['potenza']})"),
                        Text("🛡 Difesa: ${_personaggioEstratto!['difesa']}"),
                        Text("🌟 Rarità: ${_personaggioEstratto!['rarita']}", style: const TextStyle(fontStyle: FontStyle.italic))
                      ],
                    ),
                  ),
                )
              ] else ...[
                const Icon(Icons.catching_pokemon, size: 100, color: Colors.brown),
                const SizedBox(height: 20),
                const Text("Premi sotto per evocare un personaggio")
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isEvocando ? null : _evoca,
                child: const Text("Evoca"),
              )
            ],
          ),
        ),
      ),
    );
  }
}