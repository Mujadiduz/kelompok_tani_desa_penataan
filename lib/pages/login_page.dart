import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

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
          .orderByChild('nik')
          .equalTo(nik)
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (!snapshot.exists || snapshot.value == null) {
        _showMessage(
          'Akun belum ditemukan. Cek status pendaftaran terlebih dahulu.',
        );
        return;
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final anggota = Map<dynamic, dynamic>.from(data.values.first as Map);

      final passwordDb = anggota['password']?.toString().trim() ?? '';
      final statusDb = anggota['status']?.toString().trim().toLowerCase() ?? '';
      final nama = anggota['nama']?.toString() ?? 'Pengguna';

      if (passwordDb != password) {
        _showMessage('Password salah.');
        return;
      }

      if (statusDb != 'aktif') {
        _showMessage('Akun belum aktif. Silakan cek status pendaftaran.');
        return;
      }

      await SessionHelper.saveUserSession(nik: nik, nama: nama);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UserHomePage(nama: nama, nik: nik)),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Login gagal. Periksa koneksi internet.');
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
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _brandHeader(),
                    const SizedBox(height: 18),
                    _loginCard(),
                    const SizedBox(height: 12),
                    _registerCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Column(
      children: [
        Container(
          height: 82,
          width: 82,
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.agriculture_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'TaniGo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textDark,
            fontSize: 29,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Masuk akun anggota kelompok tani',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textGrey,
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _loginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masuk Pengguna',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan NIK dan password yang sudah terdaftar.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _inputField(
            controller: _nikController,
            focusNode: _nikFocus,
            label: 'NIK',
            hint: '16 digit NIK',
            icon: Icons.badge_rounded,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 13),
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
          const SizedBox(height: 4),
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
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _loginButton(),
          const SizedBox(height: 12),
          _statusButton(),
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
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      maxLength: label == 'NIK' ? 16 : null,
      style: const TextStyle(
        color: textDark,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      counterText: '',
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryGreen),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      labelStyle: const TextStyle(color: textGrey, fontWeight: FontWeight.w700),
      hintStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.35),
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _loginPengguna,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.42),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        icon:
            _isLoading
                ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.login_rounded),
        label: Text(
          _isLoading ? 'Masuk...' : 'Masuk',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _statusButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap:
          _isLoading
              ? null
              : () {
                FocusScope.of(context).unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatusKeanggotaanPage(),
                  ),
                );
              },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: softGreen.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: primaryGreen.withValues(alpha: 0.13)),
        ),
        child: const Center(
          child: Text(
            'Cek Status Pendaftaran',
            style: TextStyle(
              color: primaryGreen,
              fontWeight: FontWeight.w900,
              fontSize: 12.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _registerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Flexible(
            child: Text(
              'Belum memiliki akun?',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap:
                _isLoading
                    ? null
                    : () {
                      FocusScope.of(context).unfocus();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
            child: const Text(
              'Daftar',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
