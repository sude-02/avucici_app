import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import '../services/database_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer.dart';
import '../utils/app_routes.dart';
import 'profile_screen.dart';
import 'register_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _dbService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kullanıcıyı Sil',
            style: TextStyle(color: Colors.white)),
        content: Text('$name silinecek. Emin misin?',
            style: TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _dbService.deleteUser(id);
      _loadUsers();
    }
  }

  void _openUserDetail(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UserDetailScreen(user: user, dbService: _dbService),
      ),
    ).then((_) => _loadUsers());
  }

  void _openUserProfile(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
    ).then((_) => _loadUsers());
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
        title: const Text('Kayıtlı Kullanıcılar',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const ShimmerUserListView()
          : _users.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return EmptyStateWidget(
      icon: Icons.people_outline_rounded,
      title: 'Kayıtlı kullanıcı yok',
      subtitle: 'Avuç içi ödeme yapabilmek için önce\nkayıt oluşturun.',
      actionLabel: 'Kayıt Ol',
      onAction: () => Navigator.push(
        context,
        AppRoutes.push(const RegisterScreen()),
      ).then((_) => _loadUsers()),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final user = _users[i];
        final hand = user['hand'] as String? ?? 'sağ';
        return GestureDetector(
          onTap: () => _openUserDetail(user),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              leading: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    user['name'][0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              title: Text(user['name'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              subtitle: Row(
                children: [
                  Icon(
                    Icons.back_hand_rounded,
                    size: 12,
                    color: const Color(0xFF6C63FF).withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${hand == 'sağ' ? 'Sağ' : 'Sol'} el',
                    style: TextStyle(
                        color: const Color(0xFF6C63FF).withOpacity(0.7),
                        fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text('• Detaylar için dokun',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        color: Color(0xFF6C63FF), size: 20),
                    tooltip: 'Profili düzenle',
                    onPressed: () => _openUserProfile(user),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    onPressed: () =>
                        _deleteUser(user['id'], user['name']),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Kullanıcı detay ekranı ──────────────────────────────────────────
class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final DatabaseService dbService;

  const UserDetailScreen(
      {super.key, required this.user, required this.dbService});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  List<Map<String, dynamic>> _samples = [];
  bool _isLoading = true;
  bool _isAddingMore = false;
  final CameraService _cameraService = CameraService();

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _loadSamples() async {
    setState(() => _isLoading = true);
    final samples = await widget.dbService
        .getUserSamples(widget.user['id'] as int);
    setState(() {
      _samples = samples;
      _isLoading = false;
    });
  }

  Future<void> _deleteSample(int sampleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Örneği Sil',
            style: TextStyle(color: Colors.white)),
        content: Text('Bu örnek silinecek.',
            style:
                TextStyle(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await widget.dbService
          .deleteSample(sampleId, widget.user['id'] as int);
      _loadSamples();
    }
  }

  Future<void> _addMoreSamples() async {
    setState(() => _isAddingMore = true);
    await _cameraService.initialize();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AddSampleSheet(
        cameraService: _cameraService,
        onCapture: (result) async {
          // Güncellenmiş addSample — flippedEmbedding de geçiliyor
          await widget.dbService.addSample(
            widget.user['id'] as int,
            result.embedding,
            result.flippedEmbedding,
            result.imagePath,
          );
          _loadSamples();
        },
      ),
    ).then((_) {
      setState(() => _isAddingMore = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hand = widget.user['hand'] as String? ?? 'sağ';
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
        title: Row(
          children: [
            Text(widget.user['name'],
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.4)),
              ),
              child: Text(
                '${hand == 'sağ' ? 'Sağ' : 'Sol'} El',
                style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_rounded,
                color: Color(0xFF6C63FF)),
            onPressed: _isAddingMore ? null : _addMoreSamples,
            tooltip: 'Yeni örnek ekle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF)))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Row(
            children: [
              Text('${_samples.length} örnek kayıtlı',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: _isAddingMore ? null : _addMoreSamples,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            const Color(0xFF6C63FF).withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add_rounded,
                          color: Color(0xFF6C63FF), size: 16),
                      SizedBox(width: 4),
                      Text('Örnek Ekle',
                          style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _samples.isEmpty
              ? Center(
                  child: Text('Örnek bulunamadı',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3))))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _samples.length,
                  itemBuilder: (_, i) =>
                      _buildSampleCard(_samples[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSampleCard(Map<String, dynamic> sample) {
    final imagePath = sample['image_path'] as String?;
    final file = imagePath != null ? File(imagePath) : null;
    final exists = file?.existsSync() ?? false;

    return GestureDetector(
      onLongPress: () => _deleteSample(sample['id'] as int),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: exists
                  ? Image.file(file!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity)
                  : Center(
                      child: Icon(Icons.back_hand_rounded,
                          color: Colors.white.withOpacity(0.2),
                          size: 32)),
            ),
          ),
          Positioned(
            top: 4, right: 4,
            child: GestureDetector(
              onTap: () => _deleteSample(sample['id'] as int),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 12),
              ),
            ),
          ),
          Positioned(
            bottom: 4, left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${sample['id'] as int}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Yeni örnek ekleme sheet'i ───────────────────────────────────────
class _AddSampleSheet extends StatefulWidget {
  final CameraService cameraService;
  final Function(CaptureResult) onCapture;

  const _AddSampleSheet(
      {required this.cameraService, required this.onCapture});

  @override
  State<_AddSampleSheet> createState() => _AddSampleSheetState();
}

class _AddSampleSheetState extends State<_AddSampleSheet> {
  bool _isCapturing = false;
  int _capturedCount = 0;
  String _status = 'Avucunu kareye tut ve çek';

  Future<void> _capture() async {
    setState(() {
      _isCapturing = true;
      _status = 'Taranıyor...';
    });
    try {
      final result =
          await widget.cameraService.captureAndExtractEmbedding();
      if (result != null) {
        await widget.onCapture(result);
        setState(() {
          _capturedCount++;
          _status = '$_capturedCount örnek eklendi ✓';
        });
      } else {
        setState(() => _status = 'El algılanamadı, tekrar dene');
      }
    } catch (e) {
      setState(() => _status = 'Hata: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: widget.cameraService.isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: widget.cameraService.controller!
                            .value.previewSize!.height,
                        height: widget.cameraService.controller!
                            .value.previewSize!.width,
                        child: CameraPreview(
                            widget.cameraService.controller!),
                      ),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF))),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _MiniSquarePainter(),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                  Text(_status,
                      style: TextStyle(
                          color: _capturedCount > 0
                              ? const Color(0xFF10B981)
                              : Colors.white70,
                          fontSize: 14),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          onPressed:
                              _isCapturing ? null : _capture,
                          child: _isCapturing
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2))
                              : const Text('Çek',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1A1A2E),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Bitti',
                            style: TextStyle(
                                color: Colors.white70)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 12, right: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final half = size.width * 0.35;
    final l = cx - half;
    final r = cx + half;
    final t = cy - half;
    final b = cy + half;
    final cl = half * 0.22;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(l, t + cl), Offset(l, t), paint);
    canvas.drawLine(Offset(l, t), Offset(l + cl, t), paint);
    canvas.drawLine(Offset(r - cl, t), Offset(r, t), paint);
    canvas.drawLine(Offset(r, t), Offset(r, t + cl), paint);
    canvas.drawLine(Offset(l, b - cl), Offset(l, b), paint);
    canvas.drawLine(Offset(l, b), Offset(l + cl, b), paint);
    canvas.drawLine(Offset(r - cl, b), Offset(r, b), paint);
    canvas.drawLine(Offset(r, b), Offset(r, b - cl), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}