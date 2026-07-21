import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminPurple = Color(0xff6256A4);
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color orangeStatus = Color(0xffD98212);
  static const Color blueStatus = Color(0xff326FA3);
  static const Color background = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _rootRef;

  @override
  void initState() {
    super.initState();
    _rootRef = _db.ref();
  }

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value == null || value is! Map) {
      return {};
    }
    return Map<dynamic, dynamic>.from(value);
  }

  String _status(dynamic value) {
    return (value ?? '').toString().toLowerCase().trim();
  }

  int _countAll(dynamic value) {
    return _asMap(value).length;
  }

  int _countStatus(dynamic value, List<String> targets) {
    final data = _asMap(value);
    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail = Map<dynamic, dynamic>.from(item);
      final status = _status(detail['status']);

      if (targets.contains(status)) {
        total++;
      }
    }

    return total;
  }

  int _countAnggotaAktif(dynamic value) {
    final data = _asMap(value);
    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail = Map<dynamic, dynamic>.from(item);
      final status = _status(detail['status']);

      if (status.isEmpty ||
          status == 'aktif' ||
          status == 'anggota' ||
          status == 'disetujui') {
        total++;
      }
    }

    return total;
  }

  double _countKgDisalurkan(dynamic value) {
    final data = _asMap(value);
    double total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail = Map<dynamic, dynamic>.from(item);
      final status = _status(detail['status']);

      if (status == 'sudah_diambil' || status == 'sudah diambil') {
        total += double.tryParse(
              (detail['jumlah_pupuk_diambil'] ??
                      detail['jumlah_kg'] ??
                      detail['jumlah_pupuk'] ??
                      detail['jumlah'] ??
                      0)
                  .toString()
                  .replaceAll(',', '.'),
            ) ??
            0;
      }
    }

    return total;
  }

  double _progress(int value, int total) {
    if (total <= 0) return 0;
    return value / total;
  }

  String _todayText() {
    final now = DateTime.now();

    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];

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
      'Desember'
    ];

    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }
    _ReportData _buildReport(dynamic value) {
    final root = _asMap(value);

    final anggota = root['anggota'];
    final calon = root['calon_anggota'];
    final pupuk = root['bantuan_pupuk'];
    final alat = root['peminjaman_alat'];

    return _ReportData(
      totalAnggotaAktif: _countAnggotaAktif(anggota),
      totalCalonAnggota: _countAll(calon),
      calonMenunggu: _countStatus(calon, ['menunggu']),
      calonDisetujui: _countStatus(calon, ['disetujui']),
      calonDitolak: _countStatus(calon, ['ditolak']),
      totalBantuanPupuk: _countAll(pupuk),
      pupukMenunggu: _countStatus(pupuk, ['menunggu']),
      pupukDisetujui: _countStatus(pupuk, ['disetujui']),
      pupukSudahDiambil: _countStatus(
        pupuk,
        ['sudah_diambil', 'sudah diambil'],
      ),
      pupukDitolak: _countStatus(pupuk, ['ditolak']),
      totalKgDisalurkan: _countKgDisalurkan(pupuk),
      totalPeminjamanAlat: _countAll(alat),
      alatMenunggu: _countStatus(alat, ['menunggu']),
      alatDisetujui: _countStatus(alat, ['disetujui']),
      alatDipinjam: _countStatus(
        alat,
        ['dipinjam', 'sedang_dipinjam', 'diambil'],
      ),
      alatDikembalikan: _countStatus(
        alat,
        ['dikembalikan', 'sudah_dikembalikan', 'selesai'],
      ),
      alatDitolak: _countStatus(alat, ['ditolak']),
    );
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );
  }

  String _formatCetak() {
    final now = DateTime.now();

    return '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _cetakLaporanPdf(_ReportData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Text(
              'LAPORAN KELOMPOK TANI DESA PENATAAN',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Sistem Informasi Kelompok Tani Berbasis Flutter dan Firebase Realtime Database',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Tanggal Cetak: ${_formatCetak()}',
            ),
            pw.SizedBox(height: 16),

            _pdfTitle('Rekap Anggota'),
            _pdfTable([
              [
                'Anggota Aktif',
                data.totalAnggotaAktif.toString(),
              ],
              [
                'Calon Anggota',
                data.totalCalonAnggota.toString(),
              ],
              [
                'Calon Menunggu',
                data.calonMenunggu.toString(),
              ],
              [
                'Calon Disetujui',
                data.calonDisetujui.toString(),
              ],
              [
                'Calon Ditolak',
                data.calonDitolak.toString(),
              ],
            ]),

            pw.SizedBox(height: 14),

            _pdfTitle('Laporan Bantuan Pupuk'),
            _pdfTable([
              [
                'Total Pengajuan',
                data.totalBantuanPupuk.toString(),
              ],
              [
                'Menunggu',
                data.pupukMenunggu.toString(),
              ],
              [
                'Disetujui',
                data.pupukDisetujui.toString(),
              ],
              [
                'Sudah Diambil',
                data.pupukSudahDiambil.toString(),
              ],
              [
                'Ditolak',
                data.pupukDitolak.toString(),
              ],
              [
                'Pupuk Disalurkan',
                '${data.totalKgDisalurkan.toStringAsFixed(1)} Kg',
              ],
            ]),

            pw.SizedBox(height: 14),

            _pdfTitle('Laporan Peminjaman Alat'),
            _pdfTable([
              [
                'Total Peminjaman',
                data.totalPeminjamanAlat.toString(),
              ],
              [
                'Menunggu',
                data.alatMenunggu.toString(),
              ],
              [
                'Disetujui',
                data.alatDisetujui.toString(),
              ],
              [
                'Sedang Dipinjam',
                data.alatDipinjam.toString(),
              ],
              [
                'Dikembalikan',
                data.alatDikembalikan.toString(),
              ],
              [
                'Ditolak',
                data.alatDitolak.toString(),
              ],
            ]),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  pw.Widget _pdfTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _pdfTable(List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      headers: [
        'Keterangan',
        'Jumlah',
      ],
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(
        fontSize: 10,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
      },
    );
  }
    @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final padding = width < 350
        ? 12.0
        : width < 600
            ? 16.0
            : 24.0;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: _rootRef.onValue,
          builder: (context, snapshot) {
            final data = _buildReport(
              snapshot.data?.snapshot.value,
            );

            return RefreshIndicator(
              color: adminPurple,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  padding,
                  16,
                  padding,
                  30,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 820,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          _header(data),
                          const SizedBox(height: 14),

                          _sectionTitle(
                            title: 'Ringkasan Laporan',
                            subtitle:
                                'Monitoring data utama aplikasi TaniGo',
                          ),

                          const SizedBox(height: 8),

                          _summaryGrid(data),

                          const SizedBox(height: 14),

                          _sectionTitle(
                            title: 'Progress Sistem',
                            subtitle:
                                'Pantauan distribusi pupuk dan alat',
                          ),

                          const SizedBox(height: 12),

                          _progressCard(data),

                          const SizedBox(height: 18),

                          _sectionTitle(
                            title: 'Detail Rekap',
                            subtitle:
                                'Rincian seluruh aktivitas kelompok tani',
                          ),

                          const SizedBox(height: 12),

                          _detailCards(data),

                          const SizedBox(height: 18),

                          _pdfButton(data),
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
    );
  }

  Widget _header(_ReportData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            adminNavy,
            adminPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _todayText(),
                  style: TextStyle(
                    color:
                        Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Laporan Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Rekap aktivitas kelompok tani',
                  style: TextStyle(
                    color:
                        Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  data.totalData.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'DATA',
                  style: TextStyle(
                    color:
                        Colors.white.withValues(alpha: 0.75),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          height: 32,
          width: 5,
          decoration: BoxDecoration(
            color: adminPurple,
            borderRadius:
                BorderRadius.circular(99),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryGrid(_ReportData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        final columns = compact ? 2 : 4;
        final gap = compact ? 7.0 : 8.0;

        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) /
                columns;

        final items = [
          _CompactSummaryItem(
            title: 'Anggota Aktif',
            value: data.totalAnggotaAktif,
            icon: Icons.groups_outlined,
            color: primaryGreen,
          ),
          _CompactSummaryItem(
            title: 'Calon Anggota',
            value: data.totalCalonAnggota,
            icon: Icons.person_add_alt_outlined,
            color: orangeStatus,
          ),
          _CompactSummaryItem(
            title: 'Bantuan Pupuk',
            value: data.totalBantuanPupuk,
            icon: Icons.eco_outlined,
            color: primaryGreen,
          ),
          _CompactSummaryItem(
            title: 'Peminjaman',
            value: data.totalPeminjamanAlat,
            icon: Icons.agriculture_outlined,
            color: blueStatus,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _summaryBox(
                title: item.title,
                value: item.value,
                icon: item.icon,
                color: item.color,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _summaryBox({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 30,
            width: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 15,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value > 999 ? '999+' : value.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 15.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 8.2,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(_ReportData data) {
    final pupuk = _progress(
      data.pupukSudahDiambil,
      data.totalBantuanPupuk,
    );

    final alat = _progress(
      data.alatDikembalikan,
      data.totalPeminjamanAlat,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _progressItem(
            title: 'Penyaluran Pupuk',
            subtitle:
                '${data.pupukSudahDiambil} dari ${data.totalBantuanPupuk} pengajuan selesai',
            value: pupuk,
            color: primaryGreen,
          ),

          const SizedBox(height: 18),

          _progressItem(
            title: 'Pengembalian Alat',
            subtitle:
                '${data.alatDikembalikan} dari ${data.totalPeminjamanAlat} peminjaman selesai',
            value: alat,
            color: orangeStatus,
          ),
        ],
      ),
    );
  }

  Widget _progressItem({
    required String title,
    required String subtitle,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        Text(
          subtitle,
          style: const TextStyle(
            color: textGrey,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 10,
            backgroundColor:
                color.withValues(alpha: 0.12),
            valueColor:
                AlwaysStoppedAnimation<Color>(
              color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailCards(_ReportData data) {
    return Column(
      children: [
        _reportCard(
          title: 'Rekap Anggota',
          icon: Icons.groups_rounded,
          color: primaryGreen,
          items: [
            _ReportItem(
              'Anggota Aktif',
              data.totalAnggotaAktif.toString(),
            ),
            _ReportItem(
              'Calon Anggota',
              data.totalCalonAnggota.toString(),
            ),
            _ReportItem(
              'Menunggu',
              data.calonMenunggu.toString(),
            ),
            _ReportItem(
              'Disetujui',
              data.calonDisetujui.toString(),
            ),
            _ReportItem(
              'Ditolak',
              data.calonDitolak.toString(),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _reportCard(
          title: 'Bantuan Pupuk',
          icon: Icons.eco_rounded,
          color: primaryGreen,
          items: [
            _ReportItem(
              'Total Pengajuan',
              data.totalBantuanPupuk.toString(),
            ),
            _ReportItem(
              'Menunggu',
              data.pupukMenunggu.toString(),
            ),
            _ReportItem(
              'Disetujui',
              data.pupukDisetujui.toString(),
            ),
            _ReportItem(
              'Sudah Diambil',
              data.pupukSudahDiambil.toString(),
            ),
            _ReportItem(
              'Total Kg',
              '${data.totalKgDisalurkan.toStringAsFixed(1)} Kg',
            ),
          ],
        ),

        const SizedBox(height: 14),

        _reportCard(
          title: 'Peminjaman Alat',
          icon: Icons.agriculture_rounded,
          color: blueStatus,
          items: [
            _ReportItem(
              'Total Peminjaman',
              data.totalPeminjamanAlat.toString(),
            ),
            _ReportItem(
              'Menunggu',
              data.alatMenunggu.toString(),
            ),
            _ReportItem(
              'Disetujui',
              data.alatDisetujui.toString(),
            ),
            _ReportItem(
              'Dipinjam',
              data.alatDipinjam.toString(),
            ),
            _ReportItem(
              'Dikembalikan',
              data.alatDikembalikan.toString(),
            ),
            _ReportItem(
              'Ditolak',
              data.alatDitolak.toString(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reportCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<_ReportItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color:
                      color.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...items.map(
            (item) => _dataRow(item),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(_ReportItem item) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: cardBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            item.value,
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
    Widget _pdfButton(_ReportData data) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _cetakLaporanPdf(data);
        },
        icon: const Icon(
          Icons.picture_as_pdf_rounded,
        ),
        label: const Text(
          'Cetak Laporan PDF',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: adminPurple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(17),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(22),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color:
              adminNavy.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}


class _CompactSummaryItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _CompactSummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _ReportData {
  final int totalAnggotaAktif;
  final int totalCalonAnggota;
  final int calonMenunggu;
  final int calonDisetujui;
  final int calonDitolak;

  final int totalBantuanPupuk;
  final int pupukMenunggu;
  final int pupukDisetujui;
  final int pupukSudahDiambil;
  final int pupukDitolak;
  final double totalKgDisalurkan;

  final int totalPeminjamanAlat;
  final int alatMenunggu;
  final int alatDisetujui;
  final int alatDipinjam;
  final int alatDikembalikan;
  final int alatDitolak;

  const _ReportData({
    required this.totalAnggotaAktif,
    required this.totalCalonAnggota,
    required this.calonMenunggu,
    required this.calonDisetujui,
    required this.calonDitolak,
    required this.totalBantuanPupuk,
    required this.pupukMenunggu,
    required this.pupukDisetujui,
    required this.pupukSudahDiambil,
    required this.pupukDitolak,
    required this.totalKgDisalurkan,
    required this.totalPeminjamanAlat,
    required this.alatMenunggu,
    required this.alatDisetujui,
    required this.alatDipinjam,
    required this.alatDikembalikan,
    required this.alatDitolak,
  });

  int get totalData {
    return totalAnggotaAktif +
        totalCalonAnggota +
        totalBantuanPupuk +
        totalPeminjamanAlat;
  }
}

class _ReportItem {
  final String label;
  final String value;

  const _ReportItem(
    this.label,
    this.value,
  );
}