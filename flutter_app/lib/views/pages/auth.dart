import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ✅ SIGNUP + SAVE USERNAME TO FIRESTORE
  Future<void> createUserWithEmailPasswordAndUsername({
    required String email,
    required String password,
    required String username,
  }) async {
    final cleanEmail = email.trim();
    final cleanUsername = username.trim();

    if (cleanUsername.isEmpty) {
      throw Exception("Username cannot be empty");
    }

    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    final uid = cred.user!.uid;

    await _firestore.collection('users').doc(uid).set({
      'username': cleanUsername,
      'email': cleanEmail,
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
