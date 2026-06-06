import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
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

  final cameraStatus = await Permission.camera.status;

  runApp(PalmPayApp(cameraGranted: cameraStatus.isGranted));
}

class PalmPayApp extends StatelessWidget {
  final bool cameraGranted;

  const PalmPayApp({super.key, required this.cameraGranted});

  @override
  Widget build(BuildContext context) {
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
      home: cameraGranted
          ? const HomeScreen()
          : const PermissionExplanationScreen(),
    );
  }
}