import 'package:carvia/core/models/test_drive_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TestDrivesPage extends StatefulWidget {
  const TestDrivesPage({super.key});

  @override
  State<TestDrivesPage> createState() => _TestDrivesPageState();
}

class _TestDrivesPageState extends State<TestDrivesPage> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("My Test Drives", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<TestDriveModel>>(
        stream: Provider.of<VehicleService>(context, listen: false).getUserTestDrivesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.calendar_remove, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text("No Test Drives Booked", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Book a test drive to experience your dream car.", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildBookingCard(TestDriveModel booking) {
    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'confirmed': statusColor = AppColors.success; break;
      case 'completed': statusColor = AppColors.primary; break;
      case 'cancelled': statusColor = AppColors.error; break;
      default: statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: booking.vehicleImage.isNotEmpty
              ? Image.network(booking.vehicleImage, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey, width: 70, height: 70))
              : Container(color: Colors.grey, width: 70, height: 70, child: const Icon(Icons.directions_car)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.vehicleName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Iconsax.calendar_1, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, y • h:mm a').format(booking.scheduledTime),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }
}
