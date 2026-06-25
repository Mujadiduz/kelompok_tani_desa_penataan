import 'package:flutter/material.dart';

import '../services/session_helper.dart';
import 'admin_home_page.dart';
import 'role_selection_page.dart';
import 'user_home_page.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF4F7F4);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    final role = await SessionHelper.getRole();

    if (!mounted) return;

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomePage()),
      );
      return;
    }

    if (role == 'user') {
      final nik = await SessionHelper.getNik();
      final nama = await SessionHelper.getNama();

      if (!mounted) return;

      if (nik != null && nama != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserHomePage(nama: nama, nik: nik)),
        );
        return;
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          child: Column(
            children: [
              const Spacer(),
              _logo(),
              const SizedBox(height: 26),
              const Text(
                'TaniGo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkGreen,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sistem Informasi Kelompok Tani',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _desaBadge(),
              const SizedBox(height: 22),
              const Text(
                'Kelola pendaftaran anggota, bantuan pupuk, dan peminjaman alat pertanian dalam satu aplikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _infoCard(),
              const Spacer(),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: primaryGreen,
                  strokeWidth: 2.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Memuat aplikasi...',
                style: TextStyle(
                  color: darkGreen.withValues(alpha: 0.65),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Universitas Yudharta Pasuruan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: darkGreen.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 78,
          height: 78,
          decoration: const BoxDecoration(
            color: primaryGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.agriculture_rounded,
            color: Colors.white,
            size: 42,
          ),
        ),
      ),
    );
  }

  Widget _desaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.15)),
      ),
      child: const Text(
        'Desa Penataan',
        style: TextStyle(
          color: primaryGreen,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          _InfoItem(
            icon: Icons.phone_android_rounded,
            title: 'Framework',
            text: 'Flutter',
          ),
          SizedBox(height: 12),
          _InfoItem(
            icon: Icons.storage_rounded,
            title: 'Database',
            text: 'Firebase Realtime Database',
          ),
          SizedBox(height: 12),
          _InfoItem(
            icon: Icons.school_rounded,
            title: 'Program Studi',
            text: 'Teknik Informatika',
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xff2E7D32);
    const Color textDark = Color(0xff1F2937);
    const Color textGrey = Color(0xff6B7280);

    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 21, color: primaryGreen),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
