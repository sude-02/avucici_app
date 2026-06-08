import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
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

  final themeProvider = ThemeProvider();
  await themeProvider.load();

  final prefs = await SharedPreferences.getInstance();
  final termsAccepted = prefs.getBool('terms_accepted') ?? false;
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  final cameraStatus = await Permission.camera.status;

  runApp(
    ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: PalmPayApp(
        termsAccepted: termsAccepted,
        onboardingDone: onboardingDone,
        cameraGranted: cameraStatus.isGranted,
      ),
    ),
  );
}

class PalmPayApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        Widget home;
        if (!termsAccepted) {
          home = const ConsentScreen();
        } else if (!onboardingDone) {
          home = const OnboardingScreen();
        } else if (!cameraGranted) {
          home = const PermissionExplanationScreen();
        } else {
          home = const HomeScreen();
        }

        return MaterialApp(
          title: 'PalmPay',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,

          // ── Koyu tema (mevcut tasarım) ─────────────────────────────
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C3AED),
              brightness: Brightness.dark,
              surface: const Color(0xFF0A0A1A),
              surfaceContainer: const Color(0xFF1A1A2E),
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFF0A0A1A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Roboto',
              ),
            ),
            dialogTheme: DialogTheme(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            tabBarTheme: TabBarTheme(
              indicatorColor: const Color(0xFF7C3AED),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          // ── Açık tema ──────────────────────────────────────────────
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF7C3AED),
              brightness: Brightness.light,
              surface: const Color(0xFFF2F2F7),
              surfaceContainer: Colors.white,
            ),
            useMaterial3: true,
            fontFamily: 'Roboto',
            scaffoldBackgroundColor: const Color(0xFFF2F2F7),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF1C1C1E)),
              titleTextStyle: TextStyle(
                color: Color(0xFF1C1C1E),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Roboto',
              ),
            ),
            dialogTheme: DialogTheme(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            tabBarTheme: TabBarTheme(
              indicatorColor: const Color(0xFF7C3AED),
              labelColor: const Color(0xFF1C1C1E),
              unselectedLabelColor: Colors.black38,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),

          home: home,
        );
      },
    );
  }
}
