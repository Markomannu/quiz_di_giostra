import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'quiz_online_page.dart';

class UniscitiOnlinePage extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final User user = FirebaseAuth.instance.currentUser!;

  void _uniscitiAllaStanza(BuildContext context, String stanzaId) async {
    await firestore.collection('stanze_online').doc(stanzaId).update({
      'giocatore2': user.uid,
      'stato': 'completo',
    });

    final snapshot = await firestore.collection('stanze_online').doc(stanzaId).get();
    final data = snapshot.data();
    final List<String> domande = List<String>.from(data?['domande'] ?? []);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizOnlinePage(
          idStanza: stanzaId,
          isPlayer1: false,
          idDomande: domande,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Unisciti a una partita")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('stanze_online')
            .where('stato', isEqualTo: 'attesa')
            .snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final stanze = snapshot.data!.docs;
          if (stanze.isEmpty) return Center(child: Text("Nessuna stanza disponibile"));

          return ListView.builder(
            itemCount: stanze.length,
            itemBuilder: (_, index) {
              final stanza = stanze[index];
              return ListTile(
                title: Text("Stanza ${stanza.id.substring(0, 5)}"),
                subtitle: Text("In attesa di un avversario"),
                trailing: ElevatedButton(
                  child: Text("Unisciti"),
                  onPressed: () => _uniscitiAllaStanza(context, stanza.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
