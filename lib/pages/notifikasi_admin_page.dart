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
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE6ECE8);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color redStatus = Color(0xffDC2626);

  final DatabaseReference notifRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('notifikasi_admin');

  String filter = 'semua';
  bool isProcessing = false;

  List<Map<String, dynamic>> getNotifications(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries.where((entry) => entry.value is Map).map((entry) {
          final item = Map<String, dynamic>.from(entry.value as Map);
          item['id_notifikasi'] = entry.key.toString();
          return item;
        }).toList();

    list.sort((a, b) => timeValue(b).compareTo(timeValue(a)));
    return list;
  }

  int timeValue(Map<String, dynamic> item) {
    final raw = item['tanggal'] ?? item['created_at'] ?? item['createdAt'];
    final parsed = DateTime.tryParse((raw ?? '').toString().trim());
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  bool isUnread(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase().trim();
    final dibaca = data['dibaca'];
    return status == 'belum_dibaca' || dibaca == false;
  }

  List<Map<String, dynamic>> filteredList(List<Map<String, dynamic>> list) {
    if (filter == 'belum') {
      return list.where((item) => isUnread(item)).toList();
    }
    return list;
  }

  Map<String, List<Map<String, dynamic>>> groupedByDate(
    List<Map<String, dynamic>> list,
  ) {
    final result = <String, List<Map<String, dynamic>>>{};

    for (final item in list) {
      final label = groupDateLabel((item['tanggal'] ?? '').toString());
      result.putIfAbsent(label, () => []);
      result[label]!.add(item);
    }

    return result;
  }

  String groupDateLabel(String value) {
    final date = DateTime.tryParse(value.trim());
    if (date == null) return 'Tanggal Tidak Diketahui';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notifDate = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (notifDate == today) return 'Hari Ini';
    if (notifDate == yesterday) return 'Kemarin';

    return '${date.day} ${namaBulan(date.month)} ${date.year}';
  }

  String namaBulan(int month) {
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    if (month < 1 || month > 12) return '';
    return bulan[month - 1];
  }

  String formatJam(String value) {
    final date = DateTime.tryParse(value.trim());
    if (date == null) return '-';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> markAsRead(String id) async {
    try {
      await notifRef
          .child(id)
          .update({'status': 'dibaca', 'dibaca': true})
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      if (!mounted) return;
      showSnack('Gagal menandai notifikasi.');
    }
  }

  Future<void> markAllAsRead(List<Map<String, dynamic>> list) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final updates = <String, Object?>{};

      for (final item in list) {
        if (!isUnread(item)) continue;

        final id = (item['id_notifikasi'] ?? '').toString();
        if (id.isEmpty) continue;

        updates['$id/status'] = 'dibaca';
        updates['$id/dibaca'] = true;
      }

      if (updates.isNotEmpty) {
        await notifRef.update(updates).timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;
      showSnack('Semua notifikasi sudah dibaca.');
    } catch (_) {
      if (!mounted) return;
      showSnack('Gagal membaca semua notifikasi.');
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  IconData notifIcon(String type) {
    final clean = type.toLowerCase().trim();

    if (clean == 'anggota' || clean == 'verifikasi_anggota') {
      return Icons.assignment_ind_rounded;
    }

    if (clean == 'bantuan_pupuk' || clean == 'pupuk') {
      return Icons.inventory_2_rounded;
    }

    if (clean == 'peminjaman_alat' || clean == 'alat') {
      return Icons.handyman_rounded;
    }

    if (clean == 'reset_password') {
      return Icons.lock_reset_rounded;
    }

    if (clean == 'pengumuman') {
      return Icons.campaign_rounded;
    }

    return Icons.notifications_none_rounded;
  }

  Color notifColor(String type) {
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

    if (clean == 'reset_password') {
      return redStatus;
    }

    if (clean == 'pengumuman') {
      return primaryGreen;
    }

    return primaryGreen;
  }

  String notifTypeLabel(String type) {
    final clean = type.toLowerCase().trim();

    if (clean == 'anggota' || clean == 'verifikasi_anggota') {
      return 'Anggota';
    }

    if (clean == 'bantuan_pupuk' || clean == 'pupuk') {
      return 'Pupuk';
    }

    if (clean == 'peminjaman_alat' || clean == 'alat') {
      return 'Alat';
    }

    if (clean == 'reset_password') {
      return 'Reset';
    }

    if (clean == 'pengumuman') {
      return 'Info';
    }

    return 'Sistem';
  }

  void showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: notifRef.onValue,
          builder: (context, snapshot) {
            final allNotifications = getNotifications(
              snapshot.data?.snapshot.value,
            );

            final unreadCount =
                allNotifications.where((item) => isUnread(item)).length;

            final shownNotifications = filteredList(allNotifications);
            final grouped = groupedByDate(shownNotifications);

            return Column(
              children: [
                _header(
                  allNotifications: allNotifications,
                  unreadCount: unreadCount,
                ),
                _filterBar(
                  totalCount: allNotifications.length,
                  unreadCount: unreadCount,
                ),
                Expanded(
                  child: _content(
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                    hasError: snapshot.hasError,
                    errorMessage: snapshot.error?.toString(),
                    grouped: grouped,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header({
    required List<Map<String, dynamic>> allNotifications,
    required int unreadCount,
  }) {
    final clear = unreadCount == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _backButton(),
              const SizedBox(width: 12),
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  clear
                      ? Icons.mark_email_read_rounded
                      : Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pemberitahuan terbaru dari sistem',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xffDDEFE3),
                        fontSize: 11.8,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _headerBadge(unreadCount),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    clear
                        ? Icons.task_alt_rounded
                        : Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    clear
                        ? 'Semua notifikasi admin sudah dibaca.'
                        : '$unreadCount notifikasi belum dibaca dan perlu diperiksa.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.2,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (allNotifications.isNotEmpty)
                  InkWell(
                    onTap:
                        unreadCount == 0 || isProcessing
                            ? null
                            : () => markAllAsRead(allNotifications),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: unreadCount == 0 ? 0.08 : 0.18,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        isProcessing ? 'Proses' : 'Baca Semua',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: unreadCount == 0 ? 0.45 : 1,
                          ),
                          fontSize: 10.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fact_check_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            unreadCount > 99 ? '99+' : unreadCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar({required int totalCount, required int unreadCount}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        children: [
          _filterChip(label: 'Semua', value: 'semua', count: totalCount),
          const SizedBox(width: 8),
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
    final selected = filter == value;

    return InkWell(
      onTap: () => setState(() => filter = value),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? primaryGreen : cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.018),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textGrey,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
              decoration: BoxDecoration(
                color:
                    selected ? Colors.white.withValues(alpha: 0.20) : bgColor,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: selected ? Colors.white : textGrey,
                  fontSize: 9.6,
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
    required bool isLoading,
    required bool hasError,
    required String? errorMessage,
    required Map<String, List<Map<String, dynamic>>> grouped,
  }) {
    if (isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: List.generate(5, (_) => _loadingCard()),
      );
    }

    if (hasError) {
      return _emptyState(
        icon: Icons.fact_check_rounded,
        title: 'Notifikasi Gagal Dimuat',
        message: errorMessage ?? 'Terjadi kesalahan saat mengambil data.',
      );
    }

    if (grouped.isEmpty) {
      return _emptyState(
        icon:
            filter == 'belum'
                ? Icons.mark_email_read_rounded
                : Icons.notifications_none_rounded,
        title:
            filter == 'belum'
                ? 'Tidak Ada Notifikasi Baru'
                : 'Belum Ada Notifikasi',
        message:
            filter == 'belum'
                ? 'Semua notifikasi admin sudah dibaca.'
                : 'Notifikasi akan muncul saat ada pengajuan baru dari anggota.',
      );
    }

    final groupKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupTitle = groupKeys[groupIndex];
        final items = grouped[groupTitle] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _dateHeader(groupTitle),
            const SizedBox(height: 8),
            ...items.map((item) {
              return _notificationTile(data: item);
            }),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _dateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 4),
      child: Row(
        children: [
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: primaryGreen,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile({required Map<String, dynamic> data}) {
    final id = (data['id_notifikasi'] ?? '').toString();
    final title = (data['judul'] ?? 'Notifikasi').toString();
    final message = (data['pesan'] ?? '-').toString();
    final type = (data['tipe'] ?? '').toString();
    final date = (data['tanggal'] ?? '').toString();

    final unread = isUnread(data);
    final color = notifColor(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(radius: 20),
      child: InkWell(
        onTap: unread && id.isNotEmpty ? () => markAsRead(id) : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _notifIconBox(notifIcon(type), color, unread),
                  if (unread)
                    Positioned(
                      right: -1,
                      top: -1,
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
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _typeBadge(type, color),
                        const Spacer(),
                        Text(
                          formatJam(date),
                          style: const TextStyle(
                            color: textGrey,
                            fontSize: 10.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 14.2,
                        height: 1.25,
                        fontWeight: unread ? FontWeight.w900 : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 11.8,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _miniInfo(
                          icon:
                              unread
                                  ? Icons.mark_email_unread_rounded
                                  : Icons.mark_email_read_rounded,
                          text: unread ? 'Baru' : 'Dibaca',
                          color: unread ? redStatus : primaryGreen,
                        ),
                        const Spacer(),
                        if (unread)
                          const Text(
                            'Ketuk untuk tandai dibaca',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  Widget _notifIconBox(IconData icon, Color color, bool unread) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: unread ? 0.11 : 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  Widget _typeBadge(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.09)),
      ),
      child: Text(
        notifTypeLabel(type).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _miniInfo({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 17,
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  height: 11,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
          decoration: _cardDecoration(radius: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: softGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(icon, color: primaryGreen, size: 34),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12.4,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.026),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
