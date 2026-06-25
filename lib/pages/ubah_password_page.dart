import 'dart:math';

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
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF57C00);
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

  String? oldPasswordError;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String generatePassword() {
    final random = Random();
    final angka = List.generate(6, (_) => random.nextInt(10)).join();
    return 'TG$angka';
  }

  Future<void> changePassword() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    setState(() => oldPasswordError = null);

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
        setState(() {
          oldPasswordError = 'Password lama tidak sesuai.';
        });
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
    } catch (e) {
      if (!mounted) return;
      debugPrint('ERROR UBAH PASSWORD: $e');
      showSnack('Gagal mengubah password. Periksa koneksi internet.', redColor);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  double passwordStrength() {
    final password = newPasswordController.text.trim();
    double score = 0;

    if (password.length >= 6) score += 0.35;
    if (password.length >= 8) score += 0.20;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.15;

    return score > 1 ? 1 : score;
  }

  String strengthText() {
    final password = newPasswordController.text.trim();
    final score = passwordStrength();

    if (password.isEmpty) return 'Belum diisi';
    if (score < 0.45) return 'Lemah';
    if (score < 0.75) return 'Cukup';
    return 'Kuat';
  }

  Color strengthColor() {
    final password = newPasswordController.text.trim();
    final score = passwordStrength();

    if (password.isEmpty) return textGrey;
    if (score < 0.45) return redColor;
    if (score < 0.75) return orangeStatus;
    return primaryGreen;
  }

  bool hasMinLength() => newPasswordController.text.trim().length >= 6;

  bool hasNumber() {
    return RegExp(r'[0-9]').hasMatch(newPasswordController.text.trim());
  }

  bool hasLetter() {
    return RegExp(r'[A-Za-z]').hasMatch(newPasswordController.text.trim());
  }

  bool isPasswordMatch() {
    final confirm = confirmPasswordController.text.trim();
    if (confirm.isEmpty) return false;
    return newPasswordController.text.trim() == confirm;
  }

  void showSnack(String message, Color color) {
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

  Future<void> showSuccessDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Password Berhasil Diubah',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Silakan gunakan password baru saat login berikutnya.',
            style: TextStyle(
              color: textGrey,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Mengerti',
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
    final strength = passwordStrength();
    final color = strengthColor();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 92),
            children: [
              topBar(),
              const SizedBox(height: 14),
              headerCard(),
              const SizedBox(height: 14),
              stepCard(),
              const SizedBox(height: 14),
              formCard(strength, color),
            ],
          ),
        ),
      ),
      bottomNavigationBar: submitBar(),
    );
  }

  Widget topBar() {
    return Row(
      children: [
        topButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            if (!isLoading && mounted) Navigator.pop(context);
          },
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Ubah Password',
            style: TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget headerCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Kelola password akun agar tetap aman.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget stepCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Row(
        children: [
          stepItem('1', 'Lama', true),
          Expanded(child: stepLine()),
          stepItem('2', 'Baru', newPasswordController.text.trim().isNotEmpty),
          Expanded(child: stepLine()),
          stepItem(
            '3',
            'Konfirmasi',
            confirmPasswordController.text.trim().isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget stepItem(String number, String label, bool active) {
    return Column(
      children: [
        Container(
          height: 30,
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? primaryGreen : softGreen,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: active ? textDark : textGrey,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget stepLine() {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 19),
      color: primaryGreen.withValues(alpha: 0.18),
    );
  }

  Widget formCard(double strength, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Password',
            style: TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Gunakan password minimal 6 karakter.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          passwordField(
            label: 'Password Lama',
            controller: oldPasswordController,
            hidden: hideOldPassword,
            icon: Icons.lock_outline_rounded,
            errorText: oldPasswordError,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (oldPasswordError != null) {
                setState(() => oldPasswordError = null);
              }
            },
            onTap: () => setState(() => hideOldPassword = !hideOldPassword),
          ),
          const SizedBox(height: 12),
          passwordField(
            label: 'Password Baru',
            controller: newPasswordController,
            hidden: hideNewPassword,
            icon: Icons.lock_reset_rounded,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            onTap: () => setState(() => hideNewPassword = !hideNewPassword),
          ),
          const SizedBox(height: 10),
          generateButton(),
          const SizedBox(height: 12),
          strengthIndicator(strength, color),
          const SizedBox(height: 10),
          passwordRules(),
          const SizedBox(height: 12),
          passwordField(
            label: 'Konfirmasi Password Baru',
            controller: confirmPasswordController,
            hidden: hideConfirmPassword,
            icon: Icons.verified_rounded,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (!isLoading) changePassword();
            },
            onTap: () {
              setState(() => hideConfirmPassword = !hideConfirmPassword);
            },
          ),
          if (confirmPasswordController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            matchInfo(),
          ],
          const SizedBox(height: 14),
          noteBox(),
        ],
      ),
    );
  }

  Widget passwordField({
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required IconData icon,
    required VoidCallback onTap,
    TextInputAction textInputAction = TextInputAction.next,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      style: const TextStyle(color: textDark, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        labelStyle: const TextStyle(color: textGrey),
        prefixIcon: Icon(icon, color: primaryGreen),
        suffixIcon: IconButton(
          onPressed: onTap,
          icon: Icon(
            hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: textGrey,
          ),
        ),
        filled: true,
        fillColor: const Color(0xffFAFAFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryGreen, width: 1.4),
        ),
      ),
    );
  }

  Widget generateButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton.icon(
        onPressed:
            isLoading
                ? null
                : () {
                  setState(() {
                    newPasswordController.text = generatePassword();
                    confirmPasswordController.text = newPasswordController.text;
                    hideNewPassword = false;
                    hideConfirmPassword = false;
                  });
                },
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: const Text(
          'Generate Password Aman',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget strengthIndicator(double strength, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kekuatan Password',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                strengthText(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LinearProgressIndicator(
              value: strength,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget passwordRules() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          ruleItem('Minimal 6 karakter', hasMinLength()),
          const SizedBox(height: 7),
          ruleItem('Mengandung huruf', hasLetter()),
          const SizedBox(height: 7),
          ruleItem('Mengandung angka', hasNumber()),
        ],
      ),
    );
  }

  Widget ruleItem(String text, bool active) {
    final color = active ? primaryGreen : textGrey;

    return Row(
      children: [
        Icon(
          active ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget matchInfo() {
    final match = isPasswordMatch();
    final color = match ? primaryGreen : redColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(
            match ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              match
                  ? 'Konfirmasi password sudah sesuai.'
                  : 'Konfirmasi password belum sama.',
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget noteBox() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'Setelah password berhasil diubah, gunakan password baru saat login berikutnya.',
        style: TextStyle(
          color: primaryGreen,
          fontSize: 12.5,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget submitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.38),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: isLoading ? null : changePassword,
            child:
                isLoading
                    ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Simpan Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget topButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Icon(icon, color: textDark),
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
