import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _priceController = TextEditingController();
  final _mileageController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'Car';
  String _selectedFuel = 'Petrol';
  String _selectedTransmission = 'Automatic';
  
  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  bool _isSubmitLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Vehicle", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
             if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
             setState(() => _currentStep += 1);
          } else {
            _submitVehicle();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                    child: _isSubmitLoading 
                       ? const CircularProgressIndicator(color: Colors.white) 
                       : Text(_currentStep == 2 ? "Publish Vehicle" : "Next"),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text("Back"),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text("Details"),
            content: _buildDetailsStep(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text("Specs"),
            content: _buildSpecsStep(),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
          ),
          Step(
            title: const Text("Images"),
            content: _buildImagesStep(),
            isActive: _currentStep >= 2,
            state: _currentStep == 2 ? StepState.editing : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildDropdown("Vehicle Type", ["Car", "Bike", "Truck"], _selectedType, (val) => setState(() => _selectedType = val!)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(labelText: "Brand", prefixIcon: Icon(Iconsax.tag), border: OutlineInputBorder()),
            validator: (val) => val!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(labelText: "Model", prefixIcon: Icon(Iconsax.car), border: OutlineInputBorder()),
            validator: (val) => val!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Year", prefixIcon: Icon(Iconsax.calendar), border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price (\$)", prefixIcon: Icon(Iconsax.money), border: OutlineInputBorder()),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsStep() {
    return Column(
      children: [
        _buildDropdown("Fuel Type", ["Petrol", "Diesel", "Electric", "Hybrid"], _selectedFuel, (val) => setState(() => _selectedFuel = val!)),
        const SizedBox(height: 16),
        _buildDropdown("Transmission", ["Automatic", "Manual"], _selectedTransmission, (val) => setState(() => _selectedTransmission = val!)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mileageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Mileage (km)", prefixIcon: Icon(Iconsax.speedometer), border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: "Description", prefixIcon: Icon(Iconsax.note), border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _buildImagesStep() {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textMuted, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_upload, size: 40, color: AppColors.primary),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _uploadImageMock, 
                  child: const Text("Upload Images"),
                ),
                if (_isUploading)
                   const Padding(
                     padding: EdgeInsets.only(top: 8.0),
                     child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                   )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_uploadedImageUrls.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedImageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_uploadedImageUrls[index], width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _uploadedImageUrls.removeAt(index)),
                        child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> _uploadImageMock() async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    setState(() {
      _uploadedImageUrls.add("https://picsum.photos/seed/${DateTime.now().millisecondsSinceEpoch}/400/300"); // Mock Image
      _isUploading = false;
    });
  }

  Future<void> _submitVehicle() async {
    if (_uploadedImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please upload at least one image")));
      return;
    }
    
    setState(() => _isSubmitLoading = true);
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    
    if (user != null) {
      final vehicle = VehicleModel(
        id: "", // Auto-generated by service
        brand: _brandController.text,
        model: _modelController.text,
        year: int.parse(_yearController.text),
        fuel: _selectedFuel,
        transmission: _selectedTransmission,
        price: double.parse(_priceController.text),
        mileage: int.parse(_mileageController.text),
        images: _uploadedImageUrls,
        sellerId: user.uid,
        status: 'active',
        type: _selectedType,
        specs: {
          'description': _descriptionController.text,
        },
        viewsCount: 0,
        wishlistCount: 0,
        fullImages: _uploadedImageUrls.map((url) => {'url': url, 'type': 'main'}).toList(),
      );

      try {
        await Provider.of<VehicleService>(context, listen: false).addVehicle(vehicle);
        if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vehicle Published Successfully! 🚀")));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
    
    if (mounted) setState(() => _isSubmitLoading = false);
  }
}
