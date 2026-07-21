import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/session_helper.dart';
import '../widgets/app_background.dart';
import 'lupa_password_page.dart';
import 'register_page.dart';
import 'status_keanggotaan_page.dart';
import 'user_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color navyColor = Color(0xff17324D);
  static const Color blueColor = Color(0xff2F6B9A);
  static const Color tealColor = Color(0xff28766F);
  static const Color amberColor = Color(0xffD97706);

  static const Color softGreen = Color(0xffE4F3E8);
  static const Color softBlue = Color(0xffE4F0F8);
  static const Color softTeal = Color(0xffDCEFED);
  static const Color softAmber = Color(0xffFFF0D2);

  static const Color pageBackground = Color(0xffF5F7F9);
  static const Color cardColor = Color(0xffFFFFFF);
  static const Color borderColor = Color(0xffE2E7EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  final TextEditingController _nikController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _nikFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final DatabaseReference _database =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();

    _nikFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  Future<void> _loginPengguna() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final nik = _nikController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final password = _passwordController.text.trim();

    if (nik.isEmpty || password.isEmpty) {
      _showMessage(
        'NIK dan password wajib diisi.',
      );
      return;
    }

    if (nik.length != 16) {
      _showMessage(
        'NIK harus terdiri dari 16 digit.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _database
          .child('anggota')
          .child(nik)
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (!snapshot.exists || snapshot.value == null) {
        _showMessage(
          'Akun belum ditemukan. Jika belum mendaftar, pilih '
          'Daftar. Jika sudah mendaftar, pilih Cek Status.',
        );
        return;
      }

      final anggota = Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final passwordDb =
          anggota['password']?.toString().trim() ?? '';

      final statusDb =
          anggota['status']
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';

      final nama =
          anggota['nama']?.toString().trim() ?? 'Pengguna';

      if (passwordDb.isEmpty) {
        _showMessage(
          'Password akun belum tersimpan. Hubungi admin.',
        );
        return;
      }

      if (passwordDb != password) {
        _showMessage(
          'Password yang dimasukkan salah.',
        );
        return;
      }

      if (statusDb != 'aktif') {
        _showMessage(
          'Akun belum aktif. Silakan pilih Cek Status '
          'untuk melihat proses pengajuan.',
        );
        return;
      }

      await SessionHelper.saveUserSession(
        nik: nik,
        nama: nama,
      );

      final savedSession =
          await SessionHelper.getSession();

      if (!savedSession.isUser) {
        throw StateError(
          'Sesi pengguna gagal disimpan.',
        );
      }

      if (!mounted) return;

      TextInput.finishAutofillContext(
        shouldSave: true,
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => UserHomePage(
            nama: savedSession.nama!,
            nik: savedSession.nik!,
          ),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Login gagal. Periksa koneksi internet Anda.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.info_outline_rounded,
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navyColor,
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
        isVeryCompact ? 8.0 : (isCompact ? 10.0 : 16.0);

    final bottomPadding =
        isVeryCompact ? 14.0 : (isCompact ? 17.0 : 22.0);

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
                const _LoginBackground(),
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
                                      isCompact ||
                                              isKeyboardOpen
                                          ? MainAxisAlignment
                                              .start
                                          : MainAxisAlignment
                                              .center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    _buildHeroHeader(
                                      isCompact,
                                      isVeryCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isVeryCompact ? 8 : 11,
                                    ),
                                    _buildLoginCard(
                                      isCompact,
                                      isVeryCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isVeryCompact ? 8 : 10,
                                    ),
                                    _buildAccountGuide(
                                      isCompact,
                                      isVeryCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isVeryCompact ? 7 : 9,
                                    ),
                                    _buildSecurityFooter(),
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

  Widget _buildHeroHeader(
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
              right: 35,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBackButton(),
                    SizedBox(
                      width: isVeryCompact ? 7 : 9,
                    ),
                    Container(
                      height: isVeryCompact
                          ? 44
                          : (isCompact ? 48 : 53),
                      width: isVeryCompact
                          ? 44
                          : (isCompact ? 48 : 53),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: navyColor.withValues(
                              alpha: 0.14,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(13),
                        child: Image.asset(
                          'assets/icon/Icon-Apps.png',
                          fit: BoxFit.cover,
                        ),
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
                            'Masuk ke TaniGo',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVeryCompact
                                  ? 16.8
                                  : (isCompact
                                      ? 18
                                      : 19.5),
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: -0.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Layanan digital anggota kelompok tani',
                            maxLines: 2,
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
                                      : 10.9),
                              height: 1.3,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
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
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xffFFD582),
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Akun sudah aktif? Masukkan NIK dan '
                          'password untuk masuk.',
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

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: _isLoading
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

  Widget _buildLoginCard(
    bool isCompact,
    bool isVeryCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isVeryCompact ? 13 : (isCompact ? 15 : 17),
      ),
      decoration: _cardDecoration(
        radius: 23,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(
                icon: Icons.login_rounded,
                backgroundColor: softBlue,
                iconColor: blueColor,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sudah menjadi anggota aktif?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Masukkan data akun untuk melanjutkan.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: softGreen,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: primaryGreen.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 7.6,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: isVeryCompact ? 11 : 14,
          ),
          _buildInputField(
            controller: _nikController,
            focusNode: _nikFocus,
            label: 'NIK',
            hint: 'Masukkan 16 digit NIK',
            icon: Icons.assignment_ind_outlined,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.username,
            ],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            maxLength: 16,
            onSubmitted: (_) {
              _passwordFocus.requestFocus();
            },
          ),
          SizedBox(
            height: isVeryCompact ? 8 : 10,
          ),
          _buildInputField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Password',
            hint: 'Masukkan password',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [
              AutofillHints.password,
            ],
            onSubmitted: (_) {
              if (!_isLoading) {
                _loginPengguna();
              }
            },
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Tampilkan password'
                  : 'Sembunyikan password',
              onPressed: () {
                setState(() {
                  _obscurePassword =
                      !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: blueColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      FocusScope.of(context).unfocus();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LupaPasswordPage(),
                        ),
                      );
                    },
              icon: const Icon(
                Icons.help_outline_rounded,
                size: 15,
              ),
              label: const Text(
                'Lupa password?',
              ),
              style: TextButton.styleFrom(
                foregroundColor: blueColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 5,
                ),
                tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(
            height: isVeryCompact ? 4 : 6,
          ),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction =
        TextInputAction.done,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (label == 'NIK') ...[
              const SizedBox(width: 6),
              const Text(
                '16 digit',
                style: TextStyle(
                  color: textSoft,
                  fontSize: 9.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onTapOutside: (_) {},
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          maxLength: maxLength,
          enableSuggestions: !obscureText,
          autocorrect: false,
          scrollPadding: const EdgeInsets.only(
            bottom: 120,
          ),
          style: const TextStyle(
            color: textDark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: navyColor,
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xffFAFBFC),
            hintStyle: const TextStyle(
              color: textSoft,
              fontSize: 12.2,
              fontWeight: FontWeight.w600,
            ),
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: blueColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Semantics(
      button: true,
      label: _isLoading
          ? 'Sedang memproses login'
          : 'Masuk ke akun TaniGo',
      child: AnimatedOpacity(
        opacity: _isLoading ? 0.62 : 1,
        duration: const Duration(
          milliseconds: 180,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap:
                _isLoading ? null : _loginPengguna,
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
                child: _isLoading
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
                            'Memproses...',
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
                            Icons.login_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Masuk ke Akun',
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

  Widget _buildAccountGuide(
    bool isCompact,
    bool isVeryCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isVeryCompact ? 11 : (isCompact ? 12 : 14),
      ),
      decoration: _cardDecoration(
        radius: 21,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.route_outlined,
                color: primaryGreen,
                size: 19,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Belum bisa masuk?',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            'Ikuti langkah sesuai kondisi akun Anda.',
            style: TextStyle(
              color: textGrey,
              fontSize: 10.4,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: isVeryCompact ? 8 : 10,
          ),
          _buildProcessFlow(),
          SizedBox(
            height: isVeryCompact ? 8 : 10,
          ),
          Row(
            children: [
              Expanded(
                child: _buildCompactAction(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Daftar',
                  subtitle: 'Belum pernah mendaftar',
                  color: primaryGreen,
                  backgroundColor: softGreen,
                  onTap: () {
                    if (_isLoading) return;

                    FocusScope.of(context).unfocus();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const RegisterPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactAction(
                  icon: Icons.fact_check_outlined,
                  title: 'Cek Status',
                  subtitle: 'Sudah mengirim pendaftaran',
                  color: amberColor,
                  backgroundColor: softAmber,
                  onTap: () {
                    if (_isLoading) return;

                    FocusScope.of(context).unfocus();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StatusKeanggotaanPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessFlow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _FlowItem(
              number: '1',
              title: 'Daftar',
              color: primaryGreen,
              backgroundColor: softGreen,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: textSoft,
              size: 14,
            ),
          ),
          Expanded(
            child: _FlowItem(
              number: '2',
              title: 'Disetujui',
              color: amberColor,
              backgroundColor: softAmber,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 4,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: textSoft,
              size: 14,
            ),
          ),
          Expanded(
            child: _FlowItem(
              number: '3',
              title: 'Masuk',
              color: blueColor,
              backgroundColor: softBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 72,
            ),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(
                  alpha: 0.14,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.92,
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
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 8.9,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.91,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(
              alpha: 0.035,
            ),
            blurRadius: 11,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: primaryGreen,
            size: 17,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jaga kerahasiaan NIK dan password akun Anda.',
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

  BoxDecoration _cardDecoration({
    double radius = 22,
  }) {
    return BoxDecoration(
      color: cardColor.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: navyColor.withValues(
            alpha: 0.065,
          ),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  const _SectionIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
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
          color: iconColor.withValues(alpha: 0.08),
        ),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 19,
      ),
    );
  }
}

class _FlowItem extends StatelessWidget {
  final String number;
  final String title;
  final Color color;
  final Color backgroundColor;

  const _FlowItem({
    required this.number,
    required this.title,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 22,
          width: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _LoginPageState.textDark,
              fontSize: 9.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

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
                    child: _BackgroundCircle(
                      size: largeCircle,
                      color: _LoginPageState.softBlue,
                      borderColor:
                          _LoginPageState.blueColor,
                      alpha: 0.98,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.18,
                    right: -smallCircle * 0.05,
                    child: _BackgroundRing(
                      size: smallCircle,
                      color:
                          _LoginPageState.blueColor,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.30,
                    left: -mediumCircle * 0.58,
                    child: _BackgroundCircle(
                      size: mediumCircle,
                      color:
                          _LoginPageState.softGreen,
                      borderColor:
                          _LoginPageState.primaryGreen,
                      alpha: 0.95,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.49,
                    right: -smallCircle * 0.55,
                    child: _BackgroundCircle(
                      size: smallCircle * 1.15,
                      color: _LoginPageState.softTeal,
                      borderColor:
                          _LoginPageState.tealColor,
                      alpha: 0.88,
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.50,
                    right: -largeCircle * 0.31,
                    child: _BackgroundCircle(
                      size: largeCircle * 1.03,
                      color:
                          _LoginPageState.softAmber,
                      borderColor:
                          _LoginPageState.amberColor,
                      alpha: 0.96,
                    ),
                  ),
                  Positioned(
                    bottom: -mediumCircle * 0.18,
                    left: -mediumCircle * 0.52,
                    child: _BackgroundCircle(
                      size: mediumCircle,
                      color: _LoginPageState.softTeal,
                      borderColor:
                          _LoginPageState.tealColor,
                      alpha: 0.90,
                    ),
                  ),
                  Positioned(
                    bottom: smallCircle * 0.08,
                    right: -smallCircle * 0.10,
                    child: _BackgroundRing(
                      size: smallCircle,
                      color:
                          _LoginPageState.amberColor,
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
                            color: _LoginPageState
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
                            color: _LoginPageState
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
                    child: _BackgroundDot(
                      size: 9,
                      color:
                          _LoginPageState.blueColor,
                    ),
                  ),
                  const Positioned(
                    top: 164,
                    left: 62,
                    child: _BackgroundDot(
                      size: 6,
                      color: _LoginPageState
                          .primaryGreen,
                    ),
                  ),
                  const Positioned(
                    bottom: 122,
                    right: 48,
                    child: _BackgroundDot(
                      size: 9,
                      color:
                          _LoginPageState.amberColor,
                    ),
                  ),
                  const Positioned(
                    bottom: 72,
                    right: 98,
                    child: _BackgroundDot(
                      size: 6,
                      color:
                          _LoginPageState.tealColor,
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

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Color borderColor;
  final double alpha;

  const _BackgroundCircle({
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

class _BackgroundRing extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundRing({
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

class _BackgroundDot extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundDot({
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