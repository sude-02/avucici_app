import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/app_settings.dart';
import '../services/database_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _cameraGranted = false;
  bool _isDeleting = false;
  double _threshold = AppSettings.threshold;
  bool _isDark = AppSettings.isDark;
  String _language = AppSettings.language;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (mounted) setState(() => _cameraGranted = status.isGranted);
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Verileri Sil',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Tüm kayıtlı kullanıcılar ve biyometrik veriler kalıcı olarak silinecek. '
          'Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.white.withAlpha(179), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Evet, Sil',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await DatabaseService().deleteAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Tüm veriler silindi.',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ayarlar',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildSection(
            label: 'TANIMLAMA',
            children: [
              _buildThresholdTile(),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            label: 'GÖRÜNÜM',
            children: [
              _buildToggleTile(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF6C63FF),
                title: 'Koyu Tema',
                subtitle: _isDark ? 'Koyu mod aktif' : 'Açık mod aktif',
                value: _isDark,
                onChanged: (v) async {
                  setState(() => _isDark = v);
                  await AppSettings.setDarkMode(v);
                },
              ),
              _buildDivider(),
              _buildLanguageTile(),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            label: 'İZİNLER',
            children: [
              _buildPermissionTile(),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            label: 'YASAL',
            children: [
              _buildNavTile(
                icon: Icons.privacy_tip_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Gizlilik Politikası',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              _buildDivider(),
              _buildNavTile(
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF7C3AED),
                title: 'Kullanım Koşulları',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            label: 'VERİ YÖNETİMİ',
            children: [
              _buildDeleteTile(),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            label: 'UYGULAMA',
            children: [
              _buildInfoTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.white38,
                  title: 'Versiyon',
                  value: '1.0.0'),
              _buildDivider(),
              _buildInfoTile(
                  icon: Icons.back_hand_rounded,
                  iconColor: Colors.white38,
                  title: 'Uygulama',
                  value: 'PalmPay'),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(77),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(13)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThresholdTile() {
    final pct = (_threshold * 100).round();
    String sensitivity;
    Color sensitivityColor;
    if (_threshold >= 0.80) {
      sensitivity = 'Çok Yüksek';
      sensitivityColor = Colors.green;
    } else if (_threshold >= 0.70) {
      sensitivity = 'Yüksek';
      sensitivityColor = const Color(0xFF10B981);
    } else if (_threshold >= 0.60) {
      sensitivity = 'Orta';
      sensitivityColor = const Color(0xFF6C63FF);
    } else {
      sensitivity = 'Düşük';
      sensitivityColor = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded,
                    color: Color(0xFF6C63FF), size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avuç Tanıma Eşiği',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    Text('Eşleşme hassasiyeti',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sensitivityColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pct% · $sensitivity',
                  style: TextStyle(
                      color: sensitivityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF6C63FF),
              inactiveTrackColor: Colors.white.withAlpha(26),
              thumbColor: const Color(0xFF6C63FF),
              overlayColor: const Color(0xFF6C63FF).withAlpha(38),
              trackHeight: 4,
            ),
            child: Slider(
              value: _threshold,
              min: 0.40,
              max: 0.95,
              divisions: 11,
              onChanged: (v) => setState(() => _threshold = v),
              onChangeEnd: (v) => AppSettings.setThreshold(v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Geniş (0.40)',
                  style: TextStyle(
                      color: Colors.white.withAlpha(77), fontSize: 10)),
              Text('Hassas (0.95)',
                  style: TextStyle(
                      color: Colors.white.withAlpha(77), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.language_rounded,
                color: Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dil / Language',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                Text('Şimdilik sadece toggle',
                    style:
                        TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Row(
            children: ['tr', 'en'].map((lang) {
              final selected = _language == lang;
              return GestureDetector(
                onTap: () async {
                  setState(() => _language = lang);
                  await AppSettings.setLanguage(lang);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF3B82F6).withAlpha(51)
                        : Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF3B82F6)
                          : Colors.white.withAlpha(26),
                    ),
                  ),
                  child: Text(
                    lang.toUpperCase(),
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF3B82F6)
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (_cameraGranted
                      ? const Color(0xFF059669)
                      : Colors.red)
                  .withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              color: _cameraGranted
                  ? const Color(0xFF059669)
                  : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kamera',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                Text(
                  _cameraGranted ? 'İzin verildi' : 'İzin verilmedi',
                  style: TextStyle(
                    color: _cameraGranted
                        ? const Color(0xFF059669)
                        : Colors.red.shade300,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!_cameraGranted)
            TextButton(
              onPressed: () async {
                await openAppSettings();
                await _checkPermission();
              },
              child: const Text('Ayarlar',
                  style: TextStyle(
                      color: Color(0xFF7C3AED), fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withAlpha(77)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Text(value,
              style: TextStyle(
                  color: Colors.white.withAlpha(102), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDeleteTile() {
    return InkWell(
      onTap: _isDeleting ? null : _deleteAllData,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(38),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isDeleting
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                          color: Colors.red, strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever_rounded,
                      color: Colors.red, size: 20),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verilerimi Sil',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Text('Tüm biyometrik kayıtları siler',
                      style:
                          TextStyle(color: Colors.red, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 68,
      color: Colors.white.withAlpha(13),
    );
  }
}
