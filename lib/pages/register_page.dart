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

    final luas = double.tryParse(luasSawah);
    if (luas == null || luas <= 0) {
      throw Exception('Luas sawah harus lebih dari 0');
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
    if (isLoading) return;

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

  double estimasiJatahPupuk() {
    final luas =
        double.tryParse(luasSawahController.text.trim().replaceAll(',', '.')) ??
        0;

    return luas / 2;
  }

  String formatAngka(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
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
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Batalkan Pendaftaran?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Data yang sudah diisi belum tersimpan. Apakah Anda yakin ingin kembali?',
            style: TextStyle(color: textGrey, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tetap di Halaman'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kembali'),
            ),
          ],
        );
      },
    );

    return hasil == true;
  }

  void kembali() async {
    final bolehKeluar = await konfirmasiKeluar();

    if (!mounted) return;

    if (bolehKeluar) Navigator.pop(context);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

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
    final estimasiJatah = estimasiJatahPupuk();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        kembali();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: _stepInfoCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: _sectionTitle(
                    title: 'Data Pribadi',
                    icon: Icons.person_rounded,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: _dataPribadiCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: _sectionTitle(
                    title: 'Data Lahan & Akun',
                    icon: Icons.landscape_rounded,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: _dataLahanCard(estimasiJatah),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                  child: _sectionTitle(
                    title: 'Bukti Identitas',
                    icon: Icons.credit_card_rounded,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
                  child: _ktpCard(),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _submitBar(),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff14532D), Color(0xff2E7D32), Color(0xff66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            bottom: -42,
            child: Icon(
              Icons.groups_rounded,
              size: 160,
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Calon Anggota',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Lengkapi data diri dan data lahan dengan benar sebelum dikirim ke admin kelompok tani.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      height: 42,
                      width: 42,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0x24FFFFFF),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pendaftaran akan masuk ke admin dan berstatus menunggu verifikasi.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
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
      onTap: kembali,
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

  Widget _stepInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _stepItem(
                  number: '1',
                  title: 'Isi Data',
                  icon: Icons.edit_document,
                  active: true,
                ),
              ),
              _stepLine(),
              Expanded(
                child: _stepItem(
                  number: '2',
                  title: 'Verifikasi',
                  icon: Icons.admin_panel_settings_rounded,
                  active: false,
                ),
              ),
              _stepLine(),
              Expanded(
                child: _stepItem(
                  number: '3',
                  title: 'Aktif',
                  icon: Icons.verified_rounded,
                  active: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepItem({
    required String number,
    required String title,
    required IconData icon,
    required bool active,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: active ? primaryGreen : const Color(0xffE5E7EB),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: active ? Colors.white : textGrey, size: 21),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? primaryGreen : textGrey,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _stepLine() {
    return Container(
      width: 24,
      height: 3,
      margin: const EdgeInsets.only(bottom: 26),
      decoration: BoxDecoration(
        color: const Color(0xffE5E7EB),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Widget _sectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryGreen, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataPribadiCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
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
            maxLength: 16,
          ),
          const SizedBox(height: 13),
          _inputField(
            label: 'No Telepon',
            icon: Icons.phone_rounded,
            controller: teleponController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 13),
          _dropdownJenisKelamin(),
          const SizedBox(height: 13),
          _inputField(
            label: 'Alamat',
            icon: Icons.location_on_rounded,
            controller: alamatController,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _dataLahanCard(double estimasiJatah) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _inputField(
            label: 'Luas Sawah / Lahan (Ha)',
            icon: Icons.landscape_rounded,
            controller: luasSawahController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 13),
          _jatahInfo(estimasiJatah),
          const SizedBox(height: 13),
          _passwordField(),
        ],
      ),
    );
  }

  Widget _jatahInfo(double estimasiJatah) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.grass_rounded, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              luasSawahController.text.trim().isEmpty
                  ? 'Estimasi jatah pupuk akan muncul setelah luas lahan diisi.'
                  : 'Estimasi jatah pupuk: ${formatAngka(estimasiJatah)} Kg',
              style: const TextStyle(
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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
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
            'Upload foto KTP sebagai bukti identitas calon anggota.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (fotoKtp != null)
            Stack(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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
            )
          else
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    color: primaryGreen,
                    size: 45,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada foto KTP',
                    style: TextStyle(
                      color: textGrey,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
              onPressed: pilihFotoKtp,
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

  Widget _submitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.45),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
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
              isLoading ? 'Mengirim Pendaftaran...' : 'Kirim Pendaftaran',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
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
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
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
      counterText: '',
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
