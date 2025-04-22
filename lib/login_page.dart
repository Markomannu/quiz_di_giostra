import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_email_page.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2E9), // Beige tipo pergamena
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 📷 IMMAGINE GRANDE
                Image.asset(
                  'assets/logo_giostra.png',
                  height: 220,
                ),
                SizedBox(height: 32),

                // 🎉 TITOLO
                Text(
                  'Benvenuto al\nQuiz della Giostra!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Georgia', // stile più "storico"
                    color: Colors.brown[800],
                  ),
                ),
                SizedBox(height: 32),

                // 🔐 Google Login
                ElevatedButton.icon(
                  icon: Icon(Icons.login),
                  label: Text("Accedi con Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green[800],
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    final user = await _authService.signInWithGoogle();
                    if (user != null) {
                      print("Login riuscito: ${user.displayName}");
                    } else {
                      print("Login annullato");
                    }
                  },
                ),
                SizedBox(height: 16),

                // ✉️ Email login
                ElevatedButton.icon(
                  icon: Icon(Icons.mail),
                  label: Text("Accedi con Email"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo[900],
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginEmailPage()),
                    );
                  },
                ),
                SizedBox(height: 16),

                // ➕ Registrazione
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterPage()),
                    );
                  },
                  child: Text(
                    "Non hai un account? Registrati",
                    style: TextStyle(color: Colors.brown[700]),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
