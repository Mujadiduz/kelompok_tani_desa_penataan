import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class ResetPasswordProsesPage extends StatefulWidget {
  final String idReset;
  final String nik;
  final String nama;

  const ResetPasswordProsesPage({
    super.key,
    required this.idReset,
    required this.nik,
    required this.nama,
  });

  @override
  State<ResetPasswordProsesPage> createState() =>
      _ResetPasswordProsesPageState();
}

class _ResetPasswordProsesPageState extends State<ResetPasswordProsesPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color dangerColor = Color(0xffC62828);

  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocus = FocusNode();

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference resetRef;
  late final DatabaseReference anggotaRef;

  bool isLoading = false;
  bool obscurePassword = false;

  @override
  void initState() {
    super.initState();
    resetRef = db.ref('reset_password');
    anggotaRef = db.ref('anggota');
    passwordController.text = generatePassword();
  }

  @override
  void dispose() {
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  String generatePassword() {
    final random = Random();
    final angka = List.generate(6, (_) => random.nextInt(10)).join();
    return 'TG$angka';
  }

  Future<void> simpanPasswordBaru() async {
    FocusScope.of(context).unfocus();

    final passwordBaru = passwordController.text.trim();

    if (widget.idReset.trim().isEmpty || widget.nik.trim().isEmpty) {
      _showMessage('Data reset password tidak valid.', dangerColor);
      return;
    }

    if (passwordBaru.length < 6) {
      _showMessage('Password baru minimal 6 karakter.', dangerColor);
      return;
    }

    setState(() => isLoading = true);

    try {
      final anggotaSnapshot = await anggotaRef
          .orderByChild('nik')
          .equalTo(widget.nik.trim())
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (!anggotaSnapshot.exists || anggotaSnapshot.value == null) {
        _showMessage('Data anggota tidak ditemukan.', dangerColor);
        return;
      }

      final data = Map<dynamic, dynamic>.from(anggotaSnapshot.value as Map);
      final idAnggota = data.keys.first.toString();

      await anggotaRef
          .child(idAnggota)
          .update({
            'password': passwordBaru,
            'tanggal_reset_password': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 12));

      await resetRef
          .child(widget.idReset)
          .update({
            'status': 'selesai',
            'tanggal_diproses': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 12));

      await NotificationHelper.passwordBerhasilDireset(
        nik: widget.nik.trim(),
        passwordBaru: passwordBaru,
      );

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        'Gagal reset password. Periksa koneksi internet.',
        dangerColor,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Password Berhasil Direset',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Password baru berhasil dibuat dan dikirim ke notifikasi anggota.',
            style: TextStyle(
              color: textGrey,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text(
                'Selesai',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
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
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: EdgeInsets.fromLTRB(18, 16, 18, bottomInset + 28),
              children: [
                _header(),
                const SizedBox(height: 16),
                _userCard(),
                const SizedBox(height: 14),
                _formCard(),
                const SizedBox(height: 14),
                _infoCard(),
                const SizedBox(height: 18),
                _submitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: isLoading ? null : () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.password_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password Baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Proses reset password anggota.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.2,
                    height: 1.3,
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

  Widget _userCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: softGreen,
            child: const Icon(Icons.person_rounded, color: primaryGreen),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'NIK ${sensorNik(widget.nik)}',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12.4,
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

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password Sementara',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Admin dapat menggunakan password otomatis atau mengubahnya secara manual.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12.4,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) simpanPasswordBaru();
            },
            decoration: _inputDecoration(
              label: 'Password Baru',
              hint: 'Contoh: TG482913',
              icon: Icons.lock_rounded,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => obscurePassword = !obscurePassword);
                },
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed:
                  isLoading
                      ? null
                      : () {
                        setState(() {
                          passwordController.text = generatePassword();
                          obscurePassword = false;
                        });
                      },
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: const Text(
                'Generate Password Baru',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: BorderSide(color: primaryGreen.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.13)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Password sementara akan dikirim ke notifikasi anggota. Setelah login, anggota disarankan segera mengganti password.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.4,
                height: 1.45,
                fontWeight: FontWeight.w700,
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
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : simpanPasswordBaru,
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
            isLoading
                ? const SizedBox(
                  height: 19,
                  width: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.save_rounded),
        label: Text(
          isLoading ? 'Menyimpan...' : 'Simpan Password Baru',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
        ),
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
