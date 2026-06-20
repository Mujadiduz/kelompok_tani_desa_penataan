import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'admin_home_page.dart';
import 'register_page.dart';
import 'status_keanggotaan_page.dart';
import 'user_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color background = Color(0xFFF6FBF6);
  static const Color textDark = Color(0xFF1D2B1F);
  static const Color adminPurple = Color(0xFF5B21B6);

  final TextEditingController nikController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode nikFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  final DatabaseReference database =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();

  bool isLoading = false;
  bool obscurePassword = true;
  bool isAdminMode = false;

  Color get activeColor => isAdminMode ? adminPurple : primaryGreen;
  Color get activeDark => isAdminMode ? const Color(0xFF3B0764) : darkGreen;

  @override
  void dispose() {
    nikController.dispose();
    passwordController.dispose();
    nikFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final nik = nikController.text.trim();
    final password = passwordController.text.trim();

    if (isAdminMode) {
      await _loginAdmin(password);
    } else {
      await _loginAnggota(nik, password);
    }
  }

  Future<void> _loginAdmin(String password) async {
    if (password.isEmpty) {
      _showMessage('Password admin wajib diisi.');
      return;
    }

    setState(() => isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 350));

      if (!mounted) return;

      if (password != 'admin123') {
        _showMessage('Password admin salah.');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loginAnggota(String nik, String password) async {
    if (nik.isEmpty || password.isEmpty) {
      _showMessage('NIK dan password wajib diisi.');
      return;
    }

    if (nik.length != 16) {
      _showMessage('NIK harus terdiri dari 16 digit.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final snapshot =
          await database
              .child('anggota')
              .orderByChild('nik')
              .equalTo(nik)
              .get();

      if (!mounted) return;

      if (!snapshot.exists || snapshot.value == null) {
        _showMessage('NIK tidak ditemukan.');
        return;
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final anggota = Map<dynamic, dynamic>.from(data.values.first as Map);

      final passwordDb = anggota['password']?.toString().trim() ?? '';
      final statusDb = anggota['status']?.toString().trim().toLowerCase() ?? '';
      final nama = anggota['nama']?.toString() ?? 'Anggota';

      if (passwordDb != password) {
        _showMessage('Password salah.');
        return;
      }

      if (statusDb != 'aktif') {
        _showMessage('Akun anggota belum aktif.');
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserHomePage(nama: nama, nik: nik)),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('ERROR LOGIN USER: $e');
      _showMessage('Login gagal membaca data anggota.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _changeMode(bool adminMode) {
    FocusScope.of(context).unfocus();

    setState(() {
      isAdminMode = adminMode;
      nikController.clear();
      passwordController.clear();
      obscurePassword = true;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: activeDark,
        margin: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: background,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -90,
                child: _decorCircle(230, activeColor.withValues(alpha: 0.13)),
              ),
              Positioned(
                top: 125,
                left: -120,
                child: _decorCircle(190, lightGreen.withValues(alpha: 0.10)),
              ),
              Positioned(
                bottom: -120,
                left: -90,
                child: _decorCircle(250, activeColor.withValues(alpha: 0.09)),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      28,
                      24,
                      24 + keyboardHeight,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 52,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _topBadge(),
                          const SizedBox(height: 22),
                          _heroSection(),
                          const SizedBox(height: 22),
                          _loginCard(),
                          const SizedBox(height: 18),
                          if (!isAdminMode) _registerSection(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBadge() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: activeColor.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdminMode
                  ? Icons.admin_panel_settings_rounded
                  : Icons.eco_rounded,
              color: activeColor,
              size: 17,
            ),
            const SizedBox(width: 8),
            Text(
              isAdminMode
                  ? 'Panel Admin Kelompok Tani'
                  : 'Kelompok Tani Desa Penataan',
              style: TextStyle(
                color: activeDark,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isAdminMode
                  ? const [Color(0xFF3B0764), Color(0xFF5B21B6)]
                  : const [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              isAdminMode
                  ? Icons.admin_panel_settings_rounded
                  : Icons.agriculture_rounded,
              size: 125,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  isAdminMode
                      ? Icons.admin_panel_settings_rounded
                      : Icons.agriculture_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isAdminMode ? 'Masuk Admin' : 'Selamat Datang',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAdminMode
                    ? 'Akses panel admin untuk mengelola verifikasi, data anggota, bantuan pupuk, peminjaman alat, dan laporan.'
                    : 'Masuk untuk mengajukan bantuan pupuk, meminjam alat pertanian, dan melihat riwayat layanan.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 14.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _miniInfo(
                    isAdminMode
                        ? Icons.verified_user_rounded
                        : Icons.verified_user_rounded,
                    isAdminMode ? 'Admin' : 'Aman',
                  ),
                  _miniInfo(Icons.storage_rounded, 'Realtime'),
                  _miniInfo(Icons.mobile_friendly_rounded, 'Mobile'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: activeColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modeSwitcher(),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isAdminMode ? Icons.security_rounded : Icons.person_rounded,
                  color: activeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdminMode ? 'Login Admin' : 'Login Anggota',
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAdminMode
                          ? 'Masukkan password admin.'
                          : 'Gunakan NIK yang sudah disetujui.',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.52),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (!isAdminMode) ...[
            _inputField(
              controller: nikController,
              focusNode: nikFocus,
              label: 'NIK',
              hint: 'Masukkan 16 digit NIK',
              icon: Icons.badge_rounded,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 16),
          ],
          _inputField(
            controller: passwordController,
            focusNode: passwordFocus,
            label: 'Password',
            hint: isAdminMode ? 'Masukkan password admin' : 'Masukkan password',
            icon: Icons.lock_rounded,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => isLoading ? null : login(),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => obscurePassword = !obscurePassword);
              },
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: activeColor,
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : login,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: activeColor.withValues(alpha: 0.45),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child:
                  isLoading
                      ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isAdminMode ? 'Masuk Admin' : 'Masuk Sekarang',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
            ),
          ),
          if (!isAdminMode) ...[
            const SizedBox(height: 16),
            Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StatusKeanggotaanPage(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Text(
                    'Cek status pendaftaran anggota',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _modeSwitcher() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: activeColor.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeItem(
              title: 'Anggota',
              icon: Icons.person_rounded,
              selected: !isAdminMode,
              onTap: () => _changeMode(false),
            ),
          ),
          Expanded(
            child: _modeItem(
              title: 'Admin',
              icon: Icons.admin_panel_settings_rounded,
              selected: isAdminMode,
              onTap: () => _changeMode(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeItem({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    selected
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.48),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color:
                      selected
                          ? Colors.white
                          : Colors.black.withValues(alpha: 0.55),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.done,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: textDark,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: activeColor, size: 21),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF4FAF4),
        labelStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.60),
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.34),
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: BorderSide(color: activeColor.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(19),
          borderSide: BorderSide(color: activeColor, width: 1.4),
        ),
      ),
    );
  }

  Widget _registerSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.08)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Belum punya akun?',
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              );
            },
            child: const Text(
              'Daftar Anggota',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
