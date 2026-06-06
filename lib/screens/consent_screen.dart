import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'permission_explanation_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _termsChecked = false;
  bool _privacyChecked = false;
  bool _isSaving = false;

  bool get _canProceed => _termsChecked && _privacyChecked;

  Future<void> _accept() async {
    if (!_canProceed || _isSaving) return;
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);

    if (!mounted) return;

    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final cameraStatus = await Permission.camera.status;

    if (!mounted) return;

    Widget next;
    if (!onboardingDone) {
      next = const OnboardingScreen();
    } else if (!cameraStatus.isGranted) {
      next = const PermissionExplanationScreen();
    } else {
      next = const HomeScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => next,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openTerms() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TermsScreen()),
      );

  void _openPrivacy() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildScrollContent()),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 36),
          _buildKeyPoints(),
          const SizedBox(height: 32),
          _buildCheckboxes(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withAlpha(80),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.back_hand_rounded,
              color: Colors.white, size: 30),
        ),
        const SizedBox(height: 24),
        const Text(
          'Devam etmeden önce',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'PalmPay\'i kullanmak için kullanım koşullarını ve gizlilik politikasını kabul etmeniz gerekiyor.',
          style: TextStyle(
            color: Colors.white.withAlpha(153),
            fontSize: 15,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyPoints() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Column(
        children: [
          _buildPoint(
            icon: Icons.storage_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: 'Veriler cihazınızda kalır',
            subtitle:
                'Biyometrik veriniz hiçbir sunucuya gönderilmez.',
          ),
          _buildPointDivider(),
          _buildPoint(
            icon: Icons.no_photography_rounded,
            iconColor: const Color(0xFF059669),
            title: 'Görüntüler paylaşılmaz',
            subtitle: 'Kamera görüntüleri üçüncü taraflarla paylaşılmaz.',
          ),
          _buildPointDivider(),
          _buildPoint(
            icon: Icons.delete_outline_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'Dilediğinizde silebilirsiniz',
            subtitle:
                'Ayarlar → Verilerimi Sil ile tüm kayıtları silebilirsiniz.',
          ),
          _buildPointDivider(),
          _buildPoint(
            icon: Icons.lock_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'KVKK uyumlu',
            subtitle:
                '6698 sayılı Kişisel Verilerin Korunması Kanunu\'na uygun işleme.',
          ),
        ],
      ),
    );
  }

  Widget _buildPoint({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(128),
                      fontSize: 12,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointDivider() =>
      Divider(height: 1, indent: 66, color: Colors.white.withAlpha(13));

  Widget _buildCheckboxes() {
    return Column(
      children: [
        _buildCheckboxTile(
          checked: _termsChecked,
          onChanged: (v) => setState(() => _termsChecked = v ?? false),
          label: 'Kullanım Koşullarını',
          linkLabel: 'okudum ve kabul ediyorum',
          onLinkTap: _openTerms,
        ),
        const SizedBox(height: 12),
        _buildCheckboxTile(
          checked: _privacyChecked,
          onChanged: (v) => setState(() => _privacyChecked = v ?? false),
          label: 'Gizlilik Politikasını',
          linkLabel: 'okudum ve kabul ediyorum',
          onLinkTap: _openPrivacy,
        ),
      ],
    );
  }

  Widget _buildCheckboxTile({
    required bool checked,
    required ValueChanged<bool?> onChanged,
    required String label,
    required String linkLabel,
    required VoidCallback onLinkTap,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: checked
              ? const Color(0xFF7C3AED).withAlpha(26)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: checked
                ? const Color(0xFF7C3AED).withAlpha(128)
                : Colors.white.withAlpha(20),
            width: checked ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checked,
                onChanged: onChanged,
                activeColor: const Color(0xFF7C3AED),
                side: BorderSide(color: Colors.white.withAlpha(77)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  children: [
                    GestureDetector(
                      onTap: onLinkTap,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                    Text(
                      ' $linkLabel',
                      style: TextStyle(
                        color: Colors.white.withAlpha(179),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(13)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _canProceed
                  ? const Color(0xFF7C3AED)
                  : Colors.white.withAlpha(20),
              foregroundColor:
                  _canProceed ? Colors.white : Colors.white38,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              elevation: 0,
            ),
            onPressed: _canProceed ? _accept : null,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _canProceed
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Kabul Ediyorum',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
