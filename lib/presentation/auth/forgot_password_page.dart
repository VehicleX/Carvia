
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  
  int _step = 0; // 0: Email, 1: OTP, 2: New Password
  bool _isLoading = false;
  String? _simulatedOtpMessage;

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email")));
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.sendPasswordResetOtp(email);
      // If successful (no error thrown), it means OTP was generated and stored in service.
      // But passing it back via exception is ugly, let's just grab it from service or show generic message.
      // Actually, my AuthService implementation catches the thrown String.
      
      if (mounted) {
        setState(() {
          _step = 1;
          _simulatedOtpMessage = "OTP sent to $email"; 
          // HACK: In real app, user checks email. Here, we might need to show it?
          // The repository `debugPrint`ted it.
          // Let's assume the user is looking at console or we show it in a snackbar for demo.
        });
        
        // Show simulated OTP for convenience in this demo
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("OTP Sent! Check Debug Console (Simulated)"),
          duration: Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid 6-digit OTP")));
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false); // Fix: Use local var

    try {
      final isValid = await authService.verifyPasswordResetOtp(_emailController.text.trim(), otp);
      if (isValid) {
        setState(() => _step = 2);
      } else {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text.trim();
    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password must be at least 6 chars")));
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      await authService.resetPassword(_emailController.text.trim(), newPass);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password Reset Successful! Please Login.")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        title: Text("Reset Password", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step == 0 ? "Account Check" : (_step == 1 ? "Verify Identity" : "New Credentials"),
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ).animate().fadeIn().slideX(),
            const SizedBox(height: 8),
            Text(
              _step == 0 ? "Enter your email to receive an OTP." : (_step == 1 ? "Enter the 6-digit code sent to ${_emailController.text}" : "Create a new strong password."),
              style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            
            if (_step == 0) ...[
              _buildTextField("EMAIL", Icons.email_outlined, _emailController),
              const SizedBox(height: 24),
              _buildButton("Send OTP", _handleSendOtp),
            ] else if (_step == 1) ...[
              _buildTextField("OTP CODE", Icons.lock_clock_outlined, _otpController),
              const SizedBox(height: 24),
               _buildButton("Verify Code", _handleVerifyOtp),
            ] else ...[
               _buildTextField("NEW PASSWORD", Icons.lock_outline, _newPasswordController, isPassword: true),
              const SizedBox(height: 24),
              _buildButton("Reset Password", _handleResetPassword),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: isPassword ? "••••••" : "",
            fillColor: AppColors.surface,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(text),
      ),
    );
  }
}
