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
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.wallet_2, size: 60, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "What are Canvas Credits?",
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            
            // Show Current Balance
            Consumer<AuthService>(builder: (context, auth, _) {
              final credits = auth.currentUser?.credits ?? 0;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    Text("Your Balance", style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("$credits Credits", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              );
            }),
            
            SizedBox(height: 16),
            Text(
              "Canvas Credits are our exclusive reward points that you can earn and redeem within the Carvia ecosystem.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary, height: 1.5, fontSize: 16),
            ),
            SizedBox(height: 40),
            _buildFeatureItem(context, Iconsax.add_circle, "Earn Credits", "Get credits by buying cars, referring friends, or selling your vehicle through us."),
            _buildFeatureItem(context, Iconsax.shop, "Redeem for Discounts", "Use your credits to get discounts on service packages, accessories, or your next car purchase."),
            _buildFeatureItem(context, Iconsax.crown_1, "Premium Status", "Accumulate credits to unlock Premium Member status for exclusive benefits."),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05), blurRadius: 5),
              ],
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text(description, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
