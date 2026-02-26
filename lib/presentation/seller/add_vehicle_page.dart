import 'dart:typed_data';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddVehiclePage extends StatefulWidget {
  final VehicleModel? vehicle;

  const AddVehiclePage({super.key, this.vehicle});

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
  final _locationController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _engineCcController = TextEditingController();

  String _selectedType = 'Car';
  String _selectedFuel = 'Petrol';
  String _selectedTransmission = 'Automatic';
  String _selectedColor = 'White';

  // Images: keeps both File (for new picks) and URL (already uploaded / existing)
  final List<String> _uploadedImageUrls = [];   // existing URLs (edit mode / uploaded)
  final List<XFile> _pendingFiles = [];           // newly picked, not yet uploaded
  final List<Uint8List> _pendingBytesCache = [];  // bytes for web-safe preview
  bool _isUploading = false;
  bool _isSubmitLoading = false;

  bool get _isEditMode => widget.vehicle != null;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    if (vehicle != null) {
      _brandController.text = vehicle.brand;
      _modelController.text = vehicle.model;
      _yearController.text = vehicle.year.toString();
      _priceController.text = vehicle.price.toStringAsFixed(0);
      _mileageController.text = vehicle.mileage.toString();
      _descriptionController.text = vehicle.specs['description']?.toString() ?? '';
      _locationController.text = vehicle.location;
      _licensePlateController.text = vehicle.specs['licensePlate']?.toString() ?? '';
      _engineCcController.text = vehicle.specs['engineCc']?.toString() ?? '';
      _selectedType = vehicle.type;
      _selectedFuel = vehicle.fuel;
      _selectedTransmission = vehicle.transmission;
      _selectedColor = vehicle.specs['color']?.toString() ?? 'White';
      _uploadedImageUrls.addAll(vehicle.images);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = Provider.of<AuthService>(context, listen: false).currentUser;
        if (user != null && _locationController.text.isEmpty) {
          final businessAddress = user.sellerDetails['businessAddress']?.toString().trim();
          final city = user.address['city']?.toString().trim();
          final street = user.address['street']?.toString().trim();
          final state = user.address['state']?.toString().trim();
          _locationController.text =
              (businessAddress?.isNotEmpty == true ? businessAddress! : null) ??
              (city?.isNotEmpty == true ? city! : null) ??
              (street?.isNotEmpty == true ? street! : null) ??
              (state?.isNotEmpty == true ? state! : null) ??
              '';
        }
      });
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    _mileageController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _licensePlateController.dispose();
    _engineCcController.dispose();
    super.dispose();
  }

  // ── Image Picker ──────────────────────────────────────────────────────────

  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 80);
        if (picked.isNotEmpty) {
          final List<Uint8List> bytesList = await Future.wait(picked.map((x) => x.readAsBytes()));
          setState(() {
            _pendingFiles.addAll(picked);
            _pendingBytesCache.addAll(bytesList);
          });
        }
      } else {
        final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _pendingFiles.add(picked);
            _pendingBytesCache.add(bytes);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error picking image: $e")));
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Add Photos",
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 6),
              Text("Choose how to add vehicle photos",
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13)),
              SizedBox(height: 20),
              _ImageSourceTile(
                icon: Iconsax.camera,
                label: "Take Photo",
                subtitle: "Use your camera to capture",
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
              SizedBox(height: 12),
              _ImageSourceTile(
                icon: Iconsax.gallery,
                label: "Choose from Gallery",
                subtitle: "Select multiple photos at once",
                color: Theme.of(context).colorScheme.onSurface,
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Base64 Conversion (stored directly in Firestore) ─────────────────────

  Future<List<String>> _uploadPendingFiles() async {
    const cloudName = 'dxo7rced3';
    const uploadPreset = 'Carvia';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final urls = <String>[];

    for (int i = 0; i < _pendingFiles.length; i++) {
      final bytes = i < _pendingBytesCache.length
          ? _pendingBytesCache[i]
          : await _pendingFiles[i].readAsBytes();

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'vehicle_$i.jpg'));

      final response = await request.send();
      final body = jsonDecode(await response.stream.bytesToString());

      if (response.statusCode == 200) {
        urls.add(body['secure_url'] as String);
        debugPrint('Image ${i + 1} uploaded to Cloudinary: ${body['secure_url']}');
      } else {
        throw Exception('Cloudinary upload failed: ${body['error']?['message'] ?? response.statusCode}');
      }
    }

    return urls;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Vehicle" : "Add New Vehicle",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: Theme.of(context).colorScheme.primary),
        ),
        child: Stepper(
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
              padding: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary, strokeWidth: 2))
                          : Text(
                              _currentStep == 2
                                  ? (_isEditMode ? "Update Vehicle" : "Publish Vehicle")
                                  : "Continue →",
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text("Back"),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: Text("Details"),
              content: _buildDetailsStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.editing,
            ),
            Step(
              title: Text("Specs"),
              content: _buildSpecsStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.editing,
            ),
            Step(
              title: Text("Photos"),
              content: _buildImagesStep(),
              isActive: _currentStep >= 2,
              state: _currentStep == 2 ? StepState.editing : StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Details ───────────────────────────────────────────────────────

  Widget _buildDetailsStep() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _sectionLabel("Vehicle Type"),
          SizedBox(height: 8),
          _ChipSelector(
            options: ["Car", "Bike", "Truck", "SUV", "Van"],
            selected: _selectedType,
            onChanged: (v) => setState(() => _selectedType = v),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _field(_brandController, "Brand", Iconsax.tag)),
              SizedBox(width: 12),
              Expanded(child: _field(_modelController, "Model", Iconsax.car)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: _dec("Year", Iconsax.calendar),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _dec("Price (₹)", Iconsax.money),
                  validator: (val) => val!.isEmpty ? "Required" : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _field(_locationController, "Location (shown to buyers for test drives)", Iconsax.location),
          SizedBox(height: 16),
          _field(_licensePlateController, "License Plate (optional)", Iconsax.receipt,
              required: false),
        ],
      ),
    );
  }

  // ── Step 2: Specs ─────────────────────────────────────────────────────────

  Widget _buildSpecsStep() {
    // Determine if the selected type is a bike
    final isBike = _selectedType.toLowerCase() == 'bike';
    
    // Fuel options based on vehicle type
    final fuelOptions = isBike 
        ? ["Petrol", "Electric"] 
        : ["Petrol", "Diesel", "Electric", "Hybrid"];
    
    // Ensure selected fuel is valid for current type
    if (!fuelOptions.contains(_selectedFuel)) {
      _selectedFuel = fuelOptions.first;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Engine CC (only for bikes)
        if (isBike) ...[
          _sectionLabel("Engine Capacity"),
          SizedBox(height: 8),
          TextFormField(
            controller: _engineCcController,
            keyboardType: TextInputType.number,
            decoration: _dec("Engine (cc)", Iconsax.cpu),
            validator: (val) => val!.isEmpty ? "Required" : null,
          ),
          SizedBox(height: 16),
        ],
        
        _sectionLabel("Fuel Type"),
        SizedBox(height: 8),
        _ChipSelector(
          options: fuelOptions,
          selected: _selectedFuel,
          onChanged: (v) => setState(() => _selectedFuel = v),
        ),
        SizedBox(height: 16),
        
        // Transmission (only for cars)
        if (!isBike) ...[
          _sectionLabel("Transmission"),
          SizedBox(height: 8),
          _ChipSelector(
            options: ["Automatic", "Manual"],
            selected: _selectedTransmission,
            onChanged: (v) => setState(() => _selectedTransmission = v),
          ),
          SizedBox(height: 16),
        ],
        
        TextFormField(
          controller: _mileageController,
          keyboardType: TextInputType.number,
          decoration: _dec("Mileage (km)", Iconsax.speedometer),
          validator: (val) => val!.isEmpty ? "Required" : null,
        ),
        SizedBox(height: 16),
        
        _sectionLabel("Color"),
        SizedBox(height: 8),
        _ChipSelector(
          options: ["White", "Black", "Silver", "Red", "Blue", "Grey", "Brown", "Other"],
          selected: _selectedColor,
          onChanged: (v) => setState(() => _selectedColor = v),
        ),
        SizedBox(height: 16),
        
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: _dec("Description", Iconsax.note),
        ),
      ],
    );
  }

  // ── Step 3: Images ────────────────────────────────────────────────────────

  Widget _buildImagesStep() {
    final totalImages = _uploadedImageUrls.length + _pendingFiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload area
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Iconsax.gallery_add, size: 32, color: Theme.of(context).colorScheme.primary),
                ),
                SizedBox(height: 12),
                Text("Add Vehicle Photos",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface)),
                SizedBox(height: 4),
                Text(
                  "Tap to use Camera or Gallery\nMultiple photos supported",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),

        if (totalImages > 0) ...[
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$totalImages photo${totalImages == 1 ? '' : 's'} selected",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              TextButton.icon(
                onPressed: _showImageSourceDialog,
                icon: Icon(Iconsax.add, size: 14),
                label: Text("Add More"),
              ),
            ],
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Already uploaded URLs
                ..._uploadedImageUrls.asMap().entries.map((e) => _imageThumb(
                      onRemove: () => setState(() => _uploadedImageUrls.removeAt(e.key)),
                      child: VehicleImage(src: e.value, width: 110, height: 110),
                    )),
                // Pending local files
                ..._pendingFiles.asMap().entries.map((e) => _imageThumb(
                      isNew: true,
                      onRemove: () => setState(() {
                        _pendingFiles.removeAt(e.key);
                        if (e.key < _pendingBytesCache.length) _pendingBytesCache.removeAt(e.key);
                      }),
                      child: e.key < _pendingBytesCache.length
                          ? Image.memory(_pendingBytesCache[e.key],
                              width: 110, height: 110, fit: BoxFit.cover)
                          : Container(width: 110, height: 110, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05)),
                    )),
              ],
            ),
          ),
        ],

        if (_isUploading) ...[
          SizedBox(height: 16),
          Row(

            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text("Uploading photos...",
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13)),
            ],
          ),
        ],

        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Iconsax.info_circle, size: 14, color: Theme.of(context).colorScheme.onSurface),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "First photo will be shown as the cover. Photos are uploaded to Firebase Storage.",
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageThumb({
    required Widget child,
    required VoidCallback onRemove,
    bool isNew = false,
  }) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(width: 110, height: 110, child: child),
          ),
          if (isNew)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("NEW",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(Icons.close, size: 13, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitVehicle() async {
    final totalImages = _uploadedImageUrls.length + _pendingFiles.length;
    if (totalImages == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please add at least one photo")));
      return;
    }

    setState(() {
      _isSubmitLoading = true;
      _isUploading = _pendingFiles.isNotEmpty;
    });

    // Cache context-dependent services BEFORE any awaits
    final authService = Provider.of<AuthService>(context, listen: false);
    final vehicleService = Provider.of<VehicleService>(context, listen: false);

    try {
      // Upload pending files first
      final newUrls = await _uploadPendingFiles();
      final allUrls = [..._uploadedImageUrls, ...newUrls];

      if (!mounted) return;
      setState(() => _isUploading = false);

      final user = authService.currentUser;
      if (user == null) return;


      final vehicle = VehicleModel(
        id: widget.vehicle?.id ?? "",
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text) ?? DateTime.now().year,
        fuel: _selectedFuel,
        transmission: _selectedType.toLowerCase() == 'bike' ? 'Manual' : _selectedTransmission,
        price: double.tryParse(_priceController.text) ?? 0,
        mileage: int.tryParse(_mileageController.text) ?? 0,
        images: allUrls,
        sellerId: user.uid,
        status: 'active',
        type: _selectedType,
        location: _locationController.text.trim(),
        specs: {
          'description': _descriptionController.text.trim(),
          'color': _selectedColor,
          'licensePlate': _licensePlateController.text.trim(),
          'sellerName': user.name,
          'sellerPhone': user.phone,
          'sellerEmail': user.email,
          if (_selectedType.toLowerCase() == 'bike' && _engineCcController.text.isNotEmpty)
            'engineCc': int.tryParse(_engineCcController.text) ?? 0,
        },
        viewsCount: widget.vehicle?.viewsCount ?? 0,
        wishlistCount: widget.vehicle?.wishlistCount ?? 0,
        fullImages: allUrls.map((url) => {'url': url, 'type': 'main'}).toList(),
      );

      if (_isEditMode) {
        await vehicleService.updateVehicle(vehicle);
      } else {
        await vehicleService.addVehicle(vehicle);
      }


      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              _isEditMode ? "🚀 Vehicle updated!" : "🚗 Vehicle published!"),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitLoading = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool required = true}) {
    return TextFormField(
      controller: c,
      decoration: _dec(label, icon),
      validator: required ? (v) => (v ?? '').isEmpty ? "Required" : null : null,
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      );

  Widget _sectionLabel(String text) => Text(text,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14));
}

// ── Chip Selector ─────────────────────────────────────────────────────────────
class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _ChipSelector(
      {required this.options, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options
          .map((o) => GestureDetector(
                onTap: () => onChanged(o),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: o == selected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: o == selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(o,
                      style: TextStyle(
                          color: o == selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                          fontWeight: o == selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 13)),
                ),
              ))
          .toList(),
    );
  }
}

// ── Image Source Tile ─────────────────────────────────────────────────────────
class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ImageSourceTile(
      {required this.icon,
      required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:  TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
