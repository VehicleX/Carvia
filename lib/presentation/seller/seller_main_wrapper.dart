import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/theme_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/auth/login_page.dart';
import 'package:carvia/presentation/seller/seller_dashboard.dart';
import 'package:carvia/presentation/seller/manage_listings_page.dart';
import 'package:carvia/presentation/seller/add_vehicle_page.dart';
import 'package:carvia/presentation/seller/seller_test_drives_page.dart';
import 'package:carvia/presentation/seller/seller_analytics_page.dart';
import 'package:carvia/presentation/seller/seller_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class SellerMainWrapper extends StatefulWidget {
  const SellerMainWrapper({super.key});

  @override
  State<SellerMainWrapper> createState() => _SellerMainWrapperState();
}

class _SellerMainWrapperState extends State<SellerMainWrapper> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const SellerDashboard(),
    const ManageListingsPage(),
    const AddVehiclePage(), // Replaced placeholder
    const SellerTestDrivesPage(),
    const SellerAnalyticsPage(),
    const SellerProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);

    // Sidebar Items
    final List<Map<String, dynamic>> _menuItems = [
      {'icon': Iconsax.home, 'title': 'Dashboard'},
      {'icon': Iconsax.car, 'title': 'Inventory'},
      {'icon': Iconsax.add_circle, 'title': 'Add Vehicle'},
      {'icon': Iconsax.calendar, 'title': 'Test Drives'},
      {'icon': Iconsax.chart_2, 'title': 'Analytics'},
      {'icon': Iconsax.user, 'title': 'Profile'},
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_menuItems[_currentIndex]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Iconsax.menu_1),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Iconsax.sun_1 : Iconsax.moon),
            onPressed: themeService.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Iconsax.logout, color: AppColors.error),
            onPressed: () {
              authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueGrey, Colors.black87],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Iconsax.shop, size: 40, color: Colors.blueGrey),
              ),
              accountName: Text(authService.currentUser?.name ?? "Seller", style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(authService.currentUser?.email ?? ""),
            ),
             ..._menuItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == idx;
              return ListTile(
                leading: Icon(item['icon'], color: isSelected ? AppColors.primary : AppColors.textMuted),
                title: Text(item['title'], style: TextStyle(
                  color: isSelected ? AppColors.primary : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
                selected: isSelected,
                selectedTileColor: AppColors.primary.withOpacity(0.1),
                onTap: () {
                  setState(() => _currentIndex = idx);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const Divider(),
            ListTile(
              leading: const Icon(Iconsax.logout, color: AppColors.error),
              title: const Text("Logout", style: TextStyle(color: AppColors.error)),
              onTap: () {
                authService.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
    );
  }
}
