import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NotifikasiAdminPage extends StatefulWidget {
  const NotifikasiAdminPage({super.key});

  @override
  State<NotifikasiAdminPage> createState() => _NotifikasiAdminPageState();
}

class _NotifikasiAdminPageState extends State<NotifikasiAdminPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color backgroundColor = Color(0xffF7FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color redStatus = Color(0xffDC2626);

  final DatabaseReference _notifRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('notifikasi_admin');

  String _filter = 'semua';
  bool _isProcessing = false;

  List<MapEntry<String, dynamic>> _getNotifications(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);
    final list = data.entries.where((entry) => entry.value is Map).toList();

    list.sort((a, b) {
      final itemA = Map<dynamic, dynamic>.from(a.value as Map);
      final itemB = Map<dynamic, dynamic>.from(b.value as Map);
      return _timeValue(itemB).compareTo(_timeValue(itemA));
    });

    return list.map((e) => MapEntry(e.key.toString(), e.value)).toList();
  }

  int _timeValue(Map<dynamic, dynamic> item) {
    final raw = item['tanggal'] ?? item['created_at'] ?? item['createdAt'];
    final parsed = DateTime.tryParse((raw ?? '').toString().trim());
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  bool _isUnread(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase().trim();
    final dibaca = data['dibaca'];
    return status == 'belum_dibaca' || dibaca == false;
  }

  List<MapEntry<String, dynamic>> _filteredList(
    List<MapEntry<String, dynamic>> list,
  ) {
    if (_filter == 'belum') {
      return list.where((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        return _isUnread(data);
      }).toList();
    }

    return list;
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _notifRef
          .child(id)
          .update({'status': 'dibaca', 'dibaca': true})
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menandai notifikasi.');
    }
  }

  Future<void> _markAllAsRead(List<MapEntry<String, dynamic>> list) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final updates = <String, Object?>{};

      for (final entry in list) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        if (!_isUnread(data)) continue;

        updates['${entry.key}/status'] = 'dibaca';
        updates['${entry.key}/dibaca'] = true;
      }

      if (updates.isNotEmpty) {
        await _notifRef.update(updates).timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;
      _showSnack('Semua notifikasi sudah dibaca.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal membaca semua notifikasi.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  IconData _icon(String type) {
    final clean = type.toLowerCase().trim();

    if (clean == 'anggota' || clean == 'verifikasi_anggota') {
      return Icons.person_add_alt_1_rounded;
    }

    if (clean == 'bantuan_pupuk' || clean == 'pupuk') {
      return Icons.eco_rounded;
    }

    if (clean == 'peminjaman_alat' || clean == 'alat') {
      return Icons.agriculture_rounded;
    }

    return Icons.notifications_rounded;
  }

  Color _color(String type) {
    final clean = type.toLowerCase().trim();

    if (clean == 'anggota' || clean == 'verifikasi_anggota') {
      return blueStatus;
    }

    if (clean == 'bantuan_pupuk' || clean == 'pupuk') {
      return primaryGreen;
    }

    if (clean == 'peminjaman_alat' || clean == 'alat') {
      return orangeStatus;
    }

    return primaryGreen;
  }

  String _formatDate(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return 'Tanggal tidak tersedia';

    final date = DateTime.tryParse(raw);
    if (date == null) return raw;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: _notifRef.onValue,
          builder: (context, snapshot) {
            final allNotifications = _getNotifications(
              snapshot.data?.snapshot.value,
            );

            final unreadCount =
                allNotifications.where((entry) {
                  final data = Map<String, dynamic>.from(entry.value as Map);
                  return _isUnread(data);
                }).length;

            final shownNotifications = _filteredList(allNotifications);

            return Column(
              children: [
                _appHeader(
                  allNotifications: allNotifications,
                  unreadCount: unreadCount,
                ),
                _filterBar(
                  totalCount: allNotifications.length,
                  unreadCount: unreadCount,
                ),
                Expanded(
                  child: _content(
                    hasError: snapshot.hasError,
                    errorMessage: snapshot.error?.toString(),
                    notifications: shownNotifications,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _appHeader({
    required List<MapEntry<String, dynamic>> allNotifications,
    required int unreadCount,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              _iconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  if (mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Notifikasi',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (allNotifications.isNotEmpty)
                TextButton(
                  onPressed:
                      unreadCount == 0 || _isProcessing
                          ? null
                          : () => _markAllAsRead(allNotifications),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryGreen,
                    disabledForegroundColor: textGrey.withValues(alpha: 0.45),
                  ),
                  child: Text(
                    _isProcessing ? 'Memproses' : 'Baca Semua',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color:
                      unreadCount == 0
                          ? softGreen
                          : redStatus.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  unreadCount == 0
                      ? Icons.done_all_rounded
                      : Icons.notifications_active_rounded,
                  color: unreadCount == 0 ? primaryGreen : redStatus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  unreadCount == 0
                      ? 'Semua pemberitahuan sudah dibaca.'
                      : '$unreadCount notifikasi belum dibaca.',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterBar({required int totalCount, required int unreadCount}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          _filterChip(label: 'Semua', value: 'semua', count: totalCount),
          const SizedBox(width: 10),
          _filterChip(
            label: 'Belum Dibaca',
            value: 'belum',
            count: unreadCount,
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    required int count,
  }) {
    final selected = _filter == value;

    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? primaryGreen : cardBorder),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textGrey,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color:
                    selected
                        ? Colors.white.withValues(alpha: 0.20)
                        : Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: selected ? Colors.white : textGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content({
    required bool hasError,
    required String? errorMessage,
    required List<MapEntry<String, dynamic>> notifications,
  }) {
    if (hasError) {
      return _emptyState(
        icon: Icons.error_outline_rounded,
        title: 'Notifikasi Gagal Dimuat',
        message: errorMessage ?? 'Terjadi kesalahan saat mengambil data.',
      );
    }

    if (notifications.isEmpty) {
      return _emptyState(
        icon:
            _filter == 'belum'
                ? Icons.mark_email_read_rounded
                : Icons.notifications_none_rounded,
        title:
            _filter == 'belum'
                ? 'Tidak Ada Notifikasi Baru'
                : 'Belum Ada Notifikasi',
        message:
            _filter == 'belum'
                ? 'Semua notifikasi admin sudah dibaca.'
                : 'Notifikasi akan muncul saat ada pengajuan baru dari anggota.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = notifications[index];
        final data = Map<String, dynamic>.from(entry.value as Map);

        return _notificationTile(id: entry.key, data: data);
      },
    );
  }

  Widget _notificationTile({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final title = (data['judul'] ?? 'Notifikasi').toString();
    final message = (data['pesan'] ?? '-').toString();
    final type = (data['tipe'] ?? '').toString();
    final date = (data['tanggal'] ?? '').toString();

    final unread = _isUnread(data);
    final color = _color(type);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: unread ? () => _markAsRead(id) : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread ? color.withValues(alpha: 0.30) : cardBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: unread ? 0.14 : 0.09),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(_icon(type), color: color, size: 23),
                  ),
                  if (unread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        height: 10,
                        width: 10,
                        decoration: BoxDecoration(
                          color: redStatus,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 14.5,
                        height: 1.25,
                        fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12.3,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: textGrey.withValues(alpha: 0.75),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(date),
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        _statusPill(unread),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(bool unread) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: unread ? redStatus.withValues(alpha: 0.09) : softGreen,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        unread ? 'Baru' : 'Dibaca',
        style: TextStyle(
          color: unread ? redStatus : primaryGreen,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Icon(icon, color: textDark),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 86,
              width: 86,
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, color: primaryGreen, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
