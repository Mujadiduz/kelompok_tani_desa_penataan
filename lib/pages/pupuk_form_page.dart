import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'pupuk_konfirmasi_page.dart';

class PupukFormPage extends StatefulWidget {
  final String namaPupuk;
  final String namaUser;
  final String nikUser;

  const PupukFormPage({
    super.key,
    required this.namaPupuk,
    required this.namaUser,
    required this.nikUser,
  });

  @override
  State<PupukFormPage> createState() => _PupukFormPageState();
}

class _PupukFormPageState extends State<PupukFormPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  final jumlahPupukController = TextEditingController();
  final catatanController = TextEditingController();

  String nama = '';
  String luasSawah = '';
  double jatahPupuk = 0;

  bool isLoading = true;
  bool dataDitemukan = false;

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  @override
  void initState() {
    super.initState();
    ambilDataAnggotaLogin();
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

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        Map<String, dynamic>? anggotaDitemukan;

        for (final item in data.values) {
          if (item is Map) {
            final anggota = Map<String, dynamic>.from(item);
            final nikData = (anggota['nik'] ?? '').toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

            final nikLogin = widget.nikUser.replaceAll(RegExp(r'[^0-9]'), '');

            if (nikData == nikLogin) {
              anggotaDitemukan = anggota;
              break;
            }
          }
        }

        if (!mounted) return;

        if (anggotaDitemukan != null) {
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
          });
        } else {
          setState(() {
            nama = widget.namaUser;
          });

          _showSnackBar('Data anggota login tidak ditemukan', Colors.red);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengambil data anggota: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool melebihiJatah() {
    final jumlahDiajukan =
        double.tryParse(
          jumlahPupukController.text.trim().replaceAll(',', '.'),
        ) ??
        0;

    return jumlahDiajukan > jatahPupuk;
  }

  void lanjutKonfirmasi() {
    if (!dataDitemukan) {
      _showSnackBar('Data anggota belum ditemukan', Colors.red);
      return;
    }

    if (jumlahPupukController.text.trim().isEmpty) {
      _showSnackBar('Jumlah pupuk wajib diisi', Colors.red);
      return;
    }

    final jumlah = double.tryParse(
      jumlahPupukController.text.trim().replaceAll(',', '.'),
    );

    if (jumlah == null || jumlah <= 0) {
      _showSnackBar('Jumlah pupuk tidak valid', Colors.red);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PupukKonfirmasiPage(
              namaPupuk: widget.namaPupuk,
              nama: nama,
              nik: widget.nikUser.trim(),
              jumlahPetakSawah: luasSawah,
              jumlahPupuk: jumlahPupukController.text.trim(),
              jatahPupuk: jatahPupuk.toStringAsFixed(1),
              statusJatah: melebihiJatah() ? 'melebihi_jatah' : 'sesuai_jatah',
              catatan: catatanController.text.trim(),
            ),
      ),
    );
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

  @override
  void dispose() {
    jumlahPupukController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overLimit = dataDitemukan && melebihiJatah();

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
              _pupukCard(),
              const SizedBox(height: 14),
              if (isLoading)
                _loadingCard()
              else if (dataDitemukan)
                _anggotaCard(),
              const SizedBox(height: 14),
              _formCard(overLimit),
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
              Icons.grass_rounded,
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
                      'Isi Data Pupuk',
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
                'Pengajuan Pupuk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lengkapi jumlah pupuk yang ingin diajukan kepada admin.',
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

  Widget _pupukCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.eco_rounded, color: primaryGreen, size: 28),
          ),
          const SizedBox(width: 14),
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
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      ),
    );
  }

  Widget _anggotaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Anggota',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.person_rounded, 'Nama', nama),
          _infoRow(Icons.badge_rounded, 'NIK', widget.nikUser.trim()),
          _infoRow(Icons.landscape_rounded, 'Luas Sawah', '$luasSawah Ha'),
          _infoRow(
            Icons.inventory_2_rounded,
            'Jatah Pupuk',
            '${jatahPupuk.toStringAsFixed(1)} Kg',
          ),
          const SizedBox(height: 8),
          _noteBox(
            text:
                'Ketentuan: setiap 2 Ha sawah mendapat jatah 1 Kg pupuk subsidi.',
            color: primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _formCard(bool overLimit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Pengajuan',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan jumlah pupuk sesuai kebutuhan lahan.',
            style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: jumlahPupukController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              label: 'Jumlah Pupuk Diajukan (Kg)',
              icon: Icons.scale_rounded,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (overLimit) ...[
            const SizedBox(height: 8),
            _noteBox(
              text: 'Jumlah pupuk melebihi jatah subsidi.',
              color: Colors.red,
            ),
          ],
          const SizedBox(height: 13),
          TextField(
            controller: catatanController,
            maxLines: 3,
            decoration: _inputDecoration(
              label: 'Catatan',
              icon: Icons.notes_rounded,
            ),
          ),
          const SizedBox(height: 22),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _noteBox({required String text, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                height: 1.4,
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
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: !dataDitemukan ? null : lanjutKonfirmasi,
        child: const Text(
          'Lanjut Konfirmasi',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
          _stepCircle('2', 'Data', true),
          _stepLine(false),
          _stepCircle('3', 'Kirim', false),
        ],
      ),
    );
  }

  Widget _stepCircle(String number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 17,
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
            fontSize: 11,
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

  Widget _infoRow(IconData icon, String label, String value) {
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
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
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey),
      prefixIcon: Icon(icon, color: primaryGreen),
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
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
