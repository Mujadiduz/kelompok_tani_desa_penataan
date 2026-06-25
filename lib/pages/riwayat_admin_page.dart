import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RiwayatAdminPage extends StatefulWidget {
  const RiwayatAdminPage({super.key});

  @override
  State<RiwayatAdminPage> createState() => _RiwayatAdminPageState();
}

class _RiwayatAdminPageState extends State<RiwayatAdminPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF4F7F4);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color redStatus = Color(0xffDC2626);

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  @override
  void initState() {
    super.initState();
  }

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value == null || value is! Map) return {};
    return Map<dynamic, dynamic>.from(value);
  }

  String _safeText(dynamic value, {String fallback = ''}) {
    return (value ?? fallback).toString().trim();
  }

  String _cleanStatus(dynamic value) {
    final status = (value ?? 'menunggu').toString().toLowerCase().trim();
    return status.isEmpty ? 'menunggu' : status;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    try {
      return DateTime.parse(value.toString().trim());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _formatStatus(String status) {
    final clean = status.toLowerCase().trim().replaceAll('_', ' ');
    if (clean.isEmpty) return 'Menunggu';

    return clean
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatDateGroup(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'Tanggal Tidak Diketahui';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);

    if (selected == today) return 'Hari Ini';
    if (selected == today.subtract(const Duration(days: 1))) return 'Kemarin';

    const months = [
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return '--.--';

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour.$minute';
  }

  Color _statusColor(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'disetujui') return primaryGreen;
    if (clean == 'ditolak') return redStatus;
    if (clean == 'sudah_diambil') return blueStatus;
    if (clean == 'dipinjam') return orangeStatus;
    if (clean == 'dikembalikan') return primaryGreen;
    if (clean == 'selesai') return primaryGreen;

    return orangeStatus;
  }

  List<_RiwayatAdminItem> _buildRiwayat({
    required dynamic calonAnggotaValue,
    required dynamic bantuanPupukValue,
    required dynamic peminjamanAlatValue,
    required dynamic resetPasswordValue,
  }) {
    final result = <_RiwayatAdminItem>[];

    result.addAll(
      _extractItems(
        value: calonAnggotaValue,
        defaultTitle: 'Calon anggota baru',
        defaultSubtitle: 'Mengajukan pendaftaran anggota',
        icon: Icons.person_add_alt_1_rounded,
        color: blueStatus,
        type: 'Verifikasi Anggota',
      ),
    );

    result.addAll(
      _extractItems(
        value: bantuanPupukValue,
        defaultTitle: 'Pengajuan bantuan pupuk',
        defaultSubtitle: 'Mengajukan bantuan pupuk',
        icon: Icons.eco_rounded,
        color: primaryGreen,
        type: 'Bantuan Pupuk',
      ),
    );

    result.addAll(
      _extractItems(
        value: peminjamanAlatValue,
        defaultTitle: 'Pengajuan peminjaman alat',
        defaultSubtitle: 'Mengajukan peminjaman alat pertanian',
        icon: Icons.agriculture_rounded,
        color: orangeStatus,
        type: 'Peminjaman Alat',
      ),
    );

    result.addAll(
      _extractItems(
        value: resetPasswordValue,
        defaultTitle: 'Permintaan reset password',
        defaultSubtitle: 'Mengajukan reset password akun',
        icon: Icons.lock_reset_rounded,
        color: redStatus,
        type: 'Reset Password',
      ),
    );

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  List<_RiwayatAdminItem> _extractItems({
    required dynamic value,
    required String defaultTitle,
    required String defaultSubtitle,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    final data = _asMap(value);
    if (data.isEmpty) return [];

    final result = <_RiwayatAdminItem>[];

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail = Map<dynamic, dynamic>.from(item);

      final nama = _safeText(detail['nama']);
      final nik = _safeText(detail['nik']);
      final alat = _safeText(detail['nama_alat'] ?? detail['alat']);
      final jenisPupuk = _safeText(
        detail['jenis_pupuk'] ?? detail['nama_pupuk'] ?? detail['pupuk'],
      );
      final status = _cleanStatus(detail['status']);

      String title = nama.isEmpty ? defaultTitle : nama;
      String subtitle = defaultSubtitle;

      if (type == 'Verifikasi Anggota' && nik.isNotEmpty) {
        subtitle = 'NIK $nik';
      }

      if (type == 'Bantuan Pupuk' && jenisPupuk.isNotEmpty) {
        subtitle = 'Mengajukan bantuan $jenisPupuk';
      }

      if (type == 'Peminjaman Alat' && alat.isNotEmpty) {
        subtitle = 'Mengajukan peminjaman $alat';
      }

      final date = _parseDate(
        detail['created_at'] ??
            detail['createdAt'] ??
            detail['tanggal_pengajuan'] ??
            detail['tanggalPengajuan'] ??
            detail['tanggal_daftar'] ??
            detail['tanggalDaftar'] ??
            detail['tanggal_pinjam'] ??
            detail['tanggalPinjam'] ??
            detail['tanggal'],
      );

      result.add(
        _RiwayatAdminItem(
          title: title,
          subtitle: subtitle,
          status: status,
          date: date,
          icon: icon,
          color: color,
          type: type,
        ),
      );
    }

    return result;
  }

  Map<String, List<_RiwayatAdminItem>> _groupByDate(
    List<_RiwayatAdminItem> items,
  ) {
    final grouped = <String, List<_RiwayatAdminItem>>{};

    for (final item in items) {
      final key = _formatDateGroup(item.date);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: darkGreen,
        elevation: 0,
        title: const Text(
          'Riwayat Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: _db.ref().onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          final root = _asMap(snapshot.data?.snapshot.value);

          final items = _buildRiwayat(
            calonAnggotaValue: root['calon_anggota'],
            bantuanPupukValue: root['bantuan_pupuk'],
            peminjamanAlatValue: root['peminjaman_alat'],
            resetPasswordValue: root['reset_password'],
          );

          if (items.isEmpty) {
            return _emptyState();
          }

          final grouped = _groupByDate(items);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _header(items.length),
              const SizedBox(height: 16),
              ...grouped.entries.map((entry) {
                return _dateGroup(title: entry.key, items: entry.value);
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: primaryGreen,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$total riwayat aktivitas tercatat di sistem.',
              style: const TextStyle(
                color: textDark,
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateGroup({
    required String title,
    required List<_RiwayatAdminItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              return _timelineItem(items[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(_RiwayatAdminItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            _formatTime(item.date),
            style: const TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.type,
                style: TextStyle(
                  color: item.color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.2,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(item.status).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _formatStatus(item.status),
            style: TextStyle(
              color: _statusColor(item.status),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
          decoration: _cardDecoration(),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_rounded, color: primaryGreen, size: 44),
              SizedBox(height: 12),
              Text(
                'Belum Ada Riwayat',
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Riwayat pendaftaran anggota, bantuan pupuk, peminjaman alat, dan reset password akan tampil di halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 12,
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _RiwayatAdminItem {
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String type;

  const _RiwayatAdminItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.icon,
    required this.color,
    required this.type,
  });
}
