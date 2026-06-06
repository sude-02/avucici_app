import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer.dart';

class PinScreen extends StatefulWidget {
  final double amount;

  const PinScreen({super.key, required this.amount});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic>? _selectedUser;
  String _pin = '';
  bool _isVerifying = false;
  bool _hasError = false;
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _dbService.getAllUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    }
  }

  void _tapPin(String key) {
    if (_isVerifying) return;
    if (_hasError) setState(() => _hasError = false);
    HapticFeedback.selectionClick();
    setState(() {
      if (key == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
        return;
      }
      if (_pin.length < 6) _pin += key;
    });
    if (_pin.length == 6) _verify();
  }

  Future<void> _verify() async {
    if (_selectedUser == null || _isVerifying) return;
    setState(() => _isVerifying = true);

    final userId = _selectedUser!['id'] as int;
    final valid = await _dbService.verifyUserPin(userId, _pin);

    if (!mounted) return;

    if (valid) {
      HapticFeedback.heavyImpact();
      await _dbService.saveTransaction(
        userName: _selectedUser!['name'] as String,
        userId: userId,
        amount: widget.amount,
        isSuccess: true,
        hand: (_selectedUser!['hand'] as String?) ?? '—',
      );
      _showSuccessSheet();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _pin = '';
        _hasError = true;
        _isVerifying = false;
      });
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF10B981), size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Kimlik Doğrulandı',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              _selectedUser!['name'] as String,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('PIN ile doğrulandı',
                style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '₺${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text('Ödeme Onaylandı',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // sheet
                Navigator.pop(context); // pin screen
                Navigator.pop(context); // scan screen
              },
              child: const Text('Kapat',
                  style: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showForgotDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('PIN Unutuldu', style: TextStyle(color: Colors.white)),
        content: const Text(
          'PIN\'inizi unuttuysanız lütfen yönetici ile iletişime geçin.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam',
                style: TextStyle(color: Color(0xFF6C63FF))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('PIN ile Doğrula',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child:
            _selectedUser == null ? _buildUserSelect() : _buildPinEntry(),
      ),
    );
  }

  Widget _buildUserSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text('Hesabınızı seçin',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text('Ödeme tutarı: ₺${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
        if (_isLoadingUsers)
          const Expanded(child: ShimmerUserListView(count: 3))
        else if (_users.isEmpty)
          const Expanded(
            child: EmptyStateWidget(
              icon: Icons.lock_open_rounded,
              iconColor: Color(0xFF6C63FF),
              title: 'Kayıtlı kullanıcı yok',
              subtitle: 'PIN doğrulaması için önce\nkayıt oluşturun.',
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _users.length,
              itemBuilder: (_, i) {
                final user = _users[i];
                final hand = (user['hand'] as String?) ?? 'sağ';
                final hasPin = (user['pin_hash'] as String?) != null;
                return Card(
                  color: const Color(0xFF1A1A2E),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side:
                        BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF6C63FF).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Color(0xFF6C63FF), size: 22),
                    ),
                    title: Text(user['name'] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${hand == 'sağ' ? 'Sağ' : 'Sol'} el${hasPin ? '' : ' • PIN tanımlı değil'}',
                      style: TextStyle(
                          color: hasPin
                              ? Colors.white.withOpacity(0.4)
                              : Colors.orange.withOpacity(0.7),
                          fontSize: 12),
                    ),
                    trailing: hasPin
                        ? const Icon(Icons.chevron_right_rounded,
                            color: Colors.white38)
                        : const Icon(Icons.lock_open_rounded,
                            color: Colors.orange, size: 18),
                    onTap: hasPin
                        ? () => setState(() => _selectedUser = user)
                        : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPinEntry() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          _selectedUser!['name'] as String,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '₺${widget.amount.toStringAsFixed(2)}',
          style: const TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 40),
        const Text('6 haneli PIN girin',
            style: TextStyle(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 24),
        _buildDots(),
        AnimatedOpacity(
          opacity: _hasError ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('Yanlış PIN, tekrar deneyin',
                style: TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ),
        if (_isVerifying)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child:
                CircularProgressIndicator(color: Color(0xFF6C63FF)),
          ),
        const Spacer(),
        _buildNumpad(),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _showForgotDialog,
          child: const Text('PIN\'i unuttum',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => setState(() {
            _selectedUser = null;
            _pin = '';
            _hasError = false;
          }),
          icon: const Icon(Icons.swap_horiz_rounded,
              color: Colors.white38, size: 16),
          label: const Text('Hesabı değiştir',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final filled = i < _pin.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? (_hasError ? Colors.red : const Color(0xFF6C63FF))
                : Colors.transparent,
            border: Border.all(
              color: filled
                  ? (_hasError
                      ? Colors.red
                      : const Color(0xFF6C63FF))
                  : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: key.isEmpty
                        ? const SizedBox()
                        : _PinKey(
                            label: key,
                            onTap: () => _tapPin(key),
                            disabled: _isVerifying,
                          ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  const _PinKey(
      {required this.label, required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF6C63FF).withAlpha(51),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: isBackspace
                ? Colors.red.withAlpha(20)
                : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBackspace
                  ? Colors.red.withAlpha(40)
                  : Colors.white.withAlpha(13),
            ),
          ),
          child: Center(
            child: isBackspace
                ? Icon(Icons.backspace_outlined,
                    color: Colors.red.withAlpha(200), size: 22)
                : Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
