import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

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
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color redStatus = Color(0xffDC2626);
  static const Color blueStatus = Color(0xff1976D2);

  bool isLoading = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference peminjamanRef;
  late final DatabaseReference notifikasiAdminRef;

  @override
  void initState() {
    super.initState();
    peminjamanRef = db.ref('peminjaman_alat');
    notifikasiAdminRef = db.ref('notifikasi_admin');
  }

  Future<void> simpanNotifikasiAdmin() async {
    await notifikasiAdminRef
        .push()
        .set({
          'judul': 'Pengajuan Peminjaman Baru',
          'pesan':
              '${widget.nama} mengajukan peminjaman ${widget.namaAlat} pada tanggal ${widget.tanggalPinjam}.',
          'tipe': 'peminjaman_alat',
          'status': 'belum_dibaca',
          'dibaca': false,
          'tanggal': DateTime.now().toIso8601String(),
        })
        .timeout(const Duration(seconds: 10));
  }

  Future<void> ajukanPeminjaman() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    if (widget.idAlat.trim().isEmpty) {
      _showSnackBar('Data alat tidak valid', redStatus);
      return;
    }

    final lanjut = await _showConfirmDialog();

    if (!mounted) return;
    if (lanjut != true) return;

    setState(() => isLoading = true);

    try {
      await peminjamanRef
          .push()
          .set({
            'id_alat': widget.idAlat.trim(),
            'alat': widget.namaAlat.trim(),
            'nama': widget.nama.trim(),
            'nik': widget.nik.trim(),
            'tanggal_pinjam': widget.tanggalPinjam.trim(),
            'tanggal_kembali': widget.tanggalKembali.trim(),
            'catatan': widget.catatan.trim(),
            'jumlah': 1,
            'jumlah_alat': 1,
            'status': 'menunggu',
            'tanggal_pengajuan': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 15));

      await simpanNotifikasiAdmin();

      if (!mounted) return;

      _showSnackBar('Pengajuan peminjaman berhasil dikirim', primaryGreen);

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Gagal mengirim pengajuan. Periksa koneksi internet.',
        redStatus,
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: primaryGreen,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ajukan Peminjaman?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pastikan seluruh data peminjaman sudah benar sebelum dikirim ke admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Kirim',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pesan,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

    if (alat.contains('sprayer')) return blueStatus;
    if (alat.contains('cangkul')) return const Color(0xffD97706);
    if (alat.contains('traktor')) return orangeStatus;

    return primaryGreen;
  }

  DateTime? _parseTanggal(String value) {
    try {
      final clean = value.trim();

      if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length != 3) return null;

        if (parts[0].length == 4) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length != 3) return null;

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  int durasiHari() {
    final pinjam = _parseTanggal(widget.tanggalPinjam);
    final kembali = _parseTanggal(widget.tanggalKembali);

    if (pinjam == null || kembali == null) return 0;

    final awal = DateTime(pinjam.year, pinjam.month, pinjam.day);
    final akhir = DateTime(kembali.year, kembali.month, kembali.day);

    final selisih = akhir.difference(awal).inDays;
    return selisih < 0 ? 0 : selisih + 1;
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final durasi = durasiHari();

    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                children: [
                  _headerPage(),
                  const SizedBox(height: 16),
                  _userInfoCard(),
                  const SizedBox(height: 14),
                  _stepCard(),
                  const SizedBox(height: 14),
                  _statusCard(durasi),
                  const SizedBox(height: 14),
                  _detailCard(durasi),
                  const SizedBox(height: 14),
                  _noteBox(),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.20),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomSubmitBar(),
    );
  }

  Widget _headerPage() {
    return Container(
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
          _backButton(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konfirmasi Peminjaman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Periksa kembali data sebelum dikirim',
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
            child: const Icon(Icons.fact_check_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _userInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pemohon',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIK ${sensorNik(widget.nik)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tahap 4 dari 4',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Periksa kembali data sebelum pengajuan dikirim ke admin.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 1,
              minHeight: 7,
              backgroundColor: primaryGreen.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(int durasi) {
    final color = warnaAlat(widget.namaAlat);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Icon(
              iconAlat(widget.namaAlat),
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.namaAlat,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Status awal pengajuan akan masuk sebagai menunggu verifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge('Menunggu Verifikasi', orangeStatus),
              _badge(durasi > 0 ? '$durasi Hari' : 'Durasi -', primaryGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailCard(int durasi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.receipt_long_rounded,
            title: 'Detail Pengajuan',
            subtitle: 'Ringkasan data peminjaman alat',
          ),
          const SizedBox(height: 14),
          _infoBox(
            children: [
              _detailRow(
                Icons.person_outline_rounded,
                'Nama Peminjam',
                widget.nama,
              ),
              _detailRow(Icons.badge_outlined, 'NIK', widget.nik),
              _detailRow(Icons.handyman_rounded, 'Nama Alat', widget.namaAlat),
              _detailRow(
                Icons.calendar_today_rounded,
                'Tanggal Pinjam',
                widget.tanggalPinjam,
              ),
              _detailRow(
                Icons.event_available_rounded,
                'Tanggal Kembali',
                widget.tanggalKembali,
              ),
              _detailRow(
                Icons.timelapse_rounded,
                'Durasi',
                durasi > 0 ? '$durasi hari' : '-',
                valueColor: primaryGreen,
              ),
              _detailRow(
                Icons.notes_rounded,
                'Catatan',
                widget.catatan.trim().isEmpty ? '-' : widget.catatan.trim(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: primaryGreen, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBox({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 4),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
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
            width: 112,
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
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? textDark,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Pengajuan akan masuk ke admin untuk diverifikasi. Alat belum tercatat dipinjam sampai admin menyetujui pengajuan.',
              style: TextStyle(
                color: primaryGreen,
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

  Widget _bottomSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : ajukanPeminjaman,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.40),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon:
                isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.send_rounded, size: 20),
            label: Text(
              isLoading ? 'Mengirim...' : 'Ajukan Peminjaman',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap:
          isLoading
              ? null
              : () {
                if (!mounted) return;
                Navigator.pop(context);
              },
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 13,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
