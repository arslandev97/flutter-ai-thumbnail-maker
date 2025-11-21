import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _usersRef => _db.collection('users');

  // Initialize user data if not exists
  Future<void> initializeUser(User user) async {
    final docRef = _usersRef.doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'email': user.email,
        'credits': 10, // Initial free credits
        'generatedCount': 0,
        'savedCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get user credits
  Stream<int> getUserCredits(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      return data?['credits'] as int? ?? 0;
    });
  }

  // Deduct credit
  Future<bool> deductCredit(String uid) async {
    final docRef = _usersRef.doc(uid);

    return await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data() as Map<String, dynamic>?;
      final currentCredits = data?['credits'] as int? ?? 0;

      if (currentCredits > 0) {
        transaction.update(docRef, {'credits': currentCredits - 1});
        return true;
      } else {
        return false;
      }
    });
  }

  // Add credits (e.g., after watching ad)
  Future<void> addCredits(String uid, int amount) async {
    await _usersRef.doc(uid).update({'credits': FieldValue.increment(amount)});
  }

  // Increment generated count
  Future<void> incrementGeneratedCount(String uid) async {
    await _usersRef.doc(uid).update({
      'generatedCount': FieldValue.increment(1),
    });
  }

  // Increment saved count
  Future<void> incrementSavedCount(String uid) async {
    await _usersRef.doc(uid).update({'savedCount': FieldValue.increment(1)});
  }

  // Get all user data stream
  Stream<Map<String, dynamic>> getUserData(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      return snapshot.data() as Map<String, dynamic>? ?? {};
    });
  }
}
