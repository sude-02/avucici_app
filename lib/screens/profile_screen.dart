import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_feedback.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _dbService = DatabaseService();
  late TextEditingController _nameController;
  late String _selectedHand;
  bool _isSaving = false;
  bool _hasChanges = false;

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String get _createdAt {
    final raw = widget.user['created_at'] as String? ?? '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '—';
    }
  }

  bool get _hasPinSet => (widget.user['pin_hash'] as String?) != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.user['name'] as String? ?? '');
    _selectedHand = (widget.user['hand'] as String?) ?? 'sağ';
    _nameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final changed = _nameController.text.trim() != widget.user['name'] ||
        _selectedHand != widget.user['hand'];
    if (changed != _hasChanges) setState(() => _hasChanges = changed);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('İsim boş bırakılamaz');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _dbService.updateUser(widget.user['id'] as int, name, _selectedHand);
      if (mounted) {
        _showSnack('Profil güncellendi', success: true);
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) _showSnack('Kayıt hatası: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (success) {
      AppFeedback.success(context, msg);
    } else {
      AppFeedback.error(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: Theme.of(context).appBarTheme.iconTheme?.color),
          onPressed: () => Navigator.pop(context, _hasChanges),
        ),
        title: const Text('Profil'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Kaydet',
                  style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _buildAvatar(context),
            const SizedBox(height: 32),
            _buildNameField(context),
            const SizedBox(height: 20),
            _buildHandSelector(context),
            const SizedBox(height: 24),
            _buildInfoCards(context),
            const SizedBox(height: 32),
            if (_hasChanges) _buildSaveButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.card(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF6C63FF), width: 2),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: Color(0xFF6C63FF), size: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Kayıt: $_createdAt',
          style: TextStyle(color: AppTheme.textMuted(context), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AD SOYAD',
          style: TextStyle(
            color: AppTheme.textMuted(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.card(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasChanges
                  ? const Color(0xFF6C63FF).withOpacity(0.5)
                  : AppTheme.border(context),
            ),
          ),
          child: TextField(
            controller: _nameController,
            style: TextStyle(
                color: AppTheme.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w500),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'İsim Soyisim',
              hintStyle: TextStyle(color: AppTheme.textMuted(context)),
              prefixIcon: const Icon(Icons.person_rounded,
                  color: Color(0xFF6C63FF), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHandSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'KAYITLI EL',
          style: TextStyle(
            color: AppTheme.textMuted(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _handOption(context, 'sol', 'Sol El', flipIcon: true)),
            const SizedBox(width: 12),
            Expanded(child: _handOption(context, 'sağ', 'Sağ El')),
          ],
        ),
      ],
    );
  }

  Widget _handOption(BuildContext context, String hand, String label,
      {bool flipIcon = false}) {
    final selected = _selectedHand == hand;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedHand = hand);
        _onChanged();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF6C63FF).withOpacity(0.12)
              : AppTheme.card(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF6C63FF)
                : AppTheme.border(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: flipIcon
                  ? (Matrix4.identity()..scale(-1.0, 1.0))
                  : Matrix4.identity(),
              child: Icon(
                Icons.back_hand_rounded,
                color: selected
                    ? const Color(0xFF6C63FF)
                    : AppTheme.textMuted(context),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppTheme.text(context) : AppTheme.textMuted(context),
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          _infoRow(context,
            icon: Icons.fingerprint_rounded,
            iconColor: const Color(0xFF6C63FF),
            label: 'Biyometrik Veri',
            value: 'Kayıtlı',
          ),
          Divider(height: 1, color: AppTheme.border(context), indent: 56),
          _infoRow(context,
            icon: Icons.lock_rounded,
            iconColor: _hasPinSet ? const Color(0xFF10B981) : Colors.orange,
            label: 'PIN Durumu',
            value: _hasPinSet ? 'Tanımlı' : 'Tanımlı değil',
            valueColor: _hasPinSet ? const Color(0xFF10B981) : Colors.orange,
          ),
          Divider(height: 1, color: AppTheme.border(context), indent: 56),
          _infoRow(context,
            icon: Icons.calendar_today_rounded,
            iconColor: AppTheme.textMuted(context),
            label: 'Kayıt Tarihi',
            value: _createdAt,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(color: AppTheme.text(context), fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textSecondary(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return AppButton(
      label: 'Değişiklikleri Kaydet',
      icon: Icons.save_rounded,
      onPressed: _isSaving ? null : _save,
      isLoading: _isSaving,
    );
  }
}
