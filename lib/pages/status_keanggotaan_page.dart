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
  static const Color deepGreen = Color(0xff0F3D25);
  static const Color softGreen = Color(0xffF3FBF5);
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
      _showSnackBar('NIK harus terdiri dari 16 digit.', dangerColor);
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
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Gagal cek status. Periksa koneksi internet.', dangerColor);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Color warnaStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') return primaryGreen;
    if (status == 'ditolak') return dangerColor;
    return warningColor;
  }

  Color backgroundStatus(String status) {
    return warnaStatus(status).withValues(alpha: 0.10);
  }

  IconData iconStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') {
      return Icons.verified_outlined;
    }

    if (status == 'ditolak') return Icons.cancel_outlined;

    return Icons.hourglass_top_rounded;
  }

  String teksStatus(String status) {
    if (status == 'aktif') return 'Aktif';
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';

    return 'Menunggu';
  }

  String pesanStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') {
      return 'Pendaftaran sudah disetujui. Silakan login menggunakan NIK dan password yang didaftarkan.';
    }

    if (status == 'ditolak') {
      return 'Pendaftaran belum dapat disetujui. Silakan hubungi admin untuk informasi lebih lanjut.';
    }

    return 'Pendaftaran masih dalam proses verifikasi admin.';
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final status =
        (dataAnggota?['status'] ?? 'menunggu').toString().toLowerCase();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        showPattern: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset + 28),
              children: [
                _header(),
                const SizedBox(height: 14),
                _inputCard(),
                const SizedBox(height: 13),
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
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deepGreen, darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
          const SizedBox(width: 11),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.19)),
            ),
            child: const Icon(
              Icons.manage_search_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Keanggotaan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cek proses pendaftaran',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _headerBadge(),
        ],
      ),
    );
  }

  Widget _headerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'CEK',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _inputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            icon: Icons.badge_outlined,
            title: 'Masukkan NIK',
            subtitle: 'Gunakan NIK yang sama saat pendaftaran.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: nikController,
            focusNode: nikFocus,
            keyboardType: TextInputType.number,
            maxLength: 16,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              if (!isLoading) cekStatus();
            },
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14.3,
            ),
            decoration: _inputDecoration(
              label: 'NIK',
              hint: 'Masukkan 16 digit NIK',
              icon: Icons.credit_card_rounded,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: primaryGreen.withValues(alpha: 0.45),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              onPressed: isLoading ? null : cekStatus,
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
                      : const Icon(Icons.search_rounded, color: Colors.white),
              label: Text(
                isLoading ? 'Mengecek...' : 'Cek Status',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.3,
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
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: backgroundStatus(status),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: color.withValues(alpha: 0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statusIcon(status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teksStatus(status),
                        style: TextStyle(
                          color: color,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pesanStatus(status),
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 11.8,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          _profileMiniCard(status),
          const SizedBox(height: 13),
          _detailBox(),
        ],
      ),
    );
  }

  Widget _statusIcon(String status) {
    final color = warnaStatus(status);

    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Icon(iconStatus(status), color: color, size: 28),
    );
  }

  Widget _profileMiniCard(String status) {
    final color = warnaStatus(status);
    final nama = (dataAnggota!['nama'] ?? '-').toString();

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.person_outline_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 14.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(status),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = warnaStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        teksStatus(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _detailBox() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _infoRow(Icons.badge_outlined, 'NIK', dataAnggota!['nik'] ?? '-'),
          _infoRow(
            Icons.call_outlined,
            'Telepon',
            dataAnggota!['telepon'] ??
                dataAnggota!['no_hp'] ??
                dataAnggota!['nomor_hp'] ??
                '-',
          ),
          _infoRow(
            Icons.home_outlined,
            'Alamat',
            dataAnggota!['alamat'] ?? '-',
          ),
          _infoRow(
            Icons.wc_outlined,
            'Jenis Kelamin',
            dataAnggota!['jenis_kelamin'] ?? '-',
          ),
          _infoRow(
            Icons.landscape_outlined,
            'Luas Lahan',
            '${ambilLuasSawah()} Ha',
          ),
          _infoRow(
            Icons.event_note_outlined,
            'Tanggal Daftar',
            formatTanggal(dataAnggota!['tanggal_daftar']),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _emptyInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(Icons.info_outline_rounded, primaryGreen),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Hasil status akan tampil setelah NIK dicek. Pastikan NIK sesuai dengan data pendaftaran.',
              style: TextStyle(
                color: textGrey,
                fontSize: 11.8,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        _iconBox(icon, primaryGreen),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.6,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    dynamic value, {
    bool isLast = false,
  }) {
    final text = value.toString().trim().isEmpty ? '-' : value.toString();

    return Container(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      decoration: BoxDecoration(
        border:
            isLast
                ? null
                : Border(
                  bottom: BorderSide(
                    color: borderColor.withValues(alpha: 0.75),
                  ),
                ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textDark,
                fontSize: 11.9,
                height: 1.3,
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
      prefixIcon: Icon(icon, color: primaryGreen, size: 20),
      counterText: '',
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      labelStyle: const TextStyle(
        color: textGrey,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.34),
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryGreen, width: 1.4),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 41,
        width: 41,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.028),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
