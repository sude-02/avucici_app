import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import '../utils/app_theme.dart';

class PermissionExplanationScreen extends StatefulWidget {
  const PermissionExplanationScreen({super.key});

  @override
  State<PermissionExplanationScreen> createState() =>
      _PermissionExplanationScreenState();
}

class _PermissionExplanationScreenState
    extends State<PermissionExplanationScreen>
    with SingleTickerProviderStateMixin {
  bool _isRequesting = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    final status = await Permission.camera.request();

    if (!mounted) return;

    if (status.isGranted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (status.isPermanentlyDenied) {
      setState(() => _isRequesting = false);
      _showSettingsDialog();
    } else {
      setState(() => _isRequesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Kamera izni olmadan uygulama çalışamaz.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card(dialogContext),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Kamera İzni Gerekli',
          style: TextStyle(
              color: AppTheme.text(dialogContext),
              fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Kamera izni kalıcı olarak reddedildi. Lütfen uygulama ayarlarından izni etkinleştirin.',
          style: TextStyle(color: AppTheme.textSecondary(dialogContext)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('İptal',
                style: TextStyle(color: AppTheme.textMuted(dialogContext))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Ayarlara Git',
                style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _buildIcon(),
              const SizedBox(height: 48),
              _buildTexts(context),
              const Spacer(flex: 3),
              _buildButton(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: child,
      ),
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildTexts(BuildContext context) {
    return Column(
      children: [
        Text(
          'Kamera İzni',
          style: TextStyle(
            color: AppTheme.text(context),
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Bu uygulama avuç içinizi okumak için\nkameraya ihtiyaç duyar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 17,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        _buildFeatureRow(
          context,
          Icons.security_rounded,
          'Görüntüler cihazınızda işlenir,\nhiçbir yere gönderilmez.',
        ),
        const SizedBox(height: 16),
        _buildFeatureRow(
          context,
          Icons.back_hand_rounded,
          'Avuç içi damar izi ile\ngüvenli kimlik doğrulama.',
        ),
      ],
    );
  }

  Widget _buildFeatureRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.3)),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        onPressed: _isRequesting ? null : _requestPermission,
        child: _isRequesting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'İzin Ver',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
