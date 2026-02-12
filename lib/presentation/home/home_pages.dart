
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/presentation/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:google_fonts/google_fonts.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildHomeScaffold(context, "User Home", Icons.person_outline);
  }
}

class SellerHomePage extends StatelessWidget {
  const SellerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildHomeScaffold(context, "Seller Dashboard", Icons.storefront_outlined);
  }
}

class PoliceHomePage extends StatelessWidget {
  const PoliceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildHomeScaffold(context, "Police Portal", Icons.local_police_outlined);
  }
}

Widget _buildHomeScaffold(BuildContext context, String title, IconData icon) {
  final authService = Provider.of<AuthService>(context, listen: false);
  
  return Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            authService.logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        ),
      ],
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            "Welcome to $title",
            style: GoogleFonts.outfit(
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This is a placeholder for the verified home screen.",
            style: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
