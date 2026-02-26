import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class PoliceDashboard extends StatelessWidget {
  const PoliceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Officer Dashboard", 
                style: GoogleFonts.outfit(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ))
                .animate().fadeIn().slideX(begin: -0.2),
              SizedBox(height: 6),
              Text("Station ID: #KOR-99 • Officer Rank: Inspector", 
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14,
                ))
                .animate().fadeIn(delay: 200.ms),
              SizedBox(height: 28),
            
            FutureBuilder<Map<String, dynamic>>(
              future: Provider.of<ChallanService>(context, listen: false).fetchDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                final stats = snapshot.data ?? {'total_issued': 0, 'revenue': 0.0, 'pending': 0};
                
                return Row(
                  children: [
                    Expanded(child: _buildStatCard(context, "Challans Issued", "${stats['total_issued']}", Iconsax.receipt, Theme.of(context).colorScheme.onSurface, 0)),
                    SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, "Total Revenue", "\$${stats['revenue']}", Iconsax.money, Theme.of(context).colorScheme.onSurface, 1)),
                    SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, "Pending Payments", "${stats['pending']}", Iconsax.timer, Theme.of(context).colorScheme.onSurface, 2)),
                  ],
                );
              },
            ),
            
            SizedBox(height: 30),
            Text("Active Alerts", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold))
                .animate().fadeIn(delay: 600.ms),
            SizedBox(height: 16),
            _buildAlertCard(context, "Stolen Vehicle Detected", "KA-01-AB-1234 spotted near MG Road.", Theme.of(context).colorScheme.onSurface, 3),
            SizedBox(height: 10),
            _buildAlertCard(context, "High Speed Violation", "TN-99-ZZ-0000 caught at 120km/h on Highway.", Theme.of(context).colorScheme.onSurface, 4),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, int index) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 16),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ],
      ),
    ).animate().fadeIn(delay: (300 + (index * 100)).ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAlertCard(BuildContext context, String title, String body, Color color, int index) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, color: color)
              .animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: Offset(1, 1), end: Offset(1.2, 1.2)),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              Text(body, style: TextStyle(color: color.withValues(alpha:0.8))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (300 + (index * 100)).ms).slideX(begin: 0.2, end: 0);
  }
}
