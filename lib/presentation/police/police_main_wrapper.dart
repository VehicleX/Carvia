import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/police/police_analytics_page.dart';
import 'package:carvia/presentation/police/police_dashboard.dart';
import 'package:carvia/presentation/police/police_issue_challan.dart';
import 'package:carvia/presentation/police/police_search_vehicle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class PoliceMainWrapper extends StatefulWidget {
  const PoliceMainWrapper({super.key});

  @override
  State<PoliceMainWrapper> createState() => _PoliceMainWrapperState();
}

class _PoliceMainWrapperState extends State<PoliceMainWrapper> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final List<Widget> _pages = [
    const PoliceDashboard(),
    const PoliceSearchVehicle(),
    const PoliceIssueChallan(), // Quick Access
    const PoliceAnalyticsPage(),
    const Center(child: Text("Notifications")), // Placeholder
    const Center(child: Text("Settings")), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isSidebarExpanded ? 250 : 70,
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Logo / Header
                  if (_isSidebarExpanded)
                    Text("Carvia Police", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary))
                  else
                    const Icon(Icons.security, color: AppColors.primary),
                  
                  const SizedBox(height: 40),
                  
                  _buildNavItem(0, "Dashboard", Iconsax.home),
                  _buildNavItem(1, "Search Vehicle", Iconsax.search_normal),
                  _buildNavItem(2, "Issue Challan", Iconsax.receipt_add),
                  _buildNavItem(3, "Analytics", Iconsax.chart_2),
                  _buildNavItem(4, "Notifications", Iconsax.notification),
                  _buildNavItem(5, "Settings", Iconsax.setting),
                  
                  const Spacer(),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          
          Expanded(
            child: Column(
              children: [
                if (!isDesktop) ...[
                  AppBar(
                    title: const Text("Carvia Police"),
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                  ),
                ],
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : NavigationBar(
        selectedIndex: _selectedIndex > 3 ? 0 : _selectedIndex, // Simple mapping for mobile
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Iconsax.home), label: "Home"),
          NavigationDestination(icon: Icon(Iconsax.search_normal), label: "Search"),
          NavigationDestination(icon: Icon(Iconsax.receipt_add), label: "Challan"),
          NavigationDestination(icon: Icon(Iconsax.chart_2), label: "Analytics"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      title: _isSidebarExpanded ? Text(title, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textMuted)) : null,
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
      onTap: () => setState(() => _selectedIndex = index),
      selected: isSelected,
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Iconsax.logout, color: Colors.red),
      title: _isSidebarExpanded ? const Text("Logout", style: TextStyle(color: Colors.red)) : null,
      onTap: () {
        Provider.of<AuthService>(context, listen: false).signOut();
      },
    );
  }
}
