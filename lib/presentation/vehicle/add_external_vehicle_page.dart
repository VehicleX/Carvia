import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class AddExternalVehiclePage extends StatefulWidget {
  const AddExternalVehiclePage({super.key});

  @override
  State<AddExternalVehiclePage> createState() => _AddExternalVehiclePageState();
}

class _AddExternalVehiclePageState extends State<AddExternalVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  bool _isLoading = false;

  String _selectedType = 'Car';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add My Vehicle")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Add a vehicle you already own to manage challans, insurance, and service history.",
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
              SizedBox(height: 20),
              Text("Vehicle Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedType,
                decoration: const InputDecoration(labelText: "Vehicle Type", prefixIcon: Icon(Iconsax.category)),
                items: ['Car', 'Bike', 'Truck', 'Auto'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: "Brand", hintText: "e.g. Toyota, Honda", prefixIcon: Icon(Iconsax.verify)),
                validator: (val) => val!.isEmpty ? "Brand is required" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: "Model", prefixIcon: Icon(Iconsax.car)),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: "Year", prefixIcon: Icon(Iconsax.calendar)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(labelText: "License Plate (Reg No.)", prefixIcon: Icon(Iconsax.card)),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: EdgeInsets.all(16)),
                child: _isLoading ? CircularProgressIndicator() : Text("Add Vehicle"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final vehicleService = Provider.of<VehicleService>(context, listen: false);

    if (authService.currentUser == null) return;

    try {
      final newVehicle = VehicleModel(
        id: "", // Will be assigned by service/firestore
        brand: _brandController.text,
        model: _modelController.text,
        year: int.parse(_yearController.text),
        price: 0,
        images: [],
        sellerId: authService.currentUser!.uid,
        status: 'sold', 
        type: _selectedType, // Added type
        specs: {'licensePlate': _licensePlateController.text.trim().toUpperCase()},
        mileage: 0,
        fuel: "Petrol",
        transmission: "Manual",
        isExternal: true,
      );

      await vehicleService.addExternalVehicle(authService.currentUser!.uid, newVehicle);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vehicle Added Successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
