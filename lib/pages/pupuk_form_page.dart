import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'pupuk_konfirmasi_page.dart';

class PupukFormPage extends StatefulWidget {
  final String idPupuk;
  final String namaPupuk;
  final String namaUser;
  final String nikUser;

  const PupukFormPage({
    super.key,
    required this.idPupuk,
    required this.namaPupuk,
    required this.namaUser,
    required this.nikUser,
  });

  @override
  State<PupukFormPage> createState() => _PupukFormPageState();
}

class _PupukFormPageState extends State<PupukFormPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF4F8F4);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color redStatus = Color(0xffDC2626);

  final TextEditingController jumlahPupukController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  String nama = '';
  String luasSawah = '';
  double jatahPupuk = 0;

  bool isLoading = true;
  bool dataDitemukan = false;

  @override
  void initState() {
    super.initState();
    ambilDataAnggotaLogin();
  }

  @override
  void dispose() {
    jumlahPupukController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  Future<void> ambilDataAnggotaLogin() async {
    setState(() {
      isLoading = true;
      dataDitemukan = false;
    });

    try {
      final snapshot = await anggotaRef.get().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) return;

      if (!snapshot.exists || snapshot.value == null) {
        setState(() {
          nama = widget.namaUser;
          isLoading = false;
        });
        _showSnackBar('Data anggota masih kosong', redStatus);
        return;
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      Map<String, dynamic>? anggotaDitemukan;

      final nikLogin = widget.nikUser.replaceAll(RegExp(r'[^0-9]'), '');

      for (final item in data.values) {
        if (item is Map) {
          final anggota = Map<String, dynamic>.from(item);
          final nikData = (anggota['nik'] ?? '').toString().replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

          if (nikData == nikLogin) {
            anggotaDitemukan = anggota;
            break;
          }
        }
      }

      if (!mounted) return;

      if (anggotaDitemukan == null) {
        setState(() {
          nama = widget.namaUser;
          isLoading = false;
        });
        _showSnackBar('Data anggota login tidak ditemukan', redStatus);
        return;
      }

      final luasText = (anggotaDitemukan['luas_sawah'] ??
              anggotaDitemukan['jumlah_petak_sawah'] ??
              '0')
          .toString()
          .replaceAll(',', '.');

      final luas = double.tryParse(luasText) ?? 0;

      setState(() {
        nama = (anggotaDitemukan!['nama'] ?? widget.namaUser).toString();
        luasSawah = luasText;
        jatahPupuk = luas / 2;
        dataDitemukan = true;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar(
        'Gagal mengambil data anggota. Periksa koneksi internet.',
        redStatus,
      );
    }
  }

  double jumlahDiajukan() {
    return double.tryParse(
          jumlahPupukController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  bool melebihiJatah() {
    return jumlahDiajukan() > jatahPupuk;
  }

  String formatAngka(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  void lanjutKonfirmasi() {
    FocusScope.of(context).unfocus();

    if (!dataDitemukan) {
      _showSnackBar('Data anggota belum ditemukan', redStatus);
      return;
    }

    if (widget.idPupuk.trim().isEmpty) {
      _showSnackBar('Data pupuk tidak valid', redStatus);
      return;
    }

    final jumlahText = jumlahPupukController.text.trim();

    if (jumlahText.isEmpty) {
      _showSnackBar('Jumlah pupuk wajib diisi', redStatus);
      return;
    }

    final jumlah = double.tryParse(jumlahText.replaceAll(',', '.'));

    if (jumlah == null || jumlah <= 0) {
      _showSnackBar('Jumlah pupuk tidak valid', redStatus);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PupukKonfirmasiPage(
              idPupuk: widget.idPupuk,
              namaPupuk: widget.namaPupuk,
              nama: nama,
              nik: widget.nikUser.trim(),
              jumlahPetakSawah: luasSawah,
              jumlahPupuk: jumlahText,
              jatahPupuk: jatahPupuk.toStringAsFixed(1),
              statusJatah: melebihiJatah() ? 'melebihi_jatah' : 'sesuai_jatah',
              catatan: catatanController.text.trim(),
            ),
      ),
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
    final overLimit = dataDitemukan && melebihiJatah();

    final bisaLanjut =
        dataDitemukan &&
        !isLoading &&
        jumlahPupukController.text.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: AppBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 24),
              children: [
                _headerPage(),
                const SizedBox(height: 16),
                _infoIntroCard(),
                const SizedBox(height: 14),
                _pupukCard(),
                const SizedBox(height: 14),
                isLoading
                    ? _loadingCard()
                    : dataDitemukan
                    ? _anggotaCard()
                    : _errorCard(),
                const SizedBox(height: 14),
                _formCard(overLimit),
                const SizedBox(height: 18),
                _submitButton(bisaLanjut),
              ],
            ),
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
                  'Pengajuan Pupuk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Isi data bantuan pupuk sesuai kebutuhan lahan',
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
            child: const Icon(Icons.eco_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _infoIntroCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.info_outline_rounded, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Lengkapi jumlah pupuk yang diajukan. Setelah data benar, lanjutkan ke halaman konfirmasi.',
              style: TextStyle(
                color: textDark,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pupukCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jenis Pupuk Dipilih',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.namaPupuk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Row(
        children: [
          SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primaryGreen,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mengambil data anggota...',
              style: TextStyle(
                color: textGrey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: redStatus.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: redStatus.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.error_outline_rounded, color: redStatus),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Data anggota tidak ditemukan. Pastikan akun sudah disetujui admin.',
              style: TextStyle(
                color: redStatus,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _anggotaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.person_rounded,
            title: 'Data Anggota',
            subtitle: 'Data otomatis dari akun anggota',
          ),
          const SizedBox(height: 14),
          _infoBox(
            children: [
              _infoRow(Icons.person_outline_rounded, 'Nama', nama),
              _infoRow(Icons.badge_outlined, 'NIK', widget.nikUser.trim()),
              _infoRow(Icons.landscape_rounded, 'Luas Sawah', '$luasSawah Ha'),
              _infoRow(
                Icons.scale_rounded,
                'Jatah Pupuk',
                '${formatAngka(jatahPupuk)} Kg',
                valueColor: primaryGreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formCard(bool overLimit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.edit_note_rounded,
            title: 'Form Pengajuan',
            subtitle: 'Masukkan jumlah pupuk yang diajukan',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: jumlahPupukController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Jumlah Pupuk Diajukan (Kg)',
              icon: Icons.scale_rounded,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (overLimit) ...[
            const SizedBox(height: 10),
            _noteBox(
              text:
                  'Jumlah pupuk melebihi jatah. Admin tetap dapat memverifikasi pengajuan ini.',
              color: redStatus,
              icon: Icons.warning_amber_rounded,
            ),
          ] else if (jumlahPupukController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _noteBox(
              text: 'Jumlah pupuk masih sesuai dengan jatah lahan.',
              color: primaryGreen,
              icon: Icons.check_circle_outline_rounded,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: catatanController,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(
              label: 'Catatan Tambahan',
              icon: Icons.notes_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton(bool enabled) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: enabled ? lanjutKonfirmasi : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
        label: Text(
          enabled ? 'Lanjut Konfirmasi' : 'Lengkapi Jumlah Pupuk',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
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

  Widget _infoRow(
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
            width: 105,
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

  Widget _noteBox({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey),
      prefixIcon: Icon(icon, color: primaryGreen),
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
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
