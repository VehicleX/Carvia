import 'package:carvia/core/models/user_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:flutter/foundation.dart';

class MockAuthService extends ChangeNotifier implements AuthService {
  UserModel? _currentUser;
  bool _isLoading = false;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  bool get isLoading => _isLoading;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    
    // Simulate successful login
    _currentUser = _createMockUser(email: email);
    _setLoading(false);
    return true;
  }

  @override
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = _createMockUser(email: "google_user@example.com", name: "Google User");
    _setLoading(false);
    return true;
  }

  @override
  Future<void> sendOTP(String phone, Function(String, int?) codeSent) async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    codeSent("mock_verification_id", 123);
    _setLoading(false);
  }

  @override
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
    await Future.delayed(const Duration(seconds: 1));

    if (smsCode != "123456") {
       _setLoading(false);
       throw "Invalid OTP (Use 123456)";
    }

    _currentUser = _createMockUser(
      email: email,
      name: name,
      phone: phone,
      role: role,
    );
    _setLoading(false);
    return true;
  }

  @override
  Future<void> completeProfile({required UserRole role, required String phone}) async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    
    // Update user with new details
    // We can't use copyWith effectively if it's not on the model, but we can recreate.
    // Assuming UserModel.fromMap or just creating new instance.
    // For now, just simplistic update:
    _currentUser = UserModel(
      uid: _currentUser!.uid,
      name: _currentUser!.name,
      email: _currentUser!.email,
      phone: phone,
      role: role,
      createdAt: _currentUser!.createdAt,
      updatedAt: DateTime.now(),
      isVerified: true,
    );
    _setLoading(false);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  UserModel _createMockUser({
    String email = "test@example.com",
    String name = "Test User",
    String phone = "+1234567890",
    UserRole role = UserRole.buyer,
  }) {
    return UserModel(
      uid: "mock_user_123",
      name: name,
      email: email,
      phone: phone,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isVerified: true,
      isActive: true,
    );
  }
}
