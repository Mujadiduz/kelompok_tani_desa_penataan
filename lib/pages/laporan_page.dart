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
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference anggotaRef;
  late final DatabaseReference calonAnggotaRef;
  late final DatabaseReference pupukRef;
  late final DatabaseReference peminjamanRef;

  int totalAnggota = 0;
  int totalCalon = 0;

  int totalPupuk = 0;
  int pupukMenunggu = 0;
  int pupukDisetujui = 0;
  int pupukDitolak = 0;

  int totalPeminjaman = 0;
  int peminjamanMenunggu = 0;
  int peminjamanDisetujui = 0;
  int peminjamanDitolak = 0;

  @override
  void initState() {
    super.initState();
    anggotaRef = db.ref('anggota');
    calonAnggotaRef = db.ref('calon_anggota');
    pupukRef = db.ref('bantuan_pupuk');
    peminjamanRef = db.ref('peminjaman_alat');
  }

  int hitungTotal(dynamic value) {
    if (value == null || value is! Map) return 0;
    return value.length;
  }

  int hitungStatus(dynamic value, String statusTarget) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final mapItem = Map<dynamic, dynamic>.from(item);
        final status = (mapItem['status'] ?? '').toString().toLowerCase();

        if (status == statusTarget) total++;
      }
    }

    return total;
  }

  Future<void> cetakLaporanPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'LAPORAN KELOMPOK TANI DESA PENATAAN',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Tanggal Cetak: ${DateTime.now()}'),
              pw.SizedBox(height: 18),
              pw.Text(
                'Rekap Anggota',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Total Anggota Aktif: $totalAnggota'),
              pw.Text('Calon Anggota: $totalCalon'),
              pw.SizedBox(height: 14),
              pw.Text(
                'Laporan Bantuan Pupuk',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Total Pengajuan: $totalPupuk'),
              pw.Text('Menunggu Verifikasi: $pupukMenunggu'),
              pw.Text('Disetujui Admin: $pupukDisetujui'),
              pw.Text('Ditolak Admin: $pupukDitolak'),
              pw.SizedBox(height: 14),
              pw.Text(
                'Laporan Peminjaman Alat',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Total Peminjaman: $totalPeminjaman'),
              pw.Text('Menunggu Verifikasi: $peminjamanMenunggu'),
              pw.Text('Disetujui Admin: $peminjamanDisetujui'),
              pw.Text('Ditolak Admin: $peminjamanDitolak'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: anggotaRef.onValue,
          builder: (context, anggotaSnapshot) {
            return StreamBuilder<DatabaseEvent>(
              stream: calonAnggotaRef.onValue,
              builder: (context, calonSnapshot) {
                return StreamBuilder<DatabaseEvent>(
                  stream: pupukRef.onValue,
                  builder: (context, pupukSnapshot) {
                    return StreamBuilder<DatabaseEvent>(
                      stream: peminjamanRef.onValue,
                      builder: (context, peminjamanSnapshot) {
                        return _laporanBody(
                          anggotaSnapshot.data?.snapshot.value,
                          calonSnapshot.data?.snapshot.value,
                          pupukSnapshot.data?.snapshot.value,
                          peminjamanSnapshot.data?.snapshot.value,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _laporanBody(
    dynamic anggotaValue,
    dynamic calonValue,
    dynamic pupukValue,
    dynamic peminjamanValue,
  ) {
    totalAnggota = hitungTotal(anggotaValue);
    totalCalon = hitungTotal(calonValue);

    totalPupuk = hitungTotal(pupukValue);
    pupukMenunggu = hitungStatus(pupukValue, 'menunggu');
    pupukDisetujui = hitungStatus(pupukValue, 'disetujui');
    pupukDitolak = hitungStatus(pupukValue, 'ditolak');

    totalPeminjaman = hitungTotal(peminjamanValue);
    peminjamanMenunggu = hitungStatus(peminjamanValue, 'menunggu');
    peminjamanDisetujui = hitungStatus(peminjamanValue, 'disetujui');
    peminjamanDitolak = hitungStatus(peminjamanValue, 'ditolak');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        children: [
          _header(context),
          const SizedBox(height: 20),
          _pdfButton(),
          const SizedBox(height: 18),
          _laporanCard(
            title: 'Rekap Anggota',
            icon: Icons.groups_rounded,
            color: primaryGreen,
            children: [
              _dataItem('Total Anggota Aktif', totalAnggota.toString()),
              _dataItem('Calon Anggota', totalCalon.toString()),
            ],
          ),
          const SizedBox(height: 18),
          _laporanCard(
            title: 'Laporan Bantuan Pupuk',
            icon: Icons.eco_rounded,
            color: primaryGreen,
            children: [
              _dataItem('Total Pengajuan', totalPupuk.toString()),
              _dataItem('Menunggu Verifikasi', pupukMenunggu.toString()),
              _dataItem('Disetujui Admin', pupukDisetujui.toString()),
              _dataItem('Ditolak Admin', pupukDitolak.toString()),
            ],
          ),
          const SizedBox(height: 18),
          _laporanCard(
            title: 'Laporan Peminjaman Alat',
            icon: Icons.agriculture_rounded,
            color: orangeStatus,
            children: [
              _dataItem('Total Peminjaman', totalPeminjaman.toString()),
              _dataItem('Menunggu Verifikasi', peminjamanMenunggu.toString()),
              _dataItem('Disetujui Admin', peminjamanDisetujui.toString()),
              _dataItem('Ditolak Admin', peminjamanDitolak.toString()),
            ],
          ),
        ],
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
        borderRadius: BorderRadius.circular(30),
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
              Icons.description_rounded,
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
                      'Laporan',
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
                'Rekap Data Sistem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ringkasan data anggota, bantuan pupuk, dan peminjaman alat pertanian.',
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

  Widget _pdfButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: cetakLaporanPdf,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: const Text(
          'Cetak Laporan PDF',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }

  Widget _laporanCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _dataItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
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
