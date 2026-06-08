import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';
import '../widgets/app_feedback.dart';

const _kAccent = Color(0xFF7C3AED);
const _kGreen = Color(0xFF10B981);

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
                  const Icon(Icons.lock_rounded, color: _kAccent, size: 32),
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
                              ? (hasError ? Colors.red : _kAccent)
                              : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? (hasError ? Colors.red : _kAccent)
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
                              padding: const EdgeInsets.symmetric(horizontal: 4),
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
                                                ? Icon(Icons.backspace_outlined,
                                                    color: Colors.red.withAlpha(200),
                                                    size: 20)
                                                : Text(key,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.w500)),
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
            const Icon(Icons.check_circle_rounded, color: _kGreen, size: 64),
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
                  color: _kAccent.withOpacity(0.8), fontSize: 13),
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
                  backgroundColor: _kGreen,
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
    if (isError) {
      AppFeedback.error(context, msg);
    } else {
      AppFeedback.success(context, msg);
    }
  }

  // ─── build ───────────────────────────────────────────────────────────────

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
          CircularProgressIndicator(color: _kAccent),
          SizedBox(height: 16),
          Text('Kamera başlatılıyor...',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  // Full-screen Stack: kamera + karartma overlay + UI katmanı
  Widget _buildBody() {
    final controller = _cameraService.controller!;
    final isDone = _capturedCount >= _requiredCount;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1 — Kamera tam ekran
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize!.height,
            height: controller.value.previewSize!.width,
            child: CameraPreview(controller),
          ),
        ),

        // 2 — Kare dışı karartma + köşe çizgileri + tarama çizgisi
        AnimatedBuilder(
          animation: _scanLineAnimation,
          builder: (_, __) => SizedBox.expand(
            child: CustomPaint(
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
        ),

        // 3 — UI katmanı: üst bar + alt kontrol paneli
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Üst gradient + başlık + flash
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.88),
                    Colors.transparent,
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopBar(),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      child: _cameraService.flashEnabled
                          ? const SizedBox.shrink()
                          : _buildFlashBanner(),
                    ),
                  ],
                ),
              ),
            ),

            // Kamera alanı serbest (Spacer kamerayı gösteriyor)
            const Spacer(),

            // Alt kontrol paneli (gradient + kaydırmasız)
            _buildBottomPanel(isDone),
          ],
        ),
      ],
    );
  }

  // ─── top bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    final flashOn = _cameraService.flashEnabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Avuç Kaydı',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Flash toggle — her zaman tam beyaz, görünür
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () async {
                await _cameraService.toggleFlash();
                setState(() {});
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: flashOn
                      ? Colors.amber.withOpacity(0.20)
                      : Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: flashOn
                        ? Colors.amber.withOpacity(0.60)
                        : Colors.white.withOpacity(0.30),
                    width: 1.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    key: ValueKey(flashOn),
                    color: flashOn ? Colors.amber : Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFlashBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.55)),
      ),
      child: const Row(
        children: [
          Icon(Icons.flash_off_rounded, color: Colors.amber, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Daha iyi bir sonuç için flash açmanız önerilir',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── bottom panel ─────────────────────────────────────────────────────────

  Widget _buildBottomPanel(bool isDone) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.94),
            Colors.black,
          ],
          stops: const [0.0, 0.20, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandSelector(),
              const SizedBox(height: 10),
              _buildNameInput(),
              const SizedBox(height: 10),
              _buildPoseChips(),
              const SizedBox(height: 10),
              _buildProgressSection(),
              const SizedBox(height: 12),
              _buildScanButton(isDone),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandSelector() {
    final locked = _capturedCount > 0;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          _handTab('Sol El', 'sol', locked, flipIcon: true),
          _handTab('Sağ El', 'sağ', locked, flipIcon: false),
        ],
      ),
    );
  }

  Widget _handTab(String label, String value, bool locked,
      {required bool flipIcon}) {
    final selected = _selectedHand == value;
    return Expanded(
      child: GestureDetector(
        onTap: locked ? null : () => setState(() => _selectedHand = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? _kAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
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
                  color: selected ? Colors.white : Colors.white38,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Ad Soyad',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.32)),
          prefixIcon:
              const Icon(Icons.person_rounded, color: _kAccent, size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPoseChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_capturedCount < _requiredCount)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              _angleGuides[_capturedCount]['description'] as String,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 12),
            ),
          ),
        Row(
          children: List.generate(_angleGuides.length, (i) {
            final guide = _angleGuides[i];
            final isDone = i < _capturedCount;
            final isCurrent =
                i == _capturedCount && _capturedCount < _requiredCount;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDone
                      ? _kGreen.withOpacity(0.22)
                      : isCurrent
                          ? _kAccent
                          : Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDone
                        ? _kGreen.withOpacity(0.55)
                        : isCurrent
                            ? _kAccent
                            : Colors.white.withOpacity(0.16),
                    width: isCurrent ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDone)
                      const Icon(Icons.check_rounded, color: _kGreen, size: 16)
                    else
                      Transform.rotate(
                        angle: guide['handAngle'] as double,
                        child: Icon(
                          Icons.back_hand_rounded,
                          color: isCurrent ? Colors.white : Colors.white30,
                          size: 16,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      guide['label'] as String,
                      style: TextStyle(
                        color: isDone
                            ? _kGreen
                            : isCurrent
                                ? Colors.white
                                : Colors.white38,
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Row(
          children: List.generate(
            _requiredCount,
            (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 3,
                decoration: BoxDecoration(
                  color: i < _capturedCount
                      ? _kGreen
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _capturedCount == 0
              ? '${_selectedHand == 'sağ' ? 'Sağ' : 'Sol'} avucunu kareye tut ve butona bas'
              : _capturedCount < _requiredCount
                  ? 'Sıradaki açıyla tara  •  ${_requiredCount - _capturedCount} kaldı'
                  : 'Tüm örnekler alındı, kaydediliyor...',
          style:
              TextStyle(color: Colors.white.withOpacity(0.42), fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildScanButton(bool isDone) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDone ? _kGreen : _kAccent,
          disabledBackgroundColor:
              (isDone ? _kGreen : _kAccent).withOpacity(0.45),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed:
            isDone || _isCapturing || _isSaving ? null : _captureEmbedding,
        child: _isCapturing || _isSaving
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
                    isDone ? Icons.check_rounded : Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isDone
                        ? 'Kaydedildi!'
                        : 'Avucu Tara ($_capturedCount/$_requiredCount)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Painter ────────────────────────────────────────────────────────────────

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
    // Tam ekranda kare, alt panel (~350px) ve üst bar (~90px) arasında ortalanır
    final cy = size.height * 0.40;
    final halfSide = size.width * 0.40;

    final l = cx - halfSide;
    final r = cx + halfSide;
    final t = cy - halfSide;
    final b = cy + halfSide;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTRB(l, t, r, b),
      const Radius.circular(20),
    );
    final cutPath = Path()..addRRect(rect);

    // 4 bölge karartma — kare dışı her alan
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.65);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, t), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(0, b, size.width, size.height), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(0, t, l, b), overlayPaint);
    canvas.drawRect(Rect.fromLTRB(r, t, size.width, b), overlayPaint);

    // Köşe çizgilerinin rengi — ilerlemeye göre değişir
    final progress = capturedCount / requiredCount;
    const accent = _kAccent;
    final frameColor = isCapturing
        ? accent
        : capturedCount > 0
            ? Color.lerp(accent, _kGreen, progress)!
            : Colors.white.withOpacity(0.85);

    final cornerLen = halfSide * 0.22;
    final paint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // 4 köşe — her birinde 2 çizgi
    canvas.drawLine(Offset(l, t + cornerLen), Offset(l, t), paint);
    canvas.drawLine(Offset(l, t), Offset(l + cornerLen, t), paint);
    canvas.drawLine(Offset(r - cornerLen, t), Offset(r, t), paint);
    canvas.drawLine(Offset(r, t), Offset(r, t + cornerLen), paint);
    canvas.drawLine(Offset(l, b - cornerLen), Offset(l, b), paint);
    canvas.drawLine(Offset(l, b), Offset(l + cornerLen, b), paint);
    canvas.drawLine(Offset(r - cornerLen, b), Offset(r, b), paint);
    canvas.drawLine(Offset(r, b), Offset(r, b - cornerLen), paint);

    // Tarama çizgisi (yakalama sırasında)
    if (scanProgress != null) {
      final scanY = t + (halfSide * 2 * scanProgress!);
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            accent.withOpacity(0.9),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(l, scanY, halfSide * 2, 2));
      canvas.save();
      canvas.clipPath(cutPath);
      canvas.drawRect(Rect.fromLTWH(l, scanY - 1, halfSide * 2, 2), scanPaint);
      canvas.restore();
    }

    // Sayaç metni — karenin hemen altında
    final tp = TextPainter(
      text: TextSpan(
        text: '$capturedCount/$requiredCount',
        style: TextStyle(
          color: capturedCount > 0 ? _kGreen : Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, b + 12));
  }

  @override
  bool shouldRepaint(_SquarePalmPainter old) =>
      old.scanProgress != scanProgress ||
      old.isCapturing != isCapturing ||
      old.capturedCount != capturedCount ||
      old.handAngle != handAngle;
}
