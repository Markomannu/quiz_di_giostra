import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CollezionePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final utentiRef = FirebaseFirestore.instance.collection('utenti');
    final personaggiRef = FirebaseFirestore.instance.collection('personaggi');

    return Scaffold(
      appBar: AppBar(title: Text("La mia Collezione")),
      body: FutureBuilder<DocumentSnapshot>(
        future: utentiRef.doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final collezione = List<String>.from(userData['collezione'] ?? []);

          if (collezione.isEmpty) return Center(child: Text("Nessun personaggio collezionato 😢"));

          return FutureBuilder<QuerySnapshot>(
            future: personaggiRef.get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

              final tuttiPersonaggi = snapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>..['id'] = doc.id)
                  .where((data) => collezione.contains(data['nome']))
                  .toList();

              return GridView.builder(
                padding: EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: tuttiPersonaggi.length,
                itemBuilder: (context, index) {
                  final personaggio = tuttiPersonaggi[index];
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(personaggio['nome']),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.network(personaggio['immagine'], height: 100),
                              SizedBox(height: 10),
                              Text("Rarità: ${personaggio['rarita']}"),
                              Text("Attacco: ${personaggio['attacco']}"),
                              Text("Difesa: ${personaggio['difesa']}"),
                              Text("Potenza: ${personaggio['potenza']}"),
                              SizedBox(height: 10),
                              Text(
                                personaggio['descrizione'],
                                style: TextStyle(fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Chiudi"),
                            )
                          ],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _getColorByRarita(personaggio['rarita']),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Card(
                        elevation: 4,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                child: Image.network(
                                  personaggio['immagine'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    personaggio['nome'],
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    personaggio['rarita'],
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 🌈 Colori in base alla rarità
  Color _getColorByRarita(String rarita) {
    switch (rarita.toLowerCase()) {
      case 'leggendario':
        return Colors.orangeAccent;
      case 'epico':
        return Colors.purple;
      case 'raro':
        return Colors.blue;
      case 'comune':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
