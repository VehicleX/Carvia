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
      appBar: AppBar(title: Text("Transfer Ownership")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Iconsax.refresh, size: 80, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 20),
            Text(
              "Transfer ${widget.vehicleName} (${widget.vehicleNumber})",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              "Enter the email address of the new owner. They will receive a request to accept the transfer.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "New Owner's Email",
                prefixIcon: Icon(Iconsax.sms),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isLoading ? null : _initiateTransfer,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.surface,
              ),
              child: _isLoading 
                ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary) 
                : Text("Initiate Transfer", style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateTransfer() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid email")));
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
        title: Text("Request Sent"),
        content: Text("Ownership transfer request for ${widget.vehicleName} sent to ${_emailController.text}."),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(context); // Dialog
               Navigator.pop(context); // Page
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}
