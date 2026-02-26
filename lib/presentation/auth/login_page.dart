import 'package:carvia/core/models/user_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/auth/complete_profile_page.dart';
import 'package:carvia/presentation/auth/register_page.dart';
import 'package:carvia/presentation/auth/forgot_password_page.dart';
import 'package:carvia/presentation/home/home_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      // Note: We ignore the selected UI role and rely on Firestore role
      bool success = await authService.login(
        _emailController.text.trim(), 
        _passwordController.text.trim(),
      );
      
      if (success && mounted) {
        _navigateToHome(authService.currentUser?.role ?? UserRole.buyer);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed. Check credentials.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final success = await authService.loginWithGoogle();
      if (success && mounted) {
        // User exists with complete profile, navigate to home
        _navigateToHome(authService.currentUser?.role ?? UserRole.buyer);
      } else if (!success && mounted) {
        // Login cancelled or failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-in cancelled or failed")),
        );
      }
    } catch (e) {
      if (e.toString() == "incomplete_profile") {
         if (mounted) {
            // User authenticated but needs to complete profile
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
            );
         }
      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Login Failed: ${e.toString()}")),
           );
         }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome(UserRole role) {
    Widget homePage;
    switch (role) {
      case UserRole.buyer:
        homePage = const UserHomePage();
        break;
      case UserRole.seller:
        homePage = const SellerHomePage();
        break;
      case UserRole.police:
        homePage = const PoliceHomePage();
        break;
    }
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => homePage),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withValues(alpha: 0.1),
                backgroundBlendMode: BlendMode.screen,
                boxShadow: [BoxShadow(blurRadius: 100, spreadRadius: 50, color: Colors.grey.withValues(alpha: 0.1))],
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // Logo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  
                  SizedBox(height: 24),
                  
                  // ... text ...
                  Text(
                    "Welcome Back",
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    "Sign in to manage your vehicle world",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  SizedBox(height: 32),
                  
                  // Form Card
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ... fields ...
                         Text(
                          "EMAIL ADDRESS",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.secondary),
                            hintText: "name@example.com",
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
                          ),
                        ),
                        // ... password ...
                        SizedBox(height: 24),
                        Text(
                          "PASSWORD",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).colorScheme.secondary),
                            hintText: "••••••••",
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
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading 
                                ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Login"),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat(period: 10.seconds)).shimmer(duration: 2.seconds, delay: 5.seconds),
                        
                        // ...
                        SizedBox(height: 16),
                        Center(
                            child: TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage()));
                            },
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.secondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  
                  SizedBox(height: 32),
                  
                  // OR Divider
                  // ...
                  SizedBox(height: 32),
                  
                  // Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _handleGoogleLogin,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        backgroundColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           // Placeholder for Google Logo
                          Icon(Icons.g_mobiledata, size: 28, color: Theme.of(context).colorScheme.onSurface),
                          SizedBox(width: 8),
                          Text("Continue with Google", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  
                  // ...
                  SizedBox(height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.secondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                        },
                         child: Text(
                          "Register now",
                          style: GoogleFonts.outfit(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
