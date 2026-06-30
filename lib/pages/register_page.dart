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
      throw Exception('NIK harus 16 digit angka.');
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

    if (!_validasiForm()) return;

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

  bool _validasiForm() {
    final nama = namaController.text.trim();
    final nik = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final telepon = teleponController.text.trim();
    final alamat = alamatController.text.trim();
    final luasSawah = luasSawahController.text.trim().replaceAll(',', '.');
    final password = passwordController.text.trim();

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

    final luas = double.tryParse(luasSawah);

    if (luas == null || luas <= 0) {
      _showSnackBar('Luas sawah harus lebih dari 0.', dangerColor);
      return false;
    }

    if (password.length < 6) {
      _showSnackBar('Password minimal 6 karakter.', dangerColor);
      return false;
    }

    if (fotoKtpBase64 == null) {
      _showSnackBar('Foto KTP wajib diupload.', dangerColor);
      return false;
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
            borderRadius: BorderRadius.circular(20),
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await kembali();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          showPattern: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(20, 18, 20, bottomInset + 28),
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  _introCard(),
                  const SizedBox(height: 14),
                  _dataPribadiCard(),
                  const SizedBox(height: 14),
                  _dataLahanCard(),
                  const SizedBox(height: 14),
                  _uploadKtpCard(),
                  const SizedBox(height: 14),
                  _infoCard(),
                  const SizedBox(height: 16),
                  _submitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: kembali,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              height: 40,
              width: 36,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Anggota',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Pendaftaran calon anggota',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 11.8,
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

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.assignment_ind_rounded,
              color: primaryGreen,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Lengkapi data pendaftaran dengan benar. Data akan diverifikasi oleh admin sebelum akun dapat digunakan.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                height: 1.42,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataPribadiCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.person_rounded,
            title: 'Data Pribadi',
            subtitle: 'Identitas calon anggota',
          ),
          const SizedBox(height: 16),
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

  Widget _dataLahanCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.agriculture_rounded,
            title: 'Data Lahan & Akun',
            subtitle: 'Informasi lahan dan akses login',
          ),
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
          const SizedBox(height: 13),
          _miniInfo(
            icon: Icons.lock_person_rounded,
            text:
                'Password digunakan untuk login setelah pendaftaran disetujui oleh admin.',
          ),
        ],
      ),
    );
  }

  Widget _uploadKtpCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.credit_card_rounded,
            title: 'Bukti Identitas',
            subtitle: 'Upload foto KTP yang terlihat jelas',
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.13)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pastikan seluruh data sudah sesuai. Setelah dikirim, pendaftaran akan masuk ke proses verifikasi admin.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.4,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
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
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12,
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

  Widget _genderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Kelamin',
          style: TextStyle(
            color: textGrey,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color:
              selected
                  ? primaryGreen.withValues(alpha: 0.11)
                  : const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(16),
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
                  fontSize: 12.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField() {
    return TextField(
      controller: passwordController,
      focusNode: passwordFocus,
      obscureText: hidePassword,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: textDark,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
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

  Widget _miniInfo({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
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

  Widget _ktpPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.file(
            fotoKtp!,
            width: double.infinity,
            height: 185,
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
      height: 150,
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.15)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_rounded, color: primaryGreen, size: 42),
          SizedBox(height: 8),
          Text(
            'Belum ada foto KTP',
            style: TextStyle(
              color: textGrey,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
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
      style: const TextStyle(
        color: textDark,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: ElevatedButton(
        onPressed: isLoading ? null : kirimPendaftaran,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.42),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Kirim Pendaftaran',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
