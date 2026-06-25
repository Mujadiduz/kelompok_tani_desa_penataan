import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'admin_login_page.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color adminBlue = Color(0xff1D4ED8);

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final isSmallScreen = height < 720;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, isSmallScreen ? 18 : 32, 20, 24),
            children: [
              _brandHeader(isSmallScreen: isSmallScreen),
              SizedBox(height: isSmallScreen ? 24 : 34),
              _accessCard(context),
              const SizedBox(height: 18),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandHeader({required bool isSmallScreen}) {
    return Column(
      children: [
        Container(
          height: isSmallScreen ? 72 : 86,
          width: isSmallScreen ? 72 : 86,
          decoration: BoxDecoration(
            color: darkGreen,
            borderRadius: BorderRadius.circular(isSmallScreen ? 22 : 26),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.agriculture_rounded,
            color: Colors.white,
            size: isSmallScreen ? 38 : 46,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 15),
        Text(
          'TaniGo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textDark,
            fontSize: isSmallScreen ? 27 : 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Sistem Informasi Kelompok Tani\nDesa Penataan',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textGrey,
            fontSize: 12.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _accessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Masuk Sebagai',
            style: TextStyle(
              color: textDark,
              fontSize: 18.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pilih akses sesuai peran Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 12.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _roleButton(
            icon: Icons.person_rounded,
            title: 'Pengguna',
            subtitle: 'Masuk sebagai anggota atau calon anggota',
            color: primaryGreen,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
          const SizedBox(height: 11),
          _roleButton(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Administrator',
            subtitle: 'Kelola data, verifikasi, dan pengumuman',
            color: adminBlue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roleButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.13)),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 15.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.8,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 15),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, color: primaryGreen, size: 18),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Akses aman untuk pengguna dan admin',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
