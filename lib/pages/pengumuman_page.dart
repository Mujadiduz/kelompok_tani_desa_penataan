import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class PengumumanPage extends StatefulWidget {
  const PengumumanPage({super.key});

  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color deepTeal = Color(0xff0E5F57);
  static const Color teal = Color(0xff167A6B);
  static const Color tealLight = Color(0xff248C76);
  static const Color blue = Color(0xff326FA3);
  static const Color amber = Color(0xffD98212);
  static const Color purple = Color(0xff7159B4);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color softBlue = Color(0xffEAF3FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softPurple = Color(0xffF0ECFA);

  static const Color pageBackground = Color(0xffF2F7F5);
  static const Color cardBorder = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  final DatabaseReference _pengumumanRef =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref('pengumuman');

  Future<void> _refreshData() async {
    await _pengumumanRef.get();
  }

  List<Map<String, dynamic>> _getAnnouncements(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list = data.entries
        .where((entry) => entry.value is Map)
        .map((entry) {
          final item = Map<String, dynamic>.from(entry.value as Map);
          item['id'] = entry.key.toString();
          return item;
        })
        .where((item) {
          final status =
              (item['status'] ?? 'aktif').toString().toLowerCase().trim();
          return status == 'aktif';
        })
        .toList();

    list.sort((a, b) => _timeValue(b).compareTo(_timeValue(a)));
    return list;
  }

  int _timeValue(Map<String, dynamic> item) {
    final raw =
        item['created_at'] ??
        item['createdAt'] ??
        item['tanggal'] ??
        item['tgl'];

    if (raw is int) return raw;
    if (raw is double) return raw.toInt();

    final parsed = DateTime.tryParse((raw ?? '').toString().trim());
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String _formatDate(dynamic value) {
    final raw = (value ?? '').toString().trim();

    if (raw.isEmpty || raw == '-') {
      return 'Tanggal tidak tersedia';
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _categoryLabel(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return 'Info Pupuk';
    if (clean == 'alat') return 'Info Alat';
    if (clean == 'rapat') return 'Rapat';
    if (clean == 'panen') return 'Panen';
    if (clean == 'gotong_royong') return 'Gotong Royong';

    return 'Umum';
  }

  IconData _categoryIcon(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return Icons.inventory_2_outlined;
    if (clean == 'alat') return Icons.handyman_outlined;
    if (clean == 'rapat') return Icons.groups_2_outlined;
    if (clean == 'panen') return Icons.grass_outlined;
    if (clean == 'gotong_royong') {
      return Icons.volunteer_activism_outlined;
    }

    return Icons.campaign_outlined;
  }

  Color _categoryColor(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return primaryGreen;
    if (clean == 'alat') return amber;
    if (clean == 'rapat') return blue;
    if (clean == 'panen') return deepTeal;
    if (clean == 'gotong_royong') return purple;

    return teal;
  }

  Color _categoryBackground(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return softGreen;
    if (clean == 'alat') return softAmber;
    if (clean == 'rapat') return softBlue;
    if (clean == 'panen') return softTeal;
    if (clean == 'gotong_royong') return softPurple;

    return softTeal;
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PengumumanDetailPage(
          item: item,
          formatDate: _formatDate,
          categoryLabel: _categoryLabel,
          categoryIcon: _categoryIcon,
          categoryColor: _categoryColor,
          categoryBackground: _categoryBackground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 340 ? 13.0 : 17.0;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _UserDashboardBackground(),
              SafeArea(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _pengumumanRef.onValue,
                  builder: (context, snapshot) {
                    final announcements = _getAnnouncements(
                      snapshot.data?.snapshot.value,
                    );

                    return RefreshIndicator(
                      color: teal,
                      backgroundColor: Colors.white,
                      onRefresh: _refreshData,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          13,
                          horizontalPadding,
                          30,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 720,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _header(announcements.length),
                                  const SizedBox(height: 14),
                                  _heroAnnouncement(announcements),
                                  const SizedBox(height: 14),
                                  _sectionHeader(announcements.length),
                                  const SizedBox(height: 11),
                                  _content(
                                    isLoading:
                                        snapshot.connectionState ==
                                        ConnectionState.waiting,
                                    hasError: snapshot.hasError,
                                    errorMessage: snapshot.error?.toString(),
                                    announcements: announcements,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepTeal,
            teal,
            tealLight,
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _headerIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (!mounted) return;
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengumuman',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Kabar resmi dari admin TaniGo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 10.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(
              minWidth: 45,
              minHeight: 42,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: Center(
                    child: Icon(
                      Icons.campaign_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  total > 99 ? '99+' : total.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          width: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _heroAnnouncement(
    List<Map<String, dynamic>> announcements,
  ) {
    if (announcements.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _safeIconBox(
              icon: Icons.info_outline_rounded,
              color: amber,
              backgroundColor: softAmber,
              size: 46,
              iconSize: 22,
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum ada pengumuman aktif',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Informasi terbaru dari admin akan tampil pada halaman ini.',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 10.5,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final latest = announcements.first;
    final title =
        (latest['judul'] ?? 'Pengumuman Terbaru').toString();
    final body = (latest['isi'] ?? '-').toString();
    final category = (latest['kategori'] ?? 'umum').toString();
    final date = _formatDate(
      latest['tanggal'] ?? latest['created_at'],
    );
    final color = _categoryColor(category);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: () => _openDetail(latest),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                Color.lerp(color, Colors.black, 0.18) ?? color,
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _safeIconBox(
                    icon: _categoryIcon(category),
                    color: Colors.white,
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.16),
                    size: 48,
                    iconSize: 23,
                    borderColor:
                        Colors.white.withValues(alpha: 0.14),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroLabel(category),
                        const SizedBox(height: 5),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.87),
                  fontSize: 11.7,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.82),
                              fontSize: 10.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.17),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Baca Detail',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.3,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ],
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

  Widget _heroLabel(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.13),
        ),
      ),
      child: Text(
        'TERBARU • ${_categoryLabel(category).toUpperCase()}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _sectionHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: softTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: teal.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _safeIconBox(
            icon: Icons.newspaper_outlined,
            color: teal,
            backgroundColor: Colors.white,
            size: 40,
            iconSize: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Terbaru',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pengumuman aktif dari admin kelompok tani',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 9.8,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$total AKTIF',
              style: const TextStyle(
                color: teal,
                fontSize: 8.4,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content({
    required bool isLoading,
    required bool hasError,
    required String? errorMessage,
    required List<Map<String, dynamic>> announcements,
  }) {
    if (isLoading) {
      return Column(
        children: List.generate(
          3,
          (_) => _loadingCard(),
        ),
      );
    }

    if (hasError) {
      return _emptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Pengumuman Gagal Dimuat',
        message:
            errorMessage ?? 'Periksa koneksi internet atau Firebase.',
        color: blue,
        backgroundColor: softBlue,
      );
    }

    if (announcements.isEmpty) {
      return _emptyState(
        icon: Icons.campaign_outlined,
        title: 'Belum Ada Pengumuman',
        message:
            'Pengumuman dari admin kelompok tani akan tampil di sini.',
        color: teal,
        backgroundColor: softTeal,
      );
    }

    return Column(
      children: [
        for (final item in announcements) _announcementCard(item),
      ],
    );
  }

  Widget _announcementCard(Map<String, dynamic> item) {
    final title =
        (item['judul'] ?? 'Pengumuman Desa').toString();
    final body = (item['isi'] ?? '-').toString();
    final date = _formatDate(
      item['tanggal'] ?? item['created_at'],
    );
    final category = (item['kategori'] ?? 'umum').toString();
    final color = _categoryColor(category);
    final backgroundColor = _categoryBackground(category);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(radius: 21),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          onTap: () => _openDetail(item),
          borderRadius: BorderRadius.circular(21),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _safeIconBox(
                  icon: _categoryIcon(category),
                  color: color,
                  backgroundColor: backgroundColor,
                  size: 48,
                  iconSize: 22,
                  borderColor: color.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _categoryLabel(category).toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontSize: 8.8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 31,
                            width: 31,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: color,
                              size: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 10.7,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: textSoft,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textSoft,
                                fontSize: 9.7,
                                fontWeight: FontWeight.w700,
                              ),
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
      ),
    );
  }

  Widget _safeIconBox({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required double size,
    required double iconSize,
    Color? borderColor,
  }) {
    return SizedBox(
      height: size,
      width: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size * 0.31),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor),
        ),
        child: Center(
          child: SizedBox(
            height: iconSize + 4,
            width: iconSize + 4,
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 21),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.42,
                  child: Container(
                    height: 9,
                    decoration: BoxDecoration(
                      color: cardBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.76,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: cardBorder,
                      borderRadius: BorderRadius.circular(999),
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

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          _safeIconBox(
            icon: icon,
            color: color,
            backgroundColor: backgroundColor,
            size: 76,
            iconSize: 34,
            borderColor: color.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 16.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 11.4,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: deepTeal.withValues(alpha: 0.055),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _PengumumanDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic value) formatDate;
  final String Function(String category) categoryLabel;
  final IconData Function(String category) categoryIcon;
  final Color Function(String category) categoryColor;
  final Color Function(String category) categoryBackground;

  const _PengumumanDetailPage({
    required this.item,
    required this.formatDate,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryBackground,
  });

  static const Color deepTeal = Color(0xff0E5F57);
  static const Color teal = Color(0xff167A6B);
  static const Color tealLight = Color(0xff248C76);
  static const Color pageBackground = Color(0xffF2F7F5);
  static const Color cardBorder = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 340 ? 13.0 : 17.0;

    final title =
        (item['judul'] ?? 'Pengumuman Desa').toString();
    final body = (item['isi'] ?? '-').toString();
    final date = formatDate(
      item['tanggal'] ?? item['created_at'],
    );
    final category = (item['kategori'] ?? 'umum').toString();
    final color = categoryColor(category);
    final backgroundColor = categoryBackground(category);

    return Scaffold(
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _UserDashboardBackground(),
              SafeArea(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    13,
                    horizontalPadding,
                    30,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 720,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            _detailHeader(context),
                            const SizedBox(height: 14),
                            _heroDetail(
                              title: title,
                              date: date,
                              category: category,
                              color: color,
                            ),
                            const SizedBox(height: 14),
                            _bodyCard(
                              body: body,
                              color: color,
                              backgroundColor: backgroundColor,
                            ),
                            const SizedBox(height: 12),
                            _detailCaption(),
                          ],
                        ),
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

  Widget _detailHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepTeal,
            teal,
            tealLight,
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 42,
                width: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detail Pengumuman',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Informasi lengkap dari admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 10.7,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 42,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            child: const Icon(
              Icons.article_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDetail({
    required String title,
    required String date,
    required String category,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.18) ?? color,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _detailIconBox(
                icon: categoryIcon(category),
                color: Colors.white,
                backgroundColor:
                    Colors.white.withValues(alpha: 0.16),
                size: 48,
                iconSize: 23,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  categoryLabel(category).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.3,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Colors.white,
                size: 15,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 10.8,
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

  Widget _bodyCard({
    required String body,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        16,
      ),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _detailIconBox(
                icon: Icons.description_outlined,
                color: color,
                backgroundColor: backgroundColor,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Isi Pengumuman',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Informasi resmi dari admin TaniGo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 9.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: color.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              body,
              style: const TextStyle(
                color: textDark,
                fontSize: 12.4,
                height: 1.65,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailIconBox({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required double size,
    required double iconSize,
  }) {
    return SizedBox(
      height: size,
      width: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size * 0.31),
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _detailCaption() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified_user_outlined,
          color: textSoft,
          size: 14,
        ),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            'Pengumuman resmi dari admin TaniGo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSoft,
              fontSize: 9.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: deepTeal.withValues(alpha: 0.055),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _UserDashboardBackground extends StatelessWidget {
  const _UserDashboardBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final baseSize = width < height ? width : height;

            final largeCircle = (baseSize * 0.98)
                .clamp(280.0, 460.0)
                .toDouble();

            final mediumCircle = (baseSize * 0.68)
                .clamp(190.0, 330.0)
                .toDouble();

            final smallCircle = (baseSize * 0.42)
                .clamp(120.0, 205.0)
                .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xff0E5F57),
                          Color(0xff177A6B),
                          Color(0xffDDEFEA),
                          Color(0xffF2F7F5),
                        ],
                        stops: [
                          0,
                          0.22,
                          0.49,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -largeCircle * 0.54,
                    right: -largeCircle * 0.29,
                    child: _DashboardCircle(
                      size: largeCircle,
                      color: const Color(0xff53B69C),
                      alpha: 0.20,
                      borderColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.12,
                    left: -smallCircle * 0.24,
                    child: _DashboardRing(
                      size: smallCircle,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: height * 0.28,
                    left: -mediumCircle * 0.57,
                    child: _DashboardCircle(
                      size: mediumCircle,
                      color: const Color(0xffA9DCCF),
                      alpha: 0.38,
                      borderColor: const Color(0xff167A6B),
                    ),
                  ),
                  Positioned(
                    top: height * 0.48,
                    right: -mediumCircle * 0.61,
                    child: _DashboardCircle(
                      size: mediumCircle * 1.08,
                      color: const Color(0xffE6F2F8),
                      alpha: 0.84,
                      borderColor: const Color(0xff326FA3),
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.52,
                    left: -largeCircle * 0.30,
                    child: _DashboardCircle(
                      size: largeCircle,
                      color: const Color(0xffDDEFE5),
                      alpha: 0.82,
                      borderColor: const Color(0xff2E7D32),
                    ),
                  ),
                  Positioned(
                    bottom: -mediumCircle * 0.36,
                    right: -mediumCircle * 0.43,
                    child: _DashboardCircle(
                      size: mediumCircle,
                      color: const Color(0xffEAF3FA),
                      alpha: 0.88,
                      borderColor: const Color(0xff326FA3),
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

class _DashboardCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  final Color borderColor;

  const _DashboardCircle({
    required this.size,
    required this.color,
    required this.alpha,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor.withValues(alpha: 0.08),
          width: 2,
        ),
      ),
    );
  }
}

class _DashboardRing extends StatelessWidget {
  final double size;
  final Color color;

  const _DashboardRing({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }
}
