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
  static const Color orangeStatus = Color(0xffFB8C00);

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
          .update({
            'password': passwordBaru,
            'tanggal_ubah_password': DateTime.now().toIso8601String(),
          })
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

  double kekuatanPassword() {
    final password = passwordBaruController.text.trim();

    double score = 0;

    if (password.length >= 6) score += 0.30;
    if (password.length >= 8) score += 0.20;
    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.20;

    if (score > 1) return 1;
    return score;
  }

  String teksKekuatanPassword() {
    final score = kekuatanPassword();

    if (passwordBaruController.text.trim().isEmpty) return 'Belum diisi';
    if (score < 0.35) return 'Lemah';
    if (score < 0.70) return 'Cukup';
    return 'Kuat';
  }

  Color warnaKekuatanPassword() {
    final score = kekuatanPassword();

    if (passwordBaruController.text.trim().isEmpty) return textGrey;
    if (score < 0.35) return Colors.red;
    if (score < 0.70) return orangeStatus;
    return primaryGreen;
  }

  bool passwordSama() {
    if (konfirmasiPasswordController.text.trim().isEmpty) return false;
    return passwordBaruController.text.trim() ==
        konfirmasiPasswordController.text.trim();
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

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
    final strength = kekuatanPassword();
    final strengthColor = warnaKekuatanPassword();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: _securityCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                child: _formCard(strength, strengthColor),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _submitBar(),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff14532D), Color(0xff2E7D32), Color(0xff66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            bottom: -42,
            child: Icon(
              Icons.lock_reset_rounded,
              size: 160,
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Keamanan Akun',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Gunakan password yang mudah diingat tetapi tetap aman untuk menjaga akun anggota.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.security_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'NIK: ${widget.nik}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
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
      onTap: isLoading ? null : () => Navigator.pop(context),
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

  Widget _securityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Validasi Password Lama',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Sistem akan mencocokkan password lama sebelum menyimpan password baru.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.4,
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

  Widget _formCard(double strength, Color strengthColor) {
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
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan password lama dan buat password baru untuk akun Anda.',
            style: TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          _passwordField(
            label: 'Password Lama',
            controller: passwordLamaController,
            hidden: hidePasswordLama,
            icon: Icons.lock_outline_rounded,
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
            icon: Icons.lock_reset_rounded,
            onChanged: (_) => setState(() {}),
            onTap: () {
              setState(() {
                hidePasswordBaru = !hidePasswordBaru;
              });
            },
          ),
          const SizedBox(height: 12),
          _strengthIndicator(strength, strengthColor),
          const SizedBox(height: 14),
          _passwordField(
            label: 'Konfirmasi Password Baru',
            controller: konfirmasiPasswordController,
            hidden: hideKonfirmasiPassword,
            icon: Icons.verified_rounded,
            onChanged: (_) => setState(() {}),
            onTap: () {
              setState(() {
                hideKonfirmasiPassword = !hideKonfirmasiPassword;
              });
            },
          ),
          if (konfirmasiPasswordController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _matchPasswordInfo(),
          ],
          const SizedBox(height: 16),
          _noteBox(),
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool hidden,
    required IconData icon,
    required VoidCallback onTap,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      decoration: _inputDecoration(label, icon).copyWith(
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

  Widget _strengthIndicator(double strength, Color color) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
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
                teksKekuatanPassword(),
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

  Widget _matchPasswordInfo() {
    final cocok = passwordSama();
    final color = cocok ? primaryGreen : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(
            cocok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cocok
                  ? 'Konfirmasi password sudah sesuai.'
                  : 'Konfirmasi password belum sama.',
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
              'Password baru minimal 6 karakter. Gunakan kombinasi huruf dan angka agar lebih aman.',
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

  Widget _submitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.45),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
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
              isLoading ? 'Menyimpan Password...' : 'Simpan Password',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
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
