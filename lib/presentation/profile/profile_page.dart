import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/theme_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/auth/login_page.dart';
import 'package:carvia/presentation/challan/e_challan_page.dart';
import 'package:carvia/presentation/vehicle/my_vehicles_page.dart';
import 'package:carvia/presentation/profile/orders_page.dart';
import 'package:carvia/presentation/profile/settings_page.dart';
import 'package:carvia/presentation/vehicle/test_drives_page.dart';
import 'package:carvia/presentation/vehicle/wishlist_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final user = authService.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text("Loading...")));

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    backgroundImage: user.profileImage != null ? NetworkImage(user.profileImage!) : null,
                    child: user.profileImage == null ? const Icon(Iconsax.user, size: 40, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(user.email, style: const TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Premium Member", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _showEditProfileDialog(context, user),
                icon: const Icon(Iconsax.edit),
                label: const Text("Edit Profile"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              
              // Credits Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CARVIA CREDITS", style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${user.credits} pts", style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const Icon(Iconsax.wallet_2, color: Colors.white, size: 32),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Menu Options
              _buildMenuOption(context, "My Vehicles", Iconsax.car, () {
                 // Navigate to MyVehicles via MainWrapper tab or push?
                 // Since it's a tab, we might want to just switch tab.
                 // But for now, we can push the page or let user use bottom nav.
                 // Let's push to highlight it.
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const MyVehiclesPage()));
              }),
              _buildMenuOption(context, "My Orders", Iconsax.box, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage()));
              }),
              _buildMenuOption(context, "Wishlist", Iconsax.heart, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()));
              }),
              _buildMenuOption(context, "Test Drives", Iconsax.calendar, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TestDrivesPage()));
              }),
              _buildMenuOption(context, "E-Challan", Iconsax.receipt, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const EChallanPage()));
              }),
              
              const Divider(height: 40),
              
              _buildMenuOption(context, themeService.isDarkMode ? "Light Mode" : "Dark Mode", themeService.isDarkMode ? Iconsax.sun_1 : Iconsax.moon, () {
                themeService.toggleTheme();
              }),
              _buildMenuOption(context, "Settings", Iconsax.setting, () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
              }),
              
              const SizedBox(height: 20),
              _buildMenuOption(context, "Logout", Iconsax.logout, () {
                 authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, String title, IconData icon, VoidCallback onTap, {Color? color}) {
    final textColor = color ?? Theme.of(context).textTheme.bodyLarge?.color;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? AppColors.primary), 
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context, dynamic user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final authService = Provider.of<AuthService>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Iconsax.user)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Iconsax.call)),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await authService.updateProfile(nameController.text.trim(), phoneController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
