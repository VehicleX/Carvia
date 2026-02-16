
import 'package:carvia/core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  
  // Helper
  firebase_auth.User? get currentFirebaseUser;
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
  
  // Helper to expose instance if needed (or just use getter above)
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
        // Handle error or return null
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
      // 1. Create Auth User
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user == null) return null;

      // 2. Create User Model
      final newUser = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: true, // Set to true since they verified via OTP
      );

      // 3. Save to Firestore
      await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
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
          // New Google User -> Needs to complete profile (Select Role & Phone)
          // We return null here or a specific "IncompleteUser" object?
          // For now, returning null might imply failure.
          // Let's check the doc existence in the UI flow to trigger "Complete Profile".
          return null; 
        }
      }
    } catch (e) {
      rethrow;
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
      // We don't sign in with this credential if we are linking it.
      // Or if we are just verifying.
      // If we are linking to current user:
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
        isVerified: true, // Phone verified if we reached here
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      return newUser;
    } catch (e) {
      rethrow;
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
    } catch (e) {
      return false;
    }
  }
}
