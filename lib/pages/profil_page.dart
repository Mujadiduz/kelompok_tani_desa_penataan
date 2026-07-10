import 'package:flutter/material.dart';

import '../services/session_helper.dart';
import '../widgets/app_background.dart';
import 'data_diri_page.dart';
import 'role_selection_page.dart';
import 'tentang_aplikasi_page.dart';
import 'ubah_password_page.dart';

class ProfilPage extends StatelessWidget {
  final String nama;
  final String nik;

  const ProfilPage({super.key, required this.nama, required this.nik});

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color redColor = Color(0xffDC2626);

  String get _namaAman {
    final clean = nama.trim();
    return clean.isEmpty ? 'Anggota TaniGo' : clean;
  }

  String get _nikAman {
    final clean = nik.trim();
    return clean.isEmpty ? '-' : clean;
  }

  String get _initial {
    final clean = _namaAman.trim();
    return clean.isEmpty ? 'A' : clean[0].toUpperCase();
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Keluar dari Akun?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Anda akan kembali ke halaman awal.',
            style: TextStyle(
              color: textGrey,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await SessionHelper.clearSession();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Keluar',
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
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _header(context),
              const SizedBox(height: 14),
              _profileCard(),
              const SizedBox(height: 18),
              _sectionTitle('Akun Saya'),
              const SizedBox(height: 10),
              _menuCard(context),
              const SizedBox(height: 16),
              _logoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
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
          'Profil',
          style: TextStyle(
            color: textDark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkGreen,
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
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Center(
              child: Text(
                _initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anggota Aktif',
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _namaAman,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'NIK $_nikAman',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 12.5,
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 16.5,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _menuCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _menuTile(
            icon: Icons.badge_rounded,
            title: 'Data Diri',
            subtitle: 'Lihat informasi anggota',
            color: primaryGreen,
            onTap: () => _open(context, DataDiriPage(nik: nik)),
          ),
          _divider(),
          _menuTile(
            icon: Icons.lock_rounded,
            title: 'Ubah Password',
            subtitle: 'Ganti kata sandi akun Anda',
            color: blueStatus,
            onTap: () => _open(context, UbahPasswordPage(nik: nik)),
          ),
          _divider(),
          _menuTile(
            icon: Icons.info_outline_rounded,
            title: 'Tentang TaniGo',
            subtitle: 'Informasi aplikasi',
            color: orangeStatus,
            onTap: () => _open(context, const TentangAplikasiPage()),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 27),
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return InkWell(
      onTap: () => _confirmLogout(context),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xffFEF2F2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: redColor.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: redColor, size: 25),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'Keluar',
                style: TextStyle(
                  color: redColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: redColor),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: cardBorder.withValues(alpha: 0.90));
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
