import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SellerAnalyticsPage extends StatelessWidget {
  const SellerAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      appBar: AppBar(
        title: Text("Analytics", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<VehicleModel>>(
        stream: Provider.of<VehicleService>(context, listen: false).getSellerVehiclesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final vehicles = snapshot.data ?? [];
          
          // Calculate Aggregated Stats
          int totalViews = vehicles.fold(0, (sum, v) => sum + v.viewsCount);
          int totalWishlists = vehicles.fold(0, (sum, v) => sum + v.wishlistCount);
          int activeListings = vehicles.where((v) => v.status == 'active').length;
          int soldVehicles = vehicles.where((v) => v.status == 'sold').length;
          
          // Improved Mock Revenue (since we don't store historical price fully in vehicles for sold items reliably in this mock)
          // We'll calculate based on 'sold' vehicles * their price
          double totalRevenue = vehicles.where((v) => v.status == 'sold').fold(0.0, (sum, v) => sum + v.price);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRevenueCard(context, totalRevenue),
                const SizedBox(height: 24),
                
                const Text("Engagement Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, "Total Views", "$totalViews", Iconsax.eye, Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, "Wishlists", "$totalWishlists", Iconsax.heart, Colors.pink)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildStatCard(context, "Active Listings", "$activeListings", Iconsax.car, Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, "Sold Vehicles", "$soldVehicles", Iconsax.tick_circle, Colors.green)),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text("Top Performing Vehicles", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTopVehiclesList(context, vehicles),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevenueCard(BuildContext context, double revenue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
           BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            "\$${revenue.toStringAsFixed(0)}", 
            style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
            child: const Text("+12% vs last month", style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildTopVehiclesList(BuildContext context, List<VehicleModel> vehicles) {
    // Sort by views
    final topVehicles = List<VehicleModel>.from(vehicles)..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final displayList = topVehicles.take(3).toList(); // Top 3

    if (displayList.isEmpty) return const Text("No data yet.", style: TextStyle(color: AppColors.textMuted));

    return Column(
      children: displayList.map((v) => _buildVehicleRow(context, v)).toList(),
    );
  }

  Widget _buildVehicleRow(BuildContext context, VehicleModel vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: vehicle.images.isNotEmpty
                ? Image.network(vehicle.images.first, width: 60, height: 40, fit: BoxFit.cover)
                : Container(width: 60, height: 40, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${vehicle.brand} ${vehicle.model}", style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("${vehicle.viewsCount} views", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
