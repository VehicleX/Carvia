import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/services/theme_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/services/ai_service.dart';
import 'package:carvia/core/services/location_service.dart';
import 'package:carvia/core/services/compare_service.dart';
import 'package:carvia/core/services/order_service.dart';
import 'package:carvia/core/services/notification_service.dart';
import 'package:carvia/presentation/splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => VehicleService()),
        ChangeNotifierProvider(create: (_) => ChallanService()),
        ChangeNotifierProvider(create: (_) => AIService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => CompareService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const CarviaApp(),
    ),
  );
}

class CarviaApp extends StatelessWidget {
  const CarviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          title: 'Carvia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
