import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TransferOwnershipPage extends StatefulWidget {
   final String vehicleName;
  final String vehicleNumber;
  
  const TransferOwnershipPage({super.key, required this.vehicleName, required this.vehicleNumber});

  @override
  State<TransferOwnershipPage> createState() => _TransferOwnershipPageState();
}

class _TransferOwnershipPageState extends State<TransferOwnershipPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transfer Ownership")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Iconsax.refresh, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              "Transfer ${widget.vehicleName} (${widget.vehicleNumber})",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter the email address of the new owner. They will receive a request to accept the transfer.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "New Owner's Email",
                prefixIcon: Icon(Iconsax.sms),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _initiateTransfer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("Initiate Transfer", style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateTransfer() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid email")));
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Sent"),
        content: Text("Ownership transfer request for ${widget.vehicleName} sent to ${_emailController.text}."),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(context); // Dialog
               Navigator.pop(context); // Page
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
