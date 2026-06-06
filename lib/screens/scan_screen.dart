import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';
import '../widgets/result_animation.dart';
import 'pin_screen.dart';

class ScanScreen extends StatefulWidget {
  final double amount;

  const ScanScreen({super.key, required this.amount});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with TickerProviderStateMixin {
  final CameraService _cameraService = CameraService();
  final DatabaseService _dbService = DatabaseService();

  bool _isReady = false;
  bool _isProcessing = false;
  String _selectedHand = 'sağ';
  String _statusText = 'Hangi elinizi kullanacaksınız?';
  Color _statusColor = Colors.white70;
  int _failCount = 0;
  bool _showFailureOverlay = false;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.linear),
    );
    _initCamera();
  }

  Future<void> _initCamera() async {
    await _cameraService.initialize();
    if (mounted) setState(() => _isReady = true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _performScan() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusText = 'Taranıyor...';
      _statusColor = const Color(0xFF6C63FF);
    });
    try {
      final result = await _cameraService.captureAndExtractEmbedding();
      if (result == null) {
        _updateStatus('El algılanamadı, tekrar dene', Colors.orange);
        return;
      }
      final users = await _dbService.getAllUsers();
      if (users.isEmpty) {
        _updateStatus('Kayıtlı kullanıcı yok', Colors.orange);
        return;
      }
      final match = await _dbService.findBestMatch(
          result.embedding, _selectedHand);
      if (match != null) {
        await _dbService.saveTransaction(
          userName: match['name'] as String,
          userId: match['id'] as int?,
          amount: widget.amount,
          isSuccess: true,
          hand: _selectedHand,
          matchScore: match['score'] as double?,
        );
        HapticFeedback.heavyImpact();
        unawaited(SoundService().success());
        _showSuccessSheet(match['name'], match['score'], widget.amount);
      } else {
        await _dbService.saveTransaction(
          userName: '—',
          isSuccess: false,
          hand: _selectedHand,
        );
        HapticFeedback.heavyImpact();
        unawaited(SoundService().error());
        setState(() {
          _failCount++;
          _showFailureOverlay = true;
        });
        _updateStatus(
          '${_selectedHand == 'sağ' ? 'Sağ' : 'Sol'} el ile kayıtlı kullanıcı bulunamadı',
          Colors.red,
        );
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showFailureOverlay = false);
        });
      }
    } catch (e) {
      _updateStatus('Hata: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _updateStatus(String text, Color color) {
    if (mounted) setState(() { _statusText = text; _statusColor = color; });
  }

  void _showSuccessSheet(String name, double score, double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
            const SizedBox(
              width: 80,
              height: 80,
              child: AnimatedCheck(size: 80),
            ),
            const SizedBox(height: 16),
            const Text('Kimlik Doğrulandı',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Text(name,
                style: const TextStyle(color: Colors.white,
                    fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Eşleşme: %${(score * 100).toStringAsFixed(1)}',
                style: const TextStyle(
                    color: Color(0xFF10B981), fontSize: 16)),
            const SizedBox(height: 4),
            Text('₺${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
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
                      style: TextStyle(color: Colors.white,
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(
                  '${_selectedHand == 'sağ' ? 'Sağ' : 'Sol'} avucunu kareye tut',
                  Colors.white70,
                );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isReady ? _buildCameraView() : _buildLoading(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6C63FF)),
          SizedBox(height: 16),
          Text('Kamera başlatılıyor...',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    final controller = _cameraService.controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize!.height,
              height: controller.value.previewSize!.width,
              child: CameraPreview(controller),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _scanLineAnimation,
          builder: (_, __) => CustomPaint(
            painter: _ScanOverlayPainter(
              scanProgress: _isProcessing ? _scanLineAnimation.value : null,
              isProcessing: _isProcessing,
            ),
          ),
        ),
        if (_showFailureOverlay)
          const Positioned.fill(child: FailureOverlay()),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text('Ödeme Yap',
                    style: TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                StatefulBuilder(
                  builder: (_, setS) => IconButton(
                    icon: Icon(
                      _cameraService.flashEnabled
                          ? Icons.flash_on : Icons.flash_off,
                      color: _cameraService.flashEnabled
                          ? Colors.amber : Colors.white54,
                    ),
                    onPressed: () async {
                      await _cameraService.toggleFlash();
                      setS(() {});
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_cameraService.flashEnabled)
          Positioned(
            top: 90, left: 24, right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Daha iyi sonuç için flash açmanız önerilir',
                      style: TextStyle(
                          color: Colors.amber.withOpacity(0.9),
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: _buildBottomPanel(),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black, Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // El seçimi
          _buildHandSelector(),
          const SizedBox(height: 12),
          // Durum
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusText,
                    key: ValueKey(_statusText),
                    style: TextStyle(color: _statusColor,
                        fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Avucunu aç • Kareye 15-20 cm uzaklıkta tut',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProcessing
                    ? const Color(0xFF1A1A2E)
                    : const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              onPressed: _isProcessing ? null : _performScan,
              child: _isProcessing
                  ? const CircularProgressIndicator(
                      color: Color(0xFF6C63FF))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint,
                            color: Colors.white, size: 26),
                        const SizedBox(width: 10),
                        Text(
                          '${_selectedHand == 'sağ' ? 'Sağ' : 'Sol'} Avucu Tara',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
          if (_failCount >= 3) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFBBF24),
                  side: const BorderSide(color: Color(0xFFFBBF24), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.pin_rounded, size: 20),
                label: const Text(
                  'PIN ile Devam Et',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PinScreen(amount: widget.amount),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHandSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedHand = 'sol';
              _statusText = 'Sol avucunu kareye tut';
              _statusColor = Colors.white70;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedHand == 'sol'
                    ? const Color(0xFF6C63FF).withOpacity(0.25)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedHand == 'sol'
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.15),
                  width: _selectedHand == 'sol' ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: Icon(
                      Icons.back_hand_rounded,
                      color: _selectedHand == 'sol'
                          ? const Color(0xFF6C63FF)
                          : Colors.white38,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sol El',
                    style: TextStyle(
                      color: _selectedHand == 'sol'
                          ? Colors.white : Colors.white38,
                      fontSize: 13,
                      fontWeight: _selectedHand == 'sol'
                          ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _selectedHand = 'sağ';
              _statusText = 'Sağ avucunu kareye tut';
              _statusColor = Colors.white70;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedHand == 'sağ'
                    ? const Color(0xFF6C63FF).withOpacity(0.25)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedHand == 'sağ'
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.15),
                  width: _selectedHand == 'sağ' ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.back_hand_rounded,
                    color: _selectedHand == 'sağ'
                        ? const Color(0xFF6C63FF)
                        : Colors.white38,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sağ El',
                    style: TextStyle(
                      color: _selectedHand == 'sağ'
                          ? Colors.white : Colors.white38,
                      fontSize: 13,
                      fontWeight: _selectedHand == 'sağ'
                          ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double? scanProgress;
  final bool isProcessing;

  _ScanOverlayPainter({this.scanProgress, required this.isProcessing});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final halfSide = size.width * 0.38;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy),
          width: halfSide * 2, height: halfSide * 2),
      const Radius.circular(16),
    );

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutPath = Path()..addRRect(rect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutPath),
      Paint()..color = Colors.black.withOpacity(0.6),
    );

    final frameColor = isProcessing
        ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.85);
    final cornerLen = halfSide * 0.22;
    final paint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final l = cx - halfSide;
    final r = cx + halfSide;
    final t = cy - halfSide;
    final b = cy + halfSide;

    canvas.drawLine(Offset(l, t + cornerLen), Offset(l, t), paint);
    canvas.drawLine(Offset(l, t), Offset(l + cornerLen, t), paint);
    canvas.drawLine(Offset(r - cornerLen, t), Offset(r, t), paint);
    canvas.drawLine(Offset(r, t), Offset(r, t + cornerLen), paint);
    canvas.drawLine(Offset(l, b - cornerLen), Offset(l, b), paint);
    canvas.drawLine(Offset(l, b), Offset(l + cornerLen, b), paint);
    canvas.drawLine(Offset(r - cornerLen, b), Offset(r, b), paint);
    canvas.drawLine(Offset(r, b), Offset(r, b - cornerLen), paint);

    if (scanProgress != null) {
      final scanY = t + (halfSide * 2 * scanProgress!);
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.transparent,
            const Color(0xFF6C63FF).withOpacity(0.9), Colors.transparent],
        ).createShader(Rect.fromLTWH(l, scanY, halfSide * 2, 2));
      canvas.save();
      canvas.clipPath(cutPath);
      canvas.drawRect(
          Rect.fromLTWH(l, scanY - 1, halfSide * 2, 2), scanPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) =>
      old.scanProgress != scanProgress || old.isProcessing != isProcessing;
}