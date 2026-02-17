import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class AboutCreditsPage extends StatelessWidget {
  const AboutCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Canvas Credits", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.wallet_2, size: 60, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "What are Canvas Credits?",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Show Current Balance
            Consumer<AuthService>(builder: (context, auth, _) {
              final credits = auth.currentUser?.credits ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  children: [
                    Text("Your Balance", style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("$credits Credits", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 16),
            const Text(
              "Canvas Credits are our exclusive reward points that you can earn and redeem within the Carvia ecosystem.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 16),
            ),
            const SizedBox(height: 40),
            _buildFeatureItem(Iconsax.add_circle, "Earn Credits", "Get credits by buying cars, referring friends, or selling your vehicle through us."),
            _buildFeatureItem(Iconsax.shop, "Redeem for Discounts", "Use your credits to get discounts on service packages, accessories, or your next car purchase."),
            _buildFeatureItem(Iconsax.crown_1, "Premium Status", "Accumulate credits to unlock Premium Member status for exclusive benefits."),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
              ],
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
