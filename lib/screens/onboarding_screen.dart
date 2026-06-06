import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'permission_explanation_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.back_hand_rounded,
      gradientColors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
      title: 'Avuç İzi ile Ödeme',
      description:
          'Avuç içinizdeki benzersiz damar izinizi kullanarak\nsaniyeler içinde ödeme yapın.',
      detail: 'Kart yok • Şifre yok • Temas yok',
    ),
    _OnboardingPage(
      icon: Icons.lock_rounded,
      gradientColors: [Color(0xFF059669), Color(0xFF0EA5E9)],
      title: 'Hızlı ve Güvenli',
      description:
          'Biyometrik verileriniz şifreli olarak yalnızca\ncihazınızda saklanır, hiçbir yere gönderilmez.',
      detail: 'Uçtan uca şifreleme • Yerel işleme',
    ),
    _OnboardingPage(
      icon: Icons.rocket_launch_rounded,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
      title: 'Başla',
      description:
          'Avuç izinizi kaydedin ve\nanında ödeme yapmaya başlayın.',
      detail: null,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete({bool goToRegister = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;

    if (goToRegister) {
      final status = await Permission.camera.status;
      if (!mounted) return;
      if (status.isGranted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (_) => const PermissionExplanationScreen()),
        );
      }
    } else {
      final status = await Permission.camera.status;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => status.isGranted
              ? const HomeScreen()
              : const PermissionExplanationScreen(),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isLast),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
              ),
            ),
            _buildBottomBar(isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.back_hand_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'PalmPay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (!isLast)
            TextButton(
              onPressed: () => _complete(),
              child: Text(
                'Atla',
                style: TextStyle(
                  color: Colors.white.withAlpha(128),
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isLast) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        children: [
          _DotIndicator(count: _pages.length, current: _currentPage),
          const SizedBox(height: 28),
          if (isLast) ...[
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                onPressed: () => _complete(goToRegister: true),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_rounded, size: 22),
                    SizedBox(width: 10),
                    Text('Kayıt Ol',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => _complete(),
                child: Text(
                  'Ana Sayfaya Git',
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ] else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _pages[_currentPage].gradientColors,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _pages[_currentPage]
                              .gradientColors
                              .first
                              .withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildIllustration(),
          const SizedBox(height: 56),
          _buildTexts(),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: page.gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: page.gradientColors.first.withAlpha(80),
              blurRadius: 48,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Icon(page.icon, color: Colors.white, size: 72),
      ),
    );
  }

  Widget _buildTexts() {
    return Column(
      children: [
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          page.description,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withAlpha(153),
            fontSize: 16,
            height: 1.65,
          ),
        ),
        if (page.detail != null) ...[
          const SizedBox(height: 24),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(13),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withAlpha(26)),
            ),
            child: Text(
              page.detail!,
              style: TextStyle(
                color: Colors.white.withAlpha(179),
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? const Color(0xFF7C3AED)
                : Colors.white.withAlpha(51),
          ),
        );
      }),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final List<Color> gradientColors;
  final String title;
  final String description;
  final String? detail;

  const _OnboardingPage({
    required this.icon,
    required this.gradientColors,
    required this.title,
    required this.description,
    this.detail,
  });
}
