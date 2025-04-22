import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'quartiere_selector_page.dart';
import 'intro_video_page.dart';
import 'store_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz di Giostra',
      theme: ThemeData(primarySwatch: Colors.green),
      debugShowCheckedModeBanner: false,
      initialRoute: '/intro', // 👈 parte dal video
      routes: {
        '/intro': (context) => IntroVideoPage(),      // 👈 prima schermata (una volta)
        '/auth': (context) => AuthWrapper(),          // 👈 logica di autenticazione
        '/store': (context) => StorePage(),           // 👈 pagina dello Store
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final uid = snapshot.data!.uid;
          final userDocRef = FirebaseFirestore.instance.collection('utenti').doc(uid);

          return FutureBuilder<DocumentSnapshot>(
            future: userDocRef.get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final data = userSnapshot.data?.data() as Map<String, dynamic>?;

              // ✅ Aggiunta automatica del campo 'ultimo_cuore' se manca
              if (data != null && !data.containsKey('ultimo_cuore')) {
                userDocRef.update({'ultimo_cuore': Timestamp.now()});
              }

              if (data == null || data['quartiere'] == null) {
                return QuartiereSelectorPage(); // 👈 Se non ha selezionato il quartiere
              }

              return HomePage(); // 👈 Tutto ok, va nella home
            },
          );
        }

        return LoginPage(); // 👈 Utente non loggato
      },
    );
  }
}
