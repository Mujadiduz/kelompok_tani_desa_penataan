import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class UbahPasswordPage extends StatefulWidget {
  final String nik;

  const UbahPasswordPage({super.key, required this.nik});

  @override
  State<UbahPasswordPage> createState() => _UbahPasswordPageState();
}

class _UbahPasswordPageState extends State<UbahPasswordPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

  final passwordLamaController = TextEditingController();
  final passwordBaruController = TextEditingController();
  final konfirmasiPasswordController = TextEditingController();

  bool isLoading = false;
  bool hidePasswordLama = true;
  bool hidePasswordBaru = true;
  bool hideKonfirmasiPassword = true;

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  Future<void> ubahPassword() async {
    final passwordLama = passwordLamaController.text.trim();
    final passwordBaru = passwordBaruController.text.trim();
    final konfirmasiPassword = konfirmasiPasswordController.text.trim();

    if (passwordLama.isEmpty ||
        passwordBaru.isEmpty ||
        konfirmasiPassword.isEmpty) {
      _showSnackBar('Semua kolom wajib diisi', Colors.red);
      return;
    }

    if (passwordBaru.length < 6) {
      _showSnackBar('Password baru minimal 6 karakter', Colors.red);
      return;
    }

    if (passwordBaru != konfirmasiPassword) {
      _showSnackBar('Konfirmasi password tidak sama', Colors.red);
      return;
    }

    setState(() => isLoading = true);

    try {
      final snapshot = await anggotaRef.get().timeout(
        const Duration(seconds: 10),
      );

      String? idAnggota;
      String passwordLamaFirebase = '';

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          final value = entry.value;

          if (value is Map) {
            final anggota = Map<dynamic, dynamic>.from(value);
            final nikFirebase = (anggota['nik'] ?? '').toString().trim();

            if (nikFirebase == widget.nik.trim()) {
              idAnggota = entry.key.toString();
              passwordLamaFirebase =
                  (anggota['password'] ?? '').toString().trim();
              break;
            }
          }
        }
      }

      if (!mounted) return;

      if (idAnggota == null) {
        _showSnackBar('Data anggota tidak ditemukan', Colors.red);
        return;
      }

      if (passwordLama != passwordLamaFirebase) {
        _showSnackBar('Password lama salah', Colors.red);
        return;
      }

      await anggotaRef
          .child(idAnggota)
          .update({'password': passwordBaru})
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      _showSnackBar('Password berhasil diubah', primaryGreen);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengubah password: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSnackBar(String pesan, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    passwordLamaController.dispose();
    passwordBaruController.dispose();
    konfirmasiPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 22),
              _formCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -36,
            child: Icon(
              Icons.lock_reset_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(context),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ubah Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Keamanan Akun',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Gunakan password yang mudah diingat tetapi tetap aman.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ganti Password',
            style: TextStyle(
              color: textDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan password lama dan buat password baru untuk akun Anda.',
            style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 22),
          _passwordField(
            label: 'Password Lama',
            controller: passwordLamaController,
            hidden: hidePasswordLama,
            onTap: () {
              setState(() {
                hidePasswordLama = !hidePasswordLama;
              });
            },
          ),
          const SizedBox(height: 14),
          _passwordField(
            label: 'Password Baru',
            controller: passwordBaruController,
            hidden: hidePasswordBaru,
            onTap: () {
              setState(() {
                hidePasswordBaru = !hidePasswordBaru;
              });
            },
          ),
          const SizedBox(height: 14),
          _passwordField(
            label: 'Konfirmasi Password Baru',
            controller: konfirmasiPasswordController,
            hidden: hideKonfirmasiPassword,
            onTap: () {
              setState(() {
                hideKonfirmasiPassword = !hideKonfirmasiPassword;
              });
            },
          ),
          const SizedBox(height: 18),
          _noteBox(),
          const SizedBox(height: 24),
          _submitButton(),
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(label).copyWith(
        suffixIcon: IconButton(
          onPressed: onTap,
          icon: Icon(
            hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: textGrey,
          ),
        ),
      ),
    );
  }

  Widget _noteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Password baru minimal 6 karakter. Setelah berhasil diubah, gunakan password baru saat login berikutnya.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
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
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.65),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: isLoading ? null : ubahPassword,
        icon:
            isLoading
                ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.save_rounded),
        label: Text(
          isLoading ? 'Menyimpan...' : 'Simpan Password',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey),
      prefixIcon: const Icon(Icons.lock_outline_rounded, color: primaryGreen),
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
