import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final nomeController = TextEditingController();
  String? errore;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await FirebaseFirestore.instance.collection('utenti').doc(userCredential.user!.uid).set({
          'nome': nomeController.text.trim(),
          'email': emailController.text.trim(),
          'cuori': 5,
          'soldi': 0,
          'gradi': 0,
          'risposte_corrette': 0,
          'risposte_sbagliate': 0,
          'partite_giocate': 0,
          'vittorie': 0,
          'sconfitte': 0,
          'oggetti': [],
          'quartiere': null,
          'foto': null,
          'ultimo_cuore': Timestamp.now(),
        });

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AuthWrapper()),
              (route) => false,
        );
      } catch (e) {
        setState(() {
          errore = "Errore durante la registrazione";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Sfondo pergamena
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background_parchment.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ✅ Bottone indietro
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Crea un nuovo account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField("Nome", nomeController, (v) => v!.isEmpty ? "Inserisci il tuo nome" : null),
                          _buildField("Email", emailController, (v) => v!.contains("@") ? null : "Email non valida"),
                          _buildField("Password", passwordController, (v) => v!.length < 6 ? "Minimo 6 caratteri" : null, obscure: true),
                          _buildField("Conferma Password", confirmController,
                                  (v) => v != passwordController.text ? "Le password non coincidono" : null, obscure: true),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.person_add),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: _register,
                            label: Text("Registrati", style: TextStyle(fontSize: 16)),
                          ),
                          if (errore != null) ...[
                            SizedBox(height: 16),
                            Text(errore!, style: TextStyle(color: Colors.red)),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String? Function(String?) validator, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withOpacity(0.85),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
