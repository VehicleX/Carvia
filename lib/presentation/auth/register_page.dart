import 'package:carvia/core/models/user_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/auth/widgets/otp_verification_modal.dart';
import 'package:carvia/presentation/home/home_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  UserRole _selectedRole = UserRole.buyer;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           content: Text("Please fill name, email and password", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           backgroundColor: Colors.red.shade800,
           duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
           content: Text("Password must be at least 6 characters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
           backgroundColor: Colors.red.shade800,
           duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Check if email already exists
      final emailExists = await authService.checkEmailExists(email);
      if (emailExists) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("This email is already registered. Please login instead.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              duration: Duration(seconds: 4),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
        return; // Stop here - don't proceed to OTP
      }

      // Send OTP to email
      await authService.sendRegistrationOtp(email);
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showOtpModal(email);
      }
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         String errorMessage = "Error: $e";
         
         // OTP Fallback Handler Removed as per user request for "Real" only.
         
         if (e.toString().contains("billing-not-enabled")) {
           errorMessage = "Phone Auth requires billing enabled on Firebase Console.";
         } else if (e.toString().contains("app-not-authorized")) {
           errorMessage = "App not authorized. Check SHA-1/SHA-256 fingerprints in Firebase Console.";
         } else if (e.toString().contains("internal-error")) {
           errorMessage = "Internal Error. This often happens on Windows if google-services.json is missing or invalid.";
         }

         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
              content: Text(errorMessage, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.shade800,
              duration: Duration(seconds: 4),
           ),
         );
      }
    }
  }

  // Fallback dialog removed.

  void _showOtpModal(String email) {
    // Need these from state for the closure
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final authService = Provider.of<AuthService>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => OtpVerificationModal(
        email: email,
        onResend: () async {
          try {
            await authService.resendOtp(email);
            if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP resent to your email")));
            }
          } catch (e) {
            // Check for fallback in resend too
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
          }
        },
        onVerified: (otp) async {
          try {
            final success = await authService.verifyOtpAndRegister(
              email: email,
              otp: otp,
              password: password,
              name: name,
              phone: phone,
              role: _selectedRole,
            );
            
            if (success && context.mounted) {
              Navigator.pop(context); // Close OTP modal
              
              Widget homePage;
              switch (_selectedRole) {
                case UserRole.buyer: homePage = const UserHomePage(); break;
                case UserRole.seller: homePage = const SellerHomePage(); break;
                case UserRole.police: homePage = const PoliceHomePage(); break;
              }
              
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => homePage),
                (route) => false,
              );
            } else {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registration failed")));
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e"), backgroundColor: Theme.of(context).colorScheme.surface));
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Create Account", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Join Carvia",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
            
            SizedBox(height: 8),
            
            Text(
              "Start your digital vehicle journey",
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            SizedBox(height: 32),
            
            // Role Selection
            Text("I AM A:", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _buildRoleChip("Buyer", UserRole.buyer),
                   SizedBox(width: 12),
                   _buildRoleChip("Seller", UserRole.seller),
                   SizedBox(width: 12),
                   _buildRoleChip("Police", UserRole.police),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            _buildTextField("FULL NAME", Icons.person_outline, _nameController),
            SizedBox(height: 20),
            _buildTextField("EMAIL ADDRESS", Icons.email_outlined, _emailController),
            SizedBox(height: 20),
            _buildTextField("PHONE NUMBER (OPTIONAL)", Icons.phone_outlined, _phoneController, isPhone: true),
            SizedBox(height: 20),
            _buildTextField("PASSWORD", Icons.lock_outline_rounded, _passwordController, isPassword: true),
            
            SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading 
                    ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)
                    : Text("Send OTP & Register"),
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRoleChip(String label, UserRole role) {
    final isSelected = _selectedRole == role;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedRole = role);
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary),
            hintText: isPhone ? "+1 555 000 0000" : (isPassword ? "••••••••" : ""),
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
            filled: true,
            fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
