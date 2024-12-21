import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/models.dart' show User, UserRole;
import 'firebase_service.dart';

class AuthService extends FirebaseService {
  AuthService({
    super.firestore,
    super.auth,
    super.storage,
  });

  Future<User> signIn(String email, String password) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final doc = await firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();
      
      if (!doc.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User data not found in Firestore',
        );
      }

      final user = User.fromFirestore(doc);
      await _updateLastLogin(user.id);
      return user;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }

  Future<User> signUp(String name, String email, String password) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final now = DateTime.now();
      final user = User(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: UserRole.user,
        createdAt: now,
        lastLoginAt: now,
        isVerified: false,
      );

      await firestore
          .collection('users')
          .doc(user.id)
          .set(user.toFirestore());

      return user;
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null) return null;

      final doc = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!doc.exists) return null;

      return User.fromFirestore(doc);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? avatarURL,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatarURL != null) updates['avatarURL'] = avatarURL;

      await firestore
          .collection('users')
          .doc(userId)
          .update(updates);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await firestore
          .collection('users')
          .doc(userId)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
      // We don't want to rethrow here as this is not critical
    }
  }
} 