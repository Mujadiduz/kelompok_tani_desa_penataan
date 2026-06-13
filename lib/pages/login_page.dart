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
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

  final nikController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  Future<void> login() async {
    final inputAwal = nikController.text.trim();
    final nikInput = inputAwal.replaceAll(RegExp(r'[^0-9]'), '');
    final passwordInput = passwordController.text.trim();

    if (inputAwal.isEmpty || passwordInput.isEmpty) {
      tampilPesan('NIK dan password wajib diisi', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    if (inputAwal.toLowerCase() == 'admin' && passwordInput == 'admin123') {
      if (!mounted) return;

      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
      return;
    }

    if (nikInput.length != 16) {
      if (!mounted) return;

      setState(() => isLoading = false);

      tampilPesan(
        'NIK harus 16 digit. Saat ini terbaca ${nikInput.length} digit.',
        Colors.red,
      );
      return;
    }

    try {
      final snapshot = await anggotaRef.get().timeout(
        const Duration(seconds: 10),
      );

      bool loginBerhasil = false;
      String namaLogin = '';
      String nikLogin = '';

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

        for (final item in data.values) {
          if (item is Map) {
            final anggota = Map<dynamic, dynamic>.from(item);

            final nikFirebase = (anggota['nik'] ?? '').toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

            final passwordFirebase =
                (anggota['password'] ?? '').toString().trim();

            final statusFirebase =
                (anggota['status'] ?? '').toString().toLowerCase();

            if (nikFirebase == nikInput &&
                passwordFirebase == passwordInput &&
                statusFirebase == 'aktif') {
              namaLogin = (anggota['nama'] ?? '').toString();
              nikLogin = nikFirebase;
              loginBerhasil = true;
              break;
            }
          }
        }
      }

      if (!mounted) return;

      if (loginBerhasil) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserHomePage(nama: namaLogin, nik: nikLogin),
          ),
        );
      } else {
        tampilPesan(
          'Login gagal. Akun belum disetujui admin atau data tidak sesuai.',
          Colors.red,
        );
      }
    } catch (e) {
      if (!mounted) return;
      tampilPesan('Gagal login: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void tampilPesan(String pesan, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void bukaHalaman(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  void dispose() {
    nikController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          child: Column(
            children: [
              _headerLogin(),
              const SizedBox(height: 24),
              _formLogin(),
              const SizedBox(height: 18),
              _footerText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerLogin() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -40,
            child: Icon(
              Icons.eco_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  '🌾 Kelompok Tani',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Desa Penataan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Masuk untuk mengakses layanan kelompok tani',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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

  Widget _formLogin() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masuk Akun',
            style: TextStyle(
              color: textDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan NIK dan password yang sudah disetujui admin.',
            style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: nikController,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'NIK / Admin',
              icon: Icons.badge_outlined,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: hidePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) login();
            },
            decoration: _inputDecoration(
              label: 'Password',
              icon: Icons.lock_outline_rounded,
            ).copyWith(
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: textGrey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryGreen.withValues(alpha: 0.65),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: isLoading ? null : login,
              child:
                  isLoading
                      ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                      : const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _dividerLine()),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'atau',
                  style: TextStyle(color: textGrey, fontSize: 12),
                ),
              ),
              Expanded(child: _dividerLine()),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(color: primaryGreen),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () => bukaHalaman(const RegisterPage()),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Daftar Calon Anggota',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: () => bukaHalaman(const StatusKeanggotaanPage()),
              icon: const Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: primaryGreen,
              ),
              label: const Text(
                'Cek Status Keanggotaan',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerLine() {
    return Container(height: 1, color: textGrey.withValues(alpha: 0.22));
  }

  Widget _footerText() {
    return const Text(
      '© Kelompok Tani Desa Penataan',
      style: TextStyle(
        color: textGrey,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
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
