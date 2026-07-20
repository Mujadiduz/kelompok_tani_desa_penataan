import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/session_helper.dart';
import '../widgets/app_background.dart';
import 'admin_home_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  static const Color navyColor = Color(0xff17324D);
  static const Color adminBlue = Color(0xff315F9A);
  static const Color tealColor = Color(0xff28766F);
  static const Color amberColor = Color(0xffD97706);

  static const Color softBlue = Color(0xffE4F0F8);
  static const Color softGreen = Color(0xffE4F3E8);
  static const Color softTeal = Color(0xffDCEFED);
  static const Color softAmber = Color(0xffFFF0D2);

  static const Color pageBackground = Color(0xffF5F7F9);
  static const Color cardColor = Color(0xffFFFFFF);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);
  static const Color borderColor = Color(0xffE2E7EC);
  static const Color dangerColor = Color(0xffC83B3B);

  final TextEditingController _usernameController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final DatabaseReference _adminRef =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref('admin');

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();

    _usernameFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  Future<void> _loginAdmin() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage(
        'Username dan password wajib diisi.',
        dangerColor,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await _adminRef
          .child('admin001')
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (!snapshot.exists || snapshot.value == null) {
        _showMessage(
          'Data admin belum tersedia.',
          dangerColor,
        );
        return;
      }

      final admin = Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final usernameDb =
          (admin['username'] ?? '').toString().trim();

      final passwordDb =
          (admin['password'] ?? '').toString().trim();

      final statusDb =
          (admin['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (usernameDb != username) {
        _showMessage(
          'Username admin salah.',
          dangerColor,
        );
        return;
      }

      if (passwordDb != password) {
        _showMessage(
          'Password admin salah.',
          dangerColor,
        );
        return;
      }

      if (statusDb.isNotEmpty && statusDb != 'aktif') {
        _showMessage(
          'Akun admin tidak aktif.',
          dangerColor,
        );
        return;
      }

      await SessionHelper.saveAdminSession();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminHomePage(),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      _showMessage(
        'Login admin gagal. Periksa koneksi internet.',
        dangerColor,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.error_outline_rounded,
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
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
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

    final isCompact =
        screenHeight < 700 || screenWidth < 360;

    final horizontalPadding =
        screenWidth < 340 ? 14.0 : 18.0;

    final topPadding = isCompact ? 10.0 : 16.0;
    final bottomPadding = isCompact ? 16.0 : 22.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _AdminLoginBackground(),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight =
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
                            minHeight: availableHeight > 0
                                ? availableHeight
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
                                      isCompact
                                          ? MainAxisAlignment
                                              .start
                                          : MainAxisAlignment
                                              .center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    _buildHeader(
                                      isCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isCompact ? 10 : 13,
                                    ),
                                    _buildLoginCard(
                                      isCompact,
                                    ),
                                    SizedBox(
                                      height:
                                          isCompact ? 9 : 11,
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

  Widget _buildHeader(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isCompact ? 14 : 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            navyColor,
            Color(0xff284D78),
            adminBlue,
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
              right: -44,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildBackButton(),
                    SizedBox(
                      width: isCompact ? 9 : 11,
                    ),
                    Container(
                      height: isCompact ? 45 : 49,
                      width: isCompact ? 45 : 49,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.13,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.18,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons
                            .admin_panel_settings_rounded,
                        color: Colors.white,
                        size: isCompact ? 23 : 25,
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? 10 : 12,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masuk Administrator',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  isCompact ? 17.5 : 19,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Akses pengelolaan sistem TaniGo',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(
                                0xffDCE5F0,
                              ),
                              fontSize:
                                  isCompact ? 10 : 10.8,
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
                          const EdgeInsets.symmetric(
                        horizontal: 8,
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
                          ).withValues(alpha: 0.24),
                        ),
                      ),
                      child: const Text(
                        'ADMIN',
                        style: TextStyle(
                          color: Color(0xffFFE4AC),
                          fontSize: 7.9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: isCompact ? 11 : 13,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
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
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Color(0xffFFD582),
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Gunakan akun administrator resmi yang telah terdaftar.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.3,
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

  Widget _buildLoginCard(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isCompact ? 15 : 17,
      ),
      decoration: _cardDecoration(
        radius: 23,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _AdminSectionIcon(
                icon: Icons.lock_person_rounded,
                color: adminBlue,
                backgroundColor: softBlue,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data Akun Admin',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Masukkan username dan password.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: isCompact ? 14 : 16,
          ),
          _buildInputField(
            controller: _usernameController,
            focusNode: _usernameFocus,
            label: 'Username',
            hint: 'Masukkan username admin',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [
              AutofillHints.username,
            ],
            onSubmitted: (_) {
              _passwordFocus.requestFocus();
            },
          ),
          SizedBox(
            height: isCompact ? 10 : 12,
          ),
          _buildInputField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Password',
            hint: 'Masukkan password admin',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [
              AutofillHints.password,
            ],
            onSubmitted: (_) {
              if (!_isLoading) {
                _loginAdmin();
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
                color: adminBlue,
                size: 20,
              ),
            ),
          ),
          SizedBox(
            height: isCompact ? 14 : 17,
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
    TextInputAction textInputAction =
        TextInputAction.done,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textDark,
            fontSize: 12.1,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onTapOutside: (_) {},
          autofillHints: autofillHints,
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
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: adminBlue,
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xffFAFBFC),
            hintStyle: const TextStyle(
              color: textSoft,
              fontSize: 12.3,
              fontWeight: FontWeight.w600,
            ),
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 14,
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
                color: adminBlue,
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
          ? 'Sedang memproses login administrator'
          : 'Masuk sebagai administrator',
      child: AnimatedOpacity(
        opacity: _isLoading ? 0.62 : 1,
        duration: const Duration(
          milliseconds: 180,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _isLoading ? null : _loginAdmin,
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
                    adminBlue,
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
                              fontSize: 13.4,
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
                            'Masuk ke Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.8,
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

  Widget _buildSecurityNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.91,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: adminBlue.withValues(alpha: 0.10),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: adminBlue,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Akses hanya untuk pengelola resmi. '
              'Jaga kerahasiaan username dan password.',
              style: TextStyle(
                color: textGrey,
                fontSize: 10.3,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.13,
            ),
            borderRadius: BorderRadius.circular(14),
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

class _AdminSectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _AdminSectionIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
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

class _AdminLoginBackground extends StatelessWidget {
  const _AdminLoginBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            final baseSize = screenWidth < screenHeight
                ? screenWidth
                : screenHeight;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(270.0, 440.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.72)
                    .clamp(210.0, 330.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.43)
                    .clamp(130.0, 210.0)
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
                          Color(0xffE8F1F9),
                          Color(0xffF2F6FA),
                          Color(0xffFFF5E5),
                        ],
                        stops: [
                          0,
                          0.55,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -largeCircle * 0.44,
                    right: -largeCircle * 0.29,
                    child: _AdminBackgroundCircle(
                      size: largeCircle,
                      color:
                          _AdminLoginPageState.softBlue,
                      borderColor:
                          _AdminLoginPageState.adminBlue,
                      alpha: 0.98,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.18,
                    right: -smallCircle * 0.04,
                    child: _AdminBackgroundRing(
                      size: smallCircle,
                      color:
                          _AdminLoginPageState.adminBlue,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.32,
                    left: -mediumCircle * 0.58,
                    child: _AdminBackgroundCircle(
                      size: mediumCircle,
                      color:
                          _AdminLoginPageState.softGreen,
                      borderColor:
                          _AdminLoginPageState.tealColor,
                      alpha: 0.91,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.53,
                    right: -smallCircle * 0.57,
                    child: _AdminBackgroundCircle(
                      size: smallCircle * 1.15,
                      color:
                          _AdminLoginPageState.softTeal,
                      borderColor:
                          _AdminLoginPageState.tealColor,
                      alpha: 0.88,
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.53,
                    right: -largeCircle * 0.33,
                    child: _AdminBackgroundCircle(
                      size: largeCircle * 1.04,
                      color:
                          _AdminLoginPageState.softAmber,
                      borderColor:
                          _AdminLoginPageState.amberColor,
                      alpha: 0.96,
                    ),
                  ),
                  Positioned(
                    bottom: -mediumCircle * 0.18,
                    left: -mediumCircle * 0.52,
                    child: _AdminBackgroundCircle(
                      size: mediumCircle,
                      color:
                          _AdminLoginPageState.softTeal,
                      borderColor:
                          _AdminLoginPageState.adminBlue,
                      alpha: 0.86,
                    ),
                  ),
                  Positioned(
                    bottom: smallCircle * 0.06,
                    right: -smallCircle * 0.10,
                    child: _AdminBackgroundRing(
                      size: smallCircle,
                      color:
                          _AdminLoginPageState.amberColor,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.41,
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
                            color: _AdminLoginPageState
                                .adminBlue
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
                            color: _AdminLoginPageState
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
                    child: _AdminBackgroundDot(
                      size: 9,
                      color:
                          _AdminLoginPageState.adminBlue,
                    ),
                  ),
                  const Positioned(
                    top: 164,
                    left: 62,
                    child: _AdminBackgroundDot(
                      size: 6,
                      color:
                          _AdminLoginPageState.tealColor,
                    ),
                  ),
                  const Positioned(
                    bottom: 122,
                    right: 48,
                    child: _AdminBackgroundDot(
                      size: 9,
                      color:
                          _AdminLoginPageState.amberColor,
                    ),
                  ),
                  const Positioned(
                    bottom: 72,
                    right: 98,
                    child: _AdminBackgroundDot(
                      size: 6,
                      color:
                          _AdminLoginPageState.adminBlue,
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

class _AdminBackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Color borderColor;
  final double alpha;

  const _AdminBackgroundCircle({
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

class _AdminBackgroundRing extends StatelessWidget {
  final double size;
  final Color color;

  const _AdminBackgroundRing({
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

class _AdminBackgroundDot extends StatelessWidget {
  final double size;
  final Color color;

  const _AdminBackgroundDot({
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