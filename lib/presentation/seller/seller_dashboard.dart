import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/presentation/seller/add_vehicle_page.dart' as import_seller;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SellerDashboard extends StatelessWidget {
  final Function(int)? onTabChange;
  const SellerDashboard({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final vehicleService = Provider.of<VehicleService>(context); // Listen to changes

    if (user == null) return const Center(child: Text("Loading profile..."));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome back, ${user.name}!", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold))
              .animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 5),
          const Text("Here's your dealership overview.", style: TextStyle(color: AppColors.textMuted))
              .animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          
          StreamBuilder<List<VehicleModel>>(
            stream: vehicleService.getSellerVehiclesStream(user.uid),
            builder: (context, snapshot) {
              // Calculate stats from real data
              int activeCount = 0;
              int soldCount = 0;
              int viewsCount = 0;
              
              if (snapshot.hasData) {
                final vehicles = snapshot.data!;
                activeCount = vehicles.where((v) => v.status == 'active').length;
                soldCount = vehicles.where((v) => v.status == 'sold').length;
                viewsCount = vehicles.fold(0, (sum, v) => sum + v.viewsCount);
              }

              final stats = [
                {'title': 'Active Listings', 'value': '$activeCount', 'icon': Iconsax.car, 'color': Colors.blue},
                {'title': 'Sold Vehicles', 'value': '$soldCount', 'icon': Iconsax.tick_circle, 'color': Colors.green},
                {'title': 'Total Views', 'value': '$viewsCount', 'icon': Iconsax.eye, 'color': Colors.orange},
                {'title': 'Total Earnings', 'value': '\$${soldCount * 25000} (Est)', 'icon': Iconsax.wallet_2, 'color': Colors.purple},
              ];

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1, // Taller cards to prevent overflow
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  return _buildStatCard(
                    context, 
                    stat,
                    onTap: () {
                      if (stat['title'] == 'Active Listings' || stat['title'] == 'Sold Vehicles') {
                         onTabChange?.call(1); // Navigate to Inventory
                      } else if (stat['title'] == 'Total Earnings') {
                         onTabChange?.call(4); // Navigate to Analytics
                      }
                    }
                  )
                      .animate().fadeIn(delay: (200 + (index * 100)).ms).slideY(begin: 0.2);
                },
              );
            }
          ),
          
          const SizedBox(height: 30),
          const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
              .animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 10),
          // Action Buttons instead of mock activity
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Switch to Add Vehicle Tab (Index 2)
                    onTabChange?.call(2);
                  },
                  icon: const Icon(Iconsax.add),
                  label: const Text("Add Vehicle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, Map<String, dynamic> stat, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
