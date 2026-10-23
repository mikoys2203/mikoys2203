
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (role != 'user' && role != 'restaurant') {
      throw ArgumentError('Invalid account type');
    }

    UserCredential result =
        await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    String uid = result.user!.uid;

    await firestore.collection('users').doc(uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
      'fitnessGoal': null,
      'weight': null,
      'approvalStatus':
          role == 'restaurant' ? 'pending' : 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login(
    String email,
    String password,
  ) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await auth.signOut();
  }
}
