import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class StatusKeanggotaanPage extends StatefulWidget {
  const StatusKeanggotaanPage({super.key});

  @override
  State<StatusKeanggotaanPage> createState() => _StatusKeanggotaanPageState();
}

class _StatusKeanggotaanPageState extends State<StatusKeanggotaanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color dangerColor = Color(0xffC62828);
  static const Color warningColor = Color(0xffF59E0B);

  final TextEditingController nikController = TextEditingController();
  final FocusNode nikFocus = FocusNode();

  bool isLoading = false;
  Map<String, dynamic>? dataAnggota;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  @override
  void dispose() {
    nikController.dispose();
    nikFocus.dispose();
    super.dispose();
  }

  Future<void> cekStatus() async {
    FocusScope.of(context).unfocus();

    final nikInput = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (nikInput.isEmpty) {
      _showSnackBar('NIK wajib diisi.', dangerColor);
      return;
    }

    if (nikInput.length != 16) {
      _showSnackBar(
        'NIK harus 16 digit. Saat ini terbaca ${nikInput.length} digit.',
        dangerColor,
      );
      return;
    }

    setState(() {
      isLoading = true;
      dataAnggota = null;
    });

    try {
      Map<String, dynamic>? hasil;

      final calonSnapshot = await db
          .ref('calon_anggota')
          .get()
          .timeout(const Duration(seconds: 10));

      if (calonSnapshot.exists && calonSnapshot.value != null) {
        hasil = cariDataByNik(calonSnapshot.value, nikInput);
      }

      if (hasil == null) {
        final anggotaSnapshot = await db
            .ref('anggota')
            .get()
            .timeout(const Duration(seconds: 10));

        if (anggotaSnapshot.exists && anggotaSnapshot.value != null) {
          hasil = cariDataByNik(anggotaSnapshot.value, nikInput);
        }
      }

      if (!mounted) return;

      if (hasil != null) {
        setState(() => dataAnggota = hasil);
      } else {
        _showSnackBar('Data anggota tidak ditemukan.', dangerColor);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal cek status. Periksa koneksi internet.', dangerColor);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Map<String, dynamic>? cariDataByNik(dynamic value, String nikInput) {
    if (value == null || value is! Map) return null;

    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final anggota = Map<String, dynamic>.from(item);
        final nikData = (anggota['nik'] ?? '').toString().replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

        if (nikData == nikInput) return anggota;
      }
    }

    return null;
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pesan,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color warnaStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') return primaryGreen;
    if (status == 'ditolak') return dangerColor;
    return warningColor;
  }

  Color backgroundStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') {
      return softGreen;
    }

    if (status == 'ditolak') {
      return const Color(0xffFEE2E2);
    }

    return const Color(0xffFEF3C7);
  }

  IconData iconStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') {
      return Icons.check_circle_rounded;
    }

    if (status == 'ditolak') {
      return Icons.cancel_rounded;
    }

    return Icons.hourglass_top_rounded;
  }

  String teksStatus(String status) {
    if (status == 'aktif') return 'Aktif';
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    return 'Menunggu Verifikasi';
  }

  String pesanStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') {
      return 'Pendaftaran Anda sudah disetujui. Silakan login menggunakan NIK dan password yang didaftarkan.';
    }

    if (status == 'ditolak') {
      return 'Pendaftaran Anda ditolak. Silakan hubungi admin kelompok tani untuk informasi lebih lanjut.';
    }

    return 'Pendaftaran Anda masih menunggu proses verifikasi oleh admin kelompok tani.';
  }

  String ambilLuasSawah() {
    return (dataAnggota?['luas_sawah'] ??
            dataAnggota?['jumlah_petak_sawah'] ??
            '-')
        .toString();
  }

  String formatTanggal(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return '-';

    try {
      final date = DateTime.parse(text);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day-$month-$year';
    } catch (_) {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status =
        (dataAnggota?['status'] ?? 'menunggu').toString().toLowerCase();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                _header(),
                const SizedBox(height: 16),
                _inputCard(),
                const SizedBox(height: 16),
                dataAnggota == null ? _emptyInfoCard() : _hasilCard(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(22),
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
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Keanggotaan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cek hasil pendaftaran calon anggota.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan NIK',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan NIK yang sama saat melakukan pendaftaran.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nikController,
            focusNode: nikFocus,
            keyboardType: TextInputType.number,
            maxLength: 16,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (!isLoading) cekStatus();
            },
            decoration: _inputDecoration(
              label: 'NIK',
              hint: '16 digit NIK',
              icon: Icons.badge_rounded,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryGreen.withValues(alpha: 0.45),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              onPressed: isLoading ? null : cekStatus,
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
                      : const Icon(Icons.search_rounded),
              label: Text(
                isLoading ? 'Mengecek...' : 'Cek Status',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hasilCard(String status) {
    final color = warnaStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: backgroundStatus(status),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Icon(iconStatus(status), color: color, size: 43),
          ),
          const SizedBox(height: 14),
          Text(
            teksStatus(status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pesanStatus(status),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _profileMiniCard(status),
          const SizedBox(height: 14),
          _detailBox(),
        ],
      ),
    );
  }

  Widget _profileMiniCard(String status) {
    final color = warnaStatus(status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(Icons.person_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              (dataAnggota!['nama'] ?? '-').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _infoRow(Icons.badge_rounded, 'NIK', dataAnggota!['nik'] ?? '-'),
          _infoRow(
            Icons.phone_rounded,
            'Telepon',
            dataAnggota!['telepon'] ?? '-',
          ),
          _infoRow(Icons.home_rounded, 'Alamat', dataAnggota!['alamat'] ?? '-'),
          _infoRow(
            Icons.wc_rounded,
            'Jenis Kelamin',
            dataAnggota!['jenis_kelamin'] ?? '-',
          ),
          _infoRow(
            Icons.landscape_rounded,
            'Luas Sawah',
            '${ambilLuasSawah()} Ha',
          ),
          _infoRow(
            Icons.calendar_today_rounded,
            'Tanggal Daftar',
            formatTanggal(dataAnggota!['tanggal_daftar']),
          ),
        ],
      ),
    );
  }

  Widget _emptyInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.13)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 23),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hasil status akan tampil setelah NIK dicek. Pastikan NIK sesuai dengan data pendaftaran.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.6,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    final text = value.toString().trim().isEmpty ? '-' : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryGreen),
      counterText: '',
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      labelStyle: const TextStyle(color: textGrey, fontWeight: FontWeight.w700),
      hintStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.35),
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
