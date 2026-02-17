import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class InsurancePage extends StatefulWidget {
  final String vehicleName;
  final String vehicleNumber;
  final bool isExternal;

  const InsurancePage({
    super.key, 
    required this.vehicleName, 
    required this.vehicleNumber,
    this.isExternal = false,
  });

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vehicle Insurance")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Iconsax.shield_tick, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.vehicleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(widget.vehicleNumber, style: const TextStyle(color: AppColors.textMuted)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(height: 30),
            
            if (widget.isExternal) ...[
               Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))
                ),
                child: const Column(
                  children: [
                    Icon(Iconsax.warning_2, color: Colors.orange, size: 40),
                    SizedBox(height: 10),
                    Text("No Active Policy Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("This vehicle was added manually and doesn't have a linked policy yet.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
               )
            ] else ...[
               const Text("Current Policy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
               const SizedBox(height: 16),
               _buildPolicyCard(
                "Carvia Protect Plan",
                "Valid until: Dec 31, 2026",
                "Active",
                Colors.green,
              ),
            ],
            
            const SizedBox(height: 30),
            const Text("Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
             _buildActionTile("Renew Policy", Iconsax.refresh, () {
               _showSuccessDialog("Renewal Initiated", "You will receive a quote on your email shortly.");
             }),
             _buildActionTile("Claim Insurance", Iconsax.document_text, () {
               _showSuccessDialog("Claim Request Sent", "Our agent will contact you within 24 hours.");
             }),
             _buildActionTile("Upload New Policy", Iconsax.document_upload, () {
               _showSuccessDialog("Document Uploaded", "Verification pending. Updates will be sent to your email.");
             }),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard(String plan, String validity, String status, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(plan, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 20),
          Text(validity, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
     showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
  }
}
