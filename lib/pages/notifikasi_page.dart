import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class NotifikasiPage extends StatefulWidget {
  final String nik;

  const NotifikasiPage({
    super.key,
    required this.nik,
  });

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  static const Color _darkGreen = Color(0xff14532D);
  static const Color _primaryGreen = Color(0xff2E7D32);
  static const Color _teal = Color(0xff167A6B);
  static const Color _blue = Color(0xff326FA3);
  static const Color _amber = Color(0xffD98212);
  static const Color _red = Color(0xffC83B3B);
  static const Color _purple = Color(0xff6946C6);

  static const Color _pageBackground = Color(0xffF2F7F5);
  static const Color _cardBorder = Color(0xffE0E8E5);
  static const Color _textDark = Color(0xff18212B);
  static const Color _textGrey = Color(0xff66727F);
  static const Color _textSoft = Color(0xff8B96A2);

  static const Color _softGreen = Color(0xffE9F5EB);
  static const Color _softTeal = Color(0xffE6F4F1);
  static const Color _softBlue = Color(0xffEAF3FA);
  static const Color _softAmber = Color(0xffFFF3DD);
  static const Color _softRed = Color(0xffFBEAEA);
  static const Color _softPurple = Color(0xffF0EBFC);

  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _notificationRef;

  String _selectedFilter = 'semua';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    final normalizedNik = widget.nik
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();

    _notificationRef = _database.ref(
      'notifikasi/${normalizedNik.isEmpty ? widget.nik.trim() : normalizedNik}',
    );
  }

  Map<String, dynamic> _stringMap(dynamic value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }

    return Map<dynamic, dynamic>.from(value).map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    final result = value?.toString().trim() ?? '';

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      try {
        final number = value.toInt();

        return DateTime.fromMillisecondsSinceEpoch(
          number.toString().length >= 13 ? number : number * 1000,
        ).toLocal();
      } catch (_) {
        return null;
      }
    }

    final raw = value.toString().trim();

    if (raw.isEmpty || raw == '-') {
      return null;
    }

    final numeric = int.tryParse(raw);

    if (numeric != null) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(
          raw.length >= 13 ? numeric : numeric * 1000,
        ).toLocal();
      } catch (_) {
        return null;
      }
    }

    return DateTime.tryParse(raw)?.toLocal();
  }

  List<Map<String, dynamic>> _notificationList(dynamic value) {
    if (value is! Map) {
      return <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];

    for (final entry in Map<dynamic, dynamic>.from(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final item = _stringMap(entry.value);
      item['id_notifikasi'] = entry.key.toString();
      result.add(item);
    }

    result.sort((first, second) {
      final firstDate = _parseDate(
        first['tanggal'] ??
            first['created_at'] ??
            first['createdAt'] ??
            first['waktu'],
      );

      final secondDate = _parseDate(
        second['tanggal'] ??
            second['created_at'] ??
            second['createdAt'] ??
            second['waktu'],
      );

      return (secondDate ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(firstDate ?? DateTime.fromMillisecondsSinceEpoch(0));
    });

    return result;
  }

  bool _isUnread(Map<String, dynamic> item) {
    final status = _text(
      item['status'],
      fallback: '',
    ).toLowerCase();

    final readValue = item['dibaca'];

    return status == 'belum_dibaca' ||
        status == 'belum dibaca' ||
        status == 'unread' ||
        readValue == false ||
        readValue?.toString().toLowerCase() == 'false';
  }

  String _type(Map<String, dynamic> item) {
    return _text(
      item['tipe'] ??
          item['jenis'] ??
          item['kategori'],
      fallback: 'info',
    )
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  List<Map<String, dynamic>> _filteredNotifications(
    List<Map<String, dynamic>> source,
  ) {
    if (_selectedFilter == 'belum') {
      return source.where(_isUnread).toList();
    }

    return source;
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> source,
  ) {
    final result = <String, List<Map<String, dynamic>>>{};

    for (final item in source) {
      final date = _parseDate(
        item['tanggal'] ??
            item['created_at'] ??
            item['createdAt'] ??
            item['waktu'],
      );

      final label = _groupLabel(date);
      result.putIfAbsent(label, () => <Map<String, dynamic>>[]);
      result[label]!.add(item);
    }

    return result;
  }

  String _groupLabel(DateTime? date) {
    if (date == null) {
      return 'Tanggal Tidak Diketahui';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (target == today) {
      return 'Hari Ini';
    }

    if (target == yesterday) {
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
    final date = _parseDate(
      item['tanggal'] ??
          item['created_at'] ??
          item['createdAt'] ??
          item['waktu'],
    );

    if (date == null) {
      return '-';
    }

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _typeLabel(String type) {
    if ({
      'bantuan_pupuk',
      'pupuk',
      'verifikasi_pupuk',
    }.contains(type)) {
      return 'Pupuk';
    }

    if ({
      'peminjaman_alat',
      'alat',
      'verifikasi_alat',
    }.contains(type)) {
      return 'Alat';
    }

    if ({
      'keanggotaan',
      'verifikasi_anggota',
      'anggota',
    }.contains(type)) {
      return 'Anggota';
    }

    if ({
      'reset_password',
      'akun',
      'password',
    }.contains(type)) {
      return 'Akun';
    }

    if ({
      'pengumuman',
      'informasi',
    }.contains(type)) {
      return 'Pengumuman';
    }

    return 'Info';
  }

  IconData _typeIcon(String type) {
    if ({
      'bantuan_pupuk',
      'pupuk',
      'verifikasi_pupuk',
    }.contains(type)) {
      return Icons.inventory_2_outlined;
    }

    if ({
      'peminjaman_alat',
      'alat',
      'verifikasi_alat',
    }.contains(type)) {
      return Icons.handyman_outlined;
    }

    if ({
      'keanggotaan',
      'verifikasi_anggota',
      'anggota',
    }.contains(type)) {
      return Icons.verified_user_outlined;
    }

    if ({
      'reset_password',
      'akun',
      'password',
    }.contains(type)) {
      return Icons.lock_reset_rounded;
    }

    if ({
      'pengumuman',
      'informasi',
    }.contains(type)) {
      return Icons.campaign_outlined;
    }

    return Icons.notifications_none_rounded;
  }

  Color _typeColor(String type) {
    if ({
      'bantuan_pupuk',
      'pupuk',
      'verifikasi_pupuk',
    }.contains(type)) {
      return _primaryGreen;
    }

    if ({
      'peminjaman_alat',
      'alat',
      'verifikasi_alat',
    }.contains(type)) {
      return _amber;
    }

    if ({
      'keanggotaan',
      'verifikasi_anggota',
      'anggota',
    }.contains(type)) {
      return _blue;
    }

    if ({
      'reset_password',
      'akun',
      'password',
    }.contains(type)) {
      return _red;
    }

    if ({
      'pengumuman',
      'informasi',
    }.contains(type)) {
      return _purple;
    }

    return _teal;
  }

  Color _typeBackground(String type) {
    final color = _typeColor(type);

    if (color == _primaryGreen) {
      return _softGreen;
    }

    if (color == _amber) {
      return _softAmber;
    }

    if (color == _blue) {
      return _softBlue;
    }

    if (color == _red) {
      return _softRed;
    }

    if (color == _purple) {
      return _softPurple;
    }

    return _softTeal;
  }

  Future<void> _refreshData() async {
    await _notificationRef.get();
  }

  Future<void> _markAsRead(String id) async {
    if (id.isEmpty) {
      return;
    }

    try {
      await _notificationRef.child(id).update({
        'status': 'dibaca',
        'dibaca': true,
      }).timeout(
        const Duration(seconds: 10),
      );
    } catch (error) {
      debugPrint('Gagal menandai notifikasi: $error');

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal menandai notifikasi.',
        _red,
      );
    }
  }

  Future<void> _markAllAsRead(
    List<Map<String, dynamic>> notifications,
  ) async {
    if (_isProcessing) {
      return;
    }

    final updates = <String, Object?>{};

    for (final item in notifications) {
      if (!_isUnread(item)) {
        continue;
      }

      final id = _text(
        item['id_notifikasi'],
        fallback: '',
      );

      if (id.isEmpty) {
        continue;
      }

      updates['$id/status'] = 'dibaca';
      updates['$id/dibaca'] = true;
    }

    if (updates.isEmpty) {
      _showSnackBar(
        'Semua notifikasi sudah dibaca.',
        _primaryGreen,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _notificationRef.update(updates).timeout(
        const Duration(seconds: 12),
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Semua notifikasi sudah dibaca.',
        _primaryGreen,
      );
    } catch (error) {
      debugPrint('Gagal membaca semua notifikasi: $error');

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal membaca semua notifikasi.',
        _red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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
    final screenWidth = MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 350
        ? 12.0
        : screenWidth >= 700
            ? 22.0
            : 16.0;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const _NotificationBackground(),
                SafeArea(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _notificationRef.onValue,
                    builder: (context, snapshot) {
                      final allNotifications = _notificationList(
                        snapshot.data?.snapshot.value,
                      );

                      final unreadCount = allNotifications
                          .where(_isUnread)
                          .length;

                      final readCount =
                          allNotifications.length - unreadCount;

                      final filtered = _filteredNotifications(
                        allNotifications,
                      );

                      final grouped = _groupByDate(filtered);

                      return RefreshIndicator(
                        color: _teal,
                        backgroundColor: Colors.white,
                        onRefresh: _refreshData,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            12,
                            horizontalPadding,
                            28,
                          ),
                          children: <Widget>[
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 760,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    _header(
                                      unreadCount: unreadCount,
                                    ),
                                    const SizedBox(height: 10),
                                    _summarySection(
                                      total: allNotifications.length,
                                      unread: unreadCount,
                                      read: readCount,
                                    ),
                                    const SizedBox(height: 10),
                                    _activityPanel(
                                      notifications: allNotifications,
                                      unreadCount: unreadCount,
                                    ),
                                    const SizedBox(height: 10),
                                    _filterSection(
                                      totalCount:
                                          allNotifications.length,
                                      unreadCount: unreadCount,
                                    ),
                                    const SizedBox(height: 16),
                                    _sectionTitle(
                                      resultCount: filtered.length,
                                    ),
                                    const SizedBox(height: 9),
                                    _content(
                                      snapshot: snapshot,
                                      grouped: grouped,
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
                if (_isProcessing) _processingOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header({
    required int unreadCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 370;

        return Container(
          padding: EdgeInsets.all(
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[
                _darkGreen,
                _teal,
                _primaryGreen,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _darkGreen.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              _backButton(),
              SizedBox(width: compact ? 9 : 11),
              _iconBox(
                icon: unreadCount > 0
                    ? Icons.notifications_active_outlined
                    : Icons.mark_email_read_outlined,
                color: Colors.white,
                background:
                    Colors.white.withValues(alpha: 0.14),
                size: compact ? 43 : 47,
              ),
              SizedBox(width: compact ? 9 : 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Notifikasi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Aktivitas terbaru layanan TaniGo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xffD7EEE7),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
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
        final gap = constraints.maxWidth < 350 ? 6.0 : 8.0;
        final itemWidth =
            (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            SizedBox(
              width: itemWidth,
              child: _summaryItem(
                label: 'Semua',
                value: total,
                icon: Icons.notifications_none_rounded,
                color: _teal,
                background: _softTeal,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryItem(
                label: 'Belum Dibaca',
                value: unread,
                icon: Icons.mark_email_unread_outlined,
                color: _amber,
                background: _softAmber,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryItem(
                label: 'Dibaca',
                value: read,
                icon: Icons.mark_email_read_outlined,
                color: _primaryGreen,
                background: _softGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 9,
      ),
      decoration: _cardDecoration(
        radius: 17,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value > 999 ? '999+' : '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15.5,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 8.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityPanel({
    required List<Map<String, dynamic>> notifications,
    required int unreadCount,
  }) {
    final hasUnread = unreadCount > 0;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: hasUnread ? _softAmber : _softGreen,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (hasUnread ? _amber : _primaryGreen)
              .withValues(alpha: 0.11),
        ),
      ),
      child: Row(
        children: <Widget>[
          _iconBox(
            icon: hasUnread
                ? Icons.notifications_active_outlined
                : Icons.task_alt_outlined,
            color: hasUnread ? _amber : _primaryGreen,
            background: Colors.white,
            size: 39,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hasUnread
                      ? '$unreadCount aktivitas baru'
                      : 'Semua aktivitas sudah dibaca',
                  style: TextStyle(
                    color: hasUnread ? _amber : _primaryGreen,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasUnread
                      ? 'Buka kartu notifikasi atau tandai semuanya sebagai dibaca.'
                      : 'Pemberitahuan baru akan tampil otomatis di halaman ini.',
                  style: const TextStyle(
                    color: _textGrey,
                    fontSize: 9.2,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (hasUnread) ...<Widget>[
            const SizedBox(width: 8),
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      _markAllAsRead(notifications);
                    },
              style: TextButton.styleFrom(
                foregroundColor: _amber,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'Baca Semua',
                style: TextStyle(
                  fontSize: 9.2,
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
    required int totalCount,
    required int unreadCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: <Widget>[
          _filterChip(
            label: 'Semua',
            value: 'semua',
            count: totalCount,
            icon: Icons.grid_view_rounded,
          ),
          const SizedBox(width: 7),
          _filterChip(
            label: 'Belum Dibaca',
            value: 'belum',
            count: unreadCount,
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
    final selected = _selectedFilter == value;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        borderRadius: BorderRadius.circular(99),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected ? _teal : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? _teal : _cardBorder,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _darkGreen.withValues(alpha: 0.025),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                color: selected ? Colors.white : _textGrey,
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color:
                      selected ? Colors.white : _textGrey,
                  fontSize: 9.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.18)
                      : _pageBackground,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : _textGrey,
                    fontSize: 8.1,
                    fontWeight: FontWeight.w900,
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
      children: <Widget>[
        Container(
          width: 5,
          height: 30,
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Aktivitas Notifikasi',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Perubahan status layanan pengguna.',
                style: TextStyle(
                  color: _textGrey,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _softTeal,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$resultCount data',
            style: const TextStyle(
              color: _teal,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _content({
    required AsyncSnapshot<DatabaseEvent> snapshot,
    required Map<String, List<Map<String, dynamic>>> grouped,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _loadingContent();
    }

    if (snapshot.hasError) {
      return _messageState(
        icon: Icons.cloud_off_outlined,
        title: 'Notifikasi Gagal Dimuat',
        message:
            'Periksa koneksi internet lalu tarik halaman ke bawah.',
        color: _red,
        background: _softRed,
      );
    }

    if (grouped.isEmpty) {
      return _messageState(
        icon: _selectedFilter == 'belum'
            ? Icons.mark_email_read_outlined
            : Icons.notifications_none_rounded,
        title: _selectedFilter == 'belum'
            ? 'Tidak Ada Notifikasi Baru'
            : 'Belum Ada Notifikasi',
        message: _selectedFilter == 'belum'
            ? 'Semua aktivitas sudah dibaca.'
            : 'Notifikasi akan tampil ketika status layanan berubah.',
        color: _teal,
        background: _softTeal,
      );
    }

    return Column(
      children: grouped.entries.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _dateHeader(group.key),
              const SizedBox(height: 7),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      constraints.maxWidth >= 700 ? 2 : 1;

                  const gap = 9.0;

                  final width = columns == 2
                      ? (constraints.maxWidth - gap) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: group.value.map((item) {
                      return SizedBox(
                        width: width,
                        child: _notificationCard(item),
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

  Widget _dateHeader(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: _softTeal,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: _teal.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _teal,
            fontSize: 8.8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _notificationCard(
    Map<String, dynamic> item,
  ) {
    final id = _text(
      item['id_notifikasi'],
      fallback: '',
    );

    final title = _text(
      item['judul'] ??
          item['title'],
      fallback: 'Notifikasi',
    );

    final message = _text(
      item['pesan'] ??
          item['message'] ??
          item['keterangan'],
      fallback: 'Tidak ada keterangan.',
    );

    final type = _type(item);
    final unread = _isUnread(item);
    final color = _typeColor(type);
    final itemBackground = _typeBackground(type);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: unread && id.isNotEmpty
            ? () {
                _markAsRead(id);
              }
            : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: unread
                ? Colors.white
                : Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? color.withValues(alpha: 0.24)
                  : _cardBorder,
              width: unread ? 1.2 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: _darkGreen.withValues(
                  alpha: unread ? 0.055 : 0.035,
                ),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      _iconBox(
                        icon: _typeIcon(type),
                        color: color,
                        background: itemBackground,
                        size: 42,
                      ),
                      if (unread)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: Container(
                            height: 9,
                            width: 9,
                            decoration: BoxDecoration(
                              color: _red,
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
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            _smallBadge(
                              label: _typeLabel(type),
                              color: color,
                              background: itemBackground,
                            ),
                            const Spacer(),
                            Text(
                              _timeText(item),
                              style: const TextStyle(
                                color: _textSoft,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textDark,
                            fontSize: 12.2,
                            height: 1.25,
                            fontWeight: unread
                                ? FontWeight.w900
                                : FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textGrey,
                            fontSize: 9.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: <Widget>[
                  Icon(
                    unread
                        ? Icons.mark_email_unread_outlined
                        : Icons.mark_email_read_outlined,
                    color: unread ? _amber : _primaryGreen,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    unread ? 'Belum dibaca' : 'Sudah dibaca',
                    style: TextStyle(
                      color: unread ? _amber : _primaryGreen,
                      fontSize: 8.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (unread)
                    const Text(
                      'Ketuk untuk baca',
                      style: TextStyle(
                        color: _textSoft,
                        fontSize: 8.4,
                        fontWeight: FontWeight.w600,
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

  Widget _smallBadge({
    required String label,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.09),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 7.4,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _loadingContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        const gap = 9.0;

        final width = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List<Widget>.generate(4, (index) {
            return SizedBox(
              width: width,
              child: Container(
                height: 126,
                padding: const EdgeInsets.all(11),
                decoration: _cardDecoration(radius: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: _cardBorder,
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            height: 9,
                            width: 58,
                            decoration: BoxDecoration(
                              color: _cardBorder,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 11,
                            decoration: BoxDecoration(
                              color: _cardBorder,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 9,
                            decoration: BoxDecoration(
                              color: _cardBorder,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            height: 9,
                            width: 120,
                            decoration: BoxDecoration(
                              color: _cardBorder,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
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
        vertical: 29,
      ),
      decoration: _cardDecoration(radius: 21),
      child: Column(
        children: <Widget>[
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
              color: _textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textGrey,
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
          color: _darkGreen.withValues(alpha: 0.23),
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
              maxWidth: 280,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _darkGreen.withValues(alpha: 0.17),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 31,
                  width: 31,
                  child: CircularProgressIndicator(
                    color: _teal,
                    strokeWidth: 2.7,
                  ),
                ),
                SizedBox(height: 11),
                Text(
                  'Memproses Notifikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Mohon tunggu sebentar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textGrey,
                    fontSize: 9.1,
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _isProcessing
            ? null
            : () {
                FocusScope.of(context).unfocus();
                Navigator.maybePop(context);
              },
        borderRadius: BorderRadius.circular(14),
        child: _iconBox(
          icon: Icons.arrow_back_rounded,
          color: Colors.white,
          background:
              Colors.white.withValues(alpha: 0.14),
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
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _cardBorder),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: _darkGreen.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class _NotificationBackground extends StatelessWidget {
  const _NotificationBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = constraints.maxWidth <
                    constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            final large = (base * 0.98)
                .clamp(280.0, 470.0)
                .toDouble();

            final medium = (base * 0.67)
                .clamp(190.0, 330.0)
                .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0xff14532D),
                          Color(0xff167A6B),
                          Color(0xffDDEFEA),
                          Color(0xffF2F7F5),
                        ],
                        stops: <double>[
                          0,
                          0.18,
                          0.43,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.55,
                    right: -large * 0.30,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(0xff58B89F),
                      alpha: 0.20,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.31,
                    left: -medium * 0.58,
                    child: _BackgroundCircle(
                      size: medium,
                      color: const Color(0xffA7DACD),
                      alpha: 0.34,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.31,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(0xffDDEFE6),
                      alpha: 0.82,
                    ),
                  ),
                  Positioned(
                    right: -28,
                    top: constraints.maxHeight * 0.52,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: medium * 0.58,
                      color: Colors.white.withValues(
                        alpha: 0.08,
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
  final double alpha;

  const _BackgroundCircle({
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}