import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NotifikasiAdminPage extends StatefulWidget {
  const NotifikasiAdminPage({super.key});

  @override
  State<NotifikasiAdminPage> createState() =>
      _NotifikasiAdminPageState();
}

class _NotifikasiAdminPageState
    extends State<NotifikasiAdminPage> {
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminIndigo = Color(0xff435987);
  static const Color adminPurple = Color(0xff6256A4);

  static const Color green = Color(0xff2E7D32);
  static const Color blue = Color(0xff326CA3);
  static const Color amber = Color(0xffD98212);
  static const Color red = Color(0xffC83B3B);
  static const Color teal = Color(0xff167A6B);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);
  static const Color softPurple = Color(0xffF0ECFA);

  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  final DatabaseReference notifRef =
      FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('notifikasi_admin');

  String selectedFilter = 'semua';
  bool isProcessing = false;

  List<Map<String, dynamic>> _notifications(dynamic value) {
    if (value is! Map) {
      return <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];

    for (final entry
        in Map<dynamic, dynamic>.from(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(
        entry.value as Map,
      );

      item['id_notifikasi'] = entry.key.toString();
      result.add(item);
    }

    result.sort(
      (first, second) => _dateValue(
        second,
      ).compareTo(
        _dateValue(first),
      ),
    );

    return result;
  }

  DateTime _dateValue(Map<String, dynamic> item) {
    final raw = item['tanggal'] ??
        item['created_at'] ??
        item['createdAt'] ??
        item['timestamp'];

    if (raw is num) {
      try {
        final value = raw.toInt();

        return DateTime.fromMillisecondsSinceEpoch(
          value.toString().length >= 13
              ? value
              : value * 1000,
        ).toLocal();
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final parsed = DateTime.tryParse(
      (raw ?? '').toString().trim(),
    );

    return parsed?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isUnread(Map<String, dynamic> item) {
    final status = (item['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final readValue = item['dibaca'];

    return status == 'belum_dibaca' ||
        status == 'belum dibaca' ||
        status == 'baru' ||
        readValue == false;
  }

  List<Map<String, dynamic>> _filtered(
    List<Map<String, dynamic>> source,
  ) {
    if (selectedFilter == 'belum') {
      return source.where(_isUnread).toList();
    }

    return source;
  }

  Map<String, List<Map<String, dynamic>>> _grouped(
    List<Map<String, dynamic>> source,
  ) {
    final result =
        <String, List<Map<String, dynamic>>>{};

    for (final item in source) {
      final label = _dateGroup(_dateValue(item));

      result.putIfAbsent(
        label,
        () => <Map<String, dynamic>>[],
      );

      result[label]!.add(item);
    }

    return result;
  }

  String _dateGroup(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) {
      return 'Tanggal tidak diketahui';
    }

    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final notificationDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final yesterday =
        today.subtract(const Duration(days: 1));

    if (notificationDate == today) {
      return 'Hari Ini';
    }

    if (notificationDate == yesterday) {
      return 'Kemarin';
    }

    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = <String>[
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

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String _timeText(Map<String, dynamic> item) {
    final date = _dateValue(item);

    if (date.millisecondsSinceEpoch == 0) {
      return '-';
    }

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshData() async {
    await notifRef.get();
  }

  Future<void> _markAsRead(String id) async {
    if (id.trim().isEmpty) {
      return;
    }

    try {
      await notifRef.child(id).update({
        'status': 'dibaca',
        'dibaca': true,
      }).timeout(
        const Duration(seconds: 10),
      );
    } catch (error) {
      debugPrint(
        'Gagal menandai notifikasi admin: $error',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Notifikasi gagal ditandai sebagai dibaca.',
        red,
      );
    }
  }

  Future<void> _markAllAsRead(
    List<Map<String, dynamic>> source,
  ) async {
    if (isProcessing) {
      return;
    }

    final unread = source.where(_isUnread).toList();

    if (unread.isEmpty) {
      _showSnackBar(
        'Semua notifikasi sudah dibaca.',
        green,
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final updates = <String, Object?>{};

      for (final item in unread) {
        final id =
            (item['id_notifikasi'] ?? '').toString();

        if (id.trim().isEmpty) {
          continue;
        }

        updates['$id/status'] = 'dibaca';
        updates['$id/dibaca'] = true;
      }

      if (updates.isNotEmpty) {
        await notifRef.update(updates).timeout(
              const Duration(seconds: 12),
            );
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Semua notifikasi admin sudah dibaca.',
        green,
      );
    } catch (error) {
      debugPrint(
        'Gagal membaca semua notifikasi admin: $error',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal membaca semua notifikasi.',
        red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  String _type(Map<String, dynamic> item) {
    return (item['tipe'] ??
            item['type'] ??
            item['jenis'] ??
            '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');
  }

  IconData _typeIcon(String type) {
    if (type.contains('anggota') ||
        type.contains('pendaftaran')) {
      return Icons.person_add_alt_1_rounded;
    }

    if (type.contains('pupuk')) {
      return Icons.inventory_2_outlined;
    }

    if (type.contains('alat') ||
        type.contains('peminjaman')) {
      return Icons.handyman_outlined;
    }

    if (type.contains('reset') ||
        type.contains('password') ||
        type.contains('akun')) {
      return Icons.lock_reset_rounded;
    }

    if (type.contains('pengumuman') ||
        type.contains('info')) {
      return Icons.campaign_outlined;
    }

    return Icons.notifications_none_rounded;
  }

  Color _typeColor(String type) {
    if (type.contains('anggota') ||
        type.contains('pendaftaran')) {
      return blue;
    }

    if (type.contains('pupuk')) {
      return green;
    }

    if (type.contains('alat') ||
        type.contains('peminjaman')) {
      return amber;
    }

    if (type.contains('reset') ||
        type.contains('password') ||
        type.contains('akun')) {
      return red;
    }

    if (type.contains('pengumuman') ||
        type.contains('info')) {
      return adminPurple;
    }

    return teal;
  }

  String _typeLabel(String type) {
    if (type.contains('anggota') ||
        type.contains('pendaftaran')) {
      return 'Anggota';
    }

    if (type.contains('pupuk')) {
      return 'Pupuk';
    }

    if (type.contains('alat') ||
        type.contains('peminjaman')) {
      return 'Alat';
    }

    if (type.contains('reset') ||
        type.contains('password') ||
        type.contains('akun')) {
      return 'Akun';
    }

    if (type.contains('pengumuman') ||
        type.contains('info')) {
      return 'Informasi';
    }

    return 'Sistem';
  }

  void _showSnackBar(
    String message,
    Color color,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.fixed,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 350
        ? 12.0
        : screenWidth >= 900
            ? 28.0
            : screenWidth >= 600
                ? 22.0
                : 16.0;

    return Scaffold(
      backgroundColor: pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AdminNotificationBackground(),
          SafeArea(
            child: StreamBuilder<DatabaseEvent>(
              stream: notifRef.onValue,
              builder: (context, snapshot) {
                final allNotifications =
                    _notifications(
                  snapshot.data?.snapshot.value,
                );

                final unreadCount = allNotifications
                    .where(_isUnread)
                    .length;

                final filteredNotifications =
                    _filtered(allNotifications);

                final groupedNotifications =
                    _grouped(filteredNotifications);

                final readCount =
                    allNotifications.length -
                        unreadCount;

                return RefreshIndicator(
                  color: adminPurple,
                  backgroundColor: Colors.white,
                  onRefresh: _refreshData,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      30,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(
                            maxWidth: 840,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              _header(
                                total:
                                    allNotifications.length,
                                unread: unreadCount,
                              ),
                              const SizedBox(height: 10),
                              _summarySection(
                                total:
                                    allNotifications.length,
                                unread: unreadCount,
                                read: readCount,
                              ),
                              const SizedBox(height: 8),
                              _unreadBanner(
                                allNotifications:
                                    allNotifications,
                                unread: unreadCount,
                              ),
                              const SizedBox(height: 8),
                              _filterSection(
                                total:
                                    allNotifications.length,
                                unread: unreadCount,
                              ),
                              const SizedBox(height: 12),
                              _sectionTitle(
                                resultCount:
                                    filteredNotifications
                                        .length,
                              ),
                              const SizedBox(height: 5),
                              _content(
                                loading:
                                    snapshot.connectionState ==
                                        ConnectionState
                                            .waiting,
                                error: snapshot.hasError,
                                errorMessage:
                                    snapshot.error?.toString(),
                                grouped:
                                    groupedNotifications,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (isProcessing) _processingOverlay(),
        ],
      ),
    );
  }

  Widget _header({
    required int total,
    required int unread,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 380;

        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 17,
            compact ? 15 : 18,
            compact ? 14 : 17,
            compact ? 15 : 18,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                adminNavy,
                adminIndigo,
                adminPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(27),
            boxShadow: [
              BoxShadow(
                color: adminNavy.withValues(
                  alpha: 0.26,
                ),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _backButton(),
              SizedBox(width: compact ? 10 : 13),
              _iconBox(
                icon: unread > 0
                    ? Icons.notifications_active_outlined
                    : Icons.mark_email_read_outlined,
                color: Colors.white,
                background:
                    Colors.white.withValues(
                  alpha: 0.14,
                ),
                size: compact ? 42 : 46,
              ),
              SizedBox(width: compact ? 11 : 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi Admin',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        height: 1.1,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: -0.25,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Aktivitas terbaru pengajuan TaniGo',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xffE5E7FF),
                        fontSize: 9.8,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 38,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.19,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      color: Colors.white,
                      size: 10.5,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      unread > 99
                          ? '99+'
                          : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.0,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summarySection({
    required int total,
    required int unread,
    required int read,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 350
            ? 7.0
            : 10.0;

        final itemWidth =
            (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                label: 'Semua',
                value: total,
                icon:
                    Icons.notifications_none_outlined,
                color: adminPurple,
                background: softPurple,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                label: 'Belum Dibaca',
                value: unread,
                icon: Icons
                    .mark_email_unread_outlined,
                color: amber,
                background: softAmber,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                label: 'Dibaca',
                value: read,
                icon:
                    Icons.mark_email_read_outlined,
                color: green,
                background: softGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 78,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 8,
      ),
      decoration: _cardDecoration(
        radius: 22,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            height: 27,
            width: 27,
            decoration: BoxDecoration(
              color: background,
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value > 999
                ? '999+'
                : value.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 7.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }



  Widget _unreadBanner({
    required List<Map<String, dynamic>>
        allNotifications,
    required int unread,
  }) {
    final hasUnread = unread > 0;
    final color =
        hasUnread ? amber : green;
    final panelBackground =
        hasUnread ? softAmber : softGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        10,
        10,
      ),
      decoration: BoxDecoration(
        color: panelBackground,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(
            alpha: 0.12,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(
              alpha: 0.045,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _iconBox(
            icon: hasUnread
                ? Icons.notifications_active_outlined
                : Icons.mark_email_read_outlined,
            color: color,
            background: Colors.white,
            size: 38,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  hasUnread
                      ? '$unread aktivitas baru'
                      : 'Semua aktivitas sudah dibaca',
                  style: TextStyle(
                    color: color,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasUnread
                      ? 'Buka kartu notifikasi atau tandai semuanya sebagai dibaca.'
                      : 'Belum ada notifikasi admin yang perlu diperiksa.',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9.0,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (hasUnread) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: isProcessing
                  ? null
                  : () {
                      _markAllAsRead(
                        allNotifications,
                      );
                    },
              style: TextButton.styleFrom(
                foregroundColor: amber,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                minimumSize: Size.zero,
                tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Baca Semua',
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterSection({
    required int total,
    required int unread,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip(
            label: 'Semua',
            value: 'semua',
            count: total,
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(width: 9),
          _filterChip(
            label: 'Belum Dibaca',
            value: 'belum',
            count: unread,
            icon: Icons.mark_email_unread_outlined,
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    required int count,
    required IconData icon,
  }) {
    final selected =
        selectedFilter == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFilter = value;
          });
        },
        borderRadius:
            BorderRadius.circular(99),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 170),
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: selected
                ? adminPurple
                : Colors.white.withValues(
                    alpha: 0.98,
                  ),
            borderRadius:
                BorderRadius.circular(99),
            border: Border.all(
              color: selected
                  ? adminPurple
                  : cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: adminNavy.withValues(
                  alpha: selected ? 0.10 : 0.035,
                ),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : textGrey,
                size: 10.5,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : textGrey,
                  fontSize: 8.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 20,
                ),
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(
                          alpha: 0.18,
                        )
                      : pageBackground,
                  borderRadius:
                      BorderRadius.circular(99),
                ),
                child: Text(
                  count > 99
                      ? '99+'
                      : count.toString(),
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : textGrey,
                    fontSize: 8.0,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required int resultCount,
  }) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 34,
          decoration: BoxDecoration(
            color: adminPurple,
            borderRadius:
                BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Aktivitas Notifikasi',
                style: TextStyle(
                  color: textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pengajuan dan aktivitas terbaru dari anggota.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 8.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: softPurple,
            borderRadius:
                BorderRadius.circular(99),
          ),
          child: Text(
            '$resultCount data',
            style: const TextStyle(
              color: adminPurple,
              fontSize: 8.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _content({
    required bool loading,
    required bool error,
    required String? errorMessage,
    required Map<String,
            List<Map<String, dynamic>>>
        grouped,
  }) {
    if (loading) {
      return _loadingState();
    }

    if (error) {
      return _messageState(
        icon: Icons.cloud_off_outlined,
        title: 'Notifikasi Gagal Dimuat',
        message: errorMessage == null ||
                errorMessage.trim().isEmpty
            ? 'Periksa koneksi internet lalu tarik halaman ke bawah.'
            : errorMessage,
        color: red,
        background: softRed,
      );
    }

    if (grouped.isEmpty) {
      return _messageState(
        icon: selectedFilter == 'belum'
            ? Icons.mark_email_read_outlined
            : Icons.notifications_none_outlined,
        title: selectedFilter == 'belum'
            ? 'Tidak Ada Aktivitas Baru'
            : 'Belum Ada Notifikasi',
        message: selectedFilter == 'belum'
            ? 'Semua notifikasi admin sudah dibaca.'
            : 'Aktivitas baru akan muncul ketika anggota mengirim pengajuan.',
        color: adminPurple,
        background: softPurple,
      );
    }

    final groupKeys = grouped.keys.toList();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: groupKeys.map((groupTitle) {
        final items =
            grouped[groupTitle] ?? [];

        return Padding(
          padding:
              const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _dateLabel(groupTitle),
              const SizedBox(height: 4),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth >= 700
                          ? 2
                          : 1;

                  const gap = 9.0;

                  final itemWidth = columns == 2
                      ? (constraints.maxWidth -
                              gap) /
                          2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: items.map((item) {
                      return SizedBox(
                        width: itemWidth,
                        child: _notificationCard(
                          item,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _dateLabel(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: softPurple,
        borderRadius:
            BorderRadius.circular(99),
        border: Border.all(
          color: adminPurple.withValues(
            alpha: 0.11,
          ),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: adminPurple,
          fontSize: 8.7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _notificationCard(
    Map<String, dynamic> item,
  ) {
    final id =
        (item['id_notifikasi'] ?? '').toString();

    final title = (item['judul'] ??
            item['title'] ??
            'Notifikasi Admin')
        .toString()
        .trim();

    final message = (item['pesan'] ??
            item['message'] ??
            item['keterangan'] ??
            '-')
        .toString()
        .trim();

    final type = _type(item);
    final color = _typeColor(type);
    final unread = _isUnread(item);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: unread && id.isNotEmpty
            ? () {
                _markAsRead(id);
              }
            : null,
        borderRadius:
            BorderRadius.circular(24),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(
            11,
            10,
            11,
            9,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.99,
            ),
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color: unread
                  ? color.withValues(
                      alpha: 0.24,
                    )
                  : cardBorder,
              width: unread ? 1.25 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: adminNavy.withValues(
                  alpha: unread ? 0.075 : 0.045,
                ),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _iconBox(
                        icon: _typeIcon(type),
                        color: color,
                        background:
                            color.withValues(
                          alpha: 0.10,
                        ),
                        size: 43,
                      ),
                      if (unread)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _typeBadge(
                              label:
                                  _typeLabel(type),
                              color: color,
                            ),
                            const Spacer(),
                            Text(
                              _timeText(item),
                              style:
                                  const TextStyle(
                                color: textSoft,
                                fontSize: 8.7,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title.isEmpty
                              ? 'Notifikasi Admin'
                              : title,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textDark,
                            fontSize: 12.8,
                            height: 1.25,
                            fontWeight: unread
                                ? FontWeight.w900
                                : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message.isEmpty
                              ? '-'
                              : message,
                          maxLines: 4,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: textGrey,
                            fontSize: 9.8,
                            height: 1.45,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statusBadge(unread),
                  const Spacer(),
                  if (unread)
                    const Text(
                      'Ketuk untuk baca',
                      style: TextStyle(
                        color: textSoft,
                        fontSize: 8.3,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius:
            BorderRadius.circular(99),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 7.4,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _statusBadge(bool unread) {
    final color = unread ? amber : green;
    final background =
        unread ? softAmber : softGreen;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unread
                ? Icons.mark_email_unread_outlined
                : Icons.mark_email_read_outlined,
            color: color,
            size: 10.5,
          ),
          const SizedBox(width: 5),
          Text(
            unread
                ? 'Belum dibaca'
                : 'Dibaca',
            style: TextStyle(
              color: color,
              fontSize: 8.3,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          margin:
              const EdgeInsets.only(bottom: 9),
          height: 105,
          padding: const EdgeInsets.all(11),
          decoration: _cardDecoration(
            radius: 18,
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: cardBorder,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 11,
                      decoration: BoxDecoration(
                        color: cardBorder,
                        borderRadius:
                            BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: cardBorder,
                        borderRadius:
                            BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 9,
                      width: 120,
                      alignment:
                          Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: cardBorder,
                        borderRadius:
                            BorderRadius.circular(99),
                      ),
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

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: _cardDecoration(
        radius: 21,
      ),
      child: Column(
        children: [
          _iconBox(
            icon: icon,
            color: color,
            background: background,
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 9.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 9.8,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _processingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: adminNavy.withValues(
            alpha: 0.25,
          ),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              16,
            ),
            constraints: const BoxConstraints(
              maxWidth: 270,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(21),
              boxShadow: [
                BoxShadow(
                  color: adminNavy.withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 11),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 32,
                  width: 32,
                  child:
                      CircularProgressIndicator(
                    color: adminPurple,
                    strokeWidth: 2.8,
                  ),
                ),
                SizedBox(height: 11),
                Text(
                  'Memproses Notifikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 9.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Mohon tunggu sebentar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: isProcessing
            ? null
            : () {
                FocusScope.of(context).unfocus();
                Navigator.maybePop(context);
              },
        borderRadius:
            BorderRadius.circular(14),
        child: _iconBox(
          icon: Icons.arrow_back_rounded,
          color: Colors.white,
          background:
              Colors.white.withValues(
            alpha: 0.14,
          ),
          size: 42,
        ),
      ),
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color color,
    required Color background,
    required double size,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          size * 0.32,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.98,
      ),
      borderRadius:
          BorderRadius.circular(radius),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: adminNavy.withValues(
            alpha: 0.045,
          ),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _AdminNotificationBackground
    extends StatelessWidget {
  const _AdminNotificationBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortest =
                constraints.maxWidth <
                        constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;

            final large = (shortest * 1.05)
                .clamp(290.0, 520.0)
                .toDouble();

            final medium = (shortest * 0.68)
                .clamp(190.0, 340.0)
                .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.topCenter,
                        end:
                            Alignment.bottomCenter,
                        colors: [
                          Color(0xff172A46),
                          Color(0xff435987),
                          Color(0xffE5E7F1),
                          Color(0xffF2F4F8),
                        ],
                        stops: [
                          0,
                          0.16,
                          0.42,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.58,
                    right: -large * 0.30,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(
                        0xff8D7AD0,
                      ),
                      opacity: 0.24,
                    ),
                  ),
                  Positioned(
                    top:
                        constraints.maxHeight *
                            0.31,
                    left: -medium * 0.56,
                    child: _BackgroundCircle(
                      size: medium,
                      color: const Color(
                        0xffB8C4E0,
                      ),
                      opacity: 0.36,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.55,
                    left: -large * 0.30,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(
                        0xffE3E6F4,
                      ),
                      opacity: 0.84,
                    ),
                  ),
                  Positioned(
                    right: 26,
                    top:
                        constraints.maxHeight *
                            0.22,
                    child: Icon(
                      Icons
                          .notifications_none_outlined,
                      size: (shortest * 0.19)
                          .clamp(64.0, 118.0)
                          .toDouble(),
                      color: Colors.white.withValues(
                        alpha: 0.055,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _BackgroundCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: opacity,
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}