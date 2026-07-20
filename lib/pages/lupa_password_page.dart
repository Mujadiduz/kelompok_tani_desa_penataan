import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_background.dart';

class LupaPasswordPage extends StatefulWidget {
  const LupaPasswordPage({super.key});

  @override
  State<LupaPasswordPage> createState() =>
      _LupaPasswordPageState();
}

class _LupaPasswordPageState extends State<LupaPasswordPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color tealColor = Color(0xff28766F);
  static const Color navyColor = Color(0xff17324D);
  static const Color blueColor = Color(0xff2F6B9A);
  static const Color amberColor = Color(0xffD97706);

  static const Color softGreen = Color(0xffE4F3E8);
  static const Color softBlue = Color(0xffE4F0F8);
  static const Color softAmber = Color(0xffFFF0D2);
  static const Color softTeal = Color(0xffDCEFED);

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

  late final DatabaseReference anggotaRef;
  late final DatabaseReference resetRef;
  late final DatabaseReference notifAdminRef;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    anggotaRef = db.ref('anggota');
    resetRef = db.ref('reset_password');
    notifAdminRef = db.ref('notifikasi_admin');
  }

  @override
  void dispose() {
    nikController.dispose();
    nikFocus.dispose();
    super.dispose();
  }

  Future<void> ajukanResetPassword() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final nik = nikController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (nik.isEmpty) {
      _showMessage(
        'NIK wajib diisi.',
        dangerColor,
      );
      return;
    }

    if (nik.length != 16) {
      _showMessage(
        'NIK harus terdiri dari 16 digit.',
        dangerColor,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final anggotaSnapshot = await anggotaRef
          .orderByChild('nik')
          .equalTo(nik)
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (!anggotaSnapshot.exists ||
          anggotaSnapshot.value == null) {
        _showMessage(
          'NIK tidak ditemukan sebagai anggota aktif.',
          dangerColor,
        );
        return;
      }

      final anggotaData = Map<dynamic, dynamic>.from(
        anggotaSnapshot.value as Map,
      );

      final anggota = Map<String, dynamic>.from(
        anggotaData.values.first as Map,
      );

      final nama =
          (anggota['nama'] ?? 'Anggota').toString();

      final status =
          (anggota['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (status != 'aktif') {
        _showMessage(
          'Akun anggota belum aktif.',
          dangerColor,
        );
        return;
      }

      final cekReset = await resetRef
          .orderByChild('nik')
          .equalTo(nik)
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (_masihAdaResetMenunggu(cekReset.value)) {
        _showMessage(
          'Permintaan reset password masih menunggu proses admin.',
          primaryGreen,
        );
        return;
      }

      await resetRef
          .push()
          .set({
            'nik': nik,
            'nama': nama,
            'status': 'menunggu',
            'tanggal_pengajuan':
                DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 12));

      await notifAdminRef
          .push()
          .set({
            'judul': 'Permintaan Reset Password',
            'pesan':
                '$nama mengajukan reset password akun anggota.',
            'tipe': 'reset_password',
            'status': 'belum_dibaca',
            'dibaca': false,
            'tanggal': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      _showSuccessDialog();
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Gagal mengajukan reset password.',
        dangerColor,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _masihAdaResetMenunggu(dynamic value) {
    if (value == null || value is! Map) {
      return false;
    }

    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final reset = Map<dynamic, dynamic>.from(item);

        final status =
            (reset['status'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        if (status == 'menunggu') {
          return true;
        }
      }
    }

    return false;
  }

  void _showMessage(
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
                    : Icons.info_outline_rounded,
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

  void _showSuccessDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: navyColor.withValues(alpha: 0.40),
      builder: (dialogContext) {
        final screenWidth =
            MediaQuery.of(dialogContext).size.width;

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth < 350 ? 18 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                23,
                22,
                20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 66,
                    width: 66,
                    decoration: BoxDecoration(
                      color: softGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryGreen.withValues(
                          alpha: 0.14,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      color: primaryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Permintaan Terkirim',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Permintaan reset password berhasil dikirim. '
                    'Administrator akan memeriksa pengajuan Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12.2,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: softAmber,
                      borderRadius: BorderRadius.circular(14),
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
                          Icons.schedule_outlined,
                          color: amberColor,
                          size: 17,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Hindari mengirim permintaan kembali '
                            'selama masih menunggu.',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 10.5,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final bottomInset = mediaQuery.viewInsets.bottom;

    final isKeyboardOpen = bottomInset > 0;

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
                const _ResetPasswordBackground(),
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
                                maxWidth: 500,
                              ),
                              child: AutofillGroup(
                                child: Column(
                                  mainAxisAlignment:
                                      isKeyboardOpen
                                          ? MainAxisAlignment.start
                                          : MainAxisAlignment.start,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildHeader(
                                      isCompact,
                                      isVeryCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isVeryCompact ? 8 : 11,
                                    ),
                                    _buildResetCard(
                                      isCompact,
                                      isVeryCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isVeryCompact ? 8 : 10,
                                    ),
                                    _buildProcessCard(
                                      isVeryCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isVeryCompact ? 7 : 9,
                                    ),
                                    _buildSecurityNotice(),
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

  Widget _buildHeader(
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            navyColor,
            Color(0xff24536A),
            tealColor,
          ],
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
              top: -54,
              right: -45,
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
              children: [
                Row(
                  children: [
                    _buildBackButton(),
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
                        Icons.key_off_outlined,
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
                            'Lupa Password',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVeryCompact
                                  ? 16.5
                                  : (isCompact
                                      ? 17.5
                                      : 18.5),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pemulihan akses akun anggota',
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isVeryCompact) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xffFFD582,
                          ).withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xffFFD582,
                            ).withValues(alpha: 0.23),
                          ),
                        ),
                        child: const Text(
                          'ANGGOTA',
                          style: TextStyle(
                            color: Color(0xffFFE4AC),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
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
                          'Masukkan 16 digit NIK akun anggota '
                          'yang sudah aktif.',
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

  Widget _buildResetCard(
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
          Row(
            children: [
              const _ResetSectionIcon(
                icon: Icons.badge_outlined,
                color: blueColor,
                backgroundColor: softBlue,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi Akun',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pastikan NIK terdaftar dan akun aktif.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.6,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isVeryCompact) ...[
                const SizedBox(width: 7),
                const _SmallBadge(
                  text: '16 DIGIT',
                  color: blueColor,
                  backgroundColor: softBlue,
                ),
              ],
            ],
          ),
          SizedBox(
            height: isVeryCompact ? 11 : 14,
          ),
          Row(
            children: [
              const Text(
                'NIK',
                style: TextStyle(
                  color: textDark,
                  fontSize: 12.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Nomor Induk Kependudukan',
                style: TextStyle(
                  color: textSoft,
                  fontSize: isVeryCompact ? 9.2 : 9.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: nikController,
            focusNode: nikFocus,
            keyboardType: TextInputType.number,
            maxLength: 16,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            autofillHints: const [
              AutofillHints.username,
            ],
            onTapOutside: (_) {},
            onSubmitted: (_) {
              if (!isLoading) {
                ajukanResetPassword();
              }
            },
            scrollPadding: const EdgeInsets.only(
              bottom: 120,
            ),
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
            decoration: _inputDecoration(
              hint: 'Masukkan 16 digit NIK',
              icon: Icons.credit_card_rounded,
            ),
          ),
          const SizedBox(height: 7),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: textSoft,
                  size: 14,
                ),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Gunakan NIK yang sama dengan akun anggota Anda.',
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
          SizedBox(
            height: isVeryCompact ? 12 : 15,
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Semantics(
      button: true,
      label: isLoading
          ? 'Sedang mengirim permintaan reset password'
          : 'Kirim permintaan reset password',
      child: AnimatedOpacity(
        opacity: isLoading ? 0.62 : 1,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap:
                isLoading ? null : ajukanResetPassword,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    navyColor,
                    Color(0xff296B67),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
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
                        mainAxisSize: MainAxisSize.min,
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
                            'Mengirim...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.send_outlined,
                            color: Colors.white,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Kirim Permintaan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.7,
                              fontWeight: FontWeight.w900,
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

  Widget _buildProcessCard(bool isVeryCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isVeryCompact ? 11 : 13,
      ),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.route_outlined,
                color: primaryGreen,
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Setelah permintaan dikirim',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _buildCompactStep(
                  number: '1',
                  title: 'Permintaan terkirim',
                  subtitle: 'Data masuk ke admin',
                  color: blueColor,
                  backgroundColor: softBlue,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: textSoft,
                  size: 16,
                ),
              ),
              Expanded(
                child: _buildCompactStep(
                  number: '2',
                  title: 'Admin memproses',
                  subtitle: 'Tunggu konfirmasi',
                  color: amberColor,
                  backgroundColor: softAmber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStep({
    required String number,
    required String title,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 67,
      ),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 29,
            width: 29,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 9.9,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 8.7,
                    height: 1.2,
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

  Widget _buildSecurityNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.91),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.035),
            blurRadius: 11,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: primaryGreen,
            size: 17,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jangan mengirim permintaan berulang selama '
              'permintaan sebelumnya masih menunggu.',
              style: TextStyle(
                color: textGrey,
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w600,
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
      counterText: '',
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: blueColor,
        size: 20,
      ),
      filled: true,
      fillColor: const Color(0xffFAFBFC),
      hintStyle: const TextStyle(
        color: textSoft,
        fontSize: 12.2,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
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

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
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
            borderRadius: BorderRadius.circular(13),
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

class _ResetSectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _ResetSectionIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 39,
      width: 39,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: 0.09),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color backgroundColor;

  const _SmallBadge({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.11),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 7.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _ResetPasswordBackground extends StatelessWidget {
  const _ResetPasswordBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            final baseSize =
                screenWidth < screenHeight
                    ? screenWidth
                    : screenHeight;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(280.0, 440.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.72)
                    .clamp(210.0, 330.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.43)
                    .clamp(125.0, 200.0)
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
                    child: _ResetBackgroundCircle(
                      size: largeCircle,
                      color:
                          _LupaPasswordPageState.softBlue,
                      borderColor:
                          _LupaPasswordPageState.blueColor,
                      alpha: 0.98,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.18,
                    right: -smallCircle * 0.05,
                    child: _ResetBackgroundRing(
                      size: smallCircle,
                      color:
                          _LupaPasswordPageState.blueColor,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.30,
                    left: -mediumCircle * 0.58,
                    child: _ResetBackgroundCircle(
                      size: mediumCircle,
                      color:
                          _LupaPasswordPageState.softGreen,
                      borderColor:
                          _LupaPasswordPageState
                              .primaryGreen,
                      alpha: 0.95,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.50,
                    right: -smallCircle * 0.55,
                    child: _ResetBackgroundCircle(
                      size: smallCircle * 1.15,
                      color:
                          _LupaPasswordPageState.softTeal,
                      borderColor:
                          _LupaPasswordPageState.tealColor,
                      alpha: 0.88,
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.50,
                    right: -largeCircle * 0.31,
                    child: _ResetBackgroundCircle(
                      size: largeCircle * 1.03,
                      color:
                          _LupaPasswordPageState.softAmber,
                      borderColor:
                          _LupaPasswordPageState.amberColor,
                      alpha: 0.96,
                    ),
                  ),
                  Positioned(
                    bottom: -mediumCircle * 0.18,
                    left: -mediumCircle * 0.52,
                    child: _ResetBackgroundCircle(
                      size: mediumCircle,
                      color:
                          _LupaPasswordPageState.softTeal,
                      borderColor:
                          _LupaPasswordPageState.tealColor,
                      alpha: 0.90,
                    ),
                  ),
                  Positioned(
                    bottom: smallCircle * 0.08,
                    right: -smallCircle * 0.10,
                    child: _ResetBackgroundRing(
                      size: smallCircle,
                      color:
                          _LupaPasswordPageState.amberColor,
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
                            color: _LupaPasswordPageState
                                .primaryGreen
                                .withValues(alpha: 0.08),
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
                            color: _LupaPasswordPageState
                                .tealColor
                                .withValues(alpha: 0.09),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 108,
                    left: 28,
                    child: _ResetBackgroundDot(
                      size: 9,
                      color:
                          _LupaPasswordPageState.blueColor,
                    ),
                  ),
                  const Positioned(
                    top: 164,
                    left: 62,
                    child: _ResetBackgroundDot(
                      size: 6,
                      color: _LupaPasswordPageState
                          .primaryGreen,
                    ),
                  ),
                  const Positioned(
                    bottom: 122,
                    right: 48,
                    child: _ResetBackgroundDot(
                      size: 9,
                      color:
                          _LupaPasswordPageState.amberColor,
                    ),
                  ),
                  const Positioned(
                    bottom: 72,
                    right: 98,
                    child: _ResetBackgroundDot(
                      size: 6,
                      color:
                          _LupaPasswordPageState.tealColor,
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

class _ResetBackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Color borderColor;
  final double alpha;

  const _ResetBackgroundCircle({
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
          color: borderColor.withValues(alpha: 0.07),
          width: 2,
        ),
      ),
    );
  }
}

class _ResetBackgroundRing extends StatelessWidget {
  final double size;
  final Color color;

  const _ResetBackgroundRing({
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

class _ResetBackgroundDot extends StatelessWidget {
  final double size;
  final Color color;

  const _ResetBackgroundDot({
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