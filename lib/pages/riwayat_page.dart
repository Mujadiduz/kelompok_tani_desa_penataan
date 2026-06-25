import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class RiwayatPage extends StatefulWidget {
  final String nik;

  const RiwayatPage({super.key, required this.nik});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color purpleStatus = Color(0xff7B1FA2);
  static const Color redStatus = Color(0xffDC2626);

  int selectedTab = 0;
  final Set<String> expandedCards = {};

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

  Future<void> _refreshData() async {
    await Future.wait([pupukRef.get(), peminjamanRef.get()]);
  }

  List<Map<String, dynamic>> ambilDataUser(dynamic value, String jenis) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);
    final nikUser = widget.nik.trim();

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final item = Map<String, dynamic>.from(entry.value as Map);
              item['id_riwayat'] = entry.key.toString();
              item['jenis_riwayat'] = jenis;
              return item;
            })
            .where((item) {
              final nikData = (item['nik'] ?? '').toString().trim();
              return nikData == nikUser;
            })
            .toList();

    list.sort((a, b) => timeValue(b).compareTo(timeValue(a)));
    return list;
  }

  int timeValue(Map<String, dynamic> item) {
    final raw =
        item['tanggal_pengajuan'] ??
        item['created_at'] ??
        item['createdAt'] ??
        item['tanggal_pinjam'] ??
        item['tanggal_diambil'] ??
        item['tanggal_dikembalikan'];

    final parsed = DateTime.tryParse((raw ?? '').toString().trim());
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String tanggalUtama(Map<String, dynamic> item) {
    return (item['tanggal_pengajuan'] ??
            item['created_at'] ??
            item['createdAt'] ??
            item['tanggal_pinjam'] ??
            '')
        .toString();
  }

  Map<String, List<Map<String, dynamic>>> groupedByDate(
    List<Map<String, dynamic>> list,
  ) {
    final result = <String, List<Map<String, dynamic>>>{};

    for (final item in list) {
      final label = groupDateLabel(tanggalUtama(item));
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
    final itemDate = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (itemDate == today) return 'Hari Ini';
    if (itemDate == yesterday) return 'Kemarin';

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

  String formatTanggalJam(String value) {
    final date = DateTime.tryParse(value.trim());
    if (date == null) return value.trim().isEmpty ? '-' : value;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  int hitungStatus(List<Map<String, dynamic>> data, List<String> statusList) {
    return data.where((item) {
      final status =
          (item['status'] ?? 'menunggu').toString().toLowerCase().trim();
      return statusList.contains(status);
    }).length;
  }

  Color warnaStatus(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'disetujui') return blueStatus;
    if (clean == 'sudah_diambil') return primaryGreen;
    if (clean == 'dipinjam') return purpleStatus;
    if (clean == 'dikembalikan') return primaryGreen;
    if (clean == 'ditolak') return redStatus;

    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'disetujui') return const Color(0xffE3F2FD);
    if (clean == 'sudah_diambil') return softGreen;
    if (clean == 'dipinjam') return const Color(0xffF3E5F5);
    if (clean == 'dikembalikan') return softGreen;
    if (clean == 'ditolak') return const Color(0xffFEE2E2);

    return const Color(0xffFFF7ED);
  }

  String teksStatus(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'disetujui') return 'Disetujui';
    if (clean == 'sudah_diambil') return 'Selesai';
    if (clean == 'dipinjam') return 'Dipinjam';
    if (clean == 'dikembalikan') return 'Selesai';
    if (clean == 'ditolak') return 'Ditolak';

    return 'Menunggu';
  }

  String teksStatusPanjang(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'disetujui') return 'Disetujui Admin';
    if (clean == 'sudah_diambil') return 'Pupuk Sudah Diambil';
    if (clean == 'dipinjam') return 'Alat Sedang Dipinjam';
    if (clean == 'dikembalikan') return 'Alat Sudah Dikembalikan';
    if (clean == 'ditolak') return 'Pengajuan Ditolak';

    return 'Menunggu Verifikasi';
  }

  double progressValue(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'menunggu') return 0.33;
    if (clean == 'disetujui') return 0.66;
    if (clean == 'dipinjam') return 0.66;
    if (clean == 'sudah_diambil') return 1.0;
    if (clean == 'dikembalikan') return 1.0;
    if (clean == 'ditolak') return 1.0;

    return 0.33;
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

    if (status == 'tepat_waktu') return 'Tepat waktu';

    return 'Belum diketahui';
  }

  Color warnaPengembalian(Map<String, dynamic> item) {
    final status = (item['status_pengembalian'] ?? '').toString();

    if (status == 'terlambat') return redStatus;
    if (status == 'tepat_waktu') return primaryGreen;

    return textGrey;
  }

  void toggleExpand(String id) {
    setState(() {
      if (expandedCards.contains(id)) {
        expandedCards.remove(id);
      } else {
        expandedCards.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: pupukRef.onValue,
            builder: (context, pupukSnapshot) {
              return StreamBuilder<DatabaseEvent>(
                stream: peminjamanRef.onValue,
                builder: (context, alatSnapshot) {
                  final riwayatPupuk = ambilDataUser(
                    pupukSnapshot.data?.snapshot.value,
                    'pupuk',
                  );

                  final riwayatAlat = ambilDataUser(
                    alatSnapshot.data?.snapshot.value,
                    'alat',
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

                  final listAktif =
                      selectedTab == 0 ? riwayatPupuk : riwayatAlat;
                  final grouped = groupedByDate(listAktif);

                  return Column(
                    children: [
                      _header(context),
                      Expanded(
                        child: RefreshIndicator(
                          color: primaryGreen,
                          backgroundColor: Colors.white,
                          onRefresh: _refreshData,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                            children: [
                              _summaryGrid(
                                total: totalPengajuan,
                                selesai: totalSelesai,
                                proses: totalProses,
                                ditolak: totalDitolak,
                              ),
                              const SizedBox(height: 14),
                              _tabSelector(
                                totalPupuk: riwayatPupuk.length,
                                totalAlat: riwayatAlat.length,
                              ),
                              const SizedBox(height: 14),
                              _infoBox(),
                              const SizedBox(height: 16),
                              _groupedContent(grouped),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [darkGreen, primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _backButton(context),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Pantau bantuan pupuk dan peminjaman alat',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(Icons.history_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryGrid({
    required int total,
    required int selesai,
    required int proses,
    required int ditolak,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryMini(
            title: 'Total',
            value: total.toString(),
            icon: Icons.assignment_rounded,
            color: primaryGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryMini(
            title: 'Proses',
            value: proses.toString(),
            icon: Icons.hourglass_top_rounded,
            color: orangeStatus,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryMini(
            title: 'Selesai',
            value: selesai.toString(),
            icon: Icons.check_circle_rounded,
            color: primaryGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryMini(
            title: 'Ditolak',
            value: ditolak.toString(),
            icon: Icons.cancel_rounded,
            color: redStatus,
          ),
        ),
      ],
    );
  }

  Widget _summaryMini({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabSelector({required int totalPupuk, required int totalAlat}) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              title: 'Bantuan Pupuk',
              total: totalPupuk,
              icon: Icons.eco_rounded,
              aktif: selectedTab == 0,
              color: primaryGreen,
              onTap: () => setState(() => selectedTab = 0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _tabButton(
              title: 'Peminjaman Alat',
              total: totalAlat,
              icon: Icons.agriculture_rounded,
              aktif: selectedTab == 1,
              color: orangeStatus,
              onTap: () => setState(() => selectedTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required int total,
    required IconData icon,
    required bool aktif,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: aktif ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: aktif ? Colors.white : color, size: 22),
            const SizedBox(height: 5),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: aktif ? Colors.white : textDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$total data',
              style: TextStyle(
                color: aktif ? Colors.white70 : textGrey,
                fontSize: 10.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox() {
    final color = selectedTab == 0 ? primaryGreen : orangeStatus;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              selectedTab == 0
                  ? 'Riwayat bantuan pupuk diurutkan berdasarkan tanggal pengajuan terbaru.'
                  : 'Riwayat peminjaman alat diurutkan berdasarkan tanggal pengajuan terbaru.',
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupedContent(Map<String, List<Map<String, dynamic>>> grouped) {
    if (grouped.isEmpty) {
      return _emptyCard(
        icon: selectedTab == 0 ? Icons.eco_rounded : Icons.agriculture_rounded,
        title:
            selectedTab == 0
                ? 'Belum Ada Riwayat Pupuk'
                : 'Belum Ada Riwayat Alat',
        text:
            selectedTab == 0
                ? 'Riwayat bantuan pupuk akan tampil setelah Anda melakukan pengajuan.'
                : 'Riwayat peminjaman alat akan tampil setelah Anda melakukan pengajuan.',
      );
    }

    final keys = grouped.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          keys.map((dateTitle) {
            final items = grouped[dateTitle] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dateHeader(dateTitle),
                const SizedBox(height: 8),
                ...items.map((item) {
                  return selectedTab == 0 ? _pupukCard(item) : _alatCard(item);
                }),
                const SizedBox(height: 4),
              ],
            );
          }).toList(),
    );
  }

  Widget _dateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 5,
            decoration: BoxDecoration(
              color: selectedTab == 0 ? primaryGreen : orangeStatus,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pupukCard(Map<String, dynamic> item) {
    final id = (item['id_riwayat'] ?? '').toString();
    final expanded = expandedCards.contains(id);
    final status = (item['status'] ?? 'menunggu').toString().toLowerCase();
    final title = (item['jenis_pupuk'] ?? 'Bantuan Pupuk').toString();

    final details = <_DetailItem>[
      _DetailItem('Jenis Pupuk', title),
      _DetailItem(
        'Jumlah Diajukan',
        '${item['jumlah_pupuk'] ?? item['jumlah'] ?? '-'} Kg',
      ),
      _DetailItem('Jatah Pupuk', '${item['jatah_pupuk'] ?? '-'} Kg'),
      _DetailItem('Catatan', '${item['catatan'] ?? item['keterangan'] ?? '-'}'),
      _DetailItem('Tanggal Pengajuan', formatTanggalJam(tanggalUtama(item))),
    ];

    if (status == 'sudah_diambil') {
      details.add(
        _DetailItem(
          'Tanggal Diambil',
          formatTanggalJam(
            '${item['tanggal_pengambilan'] ?? item['tanggal_diambil'] ?? '-'}',
          ),
        ),
      );
    }

    return _timelineCard(
      id: id,
      expanded: expanded,
      color: primaryGreen,
      icon: Icons.eco_rounded,
      title: title,
      subtitle: 'Bantuan Pupuk',
      status: status,
      details: details,
    );
  }

  Widget _alatCard(Map<String, dynamic> item) {
    final id = (item['id_riwayat'] ?? '').toString();
    final expanded = expandedCards.contains(id);
    final status = (item['status'] ?? 'menunggu').toString().toLowerCase();
    final alat =
        (item['alat'] ?? item['nama_alat'] ?? 'Alat Pertanian').toString();

    final details = <_DetailItem>[
      _DetailItem('Nama Alat', alat),
      _DetailItem(
        'Jumlah',
        '${item['jumlah'] ?? item['jumlah_alat'] ?? 1} Unit',
      ),
      _DetailItem('Tanggal Pinjam', '${item['tanggal_pinjam'] ?? '-'}'),
      _DetailItem('Tanggal Kembali', '${item['tanggal_kembali'] ?? '-'}'),
      _DetailItem('Catatan', '${item['catatan'] ?? '-'}'),
      _DetailItem('Tanggal Pengajuan', formatTanggalJam(tanggalUtama(item))),
    ];

    if (status == 'dipinjam' || status == 'dikembalikan') {
      details.add(
        _DetailItem('Tanggal Diambil', '${item['tanggal_diambil'] ?? '-'}'),
      );
    }

    if (status == 'dikembalikan') {
      details.addAll([
        _DetailItem(
          'Tanggal Aktual Kembali',
          '${item['tanggal_dikembalikan'] ?? '-'}',
        ),
        _DetailItem(
          'Ketepatan',
          teksPengembalian(item),
          valueColor: warnaPengembalian(item),
        ),
      ]);
    }

    return _timelineCard(
      id: id,
      expanded: expanded,
      color: orangeStatus,
      icon: iconAlat(alat),
      title: alat,
      subtitle: 'Peminjaman Alat',
      status: status,
      details: details,
    );
  }

  Widget _timelineCard({
    required String id,
    required bool expanded,
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required List<_DetailItem> details,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color.withValues(alpha: 0.12)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                width: 2,
                height: expanded ? 250 : 112,
                color: color.withValues(alpha: 0.18),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => toggleExpand(id),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecoration(
                    radius: 20,
                  ).copyWith(border: Border.all(color: cardBorder)),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: textGrey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _statusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _progressStatus(status),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              teksStatusPanjang(status),
                              style: TextStyle(
                                color: warnaStatus(status),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: textGrey,
                          ),
                        ],
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 12),
                        _detailBox(details),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressStatus(String status) {
    final color = warnaStatus(status);

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: progressValue(status),
        minHeight: 7,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Widget _detailBox(List<_DetailItem> details) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: Column(children: details.map((item) => _detailRow(item)).toList()),
    );
  }

  Widget _detailRow(_DetailItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              item.label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.value.trim().isEmpty ? '-' : item.value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: item.valueColor ?? textDark,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: warnaStatus(status).withValues(alpha: 0.15)),
      ),
      child: Text(
        teksStatus(status),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: warnaStatus(status),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem(this.label, this.value, {this.valueColor});
}
