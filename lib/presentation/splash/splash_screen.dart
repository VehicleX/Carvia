
import 'package:carvia/core/models/user_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/home/home_pages.dart';
import 'package:carvia/presentation/landing/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after a delay
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        final authService = Provider.of<AuthService>(context, listen: false);
        
        // Check if user is logged in
        Widget nextScreen = const LandingPage();
        
        if (authService.isAuthenticated && authService.currentUser != null) {
          switch (authService.currentUser!.role) {
            case UserRole.buyer:
              nextScreen = const UserHomePage();
              break;
            case UserRole.seller:
              nextScreen = const SellerHomePage();
              break;
            case UserRole.police:
              nextScreen = const PoliceHomePage();
              break;
          }
        }
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Radial Glow Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2), // Slightly above center
                  radius: 0.8,
                  colors: [
                    Color(0xFF1E293B), // Lighter slate
                    AppColors.background, // Deep slate
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lightning Logo with Glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .moveY(begin: 0, end: -10, duration: 2.seconds, curve: Curves.easeInOut)
                    .then()
                    .moveY(begin: -10, end: 0, duration: 2.seconds, curve: Curves.easeInOut),

                const SizedBox(height: 40),
                // ...
                const SizedBox(height: 60),

                // Loader
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),

          // Version Text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "v1.0.1",
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ).animate().fadeIn(delay: 1.5.seconds),
            ),
          ),
        ],
      ),
    );
  }
}
