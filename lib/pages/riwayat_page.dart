import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RiwayatPage extends StatefulWidget {
  final String nik;

  const RiwayatPage({super.key, required this.nik});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color purpleStatus = Color(0xff7B1FA2);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference pupukRef;
  late final DatabaseReference peminjamanRef;

  @override
  void initState() {
    super.initState();
    pupukRef = db.ref('bantuan_pupuk');
    peminjamanRef = db.ref('peminjaman_alat');
  }

  List<Map<String, dynamic>> ambilDataUser(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);
    final nik = widget.nik.trim();

    return data.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((item) {
          final nikData = (item['nik'] ?? '').toString().trim();
          return nikData == nik;
        })
        .toList()
        .reversed
        .toList();
  }

  int hitungStatus(List<Map<String, dynamic>> data, List<String> statusList) {
    return data.where((item) {
      final itemStatus =
          (item['status'] ?? 'menunggu').toString().toLowerCase();
      return statusList.contains(itemStatus);
    }).length;
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') return blueStatus;
    if (status == 'sudah_diambil') return primaryGreen;
    if (status == 'dipinjam') return purpleStatus;
    if (status == 'dikembalikan') return primaryGreen;
    if (status == 'ditolak') return Colors.red;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return const Color(0xffE3F2FD);
    if (status == 'sudah_diambil') return lightGreen;
    if (status == 'dipinjam') return const Color(0xffF3E5F5);
    if (status == 'dikembalikan') return lightGreen;
    if (status == 'ditolak') return const Color(0xffFFEBEE);
    return const Color(0xffFFF3E0);
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui Admin';
    if (status == 'sudah_diambil') return 'Sudah Diambil';
    if (status == 'dipinjam') return 'Sedang Dipinjam';
    if (status == 'dikembalikan') return 'Dikembalikan';
    if (status == 'ditolak') return 'Ditolak Admin';
    return 'Menunggu Verifikasi';
  }

  IconData iconAlat(String alat) {
    final nama = alat.toLowerCase();

    if (nama.contains('sprayer')) return Icons.water_drop_rounded;
    if (nama.contains('cangkul')) return Icons.construction_rounded;
    if (nama.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  String teksPengembalian(Map<String, dynamic> item) {
    final status = (item['status_pengembalian'] ?? '').toString();

    if (status == 'terlambat') {
      return 'Terlambat ${item['jumlah_hari_terlambat'] ?? 0} hari';
    }

    if (status == 'tepat_waktu') {
      return 'Tepat waktu';
    }

    return 'Belum diketahui';
  }

  Color warnaPengembalian(Map<String, dynamic> item) {
    final status = (item['status_pengembalian'] ?? '').toString();

    if (status == 'terlambat') return Colors.red;
    if (status == 'tepat_waktu') return primaryGreen;

    return textGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: pupukRef.onValue,
          builder: (context, pupukSnapshot) {
            return StreamBuilder<DatabaseEvent>(
              stream: peminjamanRef.onValue,
              builder: (context, alatSnapshot) {
                final riwayatPupuk = ambilDataUser(
                  pupukSnapshot.data?.snapshot.value,
                );

                final riwayatAlat = ambilDataUser(
                  alatSnapshot.data?.snapshot.value,
                );

                final semuaRiwayat = [...riwayatPupuk, ...riwayatAlat];

                final totalPengajuan = semuaRiwayat.length;
                final totalSelesai = hitungStatus(semuaRiwayat, [
                  'sudah_diambil',
                  'dikembalikan',
                ]);
                final totalProses = hitungStatus(semuaRiwayat, [
                  'menunggu',
                  'disetujui',
                  'dipinjam',
                ]);
                final totalDitolak = hitungStatus(semuaRiwayat, ['ditolak']);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _header(context)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                        child: _summaryGrid(
                          total: totalPengajuan,
                          selesai: totalSelesai,
                          proses: totalProses,
                          ditolak: totalDitolak,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                        child: _infoBox(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                        child: _sectionTitle(
                          title: 'Riwayat Bantuan Pupuk',
                          icon: Icons.grass_rounded,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                        child: _riwayatPupuk(riwayatPupuk),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                        child: _sectionTitle(
                          title: 'Riwayat Peminjaman Alat',
                          icon: Icons.agriculture_rounded,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                        child: _riwayatAlat(riwayatAlat),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -36,
            child: Icon(
              Icons.history_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(context),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Riwayat Pengajuan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Aktivitas Pengajuan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pantau status bantuan pupuk dan peminjaman alat pertanian.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _summaryGrid({
    required int total,
    required int selesai,
    required int proses,
    required int ditolak,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Pengajuan',
                value: total.toString(),
                subtitle: 'Semua pupuk dan alat',
                icon: Icons.assignment_rounded,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Selesai',
                value: selesai.toString(),
                subtitle: 'Sudah diambil/dikembalikan',
                icon: Icons.check_circle_rounded,
                color: primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Dalam Proses',
                value: proses.toString(),
                subtitle: 'Menunggu atau diproses admin',
                icon: Icons.hourglass_top_rounded,
                color: orangeStatus,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Ditolak Admin',
                value: ditolak.toString(),
                subtitle: 'Tidak disetujui',
                icon: Icons.cancel_rounded,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 11,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xffECFDF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Riwayat menampilkan perkembangan bantuan pupuk dan peminjaman alat mulai dari pengajuan, persetujuan, pengambilan, hingga pengembalian.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riwayatPupuk(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _emptyCard(
        icon: Icons.grass_rounded,
        text: 'Belum ada riwayat bantuan pupuk.',
      );
    }

    return Column(
      children:
          list.map((item) {
            final status =
                (item['status'] ?? 'menunggu').toString().toLowerCase();

            final details = <_DetailItem>[
              _DetailItem(
                icon: Icons.scale_rounded,
                label: 'Jumlah',
                value: '${item['jumlah_pupuk'] ?? item['jumlah'] ?? '-'} Kg',
              ),
              _DetailItem(
                icon: Icons.inventory_2_rounded,
                label: 'Jatah',
                value: '${item['jatah_pupuk'] ?? '-'} Kg',
              ),
              _DetailItem(
                icon: Icons.notes_rounded,
                label: 'Catatan',
                value: '${item['catatan'] ?? item['keterangan'] ?? '-'}',
              ),
            ];

            if (status == 'sudah_diambil') {
              details.addAll([
                _DetailItem(
                  icon: Icons.event_available_rounded,
                  label: 'Tgl Ambil',
                  value: '${item['tanggal_pengambilan'] ?? '-'}',
                ),
                _DetailItem(
                  icon: Icons.access_time_rounded,
                  label: 'Jam Ambil',
                  value: '${item['waktu_pengambilan'] ?? '-'}',
                ),
              ]);
            }

            return _riwayatCard(
              icon: Icons.grass_rounded,
              iconColor: primaryGreen,
              title: (item['jenis_pupuk'] ?? '-').toString(),
              subtitle: 'Jenis Pengajuan: Bantuan Pupuk',
              details: details,
              status: status,
            );
          }).toList(),
    );
  }

  Widget _riwayatAlat(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return _emptyCard(
        icon: Icons.agriculture_rounded,
        text: 'Belum ada riwayat peminjaman alat.',
      );
    }

    return Column(
      children:
          list.map((item) {
            final status =
                (item['status'] ?? 'menunggu').toString().toLowerCase();
            final alat = (item['alat'] ?? item['nama_alat'] ?? '-').toString();

            final details = <_DetailItem>[
              _DetailItem(
                icon: Icons.calendar_today_rounded,
                label: 'Pinjam',
                value: '${item['tanggal_pinjam'] ?? '-'}',
              ),
              _DetailItem(
                icon: Icons.event_available_rounded,
                label: 'Rencana',
                value: '${item['tanggal_kembali'] ?? '-'}',
              ),
              _DetailItem(
                icon: Icons.notes_rounded,
                label: 'Catatan',
                value: '${item['catatan'] ?? '-'}',
              ),
            ];

            if (status == 'dipinjam' || status == 'dikembalikan') {
              details.addAll([
                _DetailItem(
                  icon: Icons.output_rounded,
                  label: 'Tgl Ambil',
                  value: '${item['tanggal_diambil'] ?? '-'}',
                ),
                _DetailItem(
                  icon: Icons.access_time_rounded,
                  label: 'Jam Ambil',
                  value: '${item['waktu_diambil'] ?? '-'}',
                ),
              ]);
            }

            if (status == 'dikembalikan') {
              details.addAll([
                _DetailItem(
                  icon: Icons.event_repeat_rounded,
                  label: 'Tgl Aktual',
                  value: '${item['tanggal_dikembalikan'] ?? '-'}',
                ),
                _DetailItem(
                  icon: Icons.access_time_rounded,
                  label: 'Jam Kembali',
                  value: '${item['waktu_dikembalikan'] ?? '-'}',
                ),
                _DetailItem(
                  icon: Icons.timer_outlined,
                  label: 'Ketepatan',
                  value: teksPengembalian(item),
                  valueColor: warnaPengembalian(item),
                ),
              ]);
            }

            return _riwayatCard(
              icon: iconAlat(alat),
              iconColor: const Color(0xff2F855A),
              title: alat,
              subtitle: 'Jenis Pengajuan: Peminjaman Alat',
              details: details,
              status: status,
            );
          }).toList(),
    );
  }

  Widget _riwayatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<_DetailItem> details,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: iconColor, size: 27),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xffF9FAFB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffE5E7EB)),
            ),
            child: Column(
              children:
                  details.map((item) {
                    return _detailRow(
                      item.icon,
                      item.label,
                      item.value,
                      valueColor: item.valueColor,
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: valueColor ?? textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 98),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        teksStatus(status),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: warnaStatus(status),
          fontSize: 9.5,
          height: 1.1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyCard({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryGreen, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryGreen, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffE5E7EB)),
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

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}
