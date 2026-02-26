import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/presentation/profile/about_credits_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  // bool _darkMode = false; // Sync with ThemeService if needed, but ThemeService handles it globally

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
    });
  }

  Future<void> _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildSectionHeader("Notifications"),
          _buildSwitchTile("Push Notifications", "Receive alerts about new cars and offers", _pushNotifications, (val) {
            setState(() => _pushNotifications = val);
            _toggleSetting('push_notifications', val);
          }),
          _buildSwitchTile("Email Newsletters", "Get weekly updates on car trends", _emailNotifications, (val) {
             setState(() => _emailNotifications = val);
             _toggleSetting('email_notifications', val);
          }),
          
          SizedBox(height: 30),
          _buildSectionHeader("About"),
           ListTile(
            title: Text("About Canvas Credits"),
            subtitle: Text("Learn how our credit system works"),
            leading: Icon(Iconsax.info_circle, color: Theme.of(context).colorScheme.primary),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutCreditsPage()));
            },
          ),
          ListTile(
            title: Text("Privacy Policy"),
            leading: Icon(Iconsax.lock, color: Theme.of(context).colorScheme.secondary),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            title: Text("Terms of Service"),
            leading: Icon(Iconsax.document_text, color: Theme.of(context).colorScheme.secondary),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          
          SizedBox(height: 30),
          Center(
            child: Text("Version 1.0.0", style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
