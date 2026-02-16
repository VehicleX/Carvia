
import 'package:carvia/core/models/user_model.dart';
import 'package:carvia/core/services/email_otp_service.dart';
import 'package:carvia/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepositoryImpl();
  final EmailOtpService _emailOtpService = EmailOtpService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _authRepository.authStateChanges.listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  // Login with Email & Password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      _currentUser = await _authRepository.loginWithEmail(email, password);
      _setLoading(false);
      return _currentUser != null;
    } catch (e) {
      _setLoading(false);
      // In a real app, expose error message
      debugPrint("Login Error: $e");
      return false;
    }
  }

  // Google Login
  // Returns:
  // true: Login success, User exists, Redirect to Home
  // false: Login failed or Cancelled
  // throws "incomplete_profile": User authenticated but needs to complete profile (phone/role)
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    try {
      final user = await _authRepository.loginWithGoogle();
      
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        // If repository returns null, checks if it was just cancellation or "new user".
        // Check if Firebase Auth has a user but Firestore doc is missing
        if (await _isAuthButNoDoc()) {
          _setLoading(false);
          throw "incomplete_profile";
        }
        
        // User cancelled Google sign-in
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setLoading(false);
      if (e.toString() == "incomplete_profile") rethrow;
      rethrow;
    }
  }

  // Check if email already exists
  Future<bool> checkEmailExists(String email) async {
    return await _authRepository.checkEmailExists(email);
  }

  // Register with Email OTP Verification
  Future<String> sendRegistrationOtp(String email) async {
    _setLoading(true);
    try {
      final otp = await _emailOtpService.sendOtpToEmail(email);
      _setLoading(false);
      return otp; // For testing only - remove in production
    } catch (e) {
      _setLoading(false);

      rethrow;
    }
  }
  
  // Verify OTP and complete registration
  Future<bool> verifyOtpAndRegister({
    required String email,
    required String otp,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    _setLoading(true);
    try {
      // 1. Verify OTP
      final isValid = await _emailOtpService.verifyOtp(email, otp);
      if (!isValid) {
        _setLoading(false);
        throw 'Invalid or expired OTP';
      }
      
      // 2. Create user account
      final user = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        notifyListeners();
        return true;
      }
      
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);

      rethrow;
    }
  }
  
  // Resend OTP
  Future<String> resendOtp(String email) async {
    _setLoading(true);
    try {
      final otp = await _emailOtpService.resendOtp(email);
      _setLoading(false);
      return otp; // For testing only
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Register Flow: Send OTP
  Future<void> sendOTP(String phone, Function(String, int?) codeSent) async {
    _setLoading(true);
    try {
      await _authRepository.verifyPhone(phone, codeSent);
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // Register Flow: Verify OTP & Create User
  Future<bool> registerAndCreateUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    required String verificationId,
    required String smsCode,
  }) async {
    _setLoading(true);
    try {
      // 1. Verify OTP first (if using PhoneAuth credential linking or separate check)
      // Since we are creating a new email/pass user, we can't easily "link" phone cred if we haven't signed in.
      // Strategy: Sign in with Email/Password -> Link Phone Cred -> Save to Firestore.
      
      // Let's rely on AuthRepository.register which creates Auth User.
      // But we need to verify phone *before* or *during*.
      // If we verify phone linearly:
      // a. Verify OTP (using a dummy signInWithCredential if needed, or just trusting the code exchange if not strict)
      // Strict way: signInWithCredential(phoneCred) -> delete user? No.
      // We will assume `AuthRepository.verifyOTP` handles the verification check.
      
      final isVerified = await _authRepository.verifyOTP(verificationId, smsCode);
      if (!isVerified) throw "Invalid OTP";

      final user = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      
      _currentUser = user;
      _setLoading(false);
      return user != null;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }
  
  // Complete Profile (for Google Users)
  Future<void> completeProfile({
    required UserRole role,
    required String phone,
  }) async {
    _setLoading(true);
    try {
      final user = await _authRepository.completeProfile(
        role: role, 
        phone: phone,
        name: _authRepository.currentFirebaseUser?.displayName ?? "User",
        email: _authRepository.currentFirebaseUser?.email ?? "",
      );
      
      _currentUser = user;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> updateProfile(String name, String phone) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      await _authRepository.updateProfile(
        uid: _currentUser!.uid,
        name: name,
        phone: phone,
      );
      // Update local user model
      _currentUser = _currentUser!.copyWith(name: name, phone: phone);
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  Future<bool> _isAuthButNoDoc() async {
    return _authRepository.currentFirebaseUser != null;
  }

  // --- Password Reset Simulation ---
  String? _passwordResetOtp;

  Future<void> sendPasswordResetOtp(String email) async {
    _setLoading(true);
    try {
      // The Repo "throws" the OTP for simulation purposes
      await _authRepository.sendPasswordResetOtp(email);
    } catch (e) {
      if (e is String && e.length == 6) {
        _passwordResetOtp = e; // Caught the simulated OTP
        // In a real app, we wouldn't catch it here, the user would receive an email.
      } else {
        rethrow;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    // Verify against the stored OTP
    if (_passwordResetOtp == null) return false;
    return otp == _passwordResetOtp;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    _setLoading(true);
    try {
      await _authRepository.resetPassword(email, newPassword);
      _passwordResetOtp = null; // Clear OTP
    } finally {
      _setLoading(false);
    }
  }
}
