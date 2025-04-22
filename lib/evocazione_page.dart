import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class EvocazionePage extends StatefulWidget {
  const EvocazionePage({super.key});

  @override
  State<EvocazionePage> createState() => _EvocazionePageState();
}

class _EvocazionePageState extends State<EvocazionePage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? personaggio;
  bool loading = true;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _evoca();
  }

  Future<void> _evoca() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final utentiDoc = FirebaseFirestore.instance.collection('utenti').doc(uid);
    final personaggiSnapshot = await FirebaseFirestore.instance.collection('personaggi').get();

    final personaggi = personaggiSnapshot.docs.map((doc) => doc.data()).toList();
    personaggi.shuffle();
    final estratto = personaggi.first;

    await utentiDoc.update({
      'collezione': FieldValue.arrayUnion([estratto['nome']]),
      'evocazioni_disponibili': FieldValue.increment(-1),
    });

    // suono evocazione
    await _audioPlayer.play(AssetSource('sounds/evocazione.mp3'));

    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      personaggio = estratto;
      loading = false;
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: loading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            const Text("Evocazione in corso...",
                style: TextStyle(color: Colors.white)),
          ],
        )
            : ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 4,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    personaggio!['immagine'],
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  personaggio!['nome'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(personaggio!['descrizione']),
                const SizedBox(height: 10),
                Text("Attacco: ${personaggio!['attacco']}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Potenza: ${personaggio!['potenza']}  |  Difesa: ${personaggio!['difesa']}"),
                Text("Rarità: ${personaggio!['rarita']}",
                    style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Torna allo Store"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[400],
                    foregroundColor: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}