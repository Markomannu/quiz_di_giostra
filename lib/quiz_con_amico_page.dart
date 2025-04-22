import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizConAmicoPage extends StatefulWidget {
  final String codice;
  final bool isCreatore;

  const QuizConAmicoPage({required this.codice, required this.isCreatore, super.key});

  @override
  State<QuizConAmicoPage> createState() => _QuizConAmicoPageState();
}

class _QuizConAmicoPageState extends State<QuizConAmicoPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  List<dynamic> domande = [];
  int index = 0;
  int corrette = 0;
  bool caricamento = true;
  bool risposto = false;
  int? selezionata;

  @override
  void initState() {
    super.initState();
    _caricaDomande();
  }

  Future<void> _caricaDomande() async {
    final doc = await firestore.collection('stanze').doc(widget.codice).get();
    setState(() {
      domande = doc['domande'];
      caricamento = false;
    });
  }

  void _rispondi(int i) async {
    if (risposto) return;

    final domanda = domande[index];
    final corretta = domanda['rispostaCorretta'] == i;
    final userKey = widget.isCreatore ? 'creatoreRisposte' : 'partecipaRisposte';

    if (corretta) corrette++;

    setState(() {
      selezionata = i;
      risposto = true;
    });

    await firestore.collection('stanze').doc(widget.codice).update({
      '$userKey': FieldValue.arrayUnion([i])
    });

    Future.delayed(Duration(seconds: 1), () {
      if (index + 1 < domande.length) {
        setState(() {
          index++;
          selezionata = null;
          risposto = false;
        });
      } else {
        _termina();
      }
    });
  }

  void _termina() async {
    final doc = await firestore.collection('stanze').doc(widget.codice).get();
    final data = doc.data()!;
    final List<dynamic> risposteCreatore = data['creatoreRisposte'];
    final List<dynamic> rispostePartecipa = data['partecipaRisposte'];

    final int tot = domande.length;
    final bool isCompletata = risposteCreatore.length == tot && rispostePartecipa.length == tot;

    if (!isCompletata) {
      // Aspetta l’altro giocatore
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text("In attesa..."),
          content: Text("Aspettiamo che l'altro completi il quiz."),
        ),
      );

      // Polling semplice ogni 2 secondi
      Future.doWhile(() async {
        await Future.delayed(Duration(seconds: 2));
        final aggiornato = await firestore.collection('stanze').doc(widget.codice).get();
        final data2 = aggiornato.data()!;
        final r1 = data2['creatoreRisposte'];
        final r2 = data2['partecipaRisposte'];
        return !(r1.length == tot && r2.length == tot);
      }).then((_) {
        Navigator.of(context).pop(); // Chiude il dialogo
        _termina(); // Rilancia il confronto finale
      });
      return;
    }

    // Confronto finale
    int puntiCreatore = 0;
    int puntiPartecipa = 0;

    for (int i = 0; i < tot; i++) {
      final domanda = domande[i];
      final corretta = domanda['rispostaCorretta'];

      if (risposteCreatore[i] == corretta) puntiCreatore++;
      if (rispostePartecipa[i] == corretta) puntiPartecipa++;
    }

    final String risultato;
    if (puntiCreatore == puntiPartecipa) {
      risultato = "Pareggio! 🤝";
    } else if ((widget.isCreatore && puntiCreatore > puntiPartecipa) ||
        (!widget.isCreatore && puntiPartecipa > puntiCreatore)) {
      risultato = "Hai vinto! 🎉";
      await _aggiornaProfilo(vittoria: true);
    } else {
      risultato = "Hai perso 😢";
      await _aggiornaProfilo(vittoria: false);
    }

    // Mostra risultato
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(risultato),
        content: Text(
            "Tu: $corrette risposte corrette\nAvversario: ${widget.isCreatore ? puntiPartecipa : puntiCreatore}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text("Torna alla Home"),
          )
        ],
      ),
    );
  }

  Future<void> _aggiornaProfilo({required bool vittoria}) async {
    final uid = auth.currentUser!.uid;
    final docRef = firestore.collection('utenti').doc(uid);
    final doc = await docRef.get();
    final dati = doc.data()!;

    final int cuori = dati['cuori'] ?? 5;
    final int soldi = dati['soldi'] ?? 0;
    final int gradi = dati['gradi'] ?? 0;

    await docRef.update({
      'cuori': cuori > 0 ? cuori - 1 : 0,
      'soldi': soldi + (vittoria ? 40 : 0),
      'gradi': gradi + (vittoria ? 1 : 0),
      'vittorie': (dati['vittorie'] ?? 0) + (vittoria ? 1 : 0),
      'sconfitte': (dati['sconfitte'] ?? 0) + (vittoria ? 0 : 1),
      'partite_giocate': (dati['partite_giocate'] ?? 0) + 1,
      'risposte_corrette': (dati['risposte_corrette'] ?? 0) + corrette,
      'risposte_sbagliate':
      (dati['risposte_sbagliate'] ?? 0) + (domande.length - corrette),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (caricamento) {
      return Scaffold(
        appBar: AppBar(title: Text("Quiz con Amico")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final domanda = domande[index];
    final opzioni = List<String>.from(domanda['opzioni']);

    return Scaffold(
      appBar: AppBar(
        title: Text("Domanda ${index + 1}/${domande.length}"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              domanda['testo'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...List.generate(opzioni.length, (i) {
              Color? colore;
              if (risposto) {
                if (i == selezionata) {
                  colore = (i == domanda['rispostaCorretta']) ? Colors.green : Colors.red;
                } else if (i == domanda['rispostaCorretta']) {
                  colore = Colors.green;
                }
              }

              return Container(
                margin: EdgeInsets.symmetric(vertical: 6),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colore,
                  ),
                  onPressed: risposto ? null : () => _rispondi(i),
                  child: Text(opzioni[i]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
