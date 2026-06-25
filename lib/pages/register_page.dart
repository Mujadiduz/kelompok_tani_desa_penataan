import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/app_background.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color dangerColor = Color(0xffC62828);

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nikController = TextEditingController();
  final TextEditingController teleponController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController luasSawahController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode namaFocus = FocusNode();
  final FocusNode nikFocus = FocusNode();
  final FocusNode teleponFocus = FocusNode();
  final FocusNode alamatFocus = FocusNode();
  final FocusNode luasFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  final DatabaseReference database =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app/',
      ).ref();

  int currentStep = 0;
  String? jenisKelamin;
  File? fotoKtp;
  String? fotoKtpBase64;

  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    namaController.dispose();
    nikController.dispose();
    teleponController.dispose();
    alamatController.dispose();
    luasSawahController.dispose();
    passwordController.dispose();

    namaFocus.dispose();
    nikFocus.dispose();
    teleponFocus.dispose();
    alamatFocus.dispose();
    luasFocus.dispose();
    passwordFocus.dispose();

    super.dispose();
  }

  Future<void> pilihFotoKtp() async {
    FocusScope.of(context).unfocus();

    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 22,
      maxWidth: 700,
      maxHeight: 700,
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
      'dibaca': false,
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

    final luas = double.tryParse(luasSawah);

    if (nama.isEmpty ||
        nik.isEmpty ||
        telepon.isEmpty ||
        alamat.isEmpty ||
        luasSawah.isEmpty ||
        password.isEmpty ||
        jenisKelamin == null) {
      throw Exception('Semua data wajib diisi.');
    }

    if (nik.length != 16) {
      throw Exception(
        'NIK harus 16 digit angka. Saat ini terbaca ${nik.length} digit.',
      );
    }

    if (password.length < 6) {
      throw Exception('Password minimal 6 karakter.');
    }

    if (luas == null || luas <= 0) {
      throw Exception('Luas sawah harus lebih dari 0.');
    }

    if (fotoKtpBase64 == null) {
      throw Exception('Foto KTP wajib diupload.');
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
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_validateStep(2)) return;

    setState(() => isLoading = true);

    try {
      await simpanDataAnggota();

      if (!mounted) return;

      _showSnackBar('Pendaftaran berhasil dikirim.', primaryGreen);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), dangerColor);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void nextStep() {
    if (!_validateStep(currentStep)) return;

    if (currentStep < 2) {
      setState(() => currentStep++);
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
    } else {
      kembali();
    }
  }

  bool _validateStep(int step) {
    final nama = namaController.text.trim();
    final nik = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final telepon = teleponController.text.trim();
    final alamat = alamatController.text.trim();
    final luasSawah = luasSawahController.text.trim().replaceAll(',', '.');
    final password = passwordController.text.trim();

    if (step == 0) {
      if (nama.isEmpty) {
        _showSnackBar('Nama lengkap wajib diisi.', dangerColor);
        return false;
      }

      if (nik.length != 16) {
        _showSnackBar('NIK harus 16 digit angka.', dangerColor);
        return false;
      }

      if (telepon.isEmpty) {
        _showSnackBar('Nomor telepon wajib diisi.', dangerColor);
        return false;
      }

      if (jenisKelamin == null) {
        _showSnackBar('Jenis kelamin wajib dipilih.', dangerColor);
        return false;
      }

      if (alamat.isEmpty) {
        _showSnackBar('Alamat wajib diisi.', dangerColor);
        return false;
      }

      return true;
    }

    if (step == 1) {
      final luas = double.tryParse(luasSawah);

      if (luas == null || luas <= 0) {
        _showSnackBar('Luas sawah harus lebih dari 0.', dangerColor);
        return false;
      }

      if (password.length < 6) {
        _showSnackBar('Password minimal 6 karakter.', dangerColor);
        return false;
      }

      return true;
    }

    if (step == 2) {
      if (!_validateStep(0)) return false;
      if (!_validateStep(1)) return false;

      if (fotoKtpBase64 == null) {
        _showSnackBar('Foto KTP wajib diupload.', dangerColor);
        return false;
      }

      return true;
    }

    return true;
  }

  bool formTerisiSebagian() {
    return namaController.text.trim().isNotEmpty ||
        nikController.text.trim().isNotEmpty ||
        teleponController.text.trim().isNotEmpty ||
        alamatController.text.trim().isNotEmpty ||
        luasSawahController.text.trim().isNotEmpty ||
        passwordController.text.trim().isNotEmpty ||
        jenisKelamin != null ||
        fotoKtp != null;
  }

  Future<bool> konfirmasiKeluar() async {
    if (!formTerisiSebagian()) return true;

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Batalkan Pendaftaran?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Data yang sudah diisi belum tersimpan. Apakah Anda yakin ingin kembali?',
            style: TextStyle(
              color: textGrey,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Tetap di Halaman',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dangerColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Kembali',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    return hasil == true;
  }

  Future<void> kembali() async {
    final bolehKeluar = await konfirmasiKeluar();

    if (!mounted) return;

    if (bolehKeluar) {
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await kembali();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    children: [
                      _progressCard(),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _currentStepContent(),
                      ),
                      const SizedBox(height: 18),
                      _bottomActionBar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
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
            onTap: kembali,
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
              Icons.person_add_alt_1_rounded,
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
                  'Daftar Anggota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pendaftaran calon anggota TaniGo.',
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

  Widget _progressCard() {
    final progress = (currentStep + 1) / 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepCircle(0, Icons.person_rounded),
              _stepConnector(0),
              _stepCircle(1, Icons.landscape_rounded),
              _stepConnector(1),
              _stepCircle(2, Icons.credit_card_rounded),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xffE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Langkah ${currentStep + 1} dari 3',
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _stepTitle(),
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _stepSubtitle(),
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.4,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCircle(int index, IconData icon) {
    final active = currentStep >= index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: active ? primaryGreen : const Color(0xffE5E7EB),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: active ? Colors.white : textGrey, size: 21),
    );
  }

  Widget _stepConnector(int index) {
    final active = currentStep > index;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: active ? primaryGreen : const Color(0xffE5E7EB),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  String _stepTitle() {
    if (currentStep == 0) return 'Data Pribadi';
    if (currentStep == 1) return 'Data Lahan & Akun';
    return 'Bukti Identitas';
  }

  String _stepSubtitle() {
    if (currentStep == 0) {
      return 'Isi identitas calon anggota dengan data yang benar.';
    }

    if (currentStep == 1) {
      return 'Masukkan data lahan dan buat password akun.';
    }

    return 'Upload foto KTP sebagai bukti identitas calon anggota.';
  }

  Widget _currentStepContent() {
    if (currentStep == 0) {
      return _dataPribadiStep(key: const ValueKey('step_0'));
    }

    if (currentStep == 1) {
      return _dataLahanStep(key: const ValueKey('step_1'));
    }

    return _ktpStep(key: const ValueKey('step_2'));
  }

  Widget _dataPribadiStep({required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          _inputField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap',
            icon: Icons.person_rounded,
            controller: namaController,
            focusNode: namaFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => nikFocus.requestFocus(),
          ),
          const SizedBox(height: 13),
          _inputField(
            label: 'NIK',
            hint: 'Masukkan 16 digit NIK',
            icon: Icons.badge_rounded,
            controller: nikController,
            focusNode: nikFocus,
            keyboardType: TextInputType.number,
            maxLength: 16,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => teleponFocus.requestFocus(),
          ),
          const SizedBox(height: 13),
          _inputField(
            label: 'No Telepon',
            hint: 'Masukkan nomor telepon',
            icon: Icons.phone_rounded,
            controller: teleponController,
            focusNode: teleponFocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 13),
          _genderSelector(),
          const SizedBox(height: 13),
          _inputField(
            label: 'Alamat',
            hint: 'Masukkan alamat lengkap',
            icon: Icons.location_on_rounded,
            controller: alamatController,
            focusNode: alamatFocus,
            maxLines: 2,
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  Widget _genderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.wc_rounded, color: primaryGreen, size: 21),
            SizedBox(width: 8),
            Text(
              'Jenis Kelamin',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _genderOption(
                label: 'Laki-laki',
                icon: Icons.male_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _genderOption(
                label: 'Perempuan',
                icon: Icons.female_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _genderOption({required String label, required IconData icon}) {
    final selected = jenisKelamin == label;

    return InkWell(
      onTap: () {
        setState(() {
          jenisKelamin = label;
        });
      },
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:
              selected
                  ? primaryGreen.withValues(alpha: 0.11)
                  : const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? primaryGreen : borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? primaryGreen : textGrey, size: 22),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? primaryGreen : textGrey,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataLahanStep({required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lahanHeader(),
          const SizedBox(height: 16),
          _inputField(
            label: 'Luas Sawah / Lahan',
            hint: 'Contoh: 2.5 hektar',
            icon: Icons.landscape_rounded,
            controller: luasSawahController,
            focusNode: luasFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 13),
          _passwordField(),
          const SizedBox(height: 14),
          _accountInfoBox(),
        ],
      ),
    );
  }

  Widget _lahanHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.13)),
      ),
      child: const Row(
        children: [
          SizedBox(
            height: 44,
            width: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xffDFF3E3),
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: Icon(Icons.agriculture_rounded, color: primaryGreen),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Masukkan data lahan yang dimiliki untuk melengkapi pendaftaran anggota.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountInfoBox() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_person_rounded, color: primaryGreen, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Password digunakan untuk login setelah pendaftaran disetujui oleh admin.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ktpStep({required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Foto KTP',
            style: TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pastikan foto terlihat jelas dan tidak buram.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (fotoKtp != null) _ktpPreview() else _ktpEmpty(),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(color: primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isLoading ? null : pilihFotoKtp,
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(
                fotoKtp == null ? 'Upload Foto KTP' : 'Ganti Foto KTP',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _summaryBox(),
        ],
      ),
    );
  }

  Widget _ktpPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            fotoKtp!,
            width: double.infinity,
            height: 190,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Terupload',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ktpEmpty() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_rounded, color: primaryGreen, size: 45),
          SizedBox(height: 8),
          Text(
            'Belum ada foto KTP',
            style: TextStyle(color: textGrey, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox() {
    final nama = namaController.text.trim();
    final nik = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final luas = luasSawahController.text.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.13)),
      ),
      child: Column(
        children: [
          _summaryRow('Nama', nama.isEmpty ? '-' : nama),
          const SizedBox(height: 8),
          _summaryRow('NIK', nik.isEmpty ? '-' : nik),
          const SizedBox(height: 8),
          _summaryRow('Luas Lahan', luas.isEmpty ? '-' : '$luas Ha'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(color: textGrey, fontWeight: FontWeight.w700),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textDark,
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: passwordController,
      focusNode: passwordFocus,
      obscureText: hidePassword,
      textInputAction: TextInputAction.done,
      decoration: _inputDecoration(
        label: 'Password',
        hint: 'Minimal 6 karakter',
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
            color: primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    FocusNode? focusNode,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
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
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      counterText: '',
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

  Widget _bottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        children: [
          SizedBox(
            height: 52,
            width: 52,
            child: OutlinedButton(
              onPressed: isLoading ? null : previousStep,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: BorderSide(color: primaryGreen.withValues(alpha: 0.45)),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    isLoading
                        ? null
                        : currentStep == 2
                        ? kirimPendaftaran
                        : nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryGreen.withValues(alpha: 0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
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
                        : Icon(
                          currentStep == 2
                              ? Icons.send_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                label: Text(
                  isLoading
                      ? 'Mengirim...'
                      : currentStep == 2
                      ? 'Kirim Pendaftaran'
                      : 'Selanjutnya',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
          ),
        ],
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
