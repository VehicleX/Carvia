import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/services/theme_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/home/home_page.dart';
import 'package:carvia/presentation/profile/profile_page.dart';
import 'package:carvia/presentation/vehicle/my_vehicles_page.dart';
import 'package:carvia/presentation/challan/e_challan_page.dart';
import 'package:carvia/presentation/ai/ai_chat_page.dart';
import 'package:carvia/presentation/auth/login_page.dart';
import 'package:carvia/presentation/vehicle/wishlist_page.dart';
import 'package:carvia/presentation/profile/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _pages = [
    const HomePage(),
    const MyVehiclesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context, isDark, themeService, authService),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha:0.2),
        elevation: 10,
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.home),
            selectedIcon: Icon(Iconsax.home5, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.car),
            selectedIcon: Icon(Iconsax.car5, color: AppColors.primary),
            label: 'My Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.user),
            selectedIcon: Icon(Iconsax.user_octagon, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isDark, ThemeService themeService, AuthService authService) {
    return Drawer(
      backgroundColor: isDark ? AppColors.surface : Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Iconsax.user, size: 40, color: AppColors.primary),
            ),
            accountName: Text(authService.currentUser?.name ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(authService.currentUser?.email ?? ""),
          ),
          _drawerItem(icon: Iconsax.car, title: "Explore Vehicles", onTap: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 0);
          }),
          _drawerItem(icon: Iconsax.heart, title: "Wishlist", onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()));
          }),
          _drawerItem(icon: Iconsax.magic_star, title: "AI Recommendation", onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatPage()));
          }),
          _drawerItem(icon: Iconsax.receipt, title: "E-Challan", onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EChallanPage()));
          }),
          const Divider(),
          _drawerItem(icon: Iconsax.setting, title: "Settings", onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
          _drawerItem(icon: isDark ? Iconsax.sun_1 : Iconsax.moon, title: isDark ? "Light Mode" : "Dark Mode", onTap: () {
            themeService.toggleTheme();
          }),
          const Spacer(),
          _drawerItem(icon: Iconsax.logout, title: "Logout", color: AppColors.error, onTap: () {
            authService.logout();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textMuted),
      title: Text(title, style: TextStyle(color: color ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black))),
      onTap: onTap,
    );
  }
}
