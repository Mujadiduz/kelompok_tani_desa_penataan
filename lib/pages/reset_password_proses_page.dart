import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const Color deepGreen = Color(0xff0F3D25);
  static const Color softGreen = Color(0xffF3FBF5);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE6ECE8);
  static const Color dangerColor = Color(0xffC62828);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);

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

  String nomorAnggota = '';
  String passwordTersimpan = '';

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

 String _ambilNomor(Map<String, dynamic> data) {
  final raw = data['telepon'] ?? data['no_hp'] ?? data['nomor_hp'] ?? '';
  return raw.toString().trim();
}

  String _formatNomorIndonesia(String nomor) {
    var clean = nomor.replaceAll(RegExp(r'[^0-9+]'), '');

    if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }

    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    }

    if (!clean.startsWith('62') && clean.length >= 10) {
      clean = '62$clean';
    }

    return clean;
  }

  String _pesanPassword(String passwordBaru) {
    return 'Halo ${widget.nama}, password akun TaniGo Anda sudah direset oleh admin.\n\n'
        'Password baru: $passwordBaru\n\n'
        'Silakan login menggunakan password tersebut. Setelah berhasil masuk, disarankan mengganti password kembali melalui menu profil.\n\n'
        'Terima kasih.';
  }

  Future<void> _kirimWhatsApp(String passwordBaru) async {
    final nomor = _formatNomorIndonesia(nomorAnggota);

    if (nomor.isEmpty || nomor.length < 10) {
      _showMessage('Nomor WhatsApp anggota tidak tersedia.', dangerColor);
      return;
    }

    final pesan = Uri.encodeComponent(_pesanPassword(passwordBaru));
    final uri = Uri.parse('https://wa.me/$nomor?text=$pesan');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('WhatsApp tidak dapat dibuka.', dangerColor);
    }
  }

  Future<void> _kirimSms(String passwordBaru) async {
    final nomor = _formatNomorIndonesia(nomorAnggota);

    if (nomor.isEmpty || nomor.length < 10) {
      _showMessage('Nomor SMS anggota tidak tersedia.', dangerColor);
      return;
    }

    final uri = Uri(
      scheme: 'sms',
      path: nomor,
      queryParameters: {'body': _pesanPassword(passwordBaru)},
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showMessage('Aplikasi SMS tidak dapat dibuka.', dangerColor);
    }
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
      final anggota = Map<String, dynamic>.from(data.values.first as Map);

      nomorAnggota = _ambilNomor(anggota);
      passwordTersimpan = passwordBaru;

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
      _showSuccessDialog(passwordBaru);
    } catch (_) {
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
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSuccessDialog(String passwordBaru) {
    if (!mounted) return;

    final nomorAda = _formatNomorIndonesia(nomorAnggota).length >= 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.13),
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: primaryGreen,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Password Berhasil Direset',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nomorAda
                      ? 'Password sudah disimpan. Admin dapat mengirim password baru melalui WhatsApp atau SMS.'
                      : 'Password sudah disimpan dan masuk ke notifikasi anggota. Nomor anggota tidak terdeteksi.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: softGreen,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryGreen.withValues(alpha: 0.11),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Password Baru',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        passwordBaru,
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 20,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (nomorAda) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton.icon(
                      onPressed: () => _kirimWhatsApp(passwordBaru),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text(
                        'Kirim via WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton.icon(
                      onPressed: () => _kirimSms(passwordBaru),
                      icon: const Icon(Icons.sms_outlined, size: 18),
                      label: const Text(
                        'Kirim via SMS',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: blueStatus,
                        side: BorderSide(
                          color: blueStatus.withValues(alpha: 0.38),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        color: textGrey,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset + 28),
              children: [
                _header(),
                const SizedBox(height: 14),
                _userCard(),
                const SizedBox(height: 13),
                _passwordPanel(),
                const SizedBox(height: 13),
                _securityInfoCard(),
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
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deepGreen, darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
          _backButton(),
          const SizedBox(width: 11),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.19)),
            ),
            child: const Icon(
              Icons.password_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Password',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Buat password sementara anggota',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _headerBadge(),
        ],
      ),
    );
  }

  Widget _headerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'PROSES',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _userCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 21),
      child: Row(
        children: [
          _iconBox(Icons.badge_outlined, primaryGreen),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sensorNik(widget.nik),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _miniStatusBadge(),
        ],
      ),
    );
  }

  Widget _miniStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: orangeStatus.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: orangeStatus.withValues(alpha: 0.13)),
      ),
      child: const Text(
        'RESET',
        style: TextStyle(
          color: orangeStatus,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _passwordPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.key_rounded,
            title: 'Password Sementara',
            subtitle: 'Bisa pakai otomatis atau diubah manual',
            color: primaryGreen,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.10)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: passwordController,
                  focusNode: passwordFocus,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isLoading) simpanPasswordBaru();
                  },
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17.5,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: _inputDecoration(
                    label: 'Password Baru',
                    hint: 'Contoh: TG482913',
                    icon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: primaryGreen,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  height: 45,
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
                    icon: const Icon(Icons.autorenew_rounded, size: 18),
                    label: const Text(
                      'Generate Password Baru',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryGreen,
                      side: BorderSide(
                        color: primaryGreen.withValues(alpha: 0.42),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
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

  Widget _securityInfoCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 19),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(Icons.shield_outlined, blueStatus),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keamanan Akun',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Password dikirim ke notifikasi anggota. Admin juga dapat mengirim pesan melalui WhatsApp atau SMS.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
                : const Icon(Icons.check_circle_outline_rounded),
        label: Text(
          isLoading ? 'Menyimpan...' : 'Simpan Password Baru',
          style: const TextStyle(fontSize: 14.2, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        _iconBox(icon, color),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      prefixIcon: Icon(icon, color: primaryGreen, size: 19),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        color: textGrey,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.34),
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryGreen, width: 1.4),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: isLoading ? null : () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 41,
        width: 41,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.028),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
