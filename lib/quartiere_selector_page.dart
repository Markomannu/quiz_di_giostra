import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class QuartiereSelectorPage extends StatelessWidget {
  final List<String> quartieri = [
    'Porta Sant\'Andrea',
    'Porta Crucifera',
    'Porta Santo Spirito',
    'Porta del Foro'
  ];

  final user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void _salvaQuartiere(BuildContext context, String selected) async {
    await firestore.collection('utenti').doc(user.uid).set({
      'nome': user.displayName,
      'email': user.email,
      'quartiere': selected,
      'foto': user.photoURL,
      'gradi': 0,
      'soldi': 0,
      'cuori': 5,
      'risposte_corrette': 0,
      'risposte_sbagliate': 0,
      'partite_giocate': 0,
      'vittorie': 0,
      'sconfitte': 0,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scegli il tuo Quartiere")),
      body: ListView.builder(
        itemCount: quartieri.length,
        itemBuilder: (context, index) {
          final quartiere = quartieri[index];
          return ListTile(
            leading: Icon(Icons.shield),
            title: Text(quartiere),
            onTap: () => _salvaQuartiere(context, quartiere),
          );
        },
      ),
    );
  }
}
