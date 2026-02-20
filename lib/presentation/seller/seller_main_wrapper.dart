import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/theme_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/auth/login_page.dart';
import 'package:carvia/presentation/seller/seller_dashboard.dart';
import 'package:carvia/presentation/seller/manage_listings_page.dart';
import 'package:carvia/presentation/seller/add_vehicle_page.dart';
import 'package:carvia/presentation/seller/seller_orders_page.dart';
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
    const SizedBox(), // Placeholder, will be initialized in initState
    const ManageListingsPage(),
    const AddVehiclePage(),
    const SellerOrdersPage(),
    const SellerTestDrivesPage(),
    const SellerAnalyticsPage(),
    const SellerProfilePage(),
  ];


  @override
  void initState() {
    super.initState();
    // Initialize pages here to access setState
    _pages[0] = SellerDashboard(onTabChange: (index) {
      setState(() => _currentIndex = index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);

    // Sidebar Items
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Iconsax.home, 'title': 'Dashboard'},
      {'icon': Iconsax.car, 'title': 'Inventory'},
      {'icon': Iconsax.add_circle, 'title': 'Add Vehicle'},
      {'icon': Iconsax.box, 'title': 'Orders'},
      {'icon': Iconsax.calendar, 'title': 'Test Drives'},
      {'icon': Iconsax.chart_2, 'title': 'Analytics'},
      {'icon': Iconsax.user, 'title': 'Profile'},
    ];


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
          return;
        }

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // If on Dashboard (index 0), confirm exit
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Exit App"),
            content: const Text("Are you sure you want to exit?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancel")),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Exit")),
            ],
          ),
        );

        if (shouldExit == true && context.mounted) {
           Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(menuItems[_currentIndex]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
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
             ...menuItems.asMap().entries.map((entry) {
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
                selectedTileColor: AppColors.primary.withValues(alpha:0.1),
                onTap: () {
                  setState(() => _currentIndex = idx);
                  Navigator.pop(context);
                },
              );
            }),
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
    ),
    );
  }
}
