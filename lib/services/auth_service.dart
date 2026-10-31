import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Authentication and profile storage use separate Firebase services.
/// A successful Auth signup is NOT automatically a successful Firestore write.
class ProfileSetupException implements Exception {
  final String message;
  const ProfileSetupException(this.message);
  @override
  String toString() => message;
}

class AuthErrorMessages {
  static String from(Object error) {
    if (error is ProfileSetupException) return error.message;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email already has an account. Log in with your password to finish setting up FastFit, or reset your password if needed.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Your password is too weak. Use at least 6 characters.';
        case 'wrong-password':
        case 'invalid-credential':
        case 'user-not-found':
        case 'invalid-login-credentials':
          return 'Incorrect email or password. Check your details or reset your password.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'network-request-failed':
          return 'Connection failed. Check your internet and try again.';
        case 'operation-not-allowed':
          return 'Sign-in is currently unavailable. Please try again later.';
        case 'requires-recent-login':
          return 'Please log in again to complete this action.';
        default:
          return 'We couldn\'t sign you in. Please try again.';
      }
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'We couldn\'t save your details right now. Please try again later or contact FastFit support.';
        case 'unavailable':
          return 'We couldn\'t connect right now. Check your internet and try again.';
        case 'not-found':
          return 'The requested profile could not be found.';
        default:
          return 'Something went wrong while loading your details. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}

class AuthService {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  static bool isPublicRole(String role) => role == 'user' || role == 'restaurant';

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    if (!isPublicRole(role)) throw ArgumentError('Invalid account type');
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) throw ArgumentError('Name is required');

    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const ProfileSetupException('Could not finish creating your account.');
    }

    // Do not delete the Auth user if Firestore fails. Deleting risks losing
    // an account when a write succeeded remotely but its ACK was lost.
    // Instead, the signed-in user can safely complete their missing profile.
    try {
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': normalizedName,
        'email': user.email ?? email.trim().toLowerCase(),
        'role': role,
        'fitnessGoal': null,
        'weight': null,
        'approvalStatus': role == 'restaurant' ? 'pending' : 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (_) {
      throw ProfileSetupException(
        'Your account is ready, but we couldn\'t finish setting up your profile. '
        'Please complete your details to continue.',
      );
    } catch (_) {
      throw const ProfileSetupException(
        'Your account is ready, but we couldn\'t finish setting up your profile. '
        'Please complete your details to continue.',
      );
    }
  }

  Future<void> completeMissingProfile({
    required String name,
    required String role,
  }) async {
    if (!isPublicRole(role)) throw ArgumentError('Invalid account type');
    final user = auth.currentUser;
    if (user == null) throw StateError('Please log in first');
    final value = name.trim();
    if (value.isEmpty) throw ArgumentError('Name is required');

    final ref = firestore.collection('users').doc(user.uid);
    await firestore.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      // Never change roles or overwrite an existing profile from recovery.
      if (existing.exists) return;
      transaction.set(ref, {
        'uid': user.uid,
        'name': value,
        'email': user.email ?? '',
        'role': role,
        'fitnessGoal': null,
        'weight': null,
        'approvalStatus': role == 'restaurant' ? 'pending' : 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> login(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) throw ArgumentError('Enter your email first');
    await auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> logout() => auth.signOut();
}
