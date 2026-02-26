import 'package:carvia/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PoliceAnalyticsPage extends StatelessWidget {
  const PoliceAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 100, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
            SizedBox(height: 20),
            Text("Advanced Analytics", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Violation hotspots and trends will appear here.", style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ],
        ),
      ),
    );
  }
}
