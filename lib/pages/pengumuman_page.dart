import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PengumumanPage extends StatefulWidget {
  const PengumumanPage({super.key});

  @override
  State<PengumumanPage> createState() => _PengumumanPageState();
}

class _PengumumanPageState extends State<PengumumanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color backgroundColor = Color(0xffF7FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeColor = Color(0xffF59E0B);
  static const Color blueColor = Color(0xff2563EB);
  static const Color purpleColor = Color(0xff7C3AED);

  final DatabaseReference _pengumumanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('pengumuman');

  List<Map<String, dynamic>> _getAnnouncements(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final item = Map<String, dynamic>.from(entry.value as Map);
              item['id'] = entry.key.toString();
              return item;
            })
            .where((item) {
              final status =
                  (item['status'] ?? 'aktif').toString().toLowerCase();
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
    if (raw.isEmpty) return 'Tanggal tidak tersedia';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

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

    if (clean == 'pupuk') return Icons.eco_rounded;
    if (clean == 'alat') return Icons.agriculture_rounded;
    if (clean == 'rapat') return Icons.groups_rounded;
    if (clean == 'panen') return Icons.grass_rounded;
    if (clean == 'gotong_royong') return Icons.handshake_rounded;

    return Icons.campaign_rounded;
  }

  Color _categoryColor(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return primaryGreen;
    if (clean == 'alat') return orangeColor;
    if (clean == 'rapat') return blueColor;
    if (clean == 'panen') return darkGreen;
    if (clean == 'gotong_royong') return purpleColor;

    return primaryGreen;
  }

  void _openDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => _PengumumanDetailPage(
              item: item,
              formatDate: _formatDate,
              categoryLabel: _categoryLabel,
              categoryIcon: _categoryIcon,
              categoryColor: _categoryColor,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: _pengumumanRef.onValue,
          builder: (context, snapshot) {
            final announcements = _getAnnouncements(
              snapshot.data?.snapshot.value,
            );

            return Column(
              children: [
                _header(announcements.length),
                Expanded(
                  child: _content(
                    hasError: snapshot.hasError,
                    errorMessage: snapshot.error?.toString(),
                    announcements: announcements,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              _topButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  if (mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pengumuman',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    total == 0
                        ? 'Informasi dari admin akan tampil di halaman ini.'
                        : '$total informasi aktif dari Kelompok Tani Desa Penataan.',
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
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

  Widget _content({
    required bool hasError,
    required String? errorMessage,
    required List<Map<String, dynamic>> announcements,
  }) {
    if (hasError) {
      return _emptyState(
        icon: Icons.error_outline_rounded,
        title: 'Pengumuman Gagal Dimuat',
        message: errorMessage ?? 'Periksa koneksi internet atau Firebase.',
      );
    }

    if (announcements.isEmpty) {
      return _emptyState(
        icon: Icons.campaign_outlined,
        title: 'Belum Ada Pengumuman',
        message: 'Pengumuman dari admin kelompok tani akan tampil di sini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _announcementCard(announcements[index]);
      },
    );
  }

  Widget _announcementCard(Map<String, dynamic> item) {
    final title = (item['judul'] ?? 'Pengumuman Desa').toString();
    final body = (item['isi'] ?? '-').toString();
    final date = _formatDate(item['tanggal'] ?? item['created_at']);
    final category = (item['kategori'] ?? 'umum').toString();
    final color = _categoryColor(category);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => _openDetail(item),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _promoBanner(
                title: title,
                body: body,
                category: category,
                compact: false,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: textGrey.withValues(alpha: 0.80),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        date,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Lihat Detail',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
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

  Widget _promoBanner({
    required String title,
    required String body,
    required String category,
    required bool compact,
  }) {
    final color = _categoryColor(category);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 16 : 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            compact
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -28,
            child: Icon(
              _categoryIcon(category),
              size: compact ? 110 : 130,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(category),
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _categoryLabel(category).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text(
                title,
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 21 : 19,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                maxLines: compact ? 6 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topButton({required IconData icon, required VoidCallback onTap}) {
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
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

  const _PengumumanDetailPage({
    required this.item,
    required this.formatDate,
    required this.categoryLabel,
    required this.categoryIcon,
    required this.categoryColor,
  });

  static const Color backgroundColor = Color(0xffF7FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);

  @override
  Widget build(BuildContext context) {
    final title = (item['judul'] ?? 'Pengumuman Desa').toString();
    final body = (item['isi'] ?? '-').toString();
    final date = formatDate(item['tanggal'] ?? item['created_at']);
    final category = (item['kategori'] ?? 'umum').toString();
    final color = categoryColor(category);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Row(
              children: [
                _topButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Detail Pengumuman',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -24,
                    bottom: -32,
                    child: Icon(
                      categoryIcon(category),
                      size: 150,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          categoryLabel(category).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(),
              child: Text(
                body,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  height: 1.65,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Icon(icon, color: textDark),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
