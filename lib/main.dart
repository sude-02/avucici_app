import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/consent_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/permission_explanation_screen.dart';
import 'services/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await AppSettings.load();

  final prefs = await SharedPreferences.getInstance();
  final termsAccepted = prefs.getBool('terms_accepted') ?? false;
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  final cameraStatus = await Permission.camera.status;

  runApp(PalmPayApp(
    termsAccepted: termsAccepted,
    onboardingDone: onboardingDone,
    cameraGranted: cameraStatus.isGranted,
  ));
}

class PalmPayApp extends StatefulWidget {
  final bool termsAccepted;
  final bool onboardingDone;
  final bool cameraGranted;

  const PalmPayApp({
    super.key,
    required this.termsAccepted,
    required this.onboardingDone,
    required this.cameraGranted,
  });

  @override
  State<PalmPayApp> createState() => _PalmPayAppState();
}

class _PalmPayAppState extends State<PalmPayApp> {
  @override
  void initState() {
    super.initState();
    AppSettings.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    AppSettings.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!widget.termsAccepted) {
      home = const ConsentScreen();
    } else if (!widget.onboardingDone) {
      home = const OnboardingScreen();
    } else if (!widget.cameraGranted) {
      home = const PermissionExplanationScreen();
    } else {
      home = const HomeScreen();
    }

    final isDark = AppSettings.themeNotifier.value == ThemeMode.dark;

    return MaterialApp(
      title: 'PalmPay',
      debugShowCheckedModeBanner: false,
      themeMode: AppSettings.themeNotifier.value,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
      ),
      home: home,
    );
  }
}