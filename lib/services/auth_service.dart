import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the instance of AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

// Provides the current auth state (User?)
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class AuthService {
  final FirebaseAuth _firebaseAuth;

  AuthService(this._firebaseAuth);

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Retrieves the user's role from Firebase Custom Claims.
  /// Ensure a Cloud Function sets this claim (e.g., 'admin', 'staff', 'warehouse', 'client').
  Future<String> getUserRole() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return 'unauthenticated';
    }

    try {
      // Force refresh to get the latest claims if they were just updated.
      final idTokenResult = await user.getIdTokenResult(true);
      final claims = idTokenResult.claims;

      if (claims != null && claims.containsKey('role')) {
        return claims['role'] as String;
      }
      
      // Default fallback if no role is assigned yet.
      return 'client'; 
    } catch (e) {
      return 'client'; // Fallback on error
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      default:
        if (e.message?.contains('CONFIGURATION_NOT_FOUND') ?? false) {
          return 'Authentication service is not fully configured on the server yet. Please try again later.';
        }
        return e.message ?? 'An unknown error occurred.';
    }
  }
}
