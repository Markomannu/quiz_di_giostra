import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'quiz_online_page.dart';
import 'dart:async';
class GiocaOnlinePage extends StatefulWidget {
  const GiocaOnlinePage({super.key});

  @override
  State<GiocaOnlinePage> createState() => _GiocaOnlinePageState();
}

class _GiocaOnlinePageState extends State<GiocaOnlinePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final User user = FirebaseAuth.instance.currentUser!;
  String? stanzaId;
  String? nomeGiocatore1;
  String? nomeGiocatore2;
  late StreamSubscription<DocumentSnapshot> listener;

  @override
  void initState() {
    super.initState();
    _creaStanza();
  }

  @override
  void dispose() {
    listener.cancel(); // 🧹 Annulla il listener quando la pagina viene chiusa
    super.dispose();
  }

  Future<String> _getNomeUtente(String uid) async {
    final snapshot = await firestore.collection('utenti').doc(uid).get();
    return snapshot.data()?['nome'] ?? 'Anonimo';
  }

  void _vaiAlMatch(List<String> idDomande) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizOnlinePage(
          idStanza: stanzaId!,
          isPlayer1: true,
          idDomande: idDomande,
        ),
      ),
    );
  }

  Future<void> _creaStanza() async {
    final snapshotDomande = await firestore.collection('domande').get();
    final tutte = snapshotDomande.docs..shuffle();
    final domandeSelezionate = tutte.take(10).map((doc) => doc.id).toList();

    final docRef = await firestore.collection('stanze_online').add({
      'giocatore1': user.uid,
      'giocatore2': '',
      'stato': 'attesa',
      'creata_il': FieldValue.serverTimestamp(),
      'domande': domandeSelezionate,
      'punteggio1': null,
      'punteggio2': null,
    });

    stanzaId = docRef.id;

    listener = docRef.snapshots().listen((snapshot) async {
      if (!mounted) return;
      final data = snapshot.data();
      if (data == null) return;

      final uid1 = data['giocatore1'];
      final uid2 = data['giocatore2'];
      final domande = List<String>.from(data['domande']);

      final nome1 = await _getNomeUtente(uid1);
      final nome2 = uid2 != '' ? await _getNomeUtente(uid2) : null;

      if (!mounted) return;
      setState(() {
        nomeGiocatore1 = nome1;
        nomeGiocatore2 = nome2;
      });

      if (uid2 != '') {
        listener.cancel(); // 👈 Chiude il listener prima di entrare nella partita
        _vaiAlMatch(domande);
      }
    });
  }

  Future<void> _annullaStanza() async {
    if (stanzaId != null) {
      await firestore.collection('stanze_online').doc(stanzaId!).delete();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gioca Online")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Stanza in attesa...", style: TextStyle(fontSize: 18)),
            if (nomeGiocatore1 != null) Text("Giocatore 1: $nomeGiocatore1"),
            if (nomeGiocatore2 != null) Text("Giocatore 2: $nomeGiocatore2"),
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _annullaStanza,
              icon: Icon(Icons.cancel),
              label: Text("Annulla"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
