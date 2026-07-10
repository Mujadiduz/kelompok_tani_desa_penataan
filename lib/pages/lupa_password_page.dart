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
  static const Color deepGreen = Color(0xff0F3D25);
  static const Color softGreen = Color(0xffF3FBF5);
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
          'Permintaan reset password masih menunggu proses admin.',
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
    } catch (_) {
      if (!mounted) return;
      _showMessage('Gagal mengajukan reset password.', dangerColor);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
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
                    Icons.mark_email_read_outlined,
                    color: primaryGreen,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Permintaan Terkirim',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permintaan reset password berhasil dikirim. Silakan tunggu proses dari admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12.8,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Mengerti',
                      style: TextStyle(fontWeight: FontWeight.w900),
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
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        showPattern: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(18, 14, 18, bottomInset + 28),
              children: [
                _header(context),
                const SizedBox(height: 14),
                _mainCard(),
                const SizedBox(height: 13),
                _infoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
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
          InkWell(
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
          ),
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
              Icons.key_off_outlined,
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
                  'Lupa Password',
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
                  'Pemulihan akses akun anggota',
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
        ],
      ),
    );
  }

  Widget _mainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.badge_outlined, primaryGreen),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi NIK',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Masukkan NIK anggota aktif.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 11.8,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
              fontSize: 14.5,
              letterSpacing: 0.2,
            ),
            decoration: _inputDecoration(
              label: 'NIK',
              hint: 'Masukkan 16 digit NIK',
              icon: Icons.credit_card_rounded,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : ajukanResetPassword,
              icon:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send_outlined, color: Colors.white),
              label: Text(
                isLoading ? 'Mengirim...' : 'Kirim Permintaan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                disabledBackgroundColor: primaryGreen.withValues(alpha: 0.42),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(Icons.shield_outlined, primaryGreen),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Permintaan akan diteruskan ke admin. Setelah diproses, password baru akan dikirim melalui notifikasi akun.',
              style: TextStyle(
                color: textGrey,
                fontSize: 11.8,
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
      prefixIcon: Icon(icon, color: primaryGreen, size: 20),
      filled: true,
      fillColor: const Color(0xffF9FAFB),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryGreen, width: 1.4),
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

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
