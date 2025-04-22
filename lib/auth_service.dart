import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) return null; // L'utente ha annullato il login

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    // 🔥 Se è un nuovo utente, creiamo il documento su Firestore
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('utenti').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'email': user.email,
          'nome': user.displayName,
          'foto': user.photoURL,
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
      }
    }

    return user;
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
