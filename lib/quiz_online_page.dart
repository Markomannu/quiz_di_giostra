import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class QuizOnlinePage extends StatefulWidget {
  final String idStanza;
  final bool isPlayer1;
  final List<String> idDomande;

  const QuizOnlinePage({
    super.key,
    required this.idStanza,
    required this.isPlayer1,
    required this.idDomande,
  });

  @override
  State<QuizOnlinePage> createState() => _QuizOnlinePageState();
}

class _QuizOnlinePageState extends State<QuizOnlinePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final player = AudioPlayer();

  late StreamSubscription<DocumentSnapshot> listener;

  List<Map<String, dynamic>> domande = [];
  int domandaCorrente = 0;
  int risposteCorrette = 0;
  int? selezionata;
  bool risposto = false;
  bool loading = true;
  bool partitaTerminata = false;
  bool aggiornamentoEffettuato = false;

  @override
  void initState() {
    super.initState();
    _caricaDomande();
    _ascoltaPartita();
    player.play(AssetSource('sounds/medieval_music.mp3'), volume: 0.5);
  }

  @override
  void dispose() {
    listener.cancel();
    player.stop();
    super.dispose();
  }

  Future<void> _caricaDomande() async {
    for (String id in widget.idDomande) {
      final doc = await firestore.collection('domande').doc(id).get();
      if (doc.exists) domande.add(doc.data()!);
    }
    setState(() => loading = false);
  }

  void _controllaRisposta(int index) {
    setState(() {
      selezionata = index;
      risposto = true;
      if (index == domande[domandaCorrente]['rispostaCorretta']) {
        risposteCorrette++;
      }
    });

    Future.delayed(Duration(seconds: 1), () {
      if (domandaCorrente < domande.length - 1) {
        setState(() {
          domandaCorrente++;
          selezionata = null;
          risposto = false;
        });
      } else {
        _salvaPunteggio();
      }
    });
  }

  Future<void> _salvaPunteggio() async {
    final campo = widget.isPlayer1 ? 'punteggio1' : 'punteggio2';
    final docRef = firestore.collection('stanze_online').doc(widget.idStanza);
    final snapshot = await docRef.get();
    final data = snapshot.data();

    if (data?[campo] == null) {
      await docRef.update({campo: risposteCorrette});
    }
  }

  void _ascoltaPartita() {
    listener = firestore
        .collection('stanze_online')
        .doc(widget.idStanza)
        .snapshots()
        .listen(_checkFinePartita);
  }

  Future<void> _checkFinePartita(DocumentSnapshot snapshot) async {
    if (partitaTerminata || aggiornamentoEffettuato) return;

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) return;

    final p1 = data['punteggio1'];
    final p2 = data['punteggio2'];

    if (p1 != null && p2 != null) {
      partitaTerminata = true;
      aggiornamentoEffettuato = true;

      await listener.cancel();
      await player.stop();

      final mioPunteggio = widget.isPlayer1 ? p1 : p2;
      final avversarioPunteggio = widget.isPlayer1 ? p2 : p1;

      final bool haiPareggiato = p1 == p2;
      final bool haiVinto = (widget.isPlayer1 && p1 > p2) || (!widget.isPlayer1 && p2 > p1);

      if (haiVinto) {
        await player.play(AssetSource('sounds/vittoria.mp3'), volume: 1.0);
      } else if (!haiPareggiato) {
        await player.play(AssetSource('sounds/sconfitta.mp3'), volume: 1.0);
      }

      final uid = auth.currentUser!.uid;
      final ref = firestore.collection('utenti').doc(uid);
      final doc = await ref.get();
      final datiUtente = doc.data() ?? {};

      int corrette = datiUtente['risposte_corrette'] ?? 0;
      int sbagliate = datiUtente['risposte_sbagliate'] ?? 0;
      int soldi = datiUtente['soldi'] ?? 0;
      int cuori = datiUtente['cuori'] ?? 5;

      int nuoviSoldi = soldi;
      int nuoviCuori = cuori;
      bool cuorePerso = false;

      if (haiPareggiato) {
        nuoviSoldi += 5;
      } else if (haiVinto) {
        nuoviSoldi += 10;
      } else {
        nuoviSoldi = (soldi - 5).clamp(0, double.infinity).toInt();
        if (nuoviCuori > 0) {
          nuoviCuori -= 1;
          cuorePerso = true;
        }
      }

      final Map<String, dynamic> updateData = {
        'soldi': nuoviSoldi,
        'cuori': nuoviCuori,
        'risposte_corrette': corrette + risposteCorrette,
        'risposte_sbagliate': sbagliate + (domande.length - risposteCorrette),
      };

      if (cuorePerso) {
        updateData['ultimo_cuore'] = Timestamp.now();
      }

      await ref.update(updateData);

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.brown[100],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            haiPareggiato
                ? "Pareggio 🤝"
                : haiVinto
                ? "Hai vinto! 🏆"
                : "Hai perso... 😞",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[900]),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Il tuo punteggio: $mioPunteggio"),
              Text("Avversario: $avversarioPunteggio"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: Text("Torna alla Home"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text("Quiz Online")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final domanda = domande[domandaCorrente];

    return Scaffold(
      appBar: AppBar(
        title: Text("Domanda ${domandaCorrente + 1}/${domande.length}"),
        backgroundColor: Colors.brown[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background_parchment.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                domanda['testo'],
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.brown[900]),
              ),
              SizedBox(height: 24),
              ...List.generate(domanda['opzioni'].length, (index) {
                final isCorretta = index == domanda['rispostaCorretta'];
                final isScelta = index == selezionata;
                Color colore = Colors.brown[200]!;

                if (risposto) {
                  if (isScelta) {
                    colore = isCorretta ? Colors.green : Colors.red;
                  } else if (isCorretta) {
                    colore = Colors.green;
                  }
                }

                return Container(
                  margin: EdgeInsets.only(bottom: 14),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colore,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.all(18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: risposto ? null : () => _controllaRisposta(index),
                    child: Text(domanda['opzioni'][index], style: TextStyle(fontSize: 16)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
