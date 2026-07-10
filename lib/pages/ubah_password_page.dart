import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class UbahPasswordPage extends StatefulWidget {
  final String nik;

  const UbahPasswordPage({super.key, required this.nik});

  @override
  State<UbahPasswordPage> createState() => _UbahPasswordPageState();
}

class _UbahPasswordPageState extends State<UbahPasswordPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color redColor = Color(0xffDC2626);

  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  bool isLoading = false;
  bool hideOldPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      showSnack('Semua kolom wajib diisi.', redColor);
      return;
    }

    if (newPassword.length < 6) {
      showSnack('Password baru minimal 6 karakter.', redColor);
      return;
    }

    if (newPassword != confirmPassword) {
      showSnack('Konfirmasi password tidak sama.', redColor);
      return;
    }

    setState(() => isLoading = true);

    try {
      final snapshot = await anggotaRef
          .orderByChild('nik')
          .equalTo(widget.nik.trim())
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (!snapshot.exists || snapshot.value == null) {
        showSnack('Data anggota tidak ditemukan.', redColor);
        return;
      }

      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final memberId = data.keys.first.toString();
      final member = Map<dynamic, dynamic>.from(data.values.first as Map);

      final currentPassword = (member['password'] ?? '').toString().trim();

      if (oldPassword != currentPassword) {
        showSnack('Password lama salah.', redColor);
        return;
      }

      await anggotaRef
          .child(memberId)
          .update({
            'password': newPassword,
            'tanggal_ubah_password': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      await showSuccessDialog();

      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      showSnack('Gagal mengubah password. Periksa koneksi internet.', redColor);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showSnack(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> showSuccessDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Password Berhasil Diubah',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Gunakan password baru saat login berikutnya.',
            style: TextStyle(
              color: textGrey,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.w900),
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
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset + 28),
              children: [
                _header(),
                const SizedBox(height: 18),
                _formCard(),
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
    return Row(
      children: [
        InkWell(
          onTap: isLoading ? null : () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textDark,
              size: 17,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Ubah Password',
          style: TextStyle(
            color: textDark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _passwordField(
            label: 'Password Lama',
            controller: oldPasswordController,
            hidden: hideOldPassword,
            onTap: () => setState(() => hideOldPassword = !hideOldPassword),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 13),
          _passwordField(
            label: 'Password Baru',
            controller: newPasswordController,
            hidden: hideNewPassword,
            onTap: () => setState(() => hideNewPassword = !hideNewPassword),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 13),
          _passwordField(
            label: 'Konfirmasi Password Baru',
            controller: confirmPasswordController,
            hidden: hideConfirmPassword,
            onTap:
                () => setState(
                  () => hideConfirmPassword = !hideConfirmPassword,
                ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) changePassword();
            },
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gunakan minimal 6 karakter.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required VoidCallback onTap,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: textDark,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.lock_rounded,
          color: primaryGreen,
          size: 21,
        ),
        suffixIcon: IconButton(
          onPressed: onTap,
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: textGrey,
            size: 21,
          ),
        ),
        filled: true,
        fillColor: const Color(0xffF9FAFB),
        labelStyle: const TextStyle(
          color: textGrey,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: primaryGreen, width: 1.4),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.42),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.3,
                    color: Colors.white,
                  ),
                )
                : const Text(
                  'Simpan Password',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}