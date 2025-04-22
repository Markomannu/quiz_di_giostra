import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_con_amico_page.dart';

class UniscitiStanzaPage extends StatefulWidget {
  const UniscitiStanzaPage({super.key});

  @override
  State<UniscitiStanzaPage> createState() => _UniscitiStanzaPageState();
}

class _UniscitiStanzaPageState extends State<UniscitiStanzaPage> {
  final _controller = TextEditingController();
  String? errore;

  Future<void> _unisciti() async {
    final codice = _controller.text.trim().toUpperCase();
    final stanza = await FirebaseFirestore.instance.collection('stanze').doc(codice).get();

    if (!stanza.exists) {
      setState(() => errore = "Codice non valido");
      return;
    }

    final data = stanza.data()!;
    if (data['partecipa'] != null) {
      setState(() => errore = "Stanza già piena");
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;
    await stanza.reference.update({
      'partecipa': user.uid,
      'stato': 'in_gioco',
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizConAmicoPage(codice: codice, isCreatore: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Unisciti a una Stanza")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "Inserisci codice",
                errorText: errore,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _unisciti,
              child: Text("Partecipa"),
            ),
          ],
        ),
      ),
    );
  }
}
