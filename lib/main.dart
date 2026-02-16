import 'package:carvia/core/services/auth_service.dart';
import 'package:carvia/core/theme/app_theme.dart';
import 'package:carvia/core/services/theme_service.dart';
import 'package:carvia/core/services/vehicle_service.dart';
import 'package:carvia/core/services/challan_service.dart';
import 'package:carvia/core/services/ai_service.dart';
import 'package:carvia/core/services/location_service.dart';
import 'package:carvia/core/services/compare_service.dart';
import 'package:carvia/core/services/order_service.dart';
import 'package:carvia/presentation/splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Check if options are available)
  try {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    // NOTE: Waiting for user to provide firebase_options.dart
    // For now, we just initialize without options (works for mobile if google-services.json is present)
    await Firebase.initializeApp(); 
  } catch (e) {
    debugPrint("Firebase Initialization Failed: $e");
    debugPrint("Did you forget to add google-services.json or firebase_options.dart?");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => VehicleService()),
        ChangeNotifierProvider(create: (_) => ChallanService()),
        ChangeNotifierProvider(create: (_) => AIService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => CompareService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
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
