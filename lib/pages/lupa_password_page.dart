import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class LupaPasswordPage extends StatefulWidget {
  const LupaPasswordPage({super.key});

  @override
  State<LupaPasswordPage> createState() => _LupaPasswordPageState();
}

class _LupaPasswordPageState extends State<LupaPasswordPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color dangerColor = Color(0xffC62828);

  final TextEditingController nikController = TextEditingController();
  final FocusNode nikFocus = FocusNode();

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference anggotaRef;
  late final DatabaseReference resetRef;
  late final DatabaseReference notifAdminRef;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    anggotaRef = db.ref('anggota');
    resetRef = db.ref('reset_password');
    notifAdminRef = db.ref('notifikasi_admin');
  }

  @override
  void dispose() {
    nikController.dispose();
    nikFocus.dispose();
    super.dispose();
  }

  Future<void> ajukanResetPassword() async {
    FocusScope.of(context).unfocus();

    final nik = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (nik.isEmpty) {
      _showMessage('NIK wajib diisi.', dangerColor);
      return;
    }

    if (nik.length != 16) {
      _showMessage('NIK harus terdiri dari 16 digit.', dangerColor);
      return;
    }

    setState(() => isLoading = true);

    try {
      final anggotaSnapshot = await anggotaRef
          .orderByChild('nik')
          .equalTo(nik)
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (!anggotaSnapshot.exists || anggotaSnapshot.value == null) {
        _showMessage('NIK tidak ditemukan sebagai anggota aktif.', dangerColor);
        return;
      }

      final anggotaData = Map<dynamic, dynamic>.from(
        anggotaSnapshot.value as Map,
      );

      final anggota = Map<String, dynamic>.from(
        anggotaData.values.first as Map,
      );

      final nama = (anggota['nama'] ?? 'Anggota').toString();
      final status = (anggota['status'] ?? '').toString().toLowerCase();

      if (status != 'aktif') {
        _showMessage('Akun anggota belum aktif.', dangerColor);
        return;
      }

      final cekReset = await resetRef
          .orderByChild('nik')
          .equalTo(nik)
          .get()
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (_masihAdaResetMenunggu(cekReset.value)) {
        _showMessage(
          'Permintaan reset password Anda masih menunggu proses admin.',
          primaryGreen,
        );
        return;
      }

      await resetRef
          .push()
          .set({
            'nik': nik,
            'nama': nama,
            'status': 'menunggu',
            'tanggal_pengajuan': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 12));

      await notifAdminRef
          .push()
          .set({
            'judul': 'Permintaan Reset Password',
            'pesan': '$nama mengajukan reset password akun anggota.',
            'tipe': 'reset_password',
            'status': 'belum_dibaca',
            'dibaca': false,
            'tanggal': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Gagal mengajukan reset password.', dangerColor);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _masihAdaResetMenunggu(dynamic value) {
    if (value == null || value is! Map) return false;

    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final reset = Map<dynamic, dynamic>.from(item);
        final status = (reset['status'] ?? '').toString().toLowerCase();

        if (status == 'menunggu') return true;
      }
    }

    return false;
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
            'Permintaan Terkirim',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Permintaan reset password berhasil dikirim ke admin. Silakan tunggu sampai admin memproses password baru Anda.',
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                _header(),
                const SizedBox(height: 16),
                _formCard(),
                const SizedBox(height: 14),
                _infoCard(),
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
            onTap: () => Navigator.pop(context),
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
              Icons.lock_reset_rounded,
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
                  'Lupa Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ajukan reset password ke admin.',
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

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Anggota',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan NIK anggota yang sudah aktif.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nikController,
            focusNode: nikFocus,
            keyboardType: TextInputType.number,
            maxLength: 16,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) ajukanResetPassword();
            },
            decoration: _inputDecoration(
              label: 'NIK',
              hint: 'Masukkan 16 digit NIK',
              icon: Icons.badge_rounded,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : ajukanResetPassword,
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
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send_rounded),
              label: Text(
                isLoading ? 'Mengirim...' : 'Kirim Permintaan',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
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
              'Admin akan memproses permintaan reset password. Setelah selesai, pemberitahuan akan masuk melalui menu notifikasi.',
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      counterText: '',
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryGreen),
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
