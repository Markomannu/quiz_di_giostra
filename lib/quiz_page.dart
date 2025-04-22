import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Domanda {
  final String testo;
  final List<String> opzioni;
  final int rispostaCorretta;

  Domanda({
    required this.testo,
    required this.opzioni,
    required this.rispostaCorretta,
  });
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Domanda> domande = [];
  bool loading = true;

  int domandaCorrente = 0;
  int risposteCorrette = 0;
  bool risposto = false;
  int? selezionata;

  @override
  void initState() {
    super.initState();
    _caricaDomande();
  }

  Future<void> _caricaDomande() async {
    final snapshot = await FirebaseFirestore.instance.collection('domande').get();

    final tutte = snapshot.docs.map((doc) {
      final data = doc.data();
      return Domanda(
        testo: data['testo'],
        opzioni: List<String>.from(data['opzioni']),
        rispostaCorretta: int.tryParse(data['rispostaCorretta'].toString()) ?? 0,
      );
    }).toList();

    tutte.shuffle();
    domande = tutte.take(10).toList();

    setState(() {
      loading = false;
    });
  }

  void controllaRisposta(int index) {
    setState(() {
      selezionata = index;
      risposto = true;

      if (index == domande[domandaCorrente].rispostaCorretta) {
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
        _terminaQuiz();
      }
    });
  }

  void _terminaQuiz() async {
    final user = FirebaseAuth.instance.currentUser!;
    final docRef = FirebaseFirestore.instance.collection('utenti').doc(user.uid);

    final doc = await docRef.get();
    final dati = doc.data()!;
    final int soldi = dati['soldi'] ?? 0;
    final int gradi = dati['gradi'] ?? 0;
    final int cuori = dati['cuori'] ?? 5;
    final int corretteTot = dati['risposte_corrette'] ?? 0;
    final int sbagliateTot = dati['risposte_sbagliate'] ?? 0;
    final int vittorie = dati['vittorie'] ?? 0;
    final int sconfitte = dati['sconfitte'] ?? 0;
    final int giocate = dati['partite_giocate'] ?? 0;

    final bool vinta = risposteCorrette >= 6;
    final int premio = risposteCorrette * 10;
    final int sbagliate = domande.length - risposteCorrette;
    final int nuoviCuori = (sbagliate > 5 && cuori > 0) ? cuori - 1 : cuori;

    await docRef.update({
      'risposte_corrette': corretteTot + risposteCorrette,
      'risposte_sbagliate': sbagliateTot + sbagliate,
      'soldi': soldi + premio - (vinta ? 0 : 50), // toglie 50 monete se perdi
      'gradi': gradi + (vinta ? 10 : -5), // guadagni 10 o perdi 5
      'cuori': nuoviCuori,
      'vittorie': vittorie + (vinta ? 1 : 0),
      'sconfitte': sconfitte + (vinta ? 0 : 1),
      'partite_giocate': giocate + 1,
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.brown[100],
        title: Text(
          vinta ? "Hai vinto! 🎉" : "Peccato! 😢",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[800]),
        ),
        content: Text(
          "Hai risposto correttamente a $risposteCorrette domande su ${domande.length}.\nHai guadagnato $premio monete.",
          style: TextStyle(fontSize: 16, color: Colors.brown[700]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text("Torna alla Home", style: TextStyle(color: Colors.green[800])),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text("Quiz di Giostra")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Sto preparando le domande..."),
            ],
          ),
        ),
      );
    }

    final domanda = domande[domandaCorrente];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF2E9),
      appBar: AppBar(
        title: Text("Domanda ${domandaCorrente + 1}/10"),
        backgroundColor: Colors.brown[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Text(
                domanda.testo,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 24),
            ...List.generate(domanda.opzioni.length, (index) {
              final opzione = domanda.opzioni[index];
              final isCorretta = index == domanda.rispostaCorretta;
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
                margin: EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colore,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.all(16),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: risposto ? null : () => controllaRisposta(index),
                  child: Text(opzione, style: TextStyle(fontSize: 16)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}