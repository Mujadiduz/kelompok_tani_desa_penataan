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
  static const Color darkGreen = Color(0xff14532D);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color goldColor = Color(0xffD97706);

  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    FocusScope.of(context).unfocus();

    final nik = _nikController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final password = _passwordController.text.trim();

    if (nik.isEmpty || password.isEmpty) {
      _showMessage('NIK dan password wajib diisi.');
      return;
    }

    if (nik.length != 16) {
      _showMessage('NIK harus terdiri dari 16 digit.');
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
          'Akun belum ditemukan. Jika belum daftar, pilih Daftar Anggota Baru. Jika sudah daftar, cek status pengajuan.',
        );
        return;
      }

      final anggota = Map<dynamic, dynamic>.from(snapshot.value as Map);

      final passwordDb = anggota['password']?.toString().trim() ?? '';
      final statusDb = anggota['status']?.toString().trim().toLowerCase() ?? '';
      final nama = anggota['nama']?.toString().trim() ?? 'Pengguna';

      if (passwordDb.isEmpty) {
        _showMessage('Password akun belum tersimpan. Hubungi admin.');
        return;
      }

      if (passwordDb != password) {
        _showMessage('Password salah.');
        return;
      }

      if (statusDb != 'aktif') {
        _showMessage('Akun belum aktif. Silakan cek status pengajuan.');
        return;
      }

      await SessionHelper.saveUserSession(nik: nik, nama: nama);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserHomePage(nama: nama, nik: nik)),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Login gagal. Periksa koneksi internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height;
    final isSmallScreen = height < 720;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              20,
              isSmallScreen ? 14 : 20,
              20,
              bottomInset + 28,
            ),
            children: [
              _brandHeader(isSmallScreen),
              SizedBox(height: isSmallScreen ? 14 : 18),
              _loginCard(),
              const SizedBox(height: 14),
              _newUserActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandHeader(bool isSmallScreen) {
    return Column(
      children: [
        Container(
          height: isSmallScreen ? 92 : 108,
          width: isSmallScreen ? 92 : 108,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Image.asset(
              'assets/icon/Icon-Apps.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 13),
        const Text(
          'TaniGo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: darkGreen,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Masuk Pengguna',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textGrey,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _loginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputField(
            controller: _nikController,
            focusNode: _nikFocus,
            label: 'NIK',
            hint: 'Masukkan 16 digit NIK',
            icon: Icons.badge_rounded,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 12),
          _inputField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Password',
            hint: 'Masukkan password',
            icon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading) _loginPengguna();
            },
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: primaryGreen,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        FocusScope.of(context).unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LupaPasswordPage(),
                          ),
                        );
                      },
              child: const Text(
                'Lupa Password?',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          _loginButton(),
        ],
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      maxLength: label == 'NIK' ? 16 : null,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(
        color: textDark,
        fontWeight: FontWeight.w800,
        fontSize: 14.5,
      ),
      decoration: InputDecoration(
        counterText: '',
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryGreen),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xffF9FAFB),
        labelStyle: const TextStyle(
          color: textGrey,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.35),
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _loginPengguna,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.42),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                : const Text(
                  'Masuk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
      ),
    );
  }

  Widget _newUserActions() {
    return Column(
      children: [
        _actionBox(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Daftar Anggota Baru',
          subtitle: 'Belum pernah daftar? Mulai dari sini.',
          color: primaryGreen,
          filled: true,
          onTap: () {
            if (_isLoading) return;
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            );
          },
        ),
        const SizedBox(height: 11),
        _actionBox(
          icon: Icons.fact_check_rounded,
          title: 'Cek Status Pengajuan',
          subtitle: 'Sudah daftar? Lihat apakah sudah disetujui admin.',
          color: goldColor,
          filled: false,
          onTap: () {
            if (_isLoading) return;
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StatusKeanggotaanPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _actionBox({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? color : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: filled ? color : color.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 13,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 47,
                width: 47,
                decoration: BoxDecoration(
                  color:
                      filled
                          ? Colors.white.withValues(alpha: 0.16)
                          : color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: filled ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: filled ? Colors.white : textDark,
                        fontSize: 15.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            filled
                                ? Colors.white.withValues(alpha: 0.84)
                                : textGrey,
                        fontSize: 11.8,
                        height: 1.33,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: filled ? Colors.white : color,
                size: 27,
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 22}) {
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