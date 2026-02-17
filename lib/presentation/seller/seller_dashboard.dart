import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    
    // Mock Stats - In production, fetch via SellerService
    final stats = [
      {'title': 'Active Listings', 'value': '12', 'icon': Iconsax.car, 'color': Colors.blue},
      {'title': 'Sold Vehicles', 'value': '5', 'icon': Iconsax.tick_circle, 'color': Colors.green},
      {'title': 'Pending Requests', 'value': '3', 'icon': Iconsax.timer, 'color': Colors.orange},
      {'title': 'Total Earnings', 'value': '\$45K', 'icon': Iconsax.wallet_2, 'color': Colors.purple},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome back, ${user?.name ?? 'Seller'}!", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold))
              .animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 5),
          const Text("Here's your dealership overview.", style: TextStyle(color: AppColors.textMuted))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return _buildStatCard(context, stat)
                  .animate().fadeIn(delay: (200 + (index * 100)).ms).slideY(begin: 0.2);
            },
          ),
          
          const SizedBox(height: 30),
          const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              .animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 10),
          _buildActivityItem(context, "Test Drive Request", "John Doe requested a test drive for BMW X5", "2 mins ago")
              .animate().fadeIn(delay: 700.ms).slideX(begin: 0.2),
          _buildActivityItem(context, "Vehicle Sold", "Toyota Camry marked as sold", "2 hours ago")
              .animate().fadeIn(delay: 800.ms).slideX(begin: 0.2),
          _buildActivityItem(context, "New Listing", "Added Tesla Model 3 to inventory", "1 day ago")
              .animate().fadeIn(delay: 900.ms).slideX(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, Map<String, dynamic> stat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (stat['color'] as Color).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: (stat['color'] as Color).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(stat['icon'], color: stat['color'], size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stat['value'], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: stat['color'])),
              Text(stat['title'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String title, String subtitle, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Iconsax.notification, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
