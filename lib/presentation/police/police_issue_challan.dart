import 'package:carvia/core/models/challan_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class PoliceIssueChallan extends StatefulWidget {
  final String? prefilledVehicleNumber;
  const PoliceIssueChallan({super.key, this.prefilledVehicleNumber});

  @override
  State<PoliceIssueChallan> createState() => _PoliceIssueChallanState();
}

class _PoliceIssueChallanState extends State<PoliceIssueChallan> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vehicleNumberController;
  
  String _selectedViolation = 'No Helmet';
  double _fineAmount = 500;
  bool _isLoading = false;
  
  final Map<String, double> _violations = {
    'No Helmet': 500,
    'Over Speeding': 2000,
    'No Seatbelt': 1000,
    'Signal Jump': 1500,
    'Drunk Driving': 10000,
    'Expired Insurance': 2000,
  };

  @override
  void initState() {
    super.initState();
    _vehicleNumberController = TextEditingController(text: widget.prefilledVehicleNumber ?? '');
  }

  void _onViolationChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedViolation = newValue;
        _fineAmount = _violations[newValue]!;
      });
    }
  }

  Future<void> _issueChallan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser!;
      final challanService = Provider.of<ChallanService>(context, listen: false);

      // Search vehicle to get ID and Owner ID
      final vehicleData = await challanService.searchVehicleDetails(_vehicleNumberController.text.trim());
      
      if (vehicleData == null) {
        throw "Vehicle not found in database. Please register manual entry (Not Implemented).";
      }

      final challan = ChallanModel(
        id: "", // Auto
        vehicleId: vehicleData['id'],
        vehicleNumber: _vehicleNumberController.text.trim(),
        ownerId: vehicleData['data']['ownerId'] ?? '',
        violationType: _selectedViolation,
        fineAmount: _fineAmount,
        issuedBy: user.uid,
        issuedAt: DateTime.now(),
        status: ChallanStatus.unpaid,
        paymentDueDate: DateTime.now().add(const Duration(days: 15)),
        evidenceImageUrl: "https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/300", // Mock
      );
      
      await challanService.issueChallan(challan);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Challan Issued Successfully! 🚨")));
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Issue E-Challan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _vehicleNumberController,
                decoration: const InputDecoration(
                  labelText: "Vehicle Number",
                  prefixIcon: Icon(Iconsax.car),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _selectedViolation,
                decoration: const InputDecoration(
                  labelText: "Violation Type",
                  prefixIcon: Icon(Iconsax.warning_2),
                  border: OutlineInputBorder(),
                ),
                items: _violations.keys.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: _onViolationChanged,
              ),
              
              const SizedBox(height: 20),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Calculated Fine", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("\$${_fineAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              const Text("Evidence Upload", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                      Text("Tap to capture/upload image", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _issueChallan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("ISSUE CHALLAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
