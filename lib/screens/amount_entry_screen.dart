import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'scan_screen.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';

class AmountEntryScreen extends StatefulWidget {
  const AmountEntryScreen({super.key});

  @override
  State<AmountEntryScreen> createState() => _AmountEntryScreenState();
}

class _AmountEntryScreenState extends State<AmountEntryScreen> {
  String _input = '';

  double? get _parsed => _input.isEmpty ? null : double.tryParse(_input);
  bool get _isValid => (_parsed ?? 0) > 0;

  String get _displayText {
    if (_input.isEmpty) return '0';
    final base = _parsed?.toStringAsFixed(
            _input.contains('.') ? (_input.split('.').last.length) : 0) ??
        _input;
    return _input.endsWith('.') ? '$base.' : base;
  }

  void _tap(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == '⌫') {
        if (_input.isNotEmpty) _input = _input.substring(0, _input.length - 1);
        return;
      }
      if (key == '.') {
        if (_input.contains('.')) return;
        _input = _input.isEmpty ? '0.' : '$_input.';
        return;
      }
      final dotIndex = _input.indexOf('.');
      if (dotIndex != -1 && (_input.length - dotIndex) > 2) return;
      if (_input == '0') {
        _input = key;
      } else {
        _input += key;
      }
    });
  }

  void _proceed() {
    if (!_isValid) return;
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      AppRoutes.push(ScanScreen(amount: _parsed!)),
    );
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
        title: const Text('Ödeme Tutarı'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDisplay(context),
            const Spacer(),
            _buildNumpad(context),
            const SizedBox(height: 16),
            _buildProceedButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
      child: Column(
        children: [
          Text(
            'Ne kadar ödemek istiyorsunuz?',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '₺$_displayText',
              key: ValueKey(_displayText),
              style: TextStyle(
                color: _isValid
                    ? AppTheme.text(context)
                    : AppTheme.textMuted(context),
                fontSize: _displayText.length > 8 ? 44 : 56,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _isValid ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              '0\'dan büyük bir tutar girin',
              style: TextStyle(color: Colors.red.withAlpha(179), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _NumpadKey(label: key, onTap: () => _tap(key)),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProceedButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isValid
                ? const Color(0xFF7C3AED)
                : AppTheme.border(context),
            foregroundColor: _isValid
                ? Colors.white
                : AppTheme.textMuted(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          onPressed: _isValid ? _proceed : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isValid ? Icons.sensors_rounded : Icons.lock_rounded,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _isValid
                    ? 'Avucu Okut  ₺${_parsed!.toStringAsFixed(2)}'
                    : 'Tutar Girin',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumpadKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';
    final isDot = label == '.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: const Color(0xFF7C3AED).withAlpha(51),
        highlightColor: const Color(0xFF7C3AED).withAlpha(26),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: isBackspace
                ? Colors.red.withAlpha(20)
                : AppTheme.card(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBackspace
                  ? Colors.red.withAlpha(51)
                  : AppTheme.border(context),
            ),
          ),
          child: Center(
            child: isBackspace
                ? Icon(Icons.backspace_outlined,
                    color: Colors.red.withAlpha(204), size: 22)
                : Text(
                    label,
                    style: TextStyle(
                      color: isDot
                          ? AppTheme.textSecondary(context)
                          : AppTheme.text(context),
                      fontSize: isDot ? 28 : 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
