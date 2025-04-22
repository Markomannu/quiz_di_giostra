import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'quiz_page.dart';
import 'classifica_page.dart';
import 'crea_stanza_page.dart';
import 'unisciti_stanza_page.dart';
import 'auth_service.dart';
import 'giocaOnlinePage.dart';
import 'uniscitiOnlinePage.dart';
import 'dart:async';
import 'main.dart';
import 'collezione_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final User user = FirebaseAuth.instance.currentUser!;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();
  Timer? _cuoriTimer;

  Map<String, dynamic>? userData;
  bool _mostraScelteAmico = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  String titolo = "";

  @override
  void initState() {
    super.initState();
    _aggiornaCuoriUtente();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
    _cuoriTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _aggiornaCuoriUtente();
    });

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    _cuoriTimer?.cancel();
    super.dispose();
  }
  void _mostraRegolamento() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Regolamento"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📜 Benvenuto nel Quiz di Giostra e di Arezzo!\n"),
              Text("• Hai 5 cuori: se li finisci, dovrai aspettare per rigiocare."),
              Text("• Modalità disponibili:\n   - Single Player\n   - Gioca Online"),
              Text("• Guadagna monete rispondendo correttamente."),
              Text("• Le monete ti permettono di acquistare nello Store e di evocare personaggi della città."),
              Text("• Scala la classifica del tuo quartiere e ottieni gradi sempre più alti!"),
              Text("\nBuona fortuna, cavaliere! ⚔️"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Chiudi"),
          ),
        ],
      ),
    );
  }

  Future<String?> uploadImageToImgBB(File imageFile) async {
    final apiKey = '2458b2442db5046062f44e95a6fc699b'; // 🔁 Inserisci qui la tua API key
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      url,
      body: {'image': base64Image},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['url'];
    } else {
      print('Errore nel caricamento: ${response.body}');
      return null;
    }
  }
  Future<void> _aggiornaCuoriUtente() async {
    final docRef = firestore.collection('utenti').doc(user.uid);
    final doc = await docRef.get();
    final data = doc.data()!;

    int cuori = data['cuori'] ?? 5;
    Timestamp? ultimo = data['ultimo_cuore'];

    if (cuori >= 5) return;

    DateTime oraAttuale = DateTime.now();
    DateTime ultimoTempo = ultimo?.toDate() ?? oraAttuale;

    int minutiPassati = oraAttuale.difference(ultimoTempo).inMinutes;
    int cuoriRigenerati = (minutiPassati ~/ 15).clamp(0, 5 - cuori);

    if (cuoriRigenerati > 0) {
      cuori += cuoriRigenerati;
      DateTime nuovoUltimo = ultimoTempo.add(Duration(minutes: 15 * cuoriRigenerati));

      await docRef.update({
        'cuori': cuori,
        'ultimo_cuore': Timestamp.fromDate(nuovoUltimo),
      });

      await _loadUserData(); // 👈 AGGIUNGI QUESTA RIGA
    }
  }

  Future<void> _loadUserData() async {
    final doc = await firestore.collection('utenti').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        userData = data;
      });
      await _calcolaTitolo(data);
    }
  }

  Future<void> _calcolaTitolo(Map<String, dynamic> data) async {
    final quartiere = data['quartiere'];
    final snapshot = await firestore
        .collection('utenti')
        .where('quartiere', isEqualTo: quartiere)
        .orderBy('soldi', descending: true)
        .get();

    final utenti = snapshot.docs;
    final posizione = utenti.indexWhere((doc) => doc.id == user.uid);
    final totale = utenti.length;

    setState(() {
      titolo = _assegnaGrado(posizione, totale);
    });
  }

  String _assegnaGrado(int posizione, int totale) {
    if (posizione == 0) return "Rettore";
    if (posizione == 1) return "Rettore vicario";
    if (posizione == 2) return "Capitano";
    if (posizione == 3) return "Vice Capitano";
    if (posizione == 4) return "Maestro d'armi";
    if (posizione == 5) return "Camerlengo";
    if (posizione == 6) return "Provveditore";
    if (posizione >= 7 && posizione <= 10) return "Cavaliere di Casata";
    if (posizione >= 11 && posizione <= 14) return "Vessillifero";
    if (posizione >= 15 && posizione <= 26) return "Lucco";

    final percentuale = (posizione + 1) / totale;
    if (percentuale <= 0.3) return "Armigero";
    if (percentuale <= 0.5) return "Balestriere";
    return "Sostenitore";
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MyApp()), // 👈 torna alla root con AuthWrapper
            (route) => false,
      );
    }
  }

  Future<void> _mostraDialogCuoriFiniti() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Hai finito le vite!"),
        content: Text("Fatti una girata per il corso!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Ok"),
          )
        ],
      ),
    );
  }

  Future<void> _controllaCuoriEFai(VoidCallback onSuccess) async {
    final cuori = userData?['cuori'] ?? 0;
    if (cuori == 0) {
      await _mostraDialogCuoriFiniti();
    } else {
      onSuccess();
    }
  }

  Future<void> _modificaNome() async {
    final controller = TextEditingController(text: userData!['nome'] ?? user.displayName ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Modifica nome"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: "Nuovo nome"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annulla"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuovoNome = controller.text.trim();
              if (nuovoNome.isNotEmpty) {
                await firestore.collection('utenti').doc(user.uid).update({'nome': nuovoNome});
                await user.updateDisplayName(nuovoNome);
                await _loadUserData();
              }
              Navigator.pop(context);
            },
            child: Text("Salva"),
          ),
        ],
      ),
    );
  }

  Future<void> _modificaFotoProfilo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final imageFile = File(picked.path);
      final imageUrl = await uploadImageToImgBB(imageFile);

      if (imageUrl != null) {
        await firestore.collection('utenti').doc(user.uid).update({'foto': imageUrl});
        await user.updatePhotoURL(imageUrl);
        await _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore nel caricamento dell'immagine")));
      }

      await _loadUserData();
    }
  }

  String _getQuartiereIcon(String nome) {
    if (nome.contains("Sant'Andrea")) return 'assets/stemmi/sant_andrea.png';
    if (nome.contains("Crucifera")) return 'assets/stemmi/crucifera.png';
    if (nome.contains("Santo Spirito")) return 'assets/stemmi/santo_spirito.png';
    if (nome.contains("Foro")) return 'assets/stemmi/porta_foro.png';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (userData == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int cuori = userData!['cuori'] ?? 0;
    final int soldi = userData!['soldi'] ?? 0;
    final int gradi = userData!['gradi'] ?? 0;
    final int rispCorrette = userData!['risposte_corrette'] ?? 0;
    final int rispSbagliate = userData!['risposte_sbagliate'] ?? 0;
    final String quartiere = userData!['quartiere'] ?? 'N/D';
    final String nomeUtente = userData!['nome'] ?? user.displayName ?? "Utente";
    final String? foto = userData!['foto'];

    final int totRisposte = rispCorrette + rispSbagliate;
    final double percentuale = totRisposte == 0 ? 0 : (rispCorrette / totRisposte * 100).clamp(0, 100);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background_parchment.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown[300]!),
                ),
                child: TextButton.icon(
                  onPressed: _mostraRegolamento,
                  icon: Icon(Icons.rule, color: Colors.brown[800], size: 18),
                  label: Text(
                    "Regolamento",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    foregroundColor: Colors.brown[800],
                  ),
                ),
              ),
            ),


                Row(
                  children: [
                    GestureDetector(
                      onTap: _modificaFotoProfilo,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundImage: foto != null ? NetworkImage(foto) : null,
                        child: foto == null ? Icon(Icons.person, size: 40) : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nomeUtente,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[900]),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 20),
                                tooltip: "Modifica nome",
                                onPressed: _modificaNome,
                              )
                            ],
                          ),
                          if (titolo.isNotEmpty)
                            Container(
                              margin: EdgeInsets.only(top: 4, bottom: 4),
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.brown[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield, color: Colors.brown[800], size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    titolo,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Row(
                            children: [
                              Text("Quartiere: $quartiere"),
                              SizedBox(width: 6),
                              Image.asset(
                                _getQuartiereIcon(quartiere),
                                width: 24,
                                height: 24,
                                errorBuilder: (_, __, ___) => SizedBox.shrink(),
                              )
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (i) =>
                                Icon(Icons.favorite, color: i < cuori ? Colors.red : Colors.grey, size: 18)),
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.redAccent),
                      onPressed: _logout,
                    )
                  ],
                ),
                SizedBox(height: 24),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                  color: Colors.white.withOpacity(0.85),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        StatRowIcon(
                          icon: Icons.monetization_on,
                          label: 'Soldi',
                          value: '$soldi 🪙',
                          valueColor: Colors.amber[800],
                        ),
                        StatRowIcon(
                          icon: Icons.check_circle,
                          label: 'Risposte Corrette',
                          value: '$rispCorrette',
                          valueColor: Colors.green[800],
                        ),
                        StatRowIcon(
                          icon: Icons.cancel,
                          label: 'Risposte Sbagliate',
                          value: '$rispSbagliate',
                          valueColor: Colors.red[700],
                        ),
                        StatRowIcon(
                          icon: Icons.percent,
                          label: 'Percentuale Corrette',
                          value: '${percentuale.toStringAsFixed(1)} %',
                          valueColor: Colors.blueGrey[800],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CollezionePage()),
                      );
                    },
                    icon: Icon(Icons.collections_bookmark, size: 28),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "Visualizza Collezione",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[600],
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                    ),
                  ),
                ),

// 👇 PULSANTE STORE qui nello spazio vuoto
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/store');
                      await _loadUserData();
                    },
                    icon: Icon(Icons.store, size: 28),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        "Entra nello Store",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 70), // 👈 Più largo e alto
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // 👈 Più rettangolare
                      ),
                      elevation: 6,
                    ),
                  ),
                ),


                SizedBox(height: 24),

                Text("Modalità di gioco", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[800])),
                SizedBox(height: 12),

                _gameButton("Gioca in Single Player", Icons.person, () async {
                  _controllaCuoriEFai(() async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPage()));
                    _loadUserData();
                  });
                }),

                _gameButton("Gioca Online", Icons.wifi, () {
                  _controllaCuoriEFai(() {
                    setState(() {
                      _mostraScelteAmico = false;
                      _controller.reset();
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.brown[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (_) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Gioca Online", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                SizedBox(height: 12),
                                _gameButton("Crea una partita", Icons.add, () async {
                                  Navigator.pop(context);
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => GiocaOnlinePage()));
                                  await _loadUserData(); // 👈 aggiorna i dati dopo la partita
                                }),

                                _gameButton("Unisciti a una partita", Icons.input, () async {
                                  Navigator.pop(context);
                                  await Navigator.push(context, MaterialPageRoute(builder: (_) => UniscitiOnlinePage()));
                                  await _loadUserData(); // 👈 aggiorna i dati dopo la partita
                                }),

                              ],
                            ),
                          );
                        },
                      );
                    });
                  });
                }),
                _gameButton("Classifiche", Icons.leaderboard, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassificaPage()))),





              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameButton(String text, IconData icon, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[600],
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: Icon(icon),
        label: Text(text),
        onPressed: onPressed,
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final String label;
  final String value;

  const StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.brown[900])),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[900]))
        ],
      ),
    );
  }
}
class StatRowIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const StatRowIcon({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.brown[700], size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: Colors.brown[900]),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.brown[800],
            ),
          ),
        ],
      ),
    );
  }
}