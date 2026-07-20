import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_background.dart';

class StatusKeanggotaanPage extends StatefulWidget {
  const StatusKeanggotaanPage({super.key});

  @override
  State<StatusKeanggotaanPage> createState() =>
      _StatusKeanggotaanPageState();
}

class _StatusKeanggotaanPageState
    extends State<StatusKeanggotaanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color navyColor = Color(0xff17324D);
  static const Color blueColor = Color(0xff2F6B9A);
  static const Color tealColor = Color(0xff28766F);
  static const Color amberColor = Color(0xffD97706);
  static const Color purpleColor = Color(0xff6D5BAE);

  static const Color softGreen = Color(0xffE4F3E8);
  static const Color softBlue = Color(0xffE4F0F8);
  static const Color softTeal = Color(0xffDCEFED);
  static const Color softAmber = Color(0xffFFF0D2);
  static const Color softPurple = Color(0xffF1ECFA);

  static const Color pageBackground = Color(0xffF5F7F9);
  static const Color cardColor = Color(0xffFFFFFF);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);
  static const Color borderColor = Color(0xffE2E7EC);
  static const Color dangerColor = Color(0xffC83B3B);

  final TextEditingController nikController =
      TextEditingController();

  final FocusNode nikFocus = FocusNode();

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  bool isLoading = false;
  bool hasSearched = false;
  bool dataNotFound = false;

  Map<String, dynamic>? dataAnggota;

  @override
  void dispose() {
    nikController.dispose();
    nikFocus.dispose();
    super.dispose();
  }

  Future<void> cekStatus() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final nikInput = nikController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (nikInput.isEmpty) {
      _showSnackBar(
        'NIK wajib diisi.',
        dangerColor,
      );
      return;
    }

    if (nikInput.length != 16) {
      _showSnackBar(
        'NIK harus terdiri dari 16 digit.',
        dangerColor,
      );
      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = false;
      dataNotFound = false;
      dataAnggota = null;
    });

    try {
      Map<String, dynamic>? hasil;

      final calonSnapshot = await db
          .ref('calon_anggota')
          .get()
          .timeout(const Duration(seconds: 10));

      if (calonSnapshot.exists &&
          calonSnapshot.value != null) {
        hasil = cariDataByNik(
          calonSnapshot.value,
          nikInput,
        );
      }

      if (hasil == null) {
        final anggotaSnapshot = await db
            .ref('anggota')
            .get()
            .timeout(const Duration(seconds: 10));

        if (anggotaSnapshot.exists &&
            anggotaSnapshot.value != null) {
          hasil = cariDataByNik(
            anggotaSnapshot.value,
            nikInput,
          );
        }
      }

      if (!mounted) return;

      if (hasil != null) {
        setState(() {
          dataAnggota = hasil;
          hasSearched = true;
          dataNotFound = false;
        });
      } else {
        setState(() {
          dataAnggota = null;
          hasSearched = true;
          dataNotFound = true;
        });

        _showSnackBar(
          'Data pendaftaran tidak ditemukan.',
          dangerColor,
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        dataAnggota = null;
        hasSearched = false;
        dataNotFound = false;
      });

      _showSnackBar(
        'Gagal mengecek status. Periksa koneksi internet.',
        dangerColor,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Map<String, dynamic>? cariDataByNik(
    dynamic value,
    String nikInput,
  ) {
    if (value == null || value is! Map) {
      return null;
    }

    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final anggota = Map<String, dynamic>.from(item);

        final nikData = (anggota['nik'] ?? '')
            .toString()
            .replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

        if (nikData == nikInput) {
          return anggota;
        }
      }
    }

    return null;
  }

  void _showSnackBar(
    String pesan,
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
                pesan,
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

  bool statusDisetujui(String status) {
    return status == 'aktif' ||
        status == 'disetujui';
  }

  bool statusDitolak(String status) {
    return status == 'ditolak';
  }

  Color warnaStatus(String status) {
    if (statusDisetujui(status)) {
      return primaryGreen;
    }

    if (statusDitolak(status)) {
      return dangerColor;
    }

    return amberColor;
  }

  Color backgroundStatus(String status) {
    if (statusDisetujui(status)) {
      return softGreen;
    }

    if (statusDitolak(status)) {
      return dangerColor.withValues(alpha: 0.08);
    }

    return softAmber;
  }

  IconData iconStatus(String status) {
    if (statusDisetujui(status)) {
      return Icons.verified_rounded;
    }

    if (statusDitolak(status)) {
      return Icons.cancel_rounded;
    }

    return Icons.hourglass_top_rounded;
  }

  String teksStatus(String status) {
    if (status == 'aktif') {
      return 'Akun Sudah Aktif';
    }

    if (status == 'disetujui') {
      return 'Pendaftaran Disetujui';
    }

    if (status == 'ditolak') {
      return 'Pendaftaran Belum Disetujui';
    }

    return 'Sedang Diverifikasi';
  }

  String badgeStatus(String status) {
    if (status == 'aktif') {
      return 'AKTIF';
    }

    if (status == 'disetujui') {
      return 'DISETUJUI';
    }

    if (status == 'ditolak') {
      return 'DITOLAK';
    }

    return 'MENUNGGU';
  }

  String pesanStatus(String status) {
    if (statusDisetujui(status)) {
      return 'Pendaftaran Anda sudah disetujui. '
          'Silakan kembali ke halaman login dan masuk menggunakan '
          'NIK serta password yang telah didaftarkan.';
    }

    if (statusDitolak(status)) {
      return 'Pendaftaran belum dapat disetujui. '
          'Silakan hubungi administrator kelompok tani untuk '
          'mengetahui data yang perlu diperbaiki.';
    }

    return 'Pendaftaran Anda sudah diterima dan sedang diperiksa '
        'oleh administrator kelompok tani.';
  }

  String judulTindakan(String status) {
    if (statusDisetujui(status)) {
      return 'Langkah berikutnya';
    }

    if (statusDitolak(status)) {
      return 'Yang perlu dilakukan';
    }

    return 'Mohon menunggu';
  }

  String pesanTindakan(String status) {
    if (statusDisetujui(status)) {
      return 'Kembali ke halaman login, kemudian masukkan NIK dan '
          'password yang dibuat saat pendaftaran.';
    }

    if (statusDitolak(status)) {
      return 'Periksa kembali data identitas, data lahan, dan foto '
          'KTP. Hubungi administrator untuk informasi selanjutnya.';
    }

    return 'Administrator sedang memeriksa identitas, data lahan, '
        'dan foto KTP Anda. Status dapat diperiksa kembali nanti.';
  }

  String ambilLuasSawah() {
    if (dataAnggota == null) return '-';

    final value =
        dataAnggota!['luas_lahan'] ??
        dataAnggota!['luas_sawah'] ??
        dataAnggota!['jumlah_petak_sawah'];

    if (value == null) return '-';

    final text = value.toString().trim();

    if (text.isEmpty || text == '-') {
      return '-';
    }

    final angka = double.tryParse(
      text.replaceAll(',', '.'),
    );

    final satuan =
        (dataAnggota!['satuan_lahan'] ?? 'ha')
            .toString()
            .trim();

    if (angka != null) {
      String angkaFormatted;

      if (angka == angka.roundToDouble()) {
        angkaFormatted = angka.toStringAsFixed(0);
      } else {
        angkaFormatted = angka.toStringAsFixed(3);

        angkaFormatted = angkaFormatted.replaceFirst(
          RegExp(r'0+$'),
          '',
        );

        angkaFormatted = angkaFormatted.replaceFirst(
          RegExp(r'\.$'),
          '',
        );
      }

      return '$angkaFormatted ${satuan.isEmpty ? 'ha' : satuan}';
    }

    final lowerText = text.toLowerCase();

    if (lowerText.contains('ha') ||
        lowerText.contains('hektare') ||
        lowerText.contains('m²') ||
        lowerText.contains('meter')) {
      return text;
    }

    return '$text ${satuan.isEmpty ? 'ha' : satuan}';
  }

  String formatTanggal(dynamic value) {
    final text = value?.toString() ?? '';

    if (text.isEmpty) return '-';

    try {
      final date = DateTime.parse(text).toLocal();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day-$month-$year';
    } catch (_) {
      return text;
    }
  }

  void _resetPencarian() {
    FocusScope.of(context).unfocus();

    setState(() {
      nikController.clear();
      dataAnggota = null;
      hasSearched = false;
      dataNotFound = false;
    });

    Future<void>.delayed(
      const Duration(milliseconds: 180),
      () {
        if (mounted) {
          nikFocus.requestFocus();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final bottomInset = mediaQuery.viewInsets.bottom;

    final isVeryCompact =
        screenHeight < 650 || screenWidth < 340;

    final isCompact =
        screenHeight < 740 || screenWidth < 380;

    final horizontalPadding =
        screenWidth < 340 ? 13.0 : 18.0;

    final topPadding =
        isVeryCompact ? 8.0 : (isCompact ? 11.0 : 16.0);

    final bottomPadding =
        isVeryCompact ? 14.0 : (isCompact ? 18.0 : 24.0);

    final status =
        (dataAnggota?['status'] ?? 'menunggu')
            .toString()
            .trim()
            .toLowerCase();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _StatusBackground(),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final minimumHeight =
                          constraints.maxHeight -
                          topPadding -
                          bottomPadding;

                      return SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior
                                .manual,
                        physics:
                            const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topPadding,
                          horizontalPadding,
                          bottomInset + bottomPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: minimumHeight > 0
                                ? minimumHeight
                                : 0,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(
                                maxWidth: 620,
                              ),
                              child: AutofillGroup(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    _header(
                                      isCompact,
                                      isVeryCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isVeryCompact ? 8 : 11,
                                    ),
                                    _inputCard(
                                      isCompact,
                                      isVeryCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isVeryCompact ? 8 : 11,
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 240,
                                      ),
                                      switchInCurve:
                                          Curves.easeOut,
                                      switchOutCurve:
                                          Curves.easeIn,
                                      child:
                                          _buildResultContent(
                                        status,
                                        isVeryCompact,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultContent(
    String status,
    bool isVeryCompact,
  ) {
    if (isLoading) {
      return const _CheckingCard(
        key: ValueKey('checking'),
      );
    }

    if (dataAnggota != null) {
      return KeyedSubtree(
        key: ValueKey(
          'result_${nikController.text}',
        ),
        child: _hasilCard(
          status,
          isVeryCompact,
        ),
      );
    }

    if (hasSearched && dataNotFound) {
      return _notFoundCard(
        key: const ValueKey('not_found'),
      );
    }

    return _initialInfoCard(
      key: const ValueKey('initial'),
      isVeryCompact: isVeryCompact,
    );
  }

  Widget _header(
    bool isCompact,
    bool isVeryCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isVeryCompact ? 12 : (isCompact ? 14 : 16),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              top: -54,
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
              right: 34,
              bottom: -66,
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _backButton(),
                    SizedBox(
                      width: isVeryCompact ? 7 : 9,
                    ),
                    Container(
                      height: isVeryCompact
                          ? 43
                          : (isCompact ? 46 : 49),
                      width: isVeryCompact
                          ? 43
                          : (isCompact ? 46 : 49),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.13,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.manage_search_rounded,
                        color: Colors.white,
                        size: isVeryCompact ? 21 : 23,
                      ),
                    ),
                    SizedBox(
                      width: isVeryCompact ? 8 : 10,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Keanggotaan',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVeryCompact
                                  ? 16.2
                                  : (isCompact
                                      ? 17.5
                                      : 18.5),
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Lihat perkembangan pendaftaran',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(
                                0xffDCE9EC,
                              ),
                              fontSize: isVeryCompact
                                  ? 9.5
                                  : (isCompact
                                      ? 10.2
                                      : 10.8),
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isVeryCompact) ...[
                      const SizedBox(width: 7),
                      _headerBadge(),
                    ],
                  ],
                ),
                SizedBox(
                  height: isVeryCompact ? 9 : 11,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
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
                      color: Colors.white.withValues(
                        alpha: 0.11,
                      ),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.assignment_ind_outlined,
                        color: Color(0xffFFD582),
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Masukkan NIK yang sama dengan '
                          'NIK saat melakukan pendaftaran.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.2,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _headerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xffFFD582,
        ).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(
            0xffFFD582,
          ).withValues(alpha: 0.25),
        ),
      ),
      child: const Text(
        'STATUS',
        style: TextStyle(
          color: Color(0xffFFE3A8),
          fontSize: 7.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _inputCard(
    bool isCompact,
    bool isVeryCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isVeryCompact ? 13 : (isCompact ? 15 : 17),
      ),
      decoration: _cardDecoration(radius: 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,
            children: [
              _AccentIcon(
                icon: Icons.badge_outlined,
                color: blueColor,
                backgroundColor: softBlue,
                size: 40,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cari Data Pendaftaran',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Gunakan 16 digit NIK sesuai KTP.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: isVeryCompact ? 11 : 14,
          ),
          const _FieldHeading(
            label: 'Nomor Induk Kependudukan',
            helper:
                'Masukkan NIK yang digunakan ketika mendaftar.',
          ),
          const SizedBox(height: 7),
          TextField(
            controller: nikController,
            focusNode: nikFocus,
            keyboardType: TextInputType.number,
            maxLength: 16,
            textInputAction: TextInputAction.search,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            autofillHints: const [
              AutofillHints.username,
            ],
            onTapOutside: (_) {},
            scrollPadding: const EdgeInsets.only(
              bottom: 140,
            ),
            onSubmitted: (_) {
              if (!isLoading) {
                cekStatus();
              }
            },
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14.2,
              letterSpacing: 0.3,
            ),
            decoration: _inputDecoration(
              hint: 'Masukkan 16 digit NIK',
              icon: Icons.assignment_ind_outlined,
            ),
          ),
          SizedBox(
            height: isVeryCompact ? 11 : 13,
          ),
          _searchButton(),
          const SizedBox(height: 9),
          const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: textSoft,
                size: 15,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'NIK hanya digunakan untuk mencari '
                  'data pendaftaran Anda.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 10.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchButton() {
    return Semantics(
      button: true,
      label: isLoading
          ? 'Sedang mengecek status'
          : 'Cek status keanggotaan',
      child: AnimatedOpacity(
        opacity: isLoading ? 0.62 : 1,
        duration: const Duration(
          milliseconds: 180,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isLoading ? null : cekStatus,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              height: 51,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    navyColor,
                    Color(0xff2F6B83),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: navyColor.withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Mengecek...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.3,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Cek Status Sekarang',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.7,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hasilCard(
    String status,
    bool isVeryCompact,
  ) {
    final color = warnaStatus(status);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            isVeryCompact ? 13 : 16,
          ),
          decoration: _cardDecoration(radius: 23),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _statusHero(
                status,
                isVeryCompact,
              ),
              const SizedBox(height: 11),
              _actionGuide(status),
              const SizedBox(height: 11),
              _progressCard(status),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _detailExpansionCard(),
        const SizedBox(height: 10),
        if (statusDisetujui(status))
          _approvedActionButtons()
        else
          _checkAnotherButton(color),
      ],
    );
  }

  Widget _statusHero(
    String status,
    bool isVeryCompact,
  ) {
    final color = warnaStatus(status);
    final nama =
        (dataAnggota?['nama'] ?? '-').toString();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isVeryCompact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                height: isVeryCompact ? 46 : 51,
                width: isVeryCompact ? 46 : 51,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.82,
                  ),
                  borderRadius:
                      BorderRadius.circular(17),
                  border: Border.all(
                    color: color.withValues(
                      alpha: 0.11,
                    ),
                  ),
                ),
                child: Icon(
                  iconStatus(status),
                  color: color,
                  size: isVeryCompact ? 25 : 28,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            teksStatus(status),
                            style: TextStyle(
                              color: color,
                              fontSize:
                                  isVeryCompact
                                      ? 15.2
                                      : 16.8,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Nama pendaftar',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 9.8,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nama,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 13.1,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pesanStatus(status),
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.9,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = warnaStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.82,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        badgeStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 7.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _actionGuide(String status) {
    final approved = statusDisetujui(status);
    final rejected = statusDitolak(status);

    final color = approved
        ? primaryGreen
        : rejected
            ? dangerColor
            : amberColor;

    final backgroundColor = approved
        ? softGreen
        : rejected
            ? dangerColor.withValues(alpha: 0.07)
            : softAmber;

    final icon = approved
        ? Icons.login_rounded
        : rejected
            ? Icons.support_agent_rounded
            : Icons.schedule_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.85,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  judulTindakan(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pesanTindakan(status),
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.5,
                    height: 1.4,
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

  Widget _progressCard(String status) {
    final approved = statusDisetujui(status);
    final rejected = statusDitolak(status);

    final verificationColor = rejected
        ? dangerColor
        : approved
            ? primaryGreen
            : amberColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffFAFBFC),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.route_outlined,
                color: blueColor,
                size: 18,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tahapan Pendaftaran',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: _StatusStepPill(
                  number: '1',
                  title: 'Diterima',
                  color: primaryGreen,
                  backgroundColor: softGreen,
                  isActive: true,
                ),
              ),
              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: textSoft,
                  size: 14,
                ),
              ),
              Expanded(
                child: _StatusStepPill(
                  number: '2',
                  title: rejected
                      ? 'Ditolak'
                      : approved
                          ? 'Disetujui'
                          : 'Diperiksa',
                  color: verificationColor,
                  backgroundColor: rejected
                      ? dangerColor.withValues(
                          alpha: 0.08,
                        )
                      : approved
                          ? softGreen
                          : softAmber,
                  isActive: true,
                ),
              ),
              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: textSoft,
                  size: 14,
                ),
              ),
              Expanded(
                child: _StatusStepPill(
                  number: '3',
                  title: approved
                      ? 'Aktif'
                      : 'Menunggu',
                  color: approved
                      ? primaryGreen
                      : textSoft,
                  backgroundColor: approved
                      ? softGreen
                      : const Color(0xffF0F2F4),
                  isActive: approved,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailExpansionCard() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(radius: 21),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            15,
            0,
            15,
            15,
          ),
          iconColor: purpleColor,
          collapsedIconColor: textGrey,
          shape: const RoundedRectangleBorder(
            side: BorderSide.none,
          ),
          collapsedShape:
              const RoundedRectangleBorder(
            side: BorderSide.none,
          ),
          leading: const _AccentIcon(
            icon: Icons.description_outlined,
            color: purpleColor,
            backgroundColor: softPurple,
            size: 40,
          ),
          title: const Text(
            'Detail Pendaftaran',
            style: TextStyle(
              color: textDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: const Text(
            'Ketuk untuk melihat data yang tersimpan.',
            style: TextStyle(
              color: textGrey,
              fontSize: 10.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xffFAFBFC),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Column(
                children: [
                  _infoRow(
                    icon:
                        Icons.assignment_ind_outlined,
                    label: 'NIK',
                    value:
                        dataAnggota?['nik'] ?? '-',
                    color: blueColor,
                  ),
                  _infoRow(
                    icon: Icons.phone_in_talk_outlined,
                    label: 'Telepon',
                    value:
                        dataAnggota?['telepon'] ??
                        dataAnggota?['no_hp'] ??
                        dataAnggota?['nomor_hp'] ??
                        '-',
                    color: tealColor,
                  ),
                  _infoRow(
                    icon: Icons.home_work_outlined,
                    label: 'Alamat',
                    value:
                        dataAnggota?['alamat'] ?? '-',
                    color: purpleColor,
                  ),
                  _infoRow(
                    icon: Icons.wc_rounded,
                    label: 'Jenis Kelamin',
                    value:
                        dataAnggota?['jenis_kelamin'] ??
                        '-',
                    color: blueColor,
                  ),
                  _infoRow(
                    icon: Icons.landscape_outlined,
                    label: 'Luas Lahan',
                    value: ambilLuasSawah(),
                    color: amberColor,
                  ),
                  _infoRow(
                    icon:
                        Icons.calendar_month_outlined,
                    label: 'Tanggal Daftar',
                    value: formatTanggal(
                      dataAnggota?['tanggal_daftar'],
                    ),
                    color: primaryGreen,
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required dynamic value,
    required Color color,
    bool isLast = false,
  }) {
    final rawText =
        value?.toString().trim() ?? '';

    final text =
        rawText.isEmpty ? '-' : rawText;

    return Container(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 11,
      ),
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 11,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: borderColor.withValues(
                    alpha: 0.80,
                  ),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 33,
            width: 33,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9.9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 11.6,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvedActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 51,
          child: ElevatedButton.icon(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.login_rounded,
              size: 19,
            ),
            label: const Text(
              'Kembali ke Halaman Login',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        TextButton.icon(
          onPressed: _resetPencarian,
          style: TextButton.styleFrom(
            foregroundColor: blueColor,
          ),
          icon: const Icon(
            Icons.manage_search_rounded,
            size: 18,
          ),
          label: const Text(
            'Cek NIK Lain',
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _checkAnotherButton(Color color) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _resetPencarian,
        style: OutlinedButton.styleFrom(
          foregroundColor: navyColor,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: color.withValues(alpha: 0.16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(
          Icons.manage_search_rounded,
          size: 19,
        ),
        label: const Text(
          'Cek NIK Lain',
          style: TextStyle(
            fontSize: 12.7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _initialInfoCard({
    Key? key,
    required bool isVeryCompact,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: EdgeInsets.all(
        isVeryCompact ? 13 : 16,
      ),
      decoration: _cardDecoration(radius: 23),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _AccentIcon(
                icon: Icons.route_outlined,
                color: primaryGreen,
                backgroundColor: softGreen,
                size: 40,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alur Keanggotaan',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Status dapat diperiksa setelah pendaftaran.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _StatusStepPill(
                  number: '1',
                  title: 'Daftar',
                  color: blueColor,
                  backgroundColor: softBlue,
                  isActive: true,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: textSoft,
                  size: 14,
                ),
              ),
              Expanded(
                child: _StatusStepPill(
                  number: '2',
                  title: 'Diperiksa',
                  color: amberColor,
                  backgroundColor: softAmber,
                  isActive: true,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: textSoft,
                  size: 14,
                ),
              ),
              Expanded(
                child: _StatusStepPill(
                  number: '3',
                  title: 'Aktif',
                  color: primaryGreen,
                  backgroundColor: softGreen,
                  isActive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: softAmber,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: amberColor.withValues(
                  alpha: 0.11,
                ),
              ),
            ),
            child: const Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: amberColor,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Masukkan NIK di atas untuk mengetahui '
                    'apakah pendaftaran masih diperiksa, '
                    'disetujui, atau memerlukan tindak lanjut.',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 10.3,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notFoundCard({
    Key? key,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 23),
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: dangerColor.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: dangerColor.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: dangerColor,
              size: 31,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Data Belum Ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 15.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ditemukan data pendaftaran untuk NIK '
            '${nikController.text}. Periksa kembali angka '
            'yang dimasukkan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.9,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _resetPencarian,
              style: OutlinedButton.styleFrom(
                foregroundColor: blueColor,
                backgroundColor: softBlue,
                side: BorderSide(
                  color: blueColor.withValues(
                    alpha: 0.18,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 19,
              ),
              label: const Text(
                'Masukkan Ulang NIK',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: blueColor,
        size: 20,
      ),
      counterText: '',
      filled: true,
      fillColor: const Color(0xffFAFBFC),
      hintStyle: const TextStyle(
        color: textSoft,
        fontSize: 12.2,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: blueColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.maybePop(context);
        },
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.13,
            ),
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 14,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 20,
  }) {
    return BoxDecoration(
      color: cardColor.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: navyColor.withValues(alpha: 0.065),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _FieldHeading extends StatelessWidget {
  final String label;
  final String helper;

  const _FieldHeading({
    required this.label,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color:
                      _StatusKeanggotaanPageState
                          .textDark,
                  fontSize: 12.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _StatusKeanggotaanPageState
                    .dangerColor
                    .withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(999),
              ),
              child: const Text(
                'WAJIB',
                style: TextStyle(
                  color:
                      _StatusKeanggotaanPageState
                          .dangerColor,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          helper,
          style: const TextStyle(
            color:
                _StatusKeanggotaanPageState
                    .textGrey,
            fontSize: 10.2,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AccentIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;

  const _AccentIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(
          size <= 40 ? 13 : 14,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.08),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size <= 40 ? 19 : 21,
      ),
    );
  }
}

class _StatusStepPill extends StatelessWidget {
  final String number;
  final String title;
  final Color color;
  final Color backgroundColor;
  final bool isActive;

  const _StatusStepPill({
    required this.number,
    required this.title,
    required this.color,
    required this.backgroundColor,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 49,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(
            alpha: isActive ? 0.13 : 0.07,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            height: 20,
            width: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.90,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive
                  ? _StatusKeanggotaanPageState
                      .textDark
                  : _StatusKeanggotaanPageState
                      .textSoft,
              fontSize: 8.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckingCard extends StatelessWidget {
  const _CheckingCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.97,
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color:
              _StatusKeanggotaanPageState
                  .borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: _StatusKeanggotaanPageState
                .navyColor
                .withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 61,
            width: 61,
            decoration: BoxDecoration(
              color:
                  _StatusKeanggotaanPageState
                      .softBlue,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color:
                      _StatusKeanggotaanPageState
                          .blueColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sedang Mencari Data',
            style: TextStyle(
              color:
                  _StatusKeanggotaanPageState
                      .textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Mohon tunggu, sistem sedang memeriksa '
            'data pendaftaran Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  _StatusKeanggotaanPageState
                      .textGrey,
              fontSize: 10.9,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBackground extends StatelessWidget {
  const _StatusBackground();

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
                        end: Alignment.bottomRight,
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
                    right: -largeCircle * 0.28,
                    child: _StatusBackgroundCircle(
                      size: largeCircle,
                      color:
                          _StatusKeanggotaanPageState
                              .softBlue,
                      borderColor:
                          _StatusKeanggotaanPageState
                              .blueColor,
                      alpha: 0.98,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.18,
                    right: -smallCircle * 0.05,
                    child: _StatusBackgroundRing(
                      size: smallCircle,
                      color:
                          _StatusKeanggotaanPageState
                              .blueColor,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.30,
                    left: -mediumCircle * 0.58,
                    child: _StatusBackgroundCircle(
                      size: mediumCircle,
                      color:
                          _StatusKeanggotaanPageState
                              .softGreen,
                      borderColor:
                          _StatusKeanggotaanPageState
                              .primaryGreen,
                      alpha: 0.95,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.50,
                    right: -smallCircle * 0.56,
                    child: _StatusBackgroundCircle(
                      size: smallCircle * 1.16,
                      color:
                          _StatusKeanggotaanPageState
                              .softPurple,
                      borderColor:
                          _StatusKeanggotaanPageState
                              .purpleColor,
                      alpha: 0.88,
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.51,
                    right: -largeCircle * 0.31,
                    child: _StatusBackgroundCircle(
                      size: largeCircle * 1.04,
                      color:
                          _StatusKeanggotaanPageState
                              .softAmber,
                      borderColor:
                          _StatusKeanggotaanPageState
                              .amberColor,
                      alpha: 0.96,
                    ),
                  ),
                  Positioned(
                    bottom: -mediumCircle * 0.18,
                    left: -mediumCircle * 0.52,
                    child: _StatusBackgroundCircle(
                      size: mediumCircle,
                      color:
                          _StatusKeanggotaanPageState
                              .softTeal,
                      borderColor:
                          _StatusKeanggotaanPageState
                              .tealColor,
                      alpha: 0.90,
                    ),
                  ),
                  Positioned(
                    bottom: smallCircle * 0.08,
                    right: -smallCircle * 0.10,
                    child: _StatusBackgroundRing(
                      size: smallCircle,
                      color:
                          _StatusKeanggotaanPageState
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
                          color: Colors.white.withValues(
                            alpha: 0.36,
                          ),
                          borderRadius:
                              BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                _StatusKeanggotaanPageState
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
                    bottom: screenHeight * 0.13,
                    left: 20,
                    child: Transform.rotate(
                      angle: 0.42,
                      child: Container(
                        height: 39,
                        width: 104,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.36,
                          ),
                          borderRadius:
                              BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                _StatusKeanggotaanPageState
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
                    child: _StatusBackgroundDot(
                      size: 9,
                      color:
                          _StatusKeanggotaanPageState
                              .blueColor,
                    ),
                  ),
                  const Positioned(
                    top: 164,
                    left: 62,
                    child: _StatusBackgroundDot(
                      size: 6,
                      color:
                          _StatusKeanggotaanPageState
                              .primaryGreen,
                    ),
                  ),
                  const Positioned(
                    bottom: 122,
                    right: 48,
                    child: _StatusBackgroundDot(
                      size: 9,
                      color:
                          _StatusKeanggotaanPageState
                              .amberColor,
                    ),
                  ),
                  const Positioned(
                    bottom: 72,
                    right: 98,
                    child: _StatusBackgroundDot(
                      size: 6,
                      color:
                          _StatusKeanggotaanPageState
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

class _StatusBackgroundCircle
    extends StatelessWidget {
  final double size;
  final Color color;
  final Color borderColor;
  final double alpha;

  const _StatusBackgroundCircle({
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
        color: color.withValues(alpha: alpha),
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

class _StatusBackgroundRing
    extends StatelessWidget {
  final double size;
  final Color color;

  const _StatusBackgroundRing({
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
          color: color.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }
}

class _StatusBackgroundDot
    extends StatelessWidget {
  final double size;
  final Color color;

  const _StatusBackgroundDot({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        shape: BoxShape.circle,
      ),
    );
  }
}