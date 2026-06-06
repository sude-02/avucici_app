import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final CameraService _cameraService = CameraService();
  final DatabaseService _dbService = DatabaseService();

  bool _isReady = false;
  bool _isCapturing = false;
  bool _isSaving = false;
  int _capturedCount = 0;
  final int _requiredCount = 5;
  List<List<double>> _embeddings = [];
  List<List<double>> _flippedEmbeddings = [];
  List<String> _imagePaths = [];
  String _selectedHand = 'sağ';

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  final List<Map<String, dynamic>> _angleGuides = [
    {'label': 'Düz', 'handAngle': 0.0, 'description': 'Avucunu düz tut'},
    {'label': 'Sol', 'handAngle': -0.3, 'description': 'Bileğini hafif sola döndür'},
    {'label': 'Sağ', 'handAngle': 0.3, 'description': 'Bileğini hafif sağa döndür'},
    {'label': 'Yakın', 'handAngle': 0.0, 'description': 'Telefonu parmaklara yaklaştır'},
    {'label': 'Uzak', 'handAngle': 0.0, 'description': 'Telefonu biraz uzaklaştır'},
  ];

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
    _nameController.dispose();
    _scanLineController.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _captureEmbedding() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Önce isim girin', isError: true);
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final result = await _cameraService.captureAndExtractEmbedding();
      if (result != null) {
        _embeddings.add(result.embedding);
        _flippedEmbeddings.add(result.flippedEmbedding);
        _imagePaths.add(result.imagePath);
        if (_capturedCount < _requiredCount) {
          _angleGuides[_capturedCount]['done'] = true;
        }
        setState(() => _capturedCount++);
        if (_capturedCount >= _requiredCount) await _showPinSetupSheet();
      } else {
        _showSnack('El algılanamadı, tekrar deneyin', isError: true);
      }
    } catch (e) {
      _showSnack('Hata: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _showPinSetupSheet() async {
    String step1Pin = '';
    String step2Pin = '';
    int step = 1;
    bool hasError = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (_, setSheet) {
          void tapKey(String key) {
            HapticFeedback.selectionClick();
            setSheet(() {
              hasError = false;
              final current = step == 1 ? step1Pin : step2Pin;
              if (key == '⌫') {
                final trimmed = current.isEmpty
                    ? current
                    : current.substring(0, current.length - 1);
                if (step == 1) step1Pin = trimmed; else step2Pin = trimmed;
                return;
              }
              if (current.length >= 6) return;
              final next = current + key;
              if (step == 1) {
                step1Pin = next;
                if (step1Pin.length == 6) step = 2;
              } else {
                step2Pin = next;
                if (step2Pin.length == 6) {
                  if (step1Pin == step2Pin) {
                    Navigator.pop(sheetCtx, step1Pin);
                  } else {
                    step2Pin = '';
                    hasError = true;
                  }
                }
              }
            });
          }

          final currentPin = step == 1 ? step1Pin : step2Pin;
          const rows = [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', '⌫'],
          ];

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Icon(Icons.lock_rounded,
                      color: Color(0xFF6C63FF), size: 32),
                  const SizedBox(height: 12),
                  Text(
                    step == 1 ? 'PIN Oluşturun' : 'PIN\'i Onaylayın',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step == 1
                        ? '6 haneli güvenlik PIN\'inizi belirleyin'
                        : 'Aynı PIN\'i tekrar girin',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final filled = i < currentPin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? (hasError
                                  ? Colors.red
                                  : const Color(0xFF6C63FF))
                              : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? (hasError
                                    ? Colors.red
                                    : const Color(0xFF6C63FF))
                                : Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  AnimatedOpacity(
                    opacity: hasError ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text('PIN\'ler eşleşmedi, tekrar deneyin',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...rows.map((row) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: row.map((key) {
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: key.isEmpty
                                  ? const SizedBox()
                                  : Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => tapKey(key),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: key == '⌫'
                                                ? Colors.red.withAlpha(20)
                                                : Colors.white.withAlpha(10),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: key == '⌫'
                                                  ? Colors.red.withAlpha(40)
                                                  : Colors.white.withAlpha(13),
                                            ),
                                          ),
                                          child: Center(
                                            child: key == '⌫'
                                                ? Icon(
                                                    Icons.backspace_outlined,
                                                    color: Colors.red
                                                        .withAlpha(200),
                                                    size: 20)
                                                : Text(key,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w500)),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        });
      },
    ).then((confirmedPin) async {
      if (confirmedPin is String) {
        await _saveUserWithPin(confirmedPin);
      }
    });
  }

  Future<void> _saveUserWithPin(String pin) async {
    setState(() => _isSaving = true);
    try {
      final userId = await _dbService.saveUser(
        _nameController.text.trim(),
        _embeddings,
        _flippedEmbeddings,
        _imagePaths,
        _selectedHand,
      );
      await _dbService.savePin(userId, pin);
      if (mounted) _showSuccessDialog();
    } catch (e) {
      _showSnack('Kayıt hatası: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF10B981), size: 64),
            const SizedBox(height: 16),
            Text('${_nameController.text} kayıt edildi!',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              '${_selectedHand == 'sağ' ? 'Sağ' : 'Sol'} el kaydedildi',
              style: TextStyle(
                  color: const Color(0xFF6C63FF).withOpacity(0.8),
                  fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text('$_requiredCount örnek başarıyla alındı.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Tamam',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isReady ? _buildBody() : _buildLoading(),
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

  Widget _buildBody() {
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
            painter: _SquarePalmPainter(
              scanProgress: _isCapturing ? _scanLineAnimation.value : null,
              isCapturing: _isCapturing,
              capturedCount: _capturedCount,
              requiredCount: _requiredCount,
              handAngle: _capturedCount < _requiredCount
                  ? (_angleGuides[_capturedCount]['handAngle'] as double)
                  : 0.0,
            ),
          ),
        ),
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
                const Text('Yeni Kayıt',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                StatefulBuilder(
                  builder: (_, setS) => IconButton(
                    icon: Icon(
                      _cameraService.flashEnabled
                          ? Icons.flash_on
                          : Icons.flash_off,
                      color: _cameraService.flashEnabled
                          ? Colors.amber
                          : Colors.white54,
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
        if (!_cameraService.flashEnabled && _capturedCount == 0)
          Positioned(
            top: 90,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          color: Colors.amber.withOpacity(0.9), fontSize: 12),
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
    final isDone = _capturedCount >= _requiredCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
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
          // El seçimi — sadece henüz tarama başlamadıysa göster
          if (_capturedCount == 0) _buildHandSelector(),
          if (_capturedCount == 0) const SizedBox(height: 12),
          _buildAngleGuides(),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.4)),
            ),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ad Soyad',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: const Icon(Icons.person_rounded,
                    color: Color(0xFF6C63FF)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              _requiredCount,
              (i) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < _capturedCount
                        ? const Color(0xFF10B981)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _capturedCount == 0
                ? '${_selectedHand == 'sağ' ? 'Sağ' : 'Sol'} avucunu kareye tut ve butona bas'
                : _capturedCount < _requiredCount
                    ? 'Sıradaki açıyla tara • ${_requiredCount - _capturedCount} kaldı'
                    : 'Tüm örnekler alındı, kaydediliyor...',
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone
                    ? const Color(0xFF10B981)
                    : const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed:
                  isDone || _isCapturing || _isSaving ? null : _captureEmbedding,
              child: _isCapturing || _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            isDone
                                ? Icons.check_rounded
                                : Icons.camera_alt_rounded,
                            color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          isDone
                              ? 'Kaydedildi!'
                              : 'Avucu Tara ($_capturedCount/$_requiredCount)',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedHand = 'sol'),
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
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: _selectedHand == 'sol'
                          ? FontWeight.bold
                          : FontWeight.normal,
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
            onTap: () => setState(() => _selectedHand = 'sağ'),
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
                          ? Colors.white
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight: _selectedHand == 'sağ'
                          ? FontWeight.bold
                          : FontWeight.normal,
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

  Widget _buildAngleGuides() {
    return Column(
      children: [
        if (_capturedCount < _requiredCount)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _angleGuides[_capturedCount]['description'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_requiredCount, (i) {
            final guide = _angleGuides[i];
            final isDone = i < _capturedCount;
            final isCurrent = i == _capturedCount;
            return Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : isCurrent
                            ? const Color(0xFF6C63FF).withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF10B981)
                          : isCurrent
                              ? const Color(0xFF6C63FF)
                              : Colors.white.withOpacity(0.15),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFF10B981), size: 22)
                      : Transform.rotate(
                          angle: guide['handAngle'] as double,
                          child: Icon(
                            Icons.back_hand_rounded,
                            color: isCurrent
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withOpacity(0.3),
                            size: 22,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  guide['label'] as String,
                  style: TextStyle(
                    color: isDone
                        ? const Color(0xFF10B981)
                        : isCurrent
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                    fontSize: 9,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _SquarePalmPainter extends CustomPainter {
  final double? scanProgress;
  final bool isCapturing;
  final int capturedCount;
  final int requiredCount;
  final double handAngle;

  _SquarePalmPainter({
    this.scanProgress,
    required this.isCapturing,
    required this.capturedCount,
    required this.requiredCount,
    required this.handAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.40;
    final halfSide = size.width * 0.36;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, cy),
          width: halfSide * 2,
          height: halfSide * 2),
      const Radius.circular(16),
    );

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutPath = Path()..addRRect(rect);
    canvas.drawPath(
      Path.combine(PathOperation.difference, fullPath, cutPath),
      Paint()..color = Colors.black.withOpacity(0.6),
    );

    final progress = capturedCount / requiredCount;
    final frameColor = isCapturing
        ? const Color(0xFF6C63FF)
        : capturedCount > 0
            ? Color.lerp(const Color(0xFF6C63FF),
                const Color(0xFF10B981), progress)!
            : Colors.white.withOpacity(0.85);

    final cornerLen = halfSide * 0.25;
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
          colors: [
            Colors.transparent,
            const Color(0xFF6C63FF).withOpacity(0.9),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(l, scanY, halfSide * 2, 2));
      canvas.save();
      canvas.clipPath(cutPath);
      canvas.drawRect(
          Rect.fromLTWH(l, scanY - 1, halfSide * 2, 2), scanPaint);
      canvas.restore();
    }

    final tp = TextPainter(
      text: TextSpan(
        text: '$capturedCount/$requiredCount',
        style: TextStyle(
          color: capturedCount > 0
              ? const Color(0xFF10B981)
              : Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, b + 10));
  }

  @override
  bool shouldRepaint(_SquarePalmPainter old) =>
      old.scanProgress != scanProgress ||
      old.isCapturing != isCapturing ||
      old.capturedCount != capturedCount ||
      old.handAngle != handAngle;
}