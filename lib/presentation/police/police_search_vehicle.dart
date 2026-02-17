import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/police/police_issue_challan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vehicle Not Found")));
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Search Vehicle", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Enter Vehicle Number (e.g. KA01AB1234)",
                      prefixIcon: const Icon(Iconsax.search_normal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Iconsax.search_normal, color: Colors.white),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            if (_isLoading)
               Center(
                 child: Column(
                   children: [
                     const CircularProgressIndicator(),
                     const SizedBox(height: 16),
                     Text("Searching Database...", style: GoogleFonts.outfit(color: AppColors.textMuted)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  image: vehicle['images'] != null && (vehicle['images'] as List).isNotEmpty
                      ? DecorationImage(image: NetworkImage(vehicle['images'][0]), fit: BoxFit.cover)
                      : null,
                ),
                child: vehicle['images'] == null || (vehicle['images'] as List).isEmpty 
                    ? const Icon(Icons.directions_car, color: Colors.white, size: 40) 
                    : null,
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle['vehicleNumber'] ?? "Unknown", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("$ownerName", style: const TextStyle(fontSize: 16, color: AppColors.textMuted)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                   // Navigate to Issue Challan with pre-filled data
                   Navigator.push(context, MaterialPageRoute(builder: (_) => PoliceIssueChallan(prefilledVehicleNumber: vehicle['vehicleNumber'])));
                }, 
                icon: const Icon(Iconsax.receipt_add),
                label: const Text("Issue Challan"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              )
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Document Status", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              if (verification == null)
                TextButton(
                  onPressed: _verifyDocs,
                  child: const Text("Verify Documents"),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          if (verification != null) ...[
            _buildDocStatus("Registration (RC)", verification['rc_status']!, Iconsax.document),
            const SizedBox(height: 10),
            _buildDocStatus("Insurance", verification['insurance_status']!, Iconsax.security_safe),
            const SizedBox(height: 10),
            _buildDocStatus("Pollution Checks (PUC)", verification['puc_status']!, Iconsax.wind),
          ] else 
            const Text("Click 'Verify Documents' to check status.", style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildDocStatus(String title, String status, IconData icon) {
    final isInvalid = status == 'Expired' || status == 'Missing';
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isInvalid ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(status, style: TextStyle(color: isInvalid ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
