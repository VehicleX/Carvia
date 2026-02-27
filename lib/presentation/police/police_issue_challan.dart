import 'package:carvia/core/models/challan_model.dart';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:flutter/material.dart';
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

  List<String> _allVehicleNumbers = [];
  bool _fetchingVehicles = false;

  @override
  void initState() {
    super.initState();
    _vehicleNumberController = TextEditingController(text: widget.prefilledVehicleNumber ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVehicles();
    });
  }

  Future<void> _fetchVehicles() async {
    setState(() => _fetchingVehicles = true);
    try {
      final vehicleService = Provider.of<VehicleService>(context, listen: false);
      // We'll use fetchVehicles to load them into the service's internal state
      // But there isn't a direct "getAllAvailable" method that returns a list easily without filtering.
      // So we'll query firestore directly here or use a helper if it exists.
      // Let's assume we want to show suggestions from what's in the system.
      
      // Fetch sold vehicles for the police suggestions
      await vehicleService.fetchSoldVehicles();
      if (mounted) {
        setState(() {
          _allVehicleNumbers = vehicleService.soldVehicles
              .map((v) => (v.specs['licensePlate'] ?? v.id).toString())
              .where((n) => n.isNotEmpty)
              .toSet()
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching vehicle suggestions: $e");
    } finally {
      if (mounted) setState(() => _fetchingVehicles = false);
    }
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

      final vehicleNumber = _vehicleNumberController.text.trim().toUpperCase().replaceAll(' ', '');
      final vehicleData = await challanService.searchVehicleDetails(vehicleNumber);
      
      // If vehicle found, use its IDs; otherwise use empty strings (manual entry)
      final vehicleId = vehicleData != null ? vehicleData['id'] : "";
      final ownerId = (vehicleData != null && vehicleData['data'] != null) ? (vehicleData['data']['ownerId'] ?? "") : "";

      final challan = ChallanModel(
        id: "", // Auto
        vehicleId: vehicleId,
        vehicleNumber: vehicleNumber,
        ownerId: ownerId,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Challan Issued Successfully! 🚨"),
            backgroundColor: Colors.green,
          ),
        );
        // Only pop if we were pushed as a route, not if we are a tab
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // Reset form if in-tab
          _formKey.currentState?.reset();
          _vehicleNumberController.clear();
        }
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
      appBar: AppBar(title: Text("Issue E-Challan")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvailableVehiclesSection(),
              const SizedBox(height: 32),
              Text("Challan Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) => Autocomplete<String>(
                  key: ValueKey(_vehicleNumberController.text),
                  initialValue: TextEditingValue(text: _vehicleNumberController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<String>.empty();
                    }
                    return _allVehicleNumbers.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _vehicleNumberController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Pre-fill the controller if it's empty and we have a pre-filled value
                    if (controller.text.isEmpty && _vehicleNumberController.text.isNotEmpty) {
                      controller.text = _vehicleNumberController.text;
                    }
                    
                    // Sync internal state whenever the field changes
                    controller.addListener(() {
                      if (_vehicleNumberController.text != controller.text) {
                        _vehicleNumberController.text = controller.text;
                      }
                    });

                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: "Vehicle Number",
                        hintText: "Enter or select vehicle",
                        prefixIcon: const Icon(Iconsax.car),
                        suffixIcon: _fetchingVehicles 
                          ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                          : IconButton(icon: const Icon(Icons.clear), onPressed: () => controller.clear()),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? "Required" : null,
                      onFieldSubmitted: (value) => onFieldSubmitted(),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        child: Container(
                          width: constraints.maxWidth,
                          color: Theme.of(context).cardColor,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedViolation,
                decoration: const InputDecoration(
                  labelText: "Violation Type",
                  prefixIcon: Icon(Iconsax.warning_2),
                  border: OutlineInputBorder(),
                ),
                items: _violations.keys.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: _onViolationChanged,
              ),
              
              SizedBox(height: 20),
              
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Calculated Fine", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("\$${_fineAmount.toStringAsFixed(0)}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              Text("Evidence Upload", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Theme.of(context).colorScheme.secondary),
                      Text("Tap to capture/upload image", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _issueChallan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading ? CircularProgressIndicator(color: Theme.of(context).colorScheme.primary) : Text("ISSUE CHALLAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableVehiclesSection() {
    final vehicleService = Provider.of<VehicleService>(context);
    final vehicles = vehicleService.soldVehicles;

    if (_fetchingVehicles && vehicles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vehicles.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Select Sold Vehicle", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            TextButton(onPressed: _fetchVehicles, child: const Text("Refresh")),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final v = vehicles[index];
              final plate = (v.specs['licensePlate']?.toString().isNotEmpty == true) 
                  ? v.specs['licensePlate'].toString().toUpperCase() 
                  : "${v.brand} ${v.model}".toUpperCase();
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _vehicleNumberController.text = plate;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Selected: $plate"), duration: const Duration(seconds: 1)),
                  );
                },
                child: Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _vehicleNumberController.text == plate 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: v.images.isNotEmpty 
                            ? Image.network(v.images[0], fit: BoxFit.cover, width: double.infinity)
                            : Container(color: Colors.grey.shade200, child: const Icon(Iconsax.car)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                plate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 10,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${v.brand} ${v.model}",
                              style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.secondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
