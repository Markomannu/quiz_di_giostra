import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassificaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Classifiche", style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "Globale"),
              Tab(text: "Quartiere"),
              Tab(text: "Tra Quartieri"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildClassificaGlobale(),
            _buildClassificaQuartiere(),
            _buildClassificaRioni(),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificaGlobale() {
    return FutureBuilder(
      future: _calcolaPunteggiUtenti(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final utenti = snapshot.data as List<Map<String, dynamic>>;

        return ListView.builder(
          itemCount: utenti.length,
          itemBuilder: (_, index) {
            final utente = utenti[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.brown[100],
                  child: Text("#${index + 1}", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                title: Text(utente['nome'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(utente['quartiere'], style: TextStyle(fontStyle: FontStyle.italic)),
                trailing: Text("${utente['punteggio']} 🪙", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClassificaQuartiere() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('utenti').doc(uid).get(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final quartiere = snapshot.data!['quartiere'];

        return FutureBuilder(
          future: _calcolaPunteggiUtenti(filtraQuartiere: quartiere),
          builder: (_, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
            final utenti = snapshot.data as List<Map<String, dynamic>>;
            final totale = utenti.length;

            String getGrado(int index) {
              if (index == 0) return "Rettore";
              if (index == 1) return "Rettore Vicario";
              if (index == 2) return "Capitano";
              if (index == 3) return "Vice Capitano";
              if (index == 4) return "Maestro d'Armi";
              if (index == 5) return "Camerlengo";
              if (index == 6) return "Provveditore";
              if (index < 11) return "Cavaliere di Casata";
              if (index < 15) return "Vessillifero";
              if (index < 27) return "Lucco";

              final percentuale = (index / totale) * 100;
              if (percentuale <= 30) return "Armigero";
              if (percentuale <= 50) return "Balestriere";
              return "Sostenitore";
            }

            return ListView.builder(
              itemCount: utenti.length,
              itemBuilder: (_, index) {
                final utente = utenti[index];
                final grado = getGrado(index);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.amber[200],
                      child: Text("#${index + 1}"),
                    ),
                    title: Text(utente['nome'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("$grado - ${utente['quartiere']}"),
                    trailing: Text("${utente['punteggio']} 🪙", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildClassificaRioni() {
    return FutureBuilder(
      future: _calcolaPunteggiUtenti(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final utenti = snapshot.data as List<Map<String, dynamic>>;

        Map<String, num> punteggiTotali = {};

        for (var u in utenti) {
          final q = u['quartiere'];
          final punti = u['punteggio'];
          punteggiTotali[q] = (punteggiTotali[q] ?? 0) + punti;
        }

        final classifica = punteggiTotali.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView.builder(
          itemCount: classifica.length,
          itemBuilder: (_, index) {
            final rione = classifica[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[200],
                  child: Text("#${index + 1}"),
                ),
                title: Text(rione.key, style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("${rione.value} 🪙", style: TextStyle(fontSize: 16)),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _calcolaPunteggiUtenti({String? filtraQuartiere}) async {
    final utentiSnapshot = await FirebaseFirestore.instance.collection('utenti').get();
    final storeSnapshot = await FirebaseFirestore.instance.collection('store').get();

    final storePrezzi = {
      for (var doc in storeSnapshot.docs)
        doc.id: int.tryParse(doc.data()['prezzo'].toString()) ?? 0
    };

    final riacquistabili = {
      for (var doc in storeSnapshot.docs)
        if (doc.data()['riacquistabile'] == true)
          doc.id: int.tryParse(doc.data()['prezzo'].toString()) ?? 0
    };

    List<Map<String, dynamic>> lista = [];

    for (var doc in utentiSnapshot.docs) {
      final data = doc.data();
      final nome = data['nome'] ?? 'Anonimo';
      final quartiere = data['quartiere'] ?? 'Sconosciuto';
      final soldi = data['soldi'] ?? 0;
      final oggetti = List<String>.from(data['oggetti'] ?? []);
      final collezione = (data['collezione'] is List) ? List<String>.from(data['collezione']) : <String>[];

      int spesaOggetti = oggetti.fold(0, (sum, id) => sum + (storePrezzi[id] ?? 0) * 2);
      int spesaCollezione = 0;
      for (final id in riacquistabili.keys) {
        final count = collezione.where((e) => e == id).length;
        spesaCollezione += count * riacquistabili[id]! * 2;
      }

      final punteggio = soldi + spesaOggetti + spesaCollezione;

      if (filtraQuartiere == null || filtraQuartiere == quartiere) {
        lista.add({
          'nome': nome,
          'quartiere': quartiere,
          'punteggio': punteggio,
        });
      }
    }

    lista.sort((a, b) => b['punteggio'].compareTo(a['punteggio']));
    return lista;
  }

}