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
    if (user == null) return Center(child: Text("Please login"));

    return Scaffold(
      appBar: AppBar(
        title: Text("Test Drive Requests", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<TestDriveModel>>(
        stream: Provider.of<VehicleService>(context, listen: false).getSellerTestDrivesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.calendar_remove, size: 60, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)),
                  SizedBox(height: 16),
                  Text("No pending test drives", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.separated(
            padding: EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => SizedBox(height: 16),
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
      case 'approved': statusColor = Theme.of(context).colorScheme.onSurface; break;
      case 'rejected': statusColor = Theme.of(context).colorScheme.onSurface; break;
      case 'completed': statusColor = Theme.of(context).colorScheme.onSurface; break;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(request.scheduledTime),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(request.status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(request.vehicleName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Iconsax.user, size: 14, color: Theme.of(context).colorScheme.secondary),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Buyer: ${request.buyerName}",
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (request.buyerPhone.isNotEmpty) ...[
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Iconsax.call, size: 14, color: Theme.of(context).colorScheme.secondary),
                SizedBox(width: 4),
                Text(request.buyerPhone, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
              ],
            ),
          ],
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Iconsax.location, size: 14, color: Theme.of(context).colorScheme.secondary),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Location: ${request.meetingLocation.isNotEmpty ? request.meetingLocation : request.sellerLocation}",
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (request.status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(context, vehicleService, request, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    child: Text("Reject"),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(context, vehicleService, request, 'approved'),
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
                    child: Text("Approve"),
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
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
