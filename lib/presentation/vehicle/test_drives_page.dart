import 'package:carvia/core/models/test_drive_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
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
  final Map<String, String> _locationCache = {};

  Future<String> _resolveLocation(TestDriveModel booking) async {
    if (booking.sellerLocation.trim().isNotEmpty) return booking.sellerLocation;
    if (_locationCache.containsKey(booking.vehicleId)) return _locationCache[booking.vehicleId]!;
    final vehicle = await Provider.of<VehicleService>(context, listen: false).getVehicleById(booking.vehicleId);
    final loc = vehicle?.location ?? '';
    _locationCache[booking.vehicleId] = loc;
    return loc;
  }

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
            return Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => SizedBox(height: 16),
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
          Icon(Iconsax.calendar_remove, size: 64, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
          SizedBox(height: 16),
          Text("No Test Drives Booked", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text("Book a test drive to experience your dream car.", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildBookingCard(TestDriveModel booking) {
    Color statusColor;
    switch (booking.status.toLowerCase()) {
      case 'confirmed': statusColor = Theme.of(context).colorScheme.onSurface; break;
      case 'completed': statusColor = Theme.of(context).colorScheme.onSurface; break;
      case 'cancelled': statusColor = Theme.of(context).colorScheme.onSurface; break;
      default: statusColor = Theme.of(context).colorScheme.onSurface;
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: booking.vehicleImage.isNotEmpty
              ? VehicleImage(src: booking.vehicleImage, width: 70, height: 70)
              : Container(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), width: 70, height: 70, child: Icon(Icons.directions_car)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.vehicleName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Iconsax.calendar_1, size: 14, color: Theme.of(context).colorScheme.secondary),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat('MMM d, y • h:mm a').format(booking.scheduledTime),
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                FutureBuilder<String>(
                  future: _resolveLocation(booking),
                  builder: (context, snap) {
                    final loc = snap.data ?? '';
                    if (loc.trim().isEmpty) return SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Iconsax.location, size: 14, color: Theme.of(context).colorScheme.secondary),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              loc,
                              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
