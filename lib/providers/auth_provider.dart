import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      final credential = await _authService.signUpWithEmail(email, password);
      if (credential.user != null) {
        await _firestoreService.initializeUser(credential.user!);
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final credential = await _authService.signInWithEmail(email, password);
      if (credential.user != null) {
        await _firestoreService.initializeUser(credential.user!);
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential.user != null) {
        await _firestoreService.initializeUser(credential.user!);
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> verifyCredentials(String email, String password) async {
    try {
      // Re-authenticate the user to verify password
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email == email) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: email,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        // If user is not logged in or email doesn't match, try to sign in
        await _authService.signInWithEmail(email, password);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
