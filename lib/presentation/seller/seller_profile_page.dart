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
    if (user == null) return Center(child: Text("Login Required"));

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
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(Iconsax.user, size: 50, color: Theme.of(context).colorScheme.onSurface),
              ),
              SizedBox(height: 16),
              Text(user.email, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOrg ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOrg ? "Organization Account" : "Individual Seller",
                      style: TextStyle(
                        color: isOrg ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (!isOrg && _isEditing) ...[
                      SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                           // Logic to upgrade to Organization
                           _showUpgradeDialog();
                        },
                        child: Text(" (Upgrade)", style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                      )
                    ]
                  ],
                ),
              ),
              SizedBox(height: 30),
              _buildSectionHeader("Basic Info"),
              SizedBox(height: 12),
              _buildTextField("Name", _nameController, Iconsax.user, enabled: _isEditing),
              SizedBox(height: 16),
              _buildTextField("Phone", _phoneController, Iconsax.call, enabled: _isEditing),
              
              if (isOrg) ...[
                SizedBox(height: 30),
                _buildSectionHeader("Business Details"),
                SizedBox(height: 12),
                _buildTextField("Business Name", _businessNameController, Iconsax.building, enabled: _isEditing),
                SizedBox(height: 16),
                _buildTextField("GST Number", _gstController, Iconsax.receipt, enabled: _isEditing),
                SizedBox(height: 16),
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
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      // Mock Update (In reality, AuthService needs updateProfile method, or we mock it)
      // await Provider.of<AuthService>(context, listen: false).updateProfile(...);
      
      if (mounted) {
         setState(() {
           _isEditing = false;
           _isLoading = false;
         });
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile Updated!")));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Upgrade to Organization"),
        content: Text("This will enable business features like adding GST, Business Name, and Address. Continue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          if (_isLoading)
            CircularProgressIndicator()
          else
            TextButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final authService = Provider.of<AuthService>(context, listen: false);

                try {
                  final user = authService.currentUser;
                  if (user != null) {
                    await authService.upgradeToOrganization(user.uid);
                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(SnackBar(content: Text("Upgraded to Organization Account!")));
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    navigator.pop(); 
                    messenger.showSnackBar(SnackBar(content: Text("Upgrade Failed: $e")));
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              }, 
              child: Text("Upgrade"),
            ),
        ],
      ),
    );
  }
}
