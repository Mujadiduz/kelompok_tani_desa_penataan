import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

  final namaController = TextEditingController();
  final nikController = TextEditingController();
  final teleponController = TextEditingController();
  final alamatController = TextEditingController();
  final luasSawahController = TextEditingController();
  final passwordController = TextEditingController();

  String? jenisKelamin;
  File? fotoKtp;
  String? fotoKtpBase64;

  bool isLoading = false;
  bool hidePassword = true;

  final DatabaseReference database =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app/',
      ).ref();

  Future<void> pilihFotoKtp() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 20,
      maxWidth: 600,
      maxHeight: 600,
    );

    if (image == null) return;

    final file = File(image.path);
    final bytes = await file.readAsBytes();

    if (!mounted) return;

    setState(() {
      fotoKtp = file;
      fotoKtpBase64 = base64Encode(bytes);
    });
  }

  Future<void> simpanNotifikasiAdmin({
    required String judul,
    required String pesan,
    required String tipe,
  }) async {
    await database.child('notifikasi_admin').push().set({
      'judul': judul,
      'pesan': pesan,
      'tipe': tipe,
      'status': 'belum_dibaca',
      'tanggal': DateTime.now().toIso8601String(),
    });
  }

  Future<void> simpanDataAnggota() async {
    final nama = namaController.text.trim();
    final nik = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final telepon = teleponController.text.trim();
    final alamat = alamatController.text.trim();
    final luasSawah = luasSawahController.text.trim().replaceAll(',', '.');
    final password = passwordController.text.trim();

    if (nama.isEmpty ||
        nik.isEmpty ||
        telepon.isEmpty ||
        alamat.isEmpty ||
        luasSawah.isEmpty ||
        password.isEmpty ||
        jenisKelamin == null) {
      throw Exception('Semua data wajib diisi');
    }

    if (nik.length != 16) {
      throw Exception(
        'NIK harus 16 digit angka. Saat ini terbaca ${nik.length} digit.',
      );
    }

    if (password.length < 6) {
      throw Exception('Password minimal 6 karakter');
    }

    if (fotoKtpBase64 == null) {
      throw Exception('Foto KTP wajib diupload');
    }

    await database
        .child('calon_anggota')
        .push()
        .set({
          'nama': nama,
          'nik': nik,
          'telepon': telepon,
          'alamat': alamat,
          'jenis_kelamin': jenisKelamin,
          'luas_sawah': luasSawah,
          'foto_ktp_base64': fotoKtpBase64,
          'password': password,
          'status': 'menunggu',
          'tanggal_daftar': DateTime.now().toIso8601String(),
        })
        .timeout(const Duration(seconds: 20));

    await simpanNotifikasiAdmin(
      judul: 'Calon Anggota Baru',
      pesan: '$nama telah mendaftar sebagai calon anggota kelompok tani.',
      tipe: 'anggota',
    );
  }

  Future<void> kirimPendaftaran() async {
    setState(() => isLoading = true);

    try {
      await simpanDataAnggota();

      if (!mounted) return;

      _showSnackBar('Pendaftaran berhasil dikirim', primaryGreen);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    namaController.dispose();
    nikController.dispose();
    teleponController.dispose();
    alamatController.dispose();
    luasSawahController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            children: [_header(), const SizedBox(height: 22), _formCard()],
          ),
        ),
      ),
    );
  }

  Widget _header() {
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
              Icons.groups_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Daftar Anggota',
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
                'Calon Anggota',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lengkapi data diri dan data lahan dengan benar sebelum dikirim ke admin.',
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

  Widget _backButton() {
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

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Pendaftaran',
            style: TextStyle(
              color: textDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pastikan data yang dimasukkan sesuai dengan identitas asli.',
            style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 22),
          _inputField(
            label: 'Nama Lengkap',
            icon: Icons.person_rounded,
            controller: namaController,
          ),
          const SizedBox(height: 13),
          _inputField(
            label: 'NIK',
            icon: Icons.badge_rounded,
            controller: nikController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 13),
          _inputField(
            label: 'No Telepon',
            icon: Icons.phone_rounded,
            controller: teleponController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 13),
          _inputField(
            label: 'Alamat',
            icon: Icons.location_on_rounded,
            controller: alamatController,
            maxLines: 2,
          ),
          const SizedBox(height: 13),
          _dropdownJenisKelamin(),
          const SizedBox(height: 13),
          _inputField(
            label: 'Luas Sawah / Luas Lahan (Ha)',
            icon: Icons.landscape_rounded,
            controller: luasSawahController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 13),
          _passwordField(),
          const SizedBox(height: 20),
          _ktpCard(),
          const SizedBox(height: 24),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _dropdownJenisKelamin() {
    return DropdownButtonFormField<String>(
      value: jenisKelamin,
      decoration: _inputDecoration(
        label: 'Jenis Kelamin',
        icon: Icons.wc_rounded,
      ),
      items: const [
        DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
        DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
      ],
      onChanged: (value) {
        setState(() {
          jenisKelamin = value;
        });
      },
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: passwordController,
      obscureText: hidePassword,
      decoration: _inputDecoration(
        label: 'Password',
        icon: Icons.lock_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => hidePassword = !hidePassword);
          },
          icon: Icon(
            hidePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: textGrey,
          ),
        ),
      ),
    );
  }

  Widget _ktpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Foto KTP',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload foto KTP sebagai bukti identitas calon anggota.',
            style: TextStyle(color: textGrey, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          if (fotoKtp != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                fotoKtp!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 152,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    color: primaryGreen,
                    size: 42,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada foto KTP',
                    style: TextStyle(
                      color: textGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(color: primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: pilihFotoKtp,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(
                fotoKtp == null ? 'Upload Foto KTP' : 'Ganti Foto KTP',
                style: const TextStyle(fontWeight: FontWeight.w800),
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
        onPressed: isLoading ? null : kirimPendaftaran,
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
          isLoading ? 'Mengirim...' : 'Kirim Pendaftaran',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(label: label, icon: icon),
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
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.055),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
