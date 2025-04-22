import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_con_amico_page.dart';

class CreaStanzaPage extends StatelessWidget {
  const CreaStanzaPage({super.key});

  String _generaCodice(int length) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
    final rand = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rand.nextInt(chars.length))));
  }

  Future<void> _creaStanza(BuildContext context) async {
    final codice = _generaCodice(6);
    final user = FirebaseAuth.instance.currentUser!;
    final domandeSnapshot = await FirebaseFirestore.instance.collection('domande').get();

    final domande = domandeSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'testo': data['testo'],
        'opzioni': data['opzioni'],
        'rispostaCorretta': data['rispostaCorretta'],
      };
    }).toList()..shuffle();

    await FirebaseFirestore.instance.collection('stanze').doc(codice).set({
      'creatore': user.uid,
      'partecipa': null,
      'stato': 'attesa',
      'domande': domande.take(10).toList(),
      'creatoreRisposte': [],
      'partecipaRisposte': [],
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizConAmicoPage(codice: codice, isCreatore: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Crea Stanza")),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.play_arrow),
          label: Text("Crea e ottieni codice"),
          onPressed: () => _creaStanza(context),
        ),
      ),
    );
  }
}
