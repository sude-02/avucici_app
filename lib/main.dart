import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permission_explanation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  final cameraStatus = await Permission.camera.status;

  runApp(PalmPayApp(
    onboardingDone: onboardingDone,
    cameraGranted: cameraStatus.isGranted,
  ));
}

class PalmPayApp extends StatelessWidget {
  final bool onboardingDone;
  final bool cameraGranted;

  const PalmPayApp({
    super.key,
    required this.onboardingDone,
    required this.cameraGranted,
  });

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!onboardingDone) {
      home = const OnboardingScreen();
    } else if (!cameraGranted) {
      home = const PermissionExplanationScreen();
    } else {
      home = const HomeScreen();
    }

    return MaterialApp(
      title: 'PalmPay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: home,
    );
  }
}