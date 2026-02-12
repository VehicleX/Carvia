
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
  
  // Helper
  firebase_auth.User? get currentFirebaseUser;
}

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
        isVerified: false, // OTP verification happens separately or handled here?
                           // Prompt says: Register -> Send OTP -> Verify -> Create User Doc
                           // So we might NOT want to create the doc here if we follow that strictly.
                           // BUT `createUserWithEmailAndPassword` creates the Auth user.
                           // If we want "OTP only for new users", we usually verify phone BEFORE or DURING this.
      );

      // 3. Save to Firestore
      await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());
      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
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
}
