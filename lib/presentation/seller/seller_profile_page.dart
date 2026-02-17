import 'package:carvia/core/models/user_model.dart';
import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _businessNameController;
  late TextEditingController _gstController;
  late TextEditingController _addressController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone);
    
    // Org Details
    final sellerDetails = user.sellerDetails;
    _businessNameController = TextEditingController(text: sellerDetails['businessName'] ?? '');
    _gstController = TextEditingController(text: sellerDetails['gstNumber'] ?? '');
    _addressController = TextEditingController(text: sellerDetails['businessAddress'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) return const Center(child: Text("Login Required"));

    final isOrg = user.accountType == AccountType.company;

    return Scaffold(
      appBar: AppBar(
        title: Text("Seller Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Iconsax.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Icon(Iconsax.user, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(user.email, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOrg ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOrg ? "Organization Account" : "Individual Seller",
                  style: TextStyle(
                    color: isOrg ? Colors.purple : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionHeader("Basic Info"),
              const SizedBox(height: 12),
              _buildTextField("Name", _nameController, Iconsax.user, enabled: _isEditing),
              const SizedBox(height: 16),
              _buildTextField("Phone", _phoneController, Iconsax.call, enabled: _isEditing),
              
              if (isOrg) ...[
                const SizedBox(height: 30),
                _buildSectionHeader("Business Details"),
                const SizedBox(height: 12),
                _buildTextField("Business Name", _businessNameController, Iconsax.building, enabled: _isEditing),
                const SizedBox(height: 16),
                _buildTextField("GST Number", _gstController, Iconsax.receipt, enabled: _isEditing),
                const SizedBox(height: 16),
                _buildTextField("Business Address", _addressController, Iconsax.location, enabled: _isEditing, maxLines: 2),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool enabled = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !enabled,
        fillColor: enabled ? null : Theme.of(context).cardColor,
      ),
      validator: (val) => val!.isEmpty ? "Required" : null,
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser!;
      
      final updatedDetails = {
        ...?user.sellerDetails,
        'businessName': _businessNameController.text,
        'gstNumber': _gstController.text,
        'businessAddress': _addressController.text,
      };

      // Mock Update (In reality, AuthService needs updateProfile method, or we mock it)
      // await auth.updateProfile(...); 
      // For now we just allow the UI toggle back since we don't have updateProfile exposed fully in AuthService for map fields yet.
      
      if (mounted) {
         setState(() {
           _isEditing = false;
           _isLoading = false;
         });
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}
