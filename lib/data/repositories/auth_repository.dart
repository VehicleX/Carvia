
import 'package:carvia/core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

abstract class AuthRepository {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> loginWithEmail(String email, String password);
  Future<UserModel?> register({
    required String email, 
    required String password, 
    required String name, 
    required String phone,
    required UserRole role,
  });
  Future<UserModel?> loginWithGoogle();
  Future<void> logout();
  Future<void> verifyPhone(String phone, Function(String, int?) codeSent);
  Future<bool> verifyOTP(String verificationId, String smsCode);
  Future<UserModel?> completeProfile({required UserRole role, required String phone, required String name, required String email});
  Future<bool> checkEmailExists(String email);
  Future<void> updateProfile({required String uid, required String name, required String phone, String? profileImage});
  Future<void> updateAccountType(String uid, UserRole role);

  
  // Helper
  firebase_auth.User? get currentFirebaseUser;

  // Password Reset Simulation
  Future<void> sendPasswordResetOtp(String email);
  Future<bool> verifyPasswordResetOtp(String email, String otp, String expectedOtp);
  Future<void> resetPassword(String email, String newPassword);
}

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // serverClientId is optional but helps with token validation
    // If you need it for backend verification, add your OAuth client ID here
    scopes: ['email', 'profile'],
  );

  @override
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;
  
  firebase_auth.FirebaseAuth get firebaseAuthInstance => _firebaseAuth;

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint("Auth Stream Error: $e");
      }
      return null;
    });
  }

  @override
  Future<UserModel?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) return null;

      final newUser = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: true, 
        credits: 500, // Welcome Bonus
      );

      // Save User
      await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());

      // Send Welcome Notification
      await _sendWelcomeNotification(newUser.uid, 500);

      return newUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw 'This email is already registered. Please login instead.';
        case 'weak-password':
          throw 'Password is too weak. Use at least 6 characters.';
        case 'invalid-email':
          throw 'Invalid email format.';
        case 'operation-not-allowed':
          throw 'Email/password accounts are not enabled.';
        default:
          throw 'Registration failed: ${e.message}';
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> loginWithGoogle() async {
    try {
      // Try silent sign-in first (recommended for web, works on all platforms)
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // If silent sign-in returns null, fall back to interactive sign-in
      // On web, this may trigger a popup (which is now deprecated but still works as fallback)
      googleUser??= await _googleSignIn.signIn();
      
      if (googleUser == null) return null; // Cancelled
      googleUser ??= await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!, doc.id);
        } else {
           return null; 
        }
      }
    } catch (e) {
       debugPrint("Google Login Error: $e");
       String msg = "Google Sign In Failed. ";
       if (e.toString().contains("ApiException: 10")) {
         msg += "Development SHA-1 fingerprint mismatch. Add your debug.keystore SHA-1 to Firebase Console.";
       } else if (e.toString().contains("ApiException: 12500")) {
         msg += "Google Sign Not Available on this device/emulator."; 
       }
       throw msg;
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> verifyPhone(String phone, Function(String, int?) codeSent) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {},
      verificationFailed: (e) { throw e; },
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  Future<bool> verifyOTP(String verificationId, String smsCode) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      if (_firebaseAuth.currentUser != null) {
         await _firebaseAuth.currentUser!.linkWithCredential(credential);
         return true;
      }
      return false; 
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserModel?> completeProfile({
    required UserRole role,
    required String phone,
    required String name,
    required String email,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw "No authenticated user";

      final newUser = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: true, 
        credits: 500, // Welcome Bonus
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      
      // Send Welcome Notification
      await _sendWelcomeNotification(user.uid, 500);

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  // Helper to send welcome notification
  Future<void> _sendWelcomeNotification(String userId, int credits) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': 'Welcome to Carvia! 🎉',
            'body': 'You have received $credits Canvas Credits as a welcome bonus. Use them to get discounts on your purchases!',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'credit_earned',
            'data': {'amount': credits},
          });
    } catch (e) {
      debugPrint("Failed to send welcome notification: $e");
    }
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      // Check Firebase Auth
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) return true;
      
      // Also check Firestore (in case auth and firestore are out of sync)
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> sendPasswordResetOtp(String email) async {
    // Use Real Firebase Password Reset
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      debugPrint("Password reset email sent to $email");
    } catch (e) {
      throw "Failed to send reset email: $e";
    }
  }

  @override
  Future<bool> verifyPasswordResetOtp(String email, String otp, String expectedOtp) async {
    // Not needed for Firebase native flow, but keeping for interface compatibility
    return true; 
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    // Not needed for Firebase native flow as the link handles it.
    // This method might be deprecated or unused in the new flow.
    // We can just return or log.
    debugPrint("Password reset handled via email link.");
  }

  @override
  Future<void> updateProfile({required String uid, required String name, required String phone, String? profileImage}) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'phone': phone,
        if (profileImage != null) 'profileImage': profileImage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        if (profileImage != null) {
          await user.updatePhotoURL(profileImage);
        }
      }
    } catch (e) {
      throw "Failed to update profile: $e";
    }
    }

  @override
  Future<void> updateAccountType(String uid, UserRole role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role.toString().split('.').last, // Store as string 'company' or 'individual'
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw "Failed to update account type: $e";
    }
  }
}
}
