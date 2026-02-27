import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/theme_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/auth/login_page.dart';
import 'package:carvia/presentation/seller/seller_dashboard.dart';
import 'package:carvia/presentation/seller/manage_listings_page.dart';
import 'package:carvia/presentation/seller/add_vehicle_page.dart';
import 'package:carvia/presentation/seller/seller_orders_page.dart';
import 'package:carvia/presentation/seller/seller_test_drives_page.dart';
import 'package:carvia/presentation/ai/voice_assistant_bottom_sheet.dart';
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
    SizedBox(), // Placeholder, will be initialized in initState
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
            title: Text("Exit App"),
            content: Text("Are you sure you want to exit?"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text("Cancel")),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text("Exit")),
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
        title: Text(menuItems[_currentIndex]['title'], style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Iconsax.menu_1),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Iconsax.sun_1 : Iconsax.moon),
            onPressed: themeService.toggleTheme,
          ),
          IconButton(
            icon: Icon(Iconsax.logout, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              Provider.of<ThemeService>(context, listen: false).resetToDark();
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2))),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(Iconsax.shop, size: 40, color: Theme.of(context).colorScheme.onPrimary),
              ),
              accountName: Text(authService.currentUser?.name ?? "Seller", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              accountEmail: Text(authService.currentUser?.email ?? "", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
             ...menuItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == idx;
              return ListTile(
                leading: Icon(item['icon'], color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
                title: Text(item['title'], style: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
                selected: isSelected,
                selectedTileColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                onTap: () {
                  setState(() => _currentIndex = idx);
                  Navigator.pop(context);
                },
              );
            }),
            Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ListTile(
              leading: Icon(Iconsax.logout, color: Theme.of(context).colorScheme.error),
              title: Text("Logout", style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Provider.of<ThemeService>(context, listen: false).resetToDark();
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => VoiceAssistantBottomSheet.show(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Iconsax.microphone_2, color: Colors.white),
      ),
    ),
    );
  }
}
