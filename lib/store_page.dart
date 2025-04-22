import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'evocazione_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  int soldi = 0;
  List<dynamic> oggettiPosseduti = [];
  int evocazioniDisponibili = 0;

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('utenti').doc(uid).get();
    final data = userDoc.data()!;
    setState(() {
      soldi = data['soldi'] ?? 0;
      oggettiPosseduti = data['oggetti'] ?? [];
      evocazioniDisponibili = data['evocazioni_disponibili'] ?? 0;
    });
  }

  Future<void> _acquista(String itemId, int prezzo, {bool isBaule = false}) async {
    if (soldi >= prezzo) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = FirebaseFirestore.instance.collection('utenti').doc(uid);

      final Map<String, dynamic> updates = {
        'soldi': soldi - prezzo,
      };

      if (!isBaule) {
        updates['oggetti'] = FieldValue.arrayUnion([itemId]);
      } else {
        updates['evocazioni_disponibili'] = FieldValue.increment(1);
      }

      await userDoc.update(updates);
      await _loadUserData();

      if (isBaule && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EvocazionePage()),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.yellow, Colors.orange],
          ).createShader(bounds),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.store, color: Colors.white),
              SizedBox(width: 8),
              Text(
                "Store",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Necessario anche con ShaderMask
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 5),
                Text(
                  "$soldi monete",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (evocazioniDisponibili > 0) ...[
                  const SizedBox(width: 20),
                  const Icon(Icons.stars, color: Colors.deepPurple),
                  Text("Evocazioni: $evocazioniDisponibili"),
                ]
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('store').snapshots(),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final items = snapshot.data!.docs;
                items.sort((a, b) {
                  if ((a.data() as Map)['nome'].toString().toLowerCase().contains('baule')) return -1;
                  if ((b.data() as Map)['nome'].toString().toLowerCase().contains('baule')) return 1;
                  return 0;
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final data = items[index].data() as Map<String, dynamic>;
                    final itemId = items[index].id;
                    final nome = data['nome'] ?? '';
                    final descrizione = data['descrizione'] ?? '';
                    final prezzo = int.tryParse(data['prezzo'].toString()) ?? 0;
                    final icona = data['icona'];
                    final isBaule = nome.toLowerCase().contains('baule');
                    final giaAcquistato = oggettiPosseduti.contains(itemId);
                    final abbastanzaSoldi = soldi >= prezzo;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (icona != null && icona.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    icona,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 70),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                nome,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                descrizione,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (!isBaule && giaAcquistato) ? "Acquistato ✅" : "$prezzo 🪙",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: (!isBaule && giaAcquistato)
                                      ? Colors.green
                                      : (abbastanzaSoldi ? Colors.black : Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: ((isBaule || !giaAcquistato) && abbastanzaSoldi)
                                    ? () => _acquista(itemId, prezzo, isBaule: isBaule)
                                    : null,
                                child: const Text("Acquista"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
