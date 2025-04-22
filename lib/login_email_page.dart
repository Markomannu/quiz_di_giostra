import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginEmailPage extends StatefulWidget {
  @override
  _LoginEmailPageState createState() => _LoginEmailPageState();
}

class _LoginEmailPageState extends State<LoginEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errore;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = cred.user;

        if (user != null) {
          final docRef = FirebaseFirestore.instance.collection('utenti').doc(user.uid);
          final doc = await docRef.get();

          if (!doc.exists) {
            await docRef.set({
              'email': user.email,
              'nome': null,
              'foto': null,
              'quartiere': null,
              'cuori': 5,
              'ultimo_cuore': Timestamp.now(),
              'soldi': 0,
              'gradi': 0,
              'risposte_corrette': 0,
              'risposte_sbagliate': 0,
              'partite_giocate': 0,
              'vittorie': 0,
              'sconfitte': 0,
            });
          } else {
            final data = doc.data()!;
            if (!data.containsKey('ultimo_cuore')) {
              await docRef.update({'ultimo_cuore': Timestamp.now()});
            }
          }
        }

        Navigator.pop(context);
      } catch (e) {
        setState(() {
          errore = "Email o password non validi.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 🔙 Bottone indietro
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.brown[800]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Login con Email",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[900],
                      ),
                    ),
                    SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(
                            label: "Email",
                            controller: emailController,
                            validator: (value) => value!.contains("@") ? null : "Email non valida",
                          ),
                          _buildField(
                            label: "Password",
                            controller: passwordController,
                            obscureText: true,
                            validator: (value) => value!.length < 6 ? "Minimo 6 caratteri" : null,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: _login,
                            label: Text("Accedi", style: TextStyle(fontSize: 16)),
                          ),
                          if (errore != null) ...[
                            SizedBox(height: 16),
                            Text(
                              errore!,
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
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
