import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/police/police_issue_challan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PoliceSearchVehicle extends StatefulWidget {
  const PoliceSearchVehicle({super.key});

  @override
  State<PoliceSearchVehicle> createState() => _PoliceSearchVehicleState();
}

class _PoliceSearchVehicleState extends State<PoliceSearchVehicle> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _vehicleData;
  bool _isLoading = false;
  Map<String, String>? _verificationStatus;

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _vehicleData = null;
      _verificationStatus = null;
    });

    final data = await Provider.of<ChallanService>(context, listen: false).searchVehicleDetails(_searchController.text.trim());

    setState(() {
      _isLoading = false;
      _vehicleData = data;
    });

    if (data == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vehicle Not Found")));
    }
  }

  Future<void> _verifyDocs() async {
    if (_vehicleData == null) return;
    setState(() => _isLoading = true);
    
    final status = await Provider.of<ChallanService>(context, listen: false).verifyDocuments(_vehicleData!['id']);
    
    setState(() {
      _isLoading = false;
      _verificationStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Search Vehicle", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Enter Vehicle Number (e.g. KA01AB1234)",
                      prefixIcon: Icon(Iconsax.search_normal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 2))
                      : Icon(Iconsax.search_normal, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            
            SizedBox(height: 30),
            
            if (_isLoading)
               Center(
                 child: Column(
                   children: [
                     CircularProgressIndicator(),
                     SizedBox(height: 16),
                     Text("Searching Database...", style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.secondary)),
                   ],
                 ),
               )
            else if (_vehicleData != null) 
              _buildVehicleCard(context).animate().fadeIn().slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context) {
    final vehicle = _vehicleData!['data'];
    final ownerName = _vehicleData!['ownerName'];
    final verification = _verificationStatus;

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  image: vehicle['images'] != null && (vehicle['images'] as List).isNotEmpty
                      ? DecorationImage(image: NetworkImage(vehicle['images'][0]), fit: BoxFit.cover)
                      : null,
                ),
                child: vehicle['images'] == null || (vehicle['images'] as List).isEmpty 
                    ? Icon(Icons.directions_car, color: Theme.of(context).colorScheme.onSurface, size: 40) 
                    : null,
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle['vehicleNumber'] ?? "Unknown", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("$ownerName", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                   // Navigate to Issue Challan with pre-filled data
                   Navigator.push(context, MaterialPageRoute(builder: (_) => PoliceIssueChallan(prefilledVehicleNumber: vehicle['vehicleNumber'])));
                }, 
                icon: Icon(Iconsax.receipt_add),
                label: Text("Issue Challan"),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.surface),
              )
            ],
          ),
          
          SizedBox(height: 24),
          Divider(),
          SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Document Status", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              if (verification == null)
                TextButton(
                  onPressed: _verifyDocs,
                  child: Text("Verify Documents"),
                ),
            ],
          ),
          
          SizedBox(height: 16),
          if (verification != null) ...[
            _buildDocStatus("Registration (RC)", verification['rc_status']!, Iconsax.document),
            SizedBox(height: 10),
            _buildDocStatus("Insurance", verification['insurance_status']!, Iconsax.security_safe),
            SizedBox(height: 10),
            _buildDocStatus("Pollution Checks (PUC)", verification['puc_status']!, Iconsax.wind),
          ] else 
            Text("Click 'Verify Documents' to check status.", style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildDocStatus(String title, String status, IconData icon) {
    final isInvalid = status == 'Expired' || status == 'Missing';
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
        SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(fontSize: 16))),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isInvalid ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status, style: TextStyle(color: isInvalid ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
