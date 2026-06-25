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
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color cardBorder = Color(0xffE5E7EB);
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
      return Icons.person_add_alt_1_rounded;
    }

    if (clean == 'bantuan_pupuk' || clean == 'pupuk') {
      return Icons.eco_rounded;
    }

    if (clean == 'peminjaman_alat' || clean == 'alat') {
      return Icons.agriculture_rounded;
    }

    if (clean == 'reset_password') {
      return Icons.lock_reset_rounded;
    }

    if (clean == 'pengumuman') {
      return Icons.campaign_rounded;
    }

    return Icons.notifications_rounded;
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
                appHeader(
                  allNotifications: allNotifications,
                  unreadCount: unreadCount,
                ),
                filterBar(
                  totalCount: allNotifications.length,
                  unreadCount: unreadCount,
                ),
                Expanded(
                  child: content(
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

  Widget appHeader({
    required List<Map<String, dynamic>> allNotifications,
    required int unreadCount,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              iconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Notifikasi Admin',
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
                      unreadCount == 0 || isProcessing
                          ? null
                          : () => markAllAsRead(allNotifications),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryGreen,
                    disabledForegroundColor: textGrey.withValues(alpha: 0.45),
                  ),
                  child: Text(
                    isProcessing ? 'Memproses' : 'Baca Semua',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color:
                  unreadCount == 0
                      ? primaryGreen.withValues(alpha: 0.08)
                      : redStatus.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    unreadCount == 0
                        ? primaryGreen.withValues(alpha: 0.16)
                        : redStatus.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: unreadCount == 0 ? softGreen : Colors.white,
                    borderRadius: BorderRadius.circular(10),
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
                        ? 'Semua pemberitahuan admin sudah dibaca.'
                        : '$unreadCount notifikasi admin belum dibaca.',
                    style: TextStyle(
                      color: unreadCount == 0 ? primaryGreen : redStatus,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
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

  Widget filterBar({required int totalCount, required int unreadCount}) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          filterChip(label: 'Semua', value: 'semua', count: totalCount),
          const SizedBox(width: 10),
          filterChip(label: 'Belum Dibaca', value: 'belum', count: unreadCount),
        ],
      ),
    );
  }

  Widget filterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? primaryGreen : cardBorder),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : textGrey,
                fontSize: 12.3,
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

  Widget content({
    required bool hasError,
    required String? errorMessage,
    required Map<String, List<Map<String, dynamic>>> grouped,
  }) {
    if (hasError) {
      return emptyState(
        icon: Icons.error_outline_rounded,
        title: 'Notifikasi Gagal Dimuat',
        message: errorMessage ?? 'Terjadi kesalahan saat mengambil data.',
      );
    }

    if (grouped.isEmpty) {
      return emptyState(
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupTitle = groupKeys[groupIndex];
        final items = grouped[groupTitle] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dateHeader(groupTitle),
            const SizedBox(height: 8),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: notificationTile(data: item),
              );
            }),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget dateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
      child: Text(
        title,
        style: const TextStyle(
          color: textDark,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget notificationTile({required Map<String, dynamic> data}) {
    final id = (data['id_notifikasi'] ?? '').toString();
    final title = (data['judul'] ?? 'Notifikasi').toString();
    final message = (data['pesan'] ?? '-').toString();
    final type = (data['tipe'] ?? '').toString();
    final date = (data['tanggal'] ?? '').toString();

    final unread = isUnread(data);
    final color = notifColor(type);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: unread && id.isNotEmpty ? () => markAsRead(id) : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unread ? color.withValues(alpha: 0.28) : cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(notifIcon(type), color: color, size: 23),
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
                        fontSize: 14.3,
                        height: 1.25,
                        fontWeight: unread ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12.2,
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
                            formatJam(date),
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        statusPill(unread),
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

  Widget statusPill(bool unread) {
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

  Widget iconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Icon(icon, color: textDark),
      ),
    );
  }

  Widget emptyState({
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
              height: 82,
              width: 82,
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: primaryGreen, size: 40),
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
