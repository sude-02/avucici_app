import 'package:flutter/material.dart';
import 'amount_entry_screen.dart';
import 'register_screen.dart';
import 'settings_screen.dart';
import 'transaction_history_screen.dart';
import 'users_screen.dart';
import 'profile_screen.dart';
import '../services/database_service.dart';
import '../utils/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _userCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserCount();
  }

  Future<void> _loadUserCount() async {
    final users = await DatabaseService().getAllUsers();
    if (mounted) setState(() => _userCount = users.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildMainButton(context),
              const SizedBox(height: 16),
              _buildSecondaryButtons(context),
              const SizedBox(height: 24),
              _buildFooter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.back_hand_rounded,
                  color: Colors.white, size: 28),
            ),
            const Spacer(),
            if (_userCount > 0)
              IconButton(
                icon: const Icon(Icons.manage_accounts_rounded,
                    color: Colors.white54),
                tooltip: 'Profil Yönet',
                onPressed: () async {
                  final users = await DatabaseService().getAllUsers();
                  if (!context.mounted || users.isEmpty) return;
                  if (users.length == 1) {
                    Navigator.push(
                      context,
                      AppRoutes.push(ProfileScreen(user: users.first)),
                    ).then((_) => _loadUserCount());
                  } else {
                    Navigator.push(
                      context,
                      AppRoutes.push(const UsersScreen()),
                    ).then((_) => _loadUserCount());
                  }
                },
              ),
            IconButton(
              icon: const Icon(Icons.settings_rounded, color: Colors.white38),
              onPressed: () => Navigator.push(
                context,
                AppRoutes.push(const SettingsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'PalmPay',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Avuç içi biyometrik ödeme sistemi',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppRoutes.push(const AmountEntryScreen()),
      ),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sensors, color: Colors.white, size: 56),
            SizedBox(height: 12),
            Text(
              'Ödeme Yap',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Avucunu okut',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryCard(
            context,
            icon: Icons.person_add_rounded,
            label: 'Kayıt Ol',
            subtitle: 'Yeni kullanıcı',
            color: const Color(0xFF10B981),
            onTap: () => Navigator.push(
              context, AppRoutes.push(const RegisterScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSecondaryCard(
            context,
            icon: Icons.people_rounded,
            label: 'Kullanıcılar',
            subtitle: 'Kayıtlı kişiler',
            color: const Color(0xFFF59E0B),
            onTap: () => Navigator.push(
              context, AppRoutes.push(const UsersScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSecondaryCard(
            context,
            icon: Icons.receipt_long_rounded,
            label: 'Geçmiş',
            subtitle: 'Tüm ödemeler',
            color: const Color(0xFF7C3AED),
            onTap: () => Navigator.push(
              context, AppRoutes.push(const TransactionHistoryScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Güvenli • Hızlı • Temassız',
        style: TextStyle(
          color: Colors.white.withOpacity(0.25),
          fontSize: 13,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}