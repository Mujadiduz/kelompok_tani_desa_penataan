import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class PupukKonfirmasiPage extends StatefulWidget {
  final String idPupuk;
  final String namaPupuk;
  final String nama;
  final String nik;
  final String jumlahPetakSawah;
  final String jumlahPupuk;
  final String catatan;
  final String jatahPupuk;
  final String statusJatah;

  const PupukKonfirmasiPage({
    super.key,
    required this.idPupuk,
    required this.namaPupuk,
    required this.nama,
    required this.nik,
    required this.jumlahPetakSawah,
    required this.jumlahPupuk,
    required this.catatan,
    required this.jatahPupuk,
    required this.statusJatah,
  });

  @override
  State<PupukKonfirmasiPage> createState() => _PupukKonfirmasiPageState();
}

class _PupukKonfirmasiPageState extends State<PupukKonfirmasiPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color redStatus = Color(0xffDC2626);

  bool isLoading = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference pupukRef;
  late final DatabaseReference notifikasiAdminRef;

  @override
  void initState() {
    super.initState();
    pupukRef = db.ref('bantuan_pupuk');
    notifikasiAdminRef = db.ref('notifikasi_admin');
  }

  bool get isMelebihiJatah => widget.statusJatah == 'melebihi_jatah';

  Color get warnaJatah => isMelebihiJatah ? redStatus : primaryGreen;

  String get teksJatah => isMelebihiJatah ? 'Melebihi Jatah' : 'Sesuai Jatah';

  Future<void> simpanNotifikasiAdmin() async {
    await notifikasiAdminRef
        .push()
        .set({
          'judul': 'Pengajuan Pupuk Baru',
          'pesan':
              '${widget.nama} mengajukan bantuan pupuk ${widget.namaPupuk} sebanyak ${widget.jumlahPupuk} Kg.',
          'tipe': 'bantuan_pupuk',
          'status': 'belum_dibaca',
          'dibaca': false,
          'tanggal': DateTime.now().toIso8601String(),
        })
        .timeout(const Duration(seconds: 10));
  }

  Future<void> kirimPermintaan() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    if (widget.idPupuk.trim().isEmpty) {
      _showSnackBar('Data pupuk tidak valid', redStatus);
      return;
    }

    final lanjut = await _showConfirmDialog();

    if (!mounted) return;
    if (lanjut != true) return;

    setState(() => isLoading = true);

    try {
      await pupukRef
          .push()
          .set({
            'id_pupuk': widget.idPupuk.trim(),
            'nama': widget.nama.trim(),
            'nik': widget.nik.trim(),
            'jenis_pupuk': widget.namaPupuk.trim(),
            'luas_sawah': widget.jumlahPetakSawah.trim(),
            'jumlah_petak_sawah': widget.jumlahPetakSawah.trim(),
            'jatah_pupuk': widget.jatahPupuk.trim(),
            'jumlah_pupuk': widget.jumlahPupuk.trim().replaceAll(',', '.'),
            'status_jatah': widget.statusJatah.trim(),
            'catatan': widget.catatan.trim(),
            'status': 'menunggu',
            'tanggal_pengajuan': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 15));

      await simpanNotifikasiAdmin();

      if (!mounted) return;

      _showSnackBar('Pengajuan pupuk berhasil dikirim', primaryGreen);

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
    final color = isMelebihiJatah ? orangeStatus : primaryGreen;

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
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMelebihiJatah
                        ? Icons.warning_amber_rounded
                        : Icons.send_rounded,
                    color: color,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kirim Pengajuan?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isMelebihiJatah
                      ? 'Jumlah pupuk melebihi jatah. Pengajuan tetap dikirim dan akan diperiksa oleh admin.'
                      : 'Pastikan seluruh data pengajuan sudah benar sebelum dikirim ke admin.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 24),
            children: [
              _headerPage(),
              const SizedBox(height: 16),
              _statusCard(),
              const SizedBox(height: 14),
              _detailCard(),
              const SizedBox(height: 14),
              _warningInfoBox(),
              const SizedBox(height: 18),
              _submitButton(),
            ],
          ),
        ),
      ),
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
                  'Konfirmasi Pupuk',
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

  Widget _statusCard() {
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
              color: primaryGreen,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            widget.namaPupuk,
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
              _badge(teksJatah, warnaJatah),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailCard() {
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
            subtitle: 'Ringkasan data bantuan pupuk',
          ),
          const SizedBox(height: 14),
          _detailInfoBox(
            children: [
              _detailRow(
                Icons.person_outline_rounded,
                'Nama Pemohon',
                widget.nama,
              ),
              _detailRow(Icons.badge_outlined, 'NIK', widget.nik),
              _detailRow(Icons.grass_rounded, 'Jenis Pupuk', widget.namaPupuk),
              _detailRow(
                Icons.landscape_rounded,
                'Luas Sawah',
                '${widget.jumlahPetakSawah} Ha',
              ),
              _detailRow(
                Icons.scale_rounded,
                'Jatah Pupuk',
                '${widget.jatahPupuk} Kg',
                valueColor: primaryGreen,
              ),
              _detailRow(
                Icons.inventory_2_rounded,
                'Jumlah Diajukan',
                '${widget.jumlahPupuk} Kg',
                valueColor: isMelebihiJatah ? redStatus : primaryGreen,
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

  Widget _detailInfoBox({required List<Widget> children}) {
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

  Widget _warningInfoBox() {
    final color = isMelebihiJatah ? orangeStatus : primaryGreen;

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
          Icon(
            isMelebihiJatah
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isMelebihiJatah
                  ? 'Jumlah pengajuan melebihi jatah. Pengajuan tetap bisa dikirim dan akan diperiksa admin.'
                  : 'Pastikan data sudah benar sebelum dikirim ke admin.',
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

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : kirimPermintaan,
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
          isLoading ? 'Mengirim...' : 'Kirim Pengajuan',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
