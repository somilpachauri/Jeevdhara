
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  Future<void> signUpCompany({
    required String safeId,
    required String syntheticEmail,
    required String password,
    required String companyName,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: syntheticEmail,
      password: password,
    );

    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'companyId': safeId,
      'companyName': companyName,
      'role': 'company',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String generateSyntheticEmail(String id, String domain) {
    String safeId = id.trim().replaceAll(' ', '').toUpperCase();
    return "$safeId@$domain";
  }

  Future<void> signUpWithRole({
    required String email,
    required String password,
    required String role,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

