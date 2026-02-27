import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/theme_service.dart';
import 'package:carvia/presentation/police/police_analytics_page.dart';
import 'package:carvia/presentation/police/police_challan_list_page.dart';
import 'package:carvia/presentation/police/police_dashboard.dart';
import 'package:carvia/presentation/police/police_issue_challan.dart';
import 'package:carvia/presentation/police/police_search_vehicle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carvia/presentation/landing/landing_page.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class PoliceMainWrapper extends StatefulWidget {
  const PoliceMainWrapper({super.key});

  @override
  State<PoliceMainWrapper> createState() => _PoliceMainWrapperState();
}

class _PoliceMainWrapperState extends State<PoliceMainWrapper> {
  int _selectedIndex = 0;
  final bool _isSidebarExpanded = true;

  final List<Widget> _pages = [
    const PoliceDashboard(),
    const PoliceSearchVehicle(),
    const PoliceIssueChallan(),
    const PoliceChallanListPage(), // New page
    const PoliceAnalyticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, color: Theme.of(context).colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        "CARVIA POLICE",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  _buildNavItem(0, "Dashboard", Iconsax.home_2),
                  _buildNavItem(1, "Search Vehicle", Iconsax.search_normal),
                  _buildNavItem(2, "Issue Challan", Iconsax.receipt_add),
                  _buildNavItem(3, "My Issued Challans", Iconsax.receipt_2),
                  _buildNavItem(4, "Analytics", Iconsax.chart_2),
                  
                  const Spacer(),
                  _buildLogoutButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          
          Expanded(
            child: Column(
              children: [
                if (!isDesktop) ...[
                  AppBar(
                    title: Text(
                      "Carvia Police",
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 0,
                    actions: [
                      IconButton(
                        onPressed: () => _showLogoutDialog(context),
                        icon: const Icon(Iconsax.logout),
                      ),
                    ],
                  ),
                ],
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _pages[_selectedIndex],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : NavigationBar(
        selectedIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Iconsax.home_2), label: "Home"),
          NavigationDestination(icon: Icon(Iconsax.search_normal), label: "Search"),
          NavigationDestination(icon: Icon(Iconsax.receipt_add), label: "Issue"),
          NavigationDestination(icon: Icon(Iconsax.receipt_2), label: "Challans"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    final color = isSelected 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          leading: Icon(icon, color: color, size: 22),
          onTap: () => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(Iconsax.logout, color: Theme.of(context).colorScheme.error),
        title: Text(
          "Logout",
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        onTap: () => _showLogoutDialog(context),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Provider.of<ThemeService>(context, listen: false).resetToDark();
              await Provider.of<AuthService>(context, listen: false).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LandingPage()),
                  (route) => false,
                );
              }
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
