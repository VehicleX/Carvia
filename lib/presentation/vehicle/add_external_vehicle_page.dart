import 'dart:typed_data';
import 'package:carvia/core/models/vehicle_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/widgets/vehicle_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
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
  
  // Image handling
  final _picker = ImagePicker();
  final List<String> _uploadedImageUrls = [];
  final List<XFile> _pendingFiles = [];
  final List<Uint8List> _pendingBytesCache = [];
  bool _isUploading = false;

  // ── Image Picker Methods ──────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    final photoStatus = await Permission.photos.request();
    final cameraStatus = await Permission.camera.request();
    
    if (photoStatus.isDenied || cameraStatus.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Photo permissions are required to add vehicle images"),
            action: SnackBarAction(
              label: "Settings",
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      // Request permissions first
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Camera permission is required")),
            );
          }
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Photo library permission is required")),
            );
          }
          return;
        }
      }

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error picking image: $e")),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Add Photos",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 6),
              Text("Choose how to add vehicle photos",
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Iconsax.camera, color: Theme.of(context).colorScheme.primary),
                title: Text("Take Photo"),
                subtitle: Text("Use your camera to capture"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Iconsax.gallery, color: Theme.of(context).colorScheme.primary),
                title: Text("Choose from Gallery"),
                subtitle: Text("Select multiple photos at once"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>> _uploadPendingFiles() async {
    const cloudName = 'dxo7rced3';
    const uploadPreset = 'Carvia';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final urls = <String>[];

    setState(() => _isUploading = true);

    for (int i = 0; i < _pendingFiles.length; i++) {
      try {
        final bytes = i < _pendingBytesCache.length
            ? _pendingBytesCache[i]
            : await _pendingFiles[i].readAsBytes();
        final base64 = base64Encode(bytes);
        final req = http.MultipartRequest('POST', uri);
        req.fields['upload_preset'] = uploadPreset;
        req.fields['file'] = 'data:image/jpeg;base64,$base64';
        final response = await req.send();
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final jsonData = json.decode(responseData);
          urls.add(jsonData['secure_url']);
        }
      } catch (e) {
        debugPrint("Upload error: $e");
      }
    }

    setState(() => _isUploading = false);
    return urls;
  }

  void _removeImage(int index) {
    final totalUploaded = _uploadedImageUrls.length;
    if (index < totalUploaded) {
      setState(() => _uploadedImageUrls.removeAt(index));
    } else {
      final pendingIndex = index - totalUploaded;
      setState(() {
        _pendingFiles.removeAt(pendingIndex);
        if (pendingIndex < _pendingBytesCache.length) {
          _pendingBytesCache.removeAt(pendingIndex);
        }
      });
    }
  }

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
              
              // ── Vehicle Photos Section ──
              Text("Vehicle Photos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              _buildImageSection(),
              SizedBox(height: 20),
              
              Text("Vehicle Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: "Vehicle Type", prefixIcon: Icon(Iconsax.category)),
                items: ['Car', 'Bike'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
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
      // Upload pending images first
      if (_pendingFiles.isNotEmpty) {
        final newUrls = await _uploadPendingFiles();
        _uploadedImageUrls.addAll(newUrls);
        _pendingFiles.clear();
        _pendingBytesCache.clear();
      }

      final newVehicle = VehicleModel(
        id: "", // Will be assigned by service/firestore
        brand: _brandController.text,
        model: _modelController.text,
        year: int.parse(_yearController.text),
        price: 0,
        images: _uploadedImageUrls,
        sellerId: authService.currentUser!.uid,
        status: 'sold', 
        type: _selectedType,
        specs: {'licensePlate': _licensePlateController.text.trim().toUpperCase().replaceAll(' ', '')},
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

  Widget _buildImageSection() {
    final totalImages = _uploadedImageUrls.length + _pendingFiles.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalImages > 0)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalImages + 1,
              itemBuilder: (context, index) {
                if (index == totalImages) {
                  return _buildAddImageCard();
                }
                return _buildImageCard(index);
              },
            ),
          )
        else
          _buildAddImageCard(),
        if (_isUploading)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildAddImageCard() {
    return InkWell(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 120,
        height: 120,
        margin: EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.camera, size: 32, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: 8),
            Text(
              "Add Photo",
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(int index) {
    final totalUploaded = _uploadedImageUrls.length;
    final isUploaded = index < totalUploaded;

    return Container(
      width: 120,
      height: 120,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isUploaded
                ? VehicleImage(
                    src: _uploadedImageUrls[index],
                    fit: BoxFit.cover,
                    width: 120,
                    height: 120,
                  )
                : Image.memory(
                    _pendingBytesCache[index - totalUploaded],
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _removeImage(index),
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
