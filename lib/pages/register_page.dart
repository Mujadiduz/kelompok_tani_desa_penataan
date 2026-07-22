import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color navyColor = Color(0xff17324D);
  static const Color blueColor = Color(0xff2F6B9A);
  static const Color tealColor = Color(0xff28766F);
  static const Color amberColor = Color(0xffD97706);
  static const Color purpleColor = Color(0xff6D5BAE);

  static const Color softGreen = Color(0xffEAF6EC);
  static const Color softBlue = Color(0xffEDF5FB);
  static const Color softTeal = Color(0xffEAF7F5);
  static const Color softAmber = Color(0xffFFF7E8);
  static const Color softPurple = Color(0xffF3F0FA);

  static const Color pageBackground = Color(0xffF5F7F9);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);
  static const Color borderColor = Color(0xffE2E7EC);
  static const Color dangerColor = Color(0xffC83B3B);

  final TextEditingController namaController =
      TextEditingController();

  final TextEditingController nikController =
      TextEditingController();

  final TextEditingController teleponController =
      TextEditingController();

  final TextEditingController alamatController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController jumlahPetakController =
      TextEditingController();

  final TextEditingController luasPerPetakController =
      TextEditingController();

  final TextEditingController meterController =
      TextEditingController();

  final TextEditingController hektareController =
      TextEditingController();

  final FocusNode namaFocus = FocusNode();
  final FocusNode nikFocus = FocusNode();
  final FocusNode teleponFocus = FocusNode();
  final FocusNode alamatFocus = FocusNode();

  final FocusNode jumlahPetakFocus = FocusNode();
  final FocusNode luasPerPetakFocus = FocusNode();
  final FocusNode meterFocus = FocusNode();
  final FocusNode hektareFocus = FocusNode();

  final FocusNode passwordFocus = FocusNode();

  final PageController _pageController = PageController();

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

  int currentStep = 0;

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
    _pageController.dispose();

    super.dispose();
  }

  void hitungLuasLahan() {
    double hasil = 0;
    String keterangan = '';

    if (modeLahan == 'petak') {
      final jumlahPetak =
          double.tryParse(
            jumlahPetakController.text.replaceAll(',', '.'),
          ) ??
          0;

      final luasPerPetak =
          double.tryParse(
            luasPerPetakController.text.replaceAll(',', '.'),
          ) ??
          0;

      final totalMeter = jumlahPetak * luasPerPetak;

      hasil = totalMeter / 10000;

      if (hasil > 0) {
        keterangan =
            '$jumlahPetak petak x $luasPerPetak m² = '
            '${hasil.toStringAsFixed(3)} ha';
      }
    } else if (modeLahan == 'meter') {
      final meter =
          double.tryParse(
            meterController.text.replaceAll(',', '.'),
          ) ??
          0;

      hasil = meter / 10000;

      if (hasil > 0) {
        keterangan =
            '$meter m² = ${hasil.toStringAsFixed(3)} ha';
      }
    } else {
      hasil =
          double.tryParse(
            hektareController.text.replaceAll(',', '.'),
          ) ??
          0;

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

  double _parseAngka(
    TextEditingController controller,
  ) {
    return double.tryParse(
          controller.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  Future<void> simpanDataAnggota() async {
    final nama = namaController.text.trim();

    final nik = nikController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final telepon = teleponController.text.trim();
    final alamat = alamatController.text.trim();
    final password = passwordController.text.trim();

    final calonRef =
        database.child('calon_anggota').push();

    final calonId = calonRef.key ?? nik;

    await calonRef
        .set({
          'nama': nama,
          'nik': nik,
          'telepon': telepon,
          'alamat': alamat,
          'jenis_kelamin': jenisKelamin,
          'luas_lahan': luasLahanHa,
          'satuan_lahan': 'ha',
          'mode_lahan': modeLahan,
          'jumlah_petak':
              _parseAngka(jumlahPetakController),
          'luas_per_petak_m2':
              _parseAngka(luasPerPetakController),
          'luas_meter_m2':
              _parseAngka(meterController),
          'keterangan_luas_lahan':
              keteranganLuasLahan,
          'foto_ktp_base64': fotoKtpBase64,
          'password': password,
          'status': 'menunggu',
          'tanggal_daftar':
              DateTime.now().toIso8601String(),
        })
        .timeout(const Duration(seconds: 20));

    try {
      await NotificationHelper.calonAnggotaUntukAdmin(
        nik: nik,
        nama: nama,
        eventId: calonId,
      );
    } catch (error) {
      debugPrint(
        'Pendaftaran tersimpan, tetapi notifikasi admin gagal: $error',
      );
    }
  }

  Future<void> kirimPendaftaran() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_validasiForm()) return;

    setState(() => isLoading = true);

    try {
      await simpanDataAnggota();

      if (!mounted) return;

      _showSnackBar(
        'Pendaftaran berhasil dikirim.',
        primaryGreen,
      );

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

    final nik = nikController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final telepon = teleponController.text.trim();
    final alamat = alamatController.text.trim();
    final password = passwordController.text.trim();

    if (nama.isEmpty) {
      _goToStep(0);

      _showSnackBar(
        'Nama lengkap wajib diisi.',
        dangerColor,
      );

      return false;
    }

    if (nik.length != 16) {
      _goToStep(0);

      _showSnackBar(
        'NIK harus 16 digit angka.',
        dangerColor,
      );

      return false;
    }

    if (telepon.isEmpty) {
      _goToStep(0);

      _showSnackBar(
        'Nomor telepon wajib diisi.',
        dangerColor,
      );

      return false;
    }

    if (jenisKelamin == null) {
      _goToStep(0);

      _showSnackBar(
        'Jenis kelamin wajib dipilih.',
        dangerColor,
      );

      return false;
    }

    if (alamat.isEmpty) {
      _goToStep(0);

      _showSnackBar(
        'Alamat wajib diisi.',
        dangerColor,
      );

      return false;
    }

    hitungLuasLahan();

    if (luasLahanHa <= 0) {
      _goToStep(1);

      _showSnackBar(
        'Luas lahan sawah wajib diisi.',
        dangerColor,
      );

      return false;
    }

    if (password.length < 6) {
      _goToStep(1);

      _showSnackBar(
        'Password minimal 6 karakter.',
        dangerColor,
      );

      return false;
    }

    if (fotoKtpBase64 == null) {
      _goToStep(2);

      _showSnackBar(
        'Foto KTP wajib diupload.',
        dangerColor,
      );

      return false;
    }

    return true;
  }

  bool _validasiLangkahPertama() {
    final nama = namaController.text.trim();

    final nik = nikController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final telepon = teleponController.text.trim();
    final alamat = alamatController.text.trim();

    if (nama.isEmpty) {
      _showSnackBar(
        'Nama lengkap wajib diisi.',
        dangerColor,
      );

      namaFocus.requestFocus();

      return false;
    }

    if (nik.length != 16) {
      _showSnackBar(
        'NIK harus 16 digit angka.',
        dangerColor,
      );

      nikFocus.requestFocus();

      return false;
    }

    if (telepon.isEmpty) {
      _showSnackBar(
        'Nomor telepon wajib diisi.',
        dangerColor,
      );

      teleponFocus.requestFocus();

      return false;
    }

    if (jenisKelamin == null) {
      _showSnackBar(
        'Jenis kelamin wajib dipilih.',
        dangerColor,
      );

      return false;
    }

    if (alamat.isEmpty) {
      _showSnackBar(
        'Alamat wajib diisi.',
        dangerColor,
      );

      alamatFocus.requestFocus();

      return false;
    }

    return true;
  }

  bool _validasiLangkahKedua() {
    hitungLuasLahan();

    if (luasLahanHa <= 0) {
      _showSnackBar(
        'Luas lahan sawah wajib diisi.',
        dangerColor,
      );

      return false;
    }

    if (passwordController.text.trim().length < 6) {
      _showSnackBar(
        'Password minimal 6 karakter.',
        dangerColor,
      );

      passwordFocus.requestFocus();

      return false;
    }

    return true;
  }

  void _lanjutLangkah() {
    if (currentStep == 0) {
      if (!_validasiLangkahPertama()) return;

      FocusScope.of(context).unfocus();

      _goToStep(1);
      return;
    }

    if (currentStep == 1) {
      if (!_validasiLangkahKedua()) return;

      FocusScope.of(context).unfocus();

      _goToStep(2);
      return;
    }

    kirimPendaftaran();
  }

  void _goToStep(int step) {
    final targetStep = step.clamp(0, 2);

    setState(() {
      currentStep = targetStep;
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        targetStep,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _langkahSebelumnya() {
    FocusScope.of(context).unfocus();

    if (currentStep > 0) {
      _goToStep(currentStep - 1);
    } else {
      kembali();
    }
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
      barrierColor: navyColor.withValues(alpha: 0.38),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                22,
                22,
                18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogIcon(
                    Icons.warning_amber_rounded,
                    dangerColor,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Batalkan Pendaftaran?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Data yang sudah diisi belum tersimpan. '
                    'Apakah Anda yakin ingin kembali?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12.6,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 21),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: navyColor,
                            minimumSize:
                                const Size(0, 48),
                            side: const BorderSide(
                              color: borderColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Lanjut Isi',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dangerColor,
                            foregroundColor: Colors.white,
                            minimumSize:
                                const Size(0, 48),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Batalkan',
                            style: TextStyle(
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  Future<void> _handleSystemBack() async {
    if (currentStep > 0) {
      _goToStep(currentStep - 1);
      return;
    }

    await kembali();
  }

  void _showSnackBar(
    String message,
    Color color,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                color == dangerColor
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.4,
                  height: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pilihJenisKelamin() async {
    FocusScope.of(context).unfocus();

    final hasil = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: navyColor.withValues(alpha: 0.35),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.fromLTRB(
              17,
              14,
              17,
              17,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color:
                      navyColor.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
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
                    borderRadius:
                        BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 17),
                const _SheetHeading(
                  icon: Icons.wc_rounded,
                  title: 'Pilih Jenis Kelamin',
                  subtitle:
                      'Pilih sesuai data pada identitas Anda.',
                ),
                const SizedBox(height: 17),
                _genderSheetOption(
                  label: 'Laki-laki',
                  icon: Icons.man_2_outlined,
                  selected:
                      jenisKelamin == 'Laki-laki',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'Laki-laki',
                    );
                  },
                ),
                const SizedBox(height: 10),
                _genderSheetOption(
                  label: 'Perempuan',
                  icon: Icons.woman_2_outlined,
                  selected:
                      jenisKelamin == 'Perempuan',
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'Perempuan',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (hasil != null) {
      setState(() {
        jenisKelamin = hasil;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.viewInsets.bottom;

    final keyboardOpen = bottomInset > 0;

    final isVeryCompact =
        screenHeight < 650 || screenWidth < 340;

    final isCompact =
        screenHeight < 740 || screenWidth < 380;

    final horizontalPadding =
        screenWidth < 340 ? 12.0 : 16.0;

    final topPadding =
        isVeryCompact ? 8.0 : (isCompact ? 10.0 : 14.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) async {
        if (didPop) return;

        await _handleSystemBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: pageBackground,
        body: SizedBox.expand(
          child: AppBackground(
            showPattern: false,
            child: SizedBox.expand(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _RegisterBackground(),
                  SafeArea(
                    child: AnimatedPadding(
                      duration:
                          const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.only(
                        bottom: bottomInset,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints:
                              const BoxConstraints(
                            maxWidth: 620,
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  topPadding,
                                  horizontalPadding,
                                  0,
                                ),
                                child: _header(
                                  compact:
                                      keyboardOpen ||
                                      isVeryCompact,
                                ),
                              ),
                              SizedBox(
                                height:
                                    keyboardOpen ? 5 : 9,
                              ),
                              if (!keyboardOpen) ...[
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(
                                    horizontal:
                                        horizontalPadding,
                                  ),
                                  child: _progressCard(
                                    compact:
                                        isVeryCompact,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ] else
                                const SizedBox(height: 2),
                              Expanded(
                                child: PageView(
                                  controller:
                                      _pageController,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  onPageChanged: (index) {
                                    if (currentStep !=
                                        index) {
                                      setState(() {
                                        currentStep =
                                            index;
                                      });
                                    }
                                  },
                                  children: [
                                    _personalStep(),
                                    _landStep(),
                                    _identityStep(),
                                  ],
                                ),
                              ),
                              _bottomNavigation(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header({
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 11 : 13,
        compact ? 10 : 12,
        compact ? 12 : 14,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            navyColor,
            Color(0xff24536A),
            tealColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
                navyColor.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              top: -56,
              right: -46,
              child: Container(
                height: 145,
                width: 145,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 32,
              bottom: -68,
              child: Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: const Color(
                    0xffFFD582,
                  ).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    _backButton(),
                    SizedBox(
                      width: compact ? 7 : 10,
                    ),
                    Container(
                      height: compact ? 38 : 42,
                      width: compact ? 38 : 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.13,
                        ),
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              Colors.white.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons
                            .person_add_alt_1_rounded,
                        color: Colors.white,
                        size: compact ? 20 : 22,
                      ),
                    ),
                    SizedBox(
                      width: compact ? 8 : 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pendaftaran Anggota TaniGo',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  compact ? 16.2 : 17.8,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Daftar online dalam 3 langkah',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(
                                0xffDCE9EC,
                              ),
                              fontSize:
                                  compact ? 9.5 : 10.5,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 9,
                        vertical: compact ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xffFFD582,
                        ).withValues(alpha: 0.16),
                        borderRadius:
                            BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(
                            0xffFFD582,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${currentStep + 1}/3',
                        style: TextStyle(
                          color: const Color(
                            0xffFFE3A8,
                          ),
                          fontSize:
                              compact ? 8.7 : 9.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 11),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            Colors.white.withValues(
                          alpha: 0.11,
                        ),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xffFFD582),
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Siapkan KTP, nomor WhatsApp, '
                            'data lahan, dan password akun.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.2,
                              height: 1.35,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard({
    required bool compact,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        11,
        compact ? 8 : 10,
        11,
        compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                navyColor.withValues(alpha: 0.05),
            blurRadius: 13,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _progressItem(
                index: 0,
                icon: Icons.person_outline_rounded,
                label: 'Data Diri',
                color: blueColor,
                compact: compact,
              ),
              _progressLine(0),
              _progressItem(
                index: 1,
                icon: Icons.agriculture_outlined,
                label: 'Lahan & Akun',
                color: amberColor,
                compact: compact,
              ),
              _progressLine(1),
              _progressItem(
                index: 2,
                icon: Icons.badge_outlined,
                label: 'KTP & Kirim',
                color: purpleColor,
                compact: compact,
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFB),
                borderRadius:
                    BorderRadius.circular(13),
                border: Border.all(
                  color: borderColor.withValues(
                    alpha: 0.85,
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: primaryGreen,
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Setelah dikirim: admin memeriksa → '
                      'cek status → login setelah akun aktif.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 9.7,
                        height: 1.3,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressItem({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
    required bool compact,
  }) {
    final active = currentStep == index;
    final completed = currentStep > index;
    final enabled = active || completed;

    return Expanded(
      child: InkWell(
        onTap: () {
          if (index < currentStep) {
            FocusScope.of(context).unfocus();
            _goToStep(index);
          }
        },
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 2,
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 180),
                height: compact ? 28 : 32,
                width: compact ? 28 : 32,
                decoration: BoxDecoration(
                  color: enabled
                      ? color.withValues(alpha: 0.12)
                      : const Color(0xffF0F3F5),
                  borderRadius:
                      BorderRadius.circular(11),
                  border: Border.all(
                    color: enabled
                        ? color.withValues(
                            alpha: 0.18,
                          )
                        : borderColor,
                  ),
                ),
                child: Icon(
                  completed
                      ? Icons.check_rounded
                      : icon,
                  color: enabled
                      ? color
                      : textSoft,
                  size: compact ? 15 : 17,
                ),
              ),
              SizedBox(
                height: compact ? 3 : 4,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      active ? color : textGrey,
                  fontSize:
                      compact ? 8.4 : 9.3,
                  fontWeight: active
                      ? FontWeight.w900
                      : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressLine(int index) {
    final completed = currentStep > index;

    return Container(
      width: 18,
      height: 2,
      margin: const EdgeInsets.only(
        bottom: 19,
      ),
      decoration: BoxDecoration(
        color: completed
            ? primaryGreen.withValues(alpha: 0.55)
            : borderColor,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _personalStep() {
    return ListView(
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.manual,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        18,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(
            radius: 23,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                icon: Icons.contact_page_outlined,
                title: 'Data Pribadi',
                subtitle:
                    'Isi sesuai data yang tercantum pada KTP',
                number: '01',
                color: blueColor,
                backgroundColor: softBlue,
              ),
              const SizedBox(height: 13),
              _stepInformation(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Langkah pertama',
                text:
                    'Masukkan identitas calon anggota. '
                    'Pastikan NIK berjumlah 16 digit dan nomor '
                    'WhatsApp masih dapat dihubungi.',
                color: blueColor,
                backgroundColor: softBlue,
              ),
              const SizedBox(height: 15),
              _inputField(
                label: 'Nama Lengkap',
                hint: 'Contoh: Ahmad Fauzi',
                icon: Icons.person_outline_rounded,
                controller: namaController,
                focusNode: namaFocus,
                textInputAction:
                    TextInputAction.next,
                textCapitalization:
                    TextCapitalization.words,
                onSubmitted: (_) {
                  nikFocus.requestFocus();
                },
              ),
              const SizedBox(height: 12),
              _inputField(
                label: 'NIK',
                hint: 'Masukkan 16 digit NIK',
                icon:
                    Icons.assignment_ind_outlined,
                controller: nikController,
                focusNode: nikFocus,
                keyboardType:
                    TextInputType.number,
                maxLength: 16,
                inputFormatters: [
                  FilteringTextInputFormatter
                      .digitsOnly,
                  LengthLimitingTextInputFormatter(
                    16,
                  ),
                ],
                textInputAction:
                    TextInputAction.next,
                onSubmitted: (_) {
                  teleponFocus.requestFocus();
                },
              ),
              const SizedBox(height: 12),
              _inputField(
                label:
                    'Nomor Telepon / WhatsApp',
                hint: 'Contoh: 081234567890',
                icon:
                    Icons.phone_in_talk_outlined,
                controller: teleponController,
                focusNode: teleponFocus,
                keyboardType:
                    TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9+]'),
                  ),
                ],
                textInputAction:
                    TextInputAction.next,
                onSubmitted: (_) {
                  alamatFocus.requestFocus();
                },
              ),
              const SizedBox(height: 12),
              _genderSelector(),
              const SizedBox(height: 12),
              _inputField(
                label: 'Alamat Lengkap',
                hint:
                    'Dusun, RT/RW, desa, dan kecamatan',
                icon: Icons.home_work_outlined,
                controller: alamatController,
                focusNode: alamatFocus,
                maxLines: 2,
                textInputAction:
                    TextInputAction.done,
                textCapitalization:
                    TextCapitalization.sentences,
              ),
              const SizedBox(height: 9),
              const _KeyboardHint(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _landStep() {
    return ListView(
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.manual,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        18,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(
            radius: 23,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                icon: Icons.agriculture_outlined,
                title: 'Data Lahan & Akun',
                subtitle:
                    'Isi luas lahan dan buat password login',
                number: '02',
                color: amberColor,
                backgroundColor: softAmber,
              ),
              const SizedBox(height: 13),
              _stepInformation(
                icon: Icons.straighten_rounded,
                title: 'Langkah kedua',
                text:
                    'Pilih cara pengisian luas lahan yang paling '
                    'mudah, lalu buat password minimal 6 karakter.',
                color: amberColor,
                backgroundColor: softAmber,
              ),
              const SizedBox(height: 15),
              _luasLahanInput(),
              const SizedBox(height: 14),
              Divider(
                color: borderColor.withValues(
                  alpha: 0.80,
                ),
                height: 1,
              ),
              const SizedBox(height: 14),
              _passwordField(),
              const SizedBox(height: 12),
              _miniInfo(
                icon: Icons.shield_outlined,
                text:
                    'Simpan password dengan aman. Password ini '
                    'digunakan untuk masuk setelah akun disetujui.',
              ),
              const SizedBox(height: 9),
              const _KeyboardHint(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _identityStep() {
    return ListView(
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.manual,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        18,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(
            radius: 23,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                icon: Icons.badge_outlined,
                title: 'Bukti Identitas',
                subtitle:
                    'Unggah foto KTP lalu kirim pendaftaran',
                number: '03',
                color: purpleColor,
                backgroundColor: softPurple,
              ),
              const SizedBox(height: 13),
              _stepInformation(
                icon: Icons.photo_camera_back_outlined,
                title: 'Langkah terakhir',
                text:
                    'Unggah foto KTP yang terang, jelas, '
                    'tidak buram, dan seluruh bagian KTP terlihat.',
                color: purpleColor,
                backgroundColor: softPurple,
              ),
              const SizedBox(height: 15),
              if (fotoKtp != null)
                _ktpPreview()
              else
                _ktpEmpty(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: OutlinedButton.icon(
                  onPressed: isLoading
                      ? null
                      : pilihFotoKtp,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purpleColor,
                    backgroundColor:
                        softPurple.withValues(
                      alpha: 0.55,
                    ),
                    side: BorderSide(
                      color: purpleColor.withValues(
                        alpha: 0.23,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  icon: Icon(
                    fotoKtp == null
                        ? Icons
                            .add_photo_alternate_outlined
                        : Icons
                            .change_circle_outlined,
                    size: 20,
                  ),
                  label: Text(
                    fotoKtp == null
                        ? 'Pilih Foto KTP'
                        : 'Ganti Foto KTP',
                    style: const TextStyle(
                      fontSize: 12.8,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _confirmationCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepInformation({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(
          alpha: 0.68,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.11),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 35,
            width: 35,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.88,
              ),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.1,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmationCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: blueColor.withValues(alpha: 0.12),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: blueColor,
                size: 21,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Periksa sebelum mengirim',
                      style: TextStyle(
                        color: blueColor,
                        fontSize: 11.8,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pastikan nama, NIK, nomor telepon, alamat, '
                      'luas lahan, password, dan foto KTP '
                      'sudah benar.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.7,
                        height: 1.4,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(
            height: 1,
            color: borderColor,
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.route_outlined,
                color: primaryGreen,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Setelah dikirim, status pendaftaran menjadi '
                  'menunggu. Admin akan memeriksa data. '
                  'Pilih Cek Status pada halaman login, lalu '
                  'masuk setelah akun dinyatakan aktif.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 10.7,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomNavigation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        9,
        16,
        11,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withValues(alpha: 0.97),
        border: const Border(
          top: BorderSide(
            color: borderColor,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                navyColor.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow =
              constraints.maxWidth < 330;

          return Row(
            children: [
              SizedBox(
                height: 51,
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : _langkahSebelumnya,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: navyColor,
                    side: const BorderSide(
                      color: borderColor,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: narrow ? 13 : 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        currentStep == 0
                            ? Icons.close_rounded
                            : Icons.arrow_back_rounded,
                        size: 19,
                      ),
                      if (!narrow) ...[
                        const SizedBox(width: 7),
                        Text(
                          currentStep == 0
                              ? 'Batal'
                              : 'Kembali',
                          style: const TextStyle(
                            fontSize: 12.3,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  button: true,
                  label: currentStep == 2
                      ? 'Kirim pendaftaran'
                      : 'Lanjut ke langkah berikutnya',
                  child: AnimatedOpacity(
                    opacity:
                        isLoading ? 0.62 : 1,
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(16),
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : _lanjutLangkah,
                        borderRadius:
                            BorderRadius.circular(16),
                        child: Ink(
                          height: 51,
                          decoration: BoxDecoration(
                            gradient:
                                const LinearGradient(
                              colors: [
                                navyColor,
                                Color(0xff296B67),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: navyColor
                                    .withValues(
                                  alpha: 0.17,
                                ),
                                blurRadius: 14,
                                offset:
                                    const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isLoading
                                ? const Row(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2.3,
                                          color:
                                              Colors
                                                  .white,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 9,
                                      ),
                                      Text(
                                        'Mengirim...',
                                        style:
                                            TextStyle(
                                          color:
                                              Colors
                                                  .white,
                                          fontSize:
                                              13,
                                          fontWeight:
                                              FontWeight
                                                  .w900,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: [
                                      Icon(
                                        currentStep == 2
                                            ? Icons
                                                .send_rounded
                                            : Icons
                                                .arrow_forward_rounded,
                                        color:
                                            Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Flexible(
                                        child: Text(
                                          currentStep ==
                                                  2
                                              ? 'Kirim Pendaftaran'
                                              : 'Lanjutkan',
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                          style:
                                              const TextStyle(
                                            color:
                                                Colors
                                                    .white,
                                            fontSize:
                                                13.4,
                                            fontWeight:
                                                FontWeight
                                                    .w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _luasLahanInput() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const _FieldHeading(
          label: 'Cara Mengisi Luas Lahan',
          requiredField: true,
        ),
        const SizedBox(height: 5),
        const Text(
          'Pilih salah satu cara yang paling mudah.',
          style: TextStyle(
            color: textGrey,
            fontSize: 10.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            _modeLahanChip(
              'petak',
              'Petak',
              Icons.grid_view_rounded,
            ),
            const SizedBox(width: 7),
            _modeLahanChip(
              'meter',
              'Meter²',
              Icons.square_foot_rounded,
            ),
            const SizedBox(width: 7),
            _modeLahanChip(
              'ha',
              'Hektare',
              Icons.landscape_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration:
              const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(modeLahan),
            child: Column(
              children: [
                if (modeLahan == 'petak') ...[
                  _inputField(
                    label: 'Jumlah Petak',
                    hint: 'Contoh: 2',
                    icon: Icons
                        .dashboard_customize_outlined,
                    controller:
                        jumlahPetakController,
                    focusNode: jumlahPetakFocus,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .allow(
                        RegExp(r'[0-9.,]'),
                      ),
                    ],
                    textInputAction:
                        TextInputAction.next,
                    onChanged: (_) {
                      hitungLuasLahan();
                    },
                    onSubmitted: (_) {
                      luasPerPetakFocus
                          .requestFocus();
                    },
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    label: 'Luas 1 Petak (m²)',
                    hint: 'Contoh: 250',
                    icon: Icons.straighten_rounded,
                    controller:
                        luasPerPetakController,
                    focusNode:
                        luasPerPetakFocus,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .allow(
                        RegExp(r'[0-9.,]'),
                      ),
                    ],
                    textInputAction:
                        TextInputAction.next,
                    onChanged: (_) {
                      hitungLuasLahan();
                    },
                    onSubmitted: (_) {
                      passwordFocus.requestFocus();
                    },
                  ),
                ] else if (modeLahan ==
                    'meter') ...[
                  _inputField(
                    label:
                        'Total Luas Lahan (m²)',
                    hint: 'Contoh: 500',
                    icon:
                        Icons.square_foot_rounded,
                    controller: meterController,
                    focusNode: meterFocus,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .allow(
                        RegExp(r'[0-9.,]'),
                      ),
                    ],
                    textInputAction:
                        TextInputAction.next,
                    onChanged: (_) {
                      hitungLuasLahan();
                    },
                    onSubmitted: (_) {
                      passwordFocus.requestFocus();
                    },
                  ),
                ] else ...[
                  _inputField(
                    label:
                        'Total Luas Lahan (ha)',
                    hint: 'Contoh: 0.05',
                    icon:
                        Icons.landscape_outlined,
                    controller:
                        hektareController,
                    focusNode: hektareFocus,
                    keyboardType:
                        const TextInputType
                            .numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter
                          .allow(
                        RegExp(r'[0-9.,]'),
                      ),
                    ],
                    textInputAction:
                        TextInputAction.next,
                    onChanged: (_) {
                      hitungLuasLahan();
                    },
                    onSubmitted: (_) {
                      passwordFocus.requestFocus();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 11),
        AnimatedContainer(
          duration:
              const Duration(milliseconds: 220),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: luasLahanHa > 0
                ? softTeal
                : softAmber,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: (luasLahanHa > 0
                      ? tealColor
                      : amberColor)
                  .withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                luasLahanHa > 0
                    ? Icons.calculate_outlined
                    : Icons
                        .lightbulb_outline_rounded,
                color: luasLahanHa > 0
                    ? tealColor
                    : amberColor,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  luasLahanHa > 0
                      ? '${luasLahanHa.toStringAsFixed(3)} hektare\n'
                          '$keteranganLuasLahan'
                      : '10.000 m² sama dengan 1 hektare.',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.9,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modeLahanChip(
    String value,
    String label,
    IconData icon,
  ) {
    final selected = modeLahan == value;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: isLoading
              ? null
              : () {
                  setState(() {
                    modeLahan = value;
                    luasLahanHa = 0;
                    keteranganLuasLahan = '';
                  });

                  hitungLuasLahan();
                },
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 180),
            height: 52,
            decoration: BoxDecoration(
              color: selected
                  ? navyColor
                  : const Color(0xffFAFBFC),
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: selected
                    ? navyColor
                    : borderColor,
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: selected
                      ? Colors.white
                      : navyColor,
                  size: 17,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : navyColor,
                    fontSize: 10.2,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderSelector() {
    final selected = jenisKelamin != null;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const _FieldHeading(
          label: 'Jenis Kelamin',
          requiredField: true,
        ),
        const SizedBox(height: 7),
        Material(
          color: Colors.transparent,
          borderRadius:
              BorderRadius.circular(16),
          child: InkWell(
            onTap: isLoading
                ? null
                : _pilihJenisKelamin,
            borderRadius:
                BorderRadius.circular(16),
            child: Container(
              height: 53,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 13,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffFAFBFC),
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? blueColor
                      : borderColor,
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wc_rounded,
                    color: selected
                        ? blueColor
                        : textGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      jenisKelamin ??
                          'Ketuk untuk memilih',
                      style: TextStyle(
                        color: selected
                            ? textDark
                            : textSoft,
                        fontSize: 13.2,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                    color: selected
                        ? blueColor
                        : textGrey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderSheetOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? softBlue
          : const Color(0xffFAFBFC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? blueColor
                  : borderColor,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              _iconBox(
                icon,
                blueColor,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? blueColor
                        : textDark,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons
                        .chevron_right_rounded,
                color: selected
                    ? blueColor
                    : textSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const _FieldHeading(
          label: 'Buat Password',
          requiredField: true,
        ),
        const SizedBox(height: 4),
        const Text(
          'Password digunakan setelah akun disetujui.',
          style: TextStyle(
            color: textGrey,
            fontSize: 10.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: passwordController,
          focusNode: passwordFocus,
          obscureText: hidePassword,
          textInputAction:
              TextInputAction.done,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [
            AutofillHints.newPassword,
          ],
          onTapOutside: (_) {},
          scrollPadding:
              const EdgeInsets.only(
            bottom: 150,
          ),
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          decoration: _inputDecoration(
            hint: 'Minimal 6 karakter',
            icon: Icons.password_rounded,
            accentColor: amberColor,
          ).copyWith(
            suffixIcon: IconButton(
              tooltip: hidePassword
                  ? 'Tampilkan password'
                  : 'Sembunyikan password',
              onPressed: () {
                setState(() {
                  hidePassword =
                      !hidePassword;
                });
              },
              icon: Icon(
                hidePassword
                    ? Icons
                        .visibility_off_outlined
                    : Icons
                        .visibility_outlined,
                color: amberColor,
                size: 21,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _ktpPreview() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 175,
          decoration: BoxDecoration(
            color: softPurple,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: purpleColor.withValues(
                alpha: 0.14,
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(17),
            child: Image.file(
              fotoKtp!,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: purpleColor,
                    size: 42,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: navyColor.withValues(
                alpha: 0.88,
              ),
              borderRadius:
                  BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                SizedBox(width: 5),
                Text(
                  'Foto siap digunakan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ktpEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        19,
      ),
      decoration: BoxDecoration(
        color:
            softPurple.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: purpleColor.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons
                  .add_photo_alternate_outlined,
              color: purpleColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum ada foto KTP',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
              fontSize: 13.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pastikan foto terang, jelas, '
            'dan seluruh bagian KTP terlihat.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 10.6,
              height: 1.4,
              fontWeight: FontWeight.w600,
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
    TextInputType keyboardType =
        TextInputType.text,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _FieldHeading(
          label: label,
          requiredField: true,
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization:
              textCapitalization,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,

          // Area kosong tidak menutup keyboard.
          onTapOutside: (_) {},

          inputFormatters: inputFormatters,
          scrollPadding:
              const EdgeInsets.only(
            bottom: 150,
          ),
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          decoration: _inputDecoration(
            hint: hint,
            icon: icon,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Color accentColor = blueColor,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: accentColor,
        size: 20,
      ),
      filled: true,
      fillColor: const Color(0xffFAFBFC),
      counterText: '',
      hintStyle: const TextStyle(
        color: textSoft,
        fontSize: 12.2,
        fontWeight: FontWeight.w600,
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: BorderSide(
          color: accentColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    required String number,
    required Color color,
    required Color backgroundColor,
  }) {
    return Row(
      children: [
        _AccentIcon(
          icon: icon,
          color: color,
          backgroundColor: backgroundColor,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 15.5,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10.8,
                  height: 1.3,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(999),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniInfo({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: softAmber,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              amberColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: amberColor,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10.8,
                height: 1.35,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _langkahSebelumnya,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.13,
            ),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 15,
          ),
        ),
      ),
    );
  }

  Widget _dialogIcon(
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 68,
      width: 68,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 34,
      ),
    );
  }

  Widget _iconBox(
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 41,
      width: 41,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: color,
        size: 21,
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 20,
  }) {
    return BoxDecoration(
      color:
          Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color:
              navyColor.withValues(alpha: 0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _FieldHeading extends StatelessWidget {
  final String label;
  final bool requiredField;

  const _FieldHeading({
    required this.label,
    required this.requiredField,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: _RegisterPageState.textDark,
              fontSize: 12.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (requiredField) ...[
          const SizedBox(width: 5),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: _RegisterPageState
                  .dangerColor
                  .withValues(alpha: 0.08),
              borderRadius:
                  BorderRadius.circular(999),
            ),
            child: const Text(
              'WAJIB',
              style: TextStyle(
                color: _RegisterPageState
                    .dangerColor,
                fontSize: 7.4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccentIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _AccentIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.08),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 21,
      ),
    );
  }
}

class _SheetHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SheetHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _AccentIcon(
          icon: icon,
          color: _RegisterPageState.blueColor,
          backgroundColor:
              _RegisterPageState.softBlue,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color:
                      _RegisterPageState.textDark,
                  fontSize: 16.5,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color:
                      _RegisterPageState.textGrey,
                  fontSize: 11.3,
                  height: 1.4,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyboardHint extends StatelessWidget {
  const _KeyboardHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.keyboard_alt_outlined,
          color: _RegisterPageState.textSoft,
          size: 14,
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            'Keyboard boleh tetap terbuka. '
            'Geser formulir dan tekan tombol Lanjutkan '
            'di bagian bawah.',
            style: TextStyle(
              color: _RegisterPageState.textGrey,
              fontSize: 9.7,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RegisterBackground extends StatelessWidget {
  const _RegisterBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth =
                constraints.maxWidth;

            final screenHeight =
                constraints.maxHeight;

            final baseSize =
                screenWidth < screenHeight
                    ? screenWidth
                    : screenHeight;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(280.0, 450.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.72)
                    .clamp(210.0, 340.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.43)
                    .clamp(125.0, 210.0)
                    .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end:
                            Alignment.bottomRight,
                        colors: [
                          Color(0xffEAF3F9),
                          Color(0xffF2F8F3),
                          Color(0xffFFF5E4),
                        ],
                        stops: [
                          0,
                          0.53,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -largeCircle * 0.43,
                    right:
                        -largeCircle * 0.28,
                    child:
                        _RegisterBackgroundCircle(
                      size: largeCircle,
                      color: _RegisterPageState
                          .softBlue,
                      borderColor:
                          _RegisterPageState
                              .blueColor,
                      alpha: 0.98,
                    ),
                  ),
                  Positioned(
                    top:
                        -smallCircle * 0.18,
                    right:
                        -smallCircle * 0.05,
                    child:
                        _RegisterBackgroundRing(
                      size: smallCircle,
                      color: _RegisterPageState
                          .blueColor,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.30,
                    left:
                        -mediumCircle * 0.58,
                    child:
                        _RegisterBackgroundCircle(
                      size: mediumCircle,
                      color: _RegisterPageState
                          .softGreen,
                      borderColor:
                          _RegisterPageState
                              .primaryGreen,
                      alpha: 0.95,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.50,
                    right:
                        -smallCircle * 0.56,
                    child:
                        _RegisterBackgroundCircle(
                      size:
                          smallCircle * 1.16,
                      color: _RegisterPageState
                          .softPurple,
                      borderColor:
                          _RegisterPageState
                              .purpleColor,
                      alpha: 0.88,
                    ),
                  ),
                  Positioned(
                    bottom:
                        -largeCircle * 0.51,
                    right:
                        -largeCircle * 0.31,
                    child:
                        _RegisterBackgroundCircle(
                      size:
                          largeCircle * 1.04,
                      color: _RegisterPageState
                          .softAmber,
                      borderColor:
                          _RegisterPageState
                              .amberColor,
                      alpha: 0.96,
                    ),
                  ),
                  Positioned(
                    bottom:
                        -mediumCircle * 0.18,
                    left:
                        -mediumCircle * 0.52,
                    child:
                        _RegisterBackgroundCircle(
                      size: mediumCircle,
                      color: _RegisterPageState
                          .softTeal,
                      borderColor:
                          _RegisterPageState
                              .tealColor,
                      alpha: 0.90,
                    ),
                  ),
                  Positioned(
                    bottom:
                        smallCircle * 0.08,
                    right:
                        -smallCircle * 0.10,
                    child:
                        _RegisterBackgroundRing(
                      size: smallCircle,
                      color: _RegisterPageState
                          .amberColor,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.40,
                    left: 14,
                    child: Transform.rotate(
                      angle: -0.42,
                      child: Container(
                        height: 43,
                        width: 110,
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(
                            alpha: 0.36,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            999,
                          ),
                          border: Border.all(
                            color:
                                _RegisterPageState
                                    .primaryGreen
                                    .withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom:
                        screenHeight * 0.13,
                    left: 20,
                    child: Transform.rotate(
                      angle: 0.42,
                      child: Container(
                        height: 39,
                        width: 104,
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(
                            alpha: 0.36,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            999,
                          ),
                          border: Border.all(
                            color:
                                _RegisterPageState
                                    .tealColor
                                    .withValues(
                              alpha: 0.09,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 108,
                    left: 28,
                    child:
                        _RegisterBackgroundDot(
                      size: 9,
                      color:
                          _RegisterPageState
                              .blueColor,
                    ),
                  ),
                  const Positioned(
                    top: 164,
                    left: 62,
                    child:
                        _RegisterBackgroundDot(
                      size: 6,
                      color:
                          _RegisterPageState
                              .primaryGreen,
                    ),
                  ),
                  const Positioned(
                    bottom: 122,
                    right: 48,
                    child:
                        _RegisterBackgroundDot(
                      size: 9,
                      color:
                          _RegisterPageState
                              .amberColor,
                    ),
                  ),
                  const Positioned(
                    bottom: 72,
                    right: 98,
                    child:
                        _RegisterBackgroundDot(
                      size: 6,
                      color:
                          _RegisterPageState
                              .purpleColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RegisterBackgroundCircle
    extends StatelessWidget {
  final double size;
  final Color color;
  final Color borderColor;
  final double alpha;

  const _RegisterBackgroundCircle({
    required this.size,
    required this.color,
    required this.borderColor,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: alpha,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor.withValues(
            alpha: 0.07,
          ),
          width: 2,
        ),
      ),
    );
  }
}

class _RegisterBackgroundRing
    extends StatelessWidget {
  final double size;
  final Color color;

  const _RegisterBackgroundRing({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(
            alpha: 0.12,
          ),
          width: 2,
        ),
      ),
    );
  }
}

class _RegisterBackgroundDot
    extends StatelessWidget {
  final double size;
  final Color color;

  const _RegisterBackgroundDot({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.20,
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}