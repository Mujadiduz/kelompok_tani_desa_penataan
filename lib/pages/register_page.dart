import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const Color deepGreen = Color(0xff0F3D25);
  static const Color softGreen = Color(0xffF3FBF5);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color dangerColor = Color(0xffC62828);

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nikController = TextEditingController();
  final TextEditingController teleponController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController jumlahPetakController = TextEditingController();
  final TextEditingController luasPerPetakController = TextEditingController();
  final TextEditingController meterController = TextEditingController();
  final TextEditingController hektareController = TextEditingController();

  final FocusNode namaFocus = FocusNode();
  final FocusNode nikFocus = FocusNode();
  final FocusNode teleponFocus = FocusNode();
  final FocusNode alamatFocus = FocusNode();
  final FocusNode jumlahPetakFocus = FocusNode();
  final FocusNode luasPerPetakFocus = FocusNode();
  final FocusNode meterFocus = FocusNode();
  final FocusNode hektareFocus = FocusNode();
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

  String modeLahan = 'petak';
  double luasLahanHa = 0;
  String keteranganLuasLahan = '';

  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    namaController.dispose();
    nikController.dispose();
    teleponController.dispose();
    alamatController.dispose();
    passwordController.dispose();

    jumlahPetakController.dispose();
    luasPerPetakController.dispose();
    meterController.dispose();
    hektareController.dispose();

    namaFocus.dispose();
    nikFocus.dispose();
    teleponFocus.dispose();
    alamatFocus.dispose();
    jumlahPetakFocus.dispose();
    luasPerPetakFocus.dispose();
    meterFocus.dispose();
    hektareFocus.dispose();
    passwordFocus.dispose();

    super.dispose();
  }

  void hitungLuasLahan() {
    double hasil = 0;
    String keterangan = '';

    if (modeLahan == 'petak') {
      final jumlahPetak =
          double.tryParse(jumlahPetakController.text.replaceAll(',', '.')) ?? 0;
      final luasPerPetak =
          double.tryParse(luasPerPetakController.text.replaceAll(',', '.')) ??
          0;

      final totalMeter = jumlahPetak * luasPerPetak;
      hasil = totalMeter / 10000;

      if (hasil > 0) {
        keterangan =
            '$jumlahPetak petak x $luasPerPetak m² = ${hasil.toStringAsFixed(3)} ha';
      }
    } else if (modeLahan == 'meter') {
      final meter =
          double.tryParse(meterController.text.replaceAll(',', '.')) ?? 0;

      hasil = meter / 10000;

      if (hasil > 0) {
        keterangan = '$meter m² = ${hasil.toStringAsFixed(3)} ha';
      }
    } else {
      hasil = double.tryParse(hektareController.text.replaceAll(',', '.')) ?? 0;

      if (hasil > 0) {
        keterangan = '${hasil.toStringAsFixed(3)} ha';
      }
    }

    setState(() {
      luasLahanHa = hasil;
      keteranganLuasLahan = keterangan;
    });
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

  double _parseAngka(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
  }

  Future<void> simpanDataAnggota() async {
    final nama = namaController.text.trim();
    final nik = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final telepon = teleponController.text.trim();
    final alamat = alamatController.text.trim();
    final password = passwordController.text.trim();

    await database
        .child('calon_anggota')
        .push()
        .set({
          'nama': nama,
          'nik': nik,
          'telepon': telepon,
          'alamat': alamat,
          'jenis_kelamin': jenisKelamin,
          'luas_lahan': luasLahanHa,
          'satuan_lahan': 'ha',
          'mode_lahan': modeLahan,
          'jumlah_petak': _parseAngka(jumlahPetakController),
          'luas_per_petak_m2': _parseAngka(luasPerPetakController),
          'luas_meter_m2': _parseAngka(meterController),
          'keterangan_luas_lahan': keteranganLuasLahan,
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
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(
        'Pendaftaran gagal. Periksa koneksi internet.',
        dangerColor,
      );
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

    hitungLuasLahan();

    if (luasLahanHa <= 0) {
      _showSnackBar('Luas lahan sawah wajib diisi.', dangerColor);
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
        jumlahPetakController.text.trim().isNotEmpty ||
        luasPerPetakController.text.trim().isNotEmpty ||
        meterController.text.trim().isNotEmpty ||
        hektareController.text.trim().isNotEmpty ||
        passwordController.text.trim().isNotEmpty ||
        jenisKelamin != null ||
        fotoKtp != null;
  }

  Future<bool> konfirmasiKeluar() async {
    if (!formTerisiSebagian()) return true;

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogIcon(Icons.warning_amber_rounded, dangerColor),
                const SizedBox(height: 14),
                const Text(
                  'Batalkan Pendaftaran?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Data yang sudah diisi belum tersimpan. Apakah Anda yakin ingin kembali?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12.6,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textGrey,
                          side: const BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dangerColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: const Text(
                          'Kembali',
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

    return hasil == true;
  }

  Future<void> kembali() async {
    FocusScope.of(context).unfocus();

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
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _pilihJenisKelamin() async {
    FocusScope.of(context).unfocus();

    final hasil = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Jenis Kelamin',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih sesuai data identitas pendaftaran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _genderSheetOption(
                  label: 'Laki-laki',
                  icon: Icons.man_2_outlined,
                  selected: jenisKelamin == 'Laki-laki',
                  onTap: () => Navigator.pop(sheetContext, 'Laki-laki'),
                ),
                const SizedBox(height: 10),
                _genderSheetOption(
                  label: 'Perempuan',
                  icon: Icons.woman_2_outlined,
                  selected: jenisKelamin == 'Perempuan',
                  onTap: () => Navigator.pop(sheetContext, 'Perempuan'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (hasil != null) {
      setState(() => jenisKelamin = hasil);
    }
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
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset + 28),
              children: [
                _header(),
                const SizedBox(height: 14),
                _introCard(),
                const SizedBox(height: 13),
                _dataPribadiCard(),
                const SizedBox(height: 13),
                _dataLahanCard(),
                const SizedBox(height: 13),
                _uploadKtpCard(),
                const SizedBox(height: 13),
                _infoCard(),
                const SizedBox(height: 18),
                _submitButton(),
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
              Icons.person_add_alt_outlined,
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
                  'Daftar Anggota',
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
                  'Pendaftaran calon anggota',
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
        'BARU',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 21),
      child: Row(
        children: [
          _iconBox(Icons.assignment_ind_outlined, primaryGreen),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Lengkapi data dengan benar. Pendaftaran akan diverifikasi admin sebelum akun dapat digunakan.',
              style: TextStyle(
                color: textGrey,
                fontSize: 11.8,
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
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.person_outline_rounded,
            title: 'Data Pribadi',
            subtitle: 'Identitas calon anggota',
          ),
          const SizedBox(height: 14),
          _inputField(
            label: 'Nama Lengkap',
            hint: 'Masukkan nama lengkap',
            icon: Icons.person_outline_rounded,
            controller: namaController,
            focusNode: namaFocus,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => nikFocus.requestFocus(),
          ),
          const SizedBox(height: 11),
          _inputField(
            label: 'NIK',
            hint: 'Masukkan 16 digit NIK',
            icon: Icons.credit_card_rounded,
            controller: nikController,
            focusNode: nikFocus,
            keyboardType: TextInputType.number,
            maxLength: 16,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => teleponFocus.requestFocus(),
          ),
          const SizedBox(height: 11),
          _inputField(
            label: 'No Telepon',
            hint: 'Masukkan nomor telepon / WhatsApp',
            icon: Icons.call_outlined,
            controller: teleponController,
            focusNode: teleponFocus,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            ],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 11),
          _genderSelector(),
          const SizedBox(height: 11),
          _inputField(
            label: 'Alamat',
            hint: 'Masukkan alamat lengkap',
            icon: Icons.location_on_outlined,
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
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.landscape_outlined,
            title: 'Data Lahan & Akun',
            subtitle: 'Luas lahan disimpan dalam satuan hektare',
          ),
          const SizedBox(height: 14),
          _luasLahanInput(),
          const SizedBox(height: 11),
          _passwordField(),
          const SizedBox(height: 11),
          _miniInfo(
            icon: Icons.info_outline_rounded,
            text:
                'Petani dapat memilih Petak, Meter², atau Hektare. Sistem tetap menyimpan hasil akhir dalam satuan hektare agar data laporan lebih rapi.',
          ),
        ],
      ),
    );
  }

  Widget _luasLahanInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Luas Lahan Sawah',
          style: TextStyle(
            color: textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            _modeLahanChip('petak', 'Petak'),
            const SizedBox(width: 7),
            _modeLahanChip('meter', 'Meter²'),
            const SizedBox(width: 7),
            _modeLahanChip('ha', 'Hektare'),
          ],
        ),
        const SizedBox(height: 12),
        if (modeLahan == 'petak') ...[
          _inputField(
            label: 'Jumlah Petak',
            hint: 'Contoh: 1',
            icon: Icons.grid_view_rounded,
            controller: jumlahPetakController,
            focusNode: jumlahPetakFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            textInputAction: TextInputAction.next,
            onChanged: (_) => hitungLuasLahan(),
            onSubmitted: (_) => luasPerPetakFocus.requestFocus(),
          ),
          const SizedBox(height: 11),
          _inputField(
            label: 'Luas 1 Petak',
            hint: 'Contoh: 250',
            icon: Icons.square_foot_rounded,
            controller: luasPerPetakController,
            focusNode: luasPerPetakFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            textInputAction: TextInputAction.next,
            onChanged: (_) => hitungLuasLahan(),
            onSubmitted: (_) => passwordFocus.requestFocus(),
          ),
        ] else if (modeLahan == 'meter') ...[
          _inputField(
            label: 'Luas Lahan',
            hint: 'Contoh: 500',
            icon: Icons.square_foot_rounded,
            controller: meterController,
            focusNode: meterFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            textInputAction: TextInputAction.next,
            onChanged: (_) => hitungLuasLahan(),
            onSubmitted: (_) => passwordFocus.requestFocus(),
          ),
        ] else ...[
          _inputField(
            label: 'Luas Lahan',
            hint: 'Contoh: 0.05',
            icon: Icons.agriculture_outlined,
            controller: hektareController,
            focusNode: hektareFocus,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            textInputAction: TextInputAction.next,
            onChanged: (_) => hitungLuasLahan(),
            onSubmitted: (_) => passwordFocus.requestFocus(),
          ),
        ],
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: softGreen,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
          ),
          child: Text(
            luasLahanHa > 0
                ? 'Luas Lahan : ${luasLahanHa.toStringAsFixed(3)} ha\n$keteranganLuasLahan'
                : 'Catatan: 1 petak tidak sama dengan 1 hektare. Masukkan perkiraan luas sawah sesuai satuan yang paling mudah.',
            style: const TextStyle(
              color: textGrey,
              fontSize: 11.8,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeLahanChip(String value, String label) {
    final selected = modeLahan == value;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap:
            isLoading
                ? null
                : () {
                  setState(() {
                    modeLahan = value;
                    luasLahanHa = 0;
                    keteranganLuasLahan = '';
                  });
                  hitungLuasLahan();
                },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primaryGreen : const Color(0xffF9FAFB),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: selected ? primaryGreen : borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : primaryGreen,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _uploadKtpCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.badge_outlined,
            title: 'Bukti Identitas',
            subtitle: 'Upload foto KTP yang terlihat jelas',
          ),
          const SizedBox(height: 14),
          if (fotoKtp != null) _ktpPreview() else _ktpEmpty(),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: BorderSide(color: primaryGreen.withValues(alpha: 0.42)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isLoading ? null : pilihFotoKtp,
              icon: const Icon(Icons.upload_file_outlined, size: 19),
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
              'Pastikan seluruh data sudah benar. Setelah dikirim, admin akan melakukan verifikasi.',
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

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
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
                : const Icon(
                  Icons.send_outlined,
                  color: Colors.white,
                  size: 20,
                ),
        label: Text(
          isLoading ? 'Mengirim...' : 'Kirim Pendaftaran',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _genderSelector() {
    final selected = jenisKelamin != null;

    return InkWell(
      onTap: isLoading ? null : _pilihJenisKelamin,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? primaryGreen : borderColor,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.wc_outlined : Icons.person_search_outlined,
              color: primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                jenisKelamin ?? 'Pilih jenis kelamin',
                style: TextStyle(
                  color:
                      selected
                          ? textDark
                          : Colors.black.withValues(alpha: 0.42),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: selected ? primaryGreen : textGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderSheetOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? primaryGreen.withValues(alpha: 0.08) : softGreen,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected ? primaryGreen : primaryGreen.withValues(alpha: 0.10),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _iconBox(icon, primaryGreen),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? primaryGreen : textDark,
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: selected ? primaryGreen : textGrey,
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
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(
        color: textDark,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        label: 'Password',
        hint: 'Minimal 6 karakter',
        icon: Icons.lock_outline_rounded,
      ).copyWith(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => hidePassword = !hidePassword);
          },
          icon: Icon(
            hidePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: primaryGreen,
          ),
        ),
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
            height: 178,
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
      height: 142,
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.13)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.badge_outlined, color: primaryGreen, size: 40),
          SizedBox(height: 8),
          Text(
            'Belum ada foto KTP',
            style: TextStyle(
              color: textGrey,
              fontWeight: FontWeight.w800,
              fontSize: 12.3,
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
    List<TextInputFormatter>? inputFormatters,
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
      inputFormatters: inputFormatters,
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
      prefixIcon: Icon(icon, color: primaryGreen, size: 20),
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      counterText: '',
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

  Widget _sectionTitle({
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

  Widget _miniInfo({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.6,
                height: 1.35,
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
      onTap: kembali,
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

  Widget _dialogIcon(IconData icon, Color color) {
    return Container(
      height: 66,
      width: 66,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Icon(icon, color: color, size: 34),
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
