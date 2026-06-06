import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  List<Map<String, dynamic>> _all = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final rows = await _db.getTransactions();
    if (mounted) setState(() { _all = rows; _isLoading = false; });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Geçmişi Temizle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Tüm işlem geçmişi silinecek.',
            style: TextStyle(color: Colors.white.withAlpha(179))),
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
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Temizle',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.clearTransactions();
      _load();
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
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('İşlem Geçmişi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (_all.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded,
                  color: Colors.white.withAlpha(128)),
              tooltip: 'Geçmişi temizle',
              onPressed: _confirmClear,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Tümü (${_all.length})'),
            Tab(
              text:
                  'Başarılı (${_all.where((t) => t['status'] == 'success').length})',
            ),
            Tab(
              text:
                  'Başarısız (${_all.where((t) => t['status'] == 'failed').length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const ShimmerTransactionListView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_all),
                _buildList(
                    _all.where((t) => t['status'] == 'success').toList(),
                    successOnly: true),
                _buildList(
                    _all.where((t) => t['status'] == 'failed').toList(),
                    failedOnly: true),
              ],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items,
      {bool successOnly = false, bool failedOnly = false}) {
    if (items.isEmpty) {
      return _buildEmpty(successOnly: successOnly, failedOnly: failedOnly);
    }

    final grouped = _groupByDate(items);
    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF7C3AED),
      backgroundColor: const Color(0xFF1A1A2E),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: grouped.length,
        itemBuilder: (_, i) {
          final entry = grouped[i];
          if (entry['type'] == 'header') {
            return _buildDateHeader(entry['label'] as String);
          }
          return _buildTransactionTile(
              entry['data'] as Map<String, dynamic>);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _groupByDate(
      List<Map<String, dynamic>> items) {
    final result = <Map<String, dynamic>>[];
    String? lastDate;
    for (final item in items) {
      final dt = DateTime.parse(item['created_at'] as String).toLocal();
      final dateLabel = _formatDateLabel(dt);
      if (dateLabel != lastDate) {
        result.add({'type': 'header', 'label': dateLabel});
        lastDate = dateLabel;
      }
      result.add({'type': 'item', 'data': item});
    }
    return result;
  }

  String _formatDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'Bugün';
    if (d == today.subtract(const Duration(days: 1))) return 'Dün';
    return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int m) {
    const names = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return names[m];
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withAlpha(102),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final isSuccess = tx['status'] == 'success';
    final dt = DateTime.parse(tx['created_at'] as String).toLocal();
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final amount = tx['amount'] as double?;
    final hand = tx['hand'] as String?;
    final score = tx['match_score'] as double?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess
              ? const Color(0xFF059669).withAlpha(51)
              : Colors.red.withAlpha(38),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildStatusIcon(isSuccess),
            const SizedBox(width: 14),
            Expanded(child: _buildTileBody(tx, isSuccess, hand, score, timeStr)),
            if (isSuccess && amount != null) _buildAmount(amount),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(bool isSuccess) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isSuccess
            ? const Color(0xFF059669).withAlpha(38)
            : Colors.red.withAlpha(38),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isSuccess
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded,
        color: isSuccess ? const Color(0xFF059669) : Colors.red,
        size: 24,
      ),
    );
  }

  Widget _buildTileBody(
    Map<String, dynamic> tx,
    bool isSuccess,
    String? hand,
    double? score,
    String timeStr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tx['user_name'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              timeStr,
              style: TextStyle(
                  color: Colors.white.withAlpha(102), fontSize: 12),
            ),
            if (hand != null) ...[
              Text(' · ',
                  style: TextStyle(
                      color: Colors.white.withAlpha(51), fontSize: 12)),
              Text(
                '${hand == 'sağ' ? 'Sağ' : 'Sol'} el',
                style: TextStyle(
                    color: Colors.white.withAlpha(102), fontSize: 12),
              ),
            ],
            if (score != null) ...[
              Text(' · ',
                  style: TextStyle(
                      color: Colors.white.withAlpha(51), fontSize: 12)),
              Text(
                '%${(score * 100).toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Color(0xFF059669), fontSize: 12),
              ),
            ],
          ],
        ),
        if (!isSuccess)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              'Eşleşme bulunamadı',
              style: TextStyle(color: Colors.red.withAlpha(179), fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildAmount(double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₺${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withAlpha(38),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Onaylandı',
            style: TextStyle(
                color: Color(0xFF059669),
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty({bool successOnly = false, bool failedOnly = false}) {
    if (successOnly) {
      return const EmptyStateWidget(
        icon: Icons.check_circle_outline_rounded,
        iconColor: Color(0xFF10B981),
        title: 'Başarılı işlem yok',
        subtitle: 'Başarıyla tamamlanan ödemeler\nburada görünecek.',
      );
    }
    if (failedOnly) {
      return const EmptyStateWidget(
        icon: Icons.cancel_outlined,
        iconColor: Color(0xFFEF4444),
        title: 'Başarısız işlem yok',
        subtitle: 'Eşleşmeyen okuma girişimleri\nburada görünecek.',
      );
    }
    return const EmptyStateWidget(
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF7C3AED),
      title: 'Henüz işlem yok',
      subtitle: 'İlk ödemenizi yaptıktan sonra\ntüm geçmiş burada listelenir.',
    );
  }
}
