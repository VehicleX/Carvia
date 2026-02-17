import 'package:carvia/core/models/test_drive_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellerTestDrivesPage extends StatelessWidget {
  const SellerTestDrivesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) return const Center(child: Text("Please login"));

    return Scaffold(
      appBar: AppBar(
        title: Text("Test Drive Requests", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<TestDriveModel>>(
        future: Provider.of<VehicleService>(context, listen: false).fetchSellerTestDrives(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.calendar_remove, size: 60, color: AppColors.textMuted.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text("No pending test drives", style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildRequestCard(context, requests[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, TestDriveModel request) {
    final vehicleService = Provider.of<VehicleService>(context, listen: false);
    
    Color statusColor;
    switch (request.status) {
      case 'approved': statusColor = Colors.green; break;
      case 'rejected': statusColor = Colors.red; break;
      case 'completed': statusColor = Colors.blue; break;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(request.scheduledTime),
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(request.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(request.vehicleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Iconsax.user, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text("Buyer ID: ${request.userId.substring(0, 5)}...", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (request.status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, vehicleService, request, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text("Reject"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, vehicleService, request, 'approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Approve"),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, VehicleService service, TestDriveModel request, String status) async {
    try {
      await service.updateTestDriveStatus(request.id, status, request.userId, request.vehicleName);
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request $status")));
         // In a real app we'd refresh the list, but FutureBuilder re-builds if we call setState or if we used a specific Provider stream. 
         // For now simpler to just pop or let user check. Ideally wrap in StreamBuilder.
         // Or force rebuild:
         (context as Element).markNeedsBuild();
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
