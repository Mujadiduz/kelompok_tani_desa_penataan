import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AlatKonfirmasiPage extends StatefulWidget {
  final String idAlat;
  final String namaAlat;
  final String nama;
  final String nik;
  final String tanggalPinjam;
  final String tanggalKembali;
  final String catatan;

  const AlatKonfirmasiPage({
    super.key,
    required this.idAlat,
    required this.namaAlat,
    required this.nama,
    required this.nik,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.catatan,
  });

  @override
  State<AlatKonfirmasiPage> createState() => _AlatKonfirmasiPageState();
}

class _AlatKonfirmasiPageState extends State<AlatKonfirmasiPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  bool isLoading = false;

  final DatabaseReference peminjamanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('peminjaman_alat');

  Future<void> ajukanPeminjaman() async {
    setState(() => isLoading = true);

    try {
      await peminjamanRef
          .push()
          .set({
            'id_alat': widget.idAlat,
            'alat': widget.namaAlat,
            'nama': widget.nama,
            'nik': widget.nik,
            'tanggal_pinjam': widget.tanggalPinjam,
            'tanggal_kembali': widget.tanggalKembali,
            'catatan': widget.catatan,
            'jumlah': 1,
            'status': 'menunggu',
            'tanggal_pengajuan': DateTime.now().toString(),
          })
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      _showSnackBar('Pengajuan peminjaman berhasil dikirim', primaryGreen);

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengirim peminjaman: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String pesan, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData iconAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return Icons.water_drop_rounded;
    if (alat.contains('cangkul')) return Icons.construction_rounded;
    if (alat.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  Color warnaAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return const Color(0xff2563EB);
    if (alat.contains('cangkul')) return const Color(0xffD97706);
    if (alat.contains('traktor')) return orangeStatus;

    return primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 22),
              _stepIndicator(),
              const SizedBox(height: 18),
              _mainCard(),
              const SizedBox(height: 18),
              _sectionTitle('Detail Pengajuan'),
              const SizedBox(height: 12),
              _detailCard(),
              const SizedBox(height: 18),
              _noteBox(),
              const SizedBox(height: 24),
              _submitButton(),
            ],
          ),
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
              Icons.task_alt_rounded,
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
                      'Konfirmasi Peminjaman',
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
                'Periksa Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pastikan data peminjaman alat sudah benar sebelum dikirim ke admin.',
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

  Widget _mainCard() {
    final color = warnaAlat(widget.namaAlat);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(iconAlat(widget.namaAlat), color: color, size: 42),
          ),
          const SizedBox(height: 14),
          Text(
            widget.namaAlat,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: orangeStatus.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'MENUNGGU PERSETUJUAN ADMIN',
              style: TextStyle(
                color: orangeStatus,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _detailItem(Icons.person_rounded, 'Nama Peminjam', widget.nama),
          const Divider(height: 24),
          _detailItem(Icons.badge_rounded, 'NIK', widget.nik),
          const Divider(height: 24),
          _detailItem(
            Icons.calendar_month_rounded,
            'Tanggal Pinjam',
            widget.tanggalPinjam,
          ),
          const Divider(height: 24),
          _detailItem(
            Icons.event_available_rounded,
            'Tanggal Kembali',
            widget.tanggalKembali,
          ),
          const Divider(height: 24),
          _detailItem(Icons.notes_rounded, 'Catatan', widget.catatan),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            value.trim().isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _noteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Setelah diajukan, admin akan memeriksa jadwal dan ketersediaan alat. Status dapat dilihat pada halaman riwayat.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.65),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: isLoading ? null : ajukanPeminjaman,
        icon:
            isLoading
                ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.send_rounded),
        label: Text(
          isLoading ? 'Mengirim...' : 'Ajukan Peminjaman',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stepCircle('1', 'Pilih', false),
          _stepLine(true),
          _stepCircle('2', 'Jadwal', false),
          _stepLine(true),
          _stepCircle('3', 'Data', false),
          _stepLine(true),
          _stepCircle('4', 'Kirim', true),
        ],
      ),
    );
  }

  Widget _stepCircle(String number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? primaryGreen : const Color(0xffE5E7EB),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : textGrey,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? primaryGreen : textGrey,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: active ? primaryGreen : const Color(0xffE5E7EB),
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
