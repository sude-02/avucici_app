import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/app_settings.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_feedback.dart';
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
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Verileri Sil',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Tüm kayıtlı kullanıcılar ve biyometrik veriler kalıcı olarak silinecek. '
          'Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
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
      AppFeedback.success(context, 'Tüm veriler başarıyla silindi.');
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: Theme.of(context).appBarTheme.iconTheme?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _buildSection(
            context,
            label: 'GÖRÜNÜM',
            children: [_buildThemeTile()],
          ),
          const SizedBox(height: 8),
          _buildSection(
            context,
            label: 'TANIMLAMA',
            children: [_buildThresholdTile(context)],
          ),
          const SizedBox(height: 8),
          _buildSection(
            context,
            label: 'İZİNLER',
            children: [_buildPermissionTile(context)],
          ),
          const SizedBox(height: 8),
          _buildSection(
            context,
            label: 'YASAL',
            children: [
              _buildNavTile(
                context,
                icon: Icons.privacy_tip_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: 'Gizlilik Politikası',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              _buildDivider(context),
              _buildNavTile(
                context,
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
            context,
            label: 'VERİ YÖNETİMİ',
            children: [_buildDeleteTile(context)],
          ),
          const SizedBox(height: 8),
          _buildSection(
            context,
            label: 'UYGULAMA',
            children: [
              _buildInfoTile(context,
                  icon: Icons.info_outline_rounded,
                  iconColor: AppTheme.textMuted(context),
                  title: 'Versiyon',
                  value: '1.0.0'),
              _buildDivider(context),
              _buildInfoTile(context,
                  icon: Icons.back_hand_rounded,
                  iconColor: AppTheme.textMuted(context),
                  title: 'Uygulama',
                  value: 'PalmPay'),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted(context),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThemeTile() {
    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        final isDark = themeProvider.isDark;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: const Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Koyu Tema',
                        style: TextStyle(
                            color: AppTheme.text(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    Text(
                      isDark ? 'Koyu mod aktif' : 'Açık mod aktif',
                      style: TextStyle(
                          color: AppTheme.textMuted(context), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: const Color(0xFF7C3AED),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThresholdTile(BuildContext context) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avuç Tanıma Eşiği',
                        style: TextStyle(
                            color: AppTheme.text(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    Text('Eşleşme hassasiyeti',
                        style: TextStyle(
                            color: AppTheme.textMuted(context), fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              inactiveTrackColor: AppTheme.border(context),
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
                      color: AppTheme.textMuted(context), fontSize: 10)),
              Text('Hassas (0.95)',
                  style: TextStyle(
                      color: AppTheme.textMuted(context), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: (_cameraGranted ? const Color(0xFF059669) : Colors.red)
                  .withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.camera_alt_rounded,
              color: _cameraGranted ? const Color(0xFF059669) : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kamera',
                    style: TextStyle(
                        color: AppTheme.text(context),
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

  Widget _buildNavTile(BuildContext context, {
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
              width: 38, height: 38,
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
                style: TextStyle(
                    color: AppTheme.text(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, {
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
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.border(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: AppTheme.text(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(
                  color: AppTheme.textSecondary(context), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDeleteTile(BuildContext context) {
    return InkWell(
      onTap: _isDeleting ? null : _deleteAllData,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
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
                      style: TextStyle(color: Colors.red, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, indent: 68, color: AppTheme.border(context));
  }
}
