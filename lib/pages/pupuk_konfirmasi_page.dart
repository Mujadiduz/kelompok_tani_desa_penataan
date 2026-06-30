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
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF59E0B);
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

  Color get warnaJatah => isMelebihiJatah ? orangeStatus : primaryGreen;

  String get teksJatah => isMelebihiJatah ? 'Melebihi Acuan' : 'Sesuai Acuan';

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Icon(
                    isMelebihiJatah
                        ? Icons.info_outline_rounded
                        : Icons.send_rounded,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Kirim Pengajuan?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isMelebihiJatah
                      ? 'Jumlah melebihi batas acuan. Pengajuan tetap dikirim untuk diverifikasi admin.'
                      : 'Pastikan data pengajuan sudah benar sebelum dikirim.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12.7,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 21),
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
        showPattern: false,
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 24),
            children: [
              _headerPage(),
              const SizedBox(height: 14),
              _statusCard(),
              const SizedBox(height: 12),
              _detailCard(),
              const SizedBox(height: 12),
              _infoBox(),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
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
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Periksa data sebelum dikirim',
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.eco_rounded, color: primaryGreen, size: 25),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.namaPupuk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _badge('Menunggu', orangeStatus),
                    _badge(teksJatah, warnaJatah),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: primaryGreen,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.receipt_long_rounded,
            title: 'Detail Pengajuan',
            subtitle: 'Ringkasan data bantuan pupuk',
          ),
          const SizedBox(height: 13),
          _detailInfoBox(
            children: [
              _detailRow(Icons.person_outline_rounded, 'Nama', widget.nama),
              _detailRow(Icons.badge_outlined, 'NIK', sensorNik(widget.nik)),
              _detailRow(Icons.grass_rounded, 'Jenis Pupuk', widget.namaPupuk),
              _detailRow(
                Icons.landscape_rounded,
                'Luas Sawah',
                '${widget.jumlahPetakSawah} Ha',
              ),
              _detailRow(
                Icons.scale_rounded,
                'Batas Acuan',
                '${widget.jatahPupuk} Kg',
                valueColor: primaryGreen,
              ),
              _detailRow(
                Icons.inventory_2_rounded,
                'Jumlah',
                '${widget.jumlahPupuk} Kg',
                valueColor: isMelebihiJatah ? orangeStatus : primaryGreen,
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
                  fontSize: 15.5,
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 3),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(15),
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
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.8,
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
                fontSize: 11.8,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox() {
    final color = isMelebihiJatah ? orangeStatus : primaryGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isMelebihiJatah
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              isMelebihiJatah
                  ? 'Jumlah melebihi batas acuan. Admin akan melakukan verifikasi.'
                  : 'Pengajuan siap dikirim. Pastikan data sudah benar.',
              style: TextStyle(
                color: color,
                fontSize: 12.2,
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
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : kirimPermintaan,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.38),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
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
                : const Icon(Icons.send_rounded, size: 20),
        label: Text(
          isLoading ? 'Mengirim...' : 'Kirim Pengajuan',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.032),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
