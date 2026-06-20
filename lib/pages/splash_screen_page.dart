import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textGrey = Color(0xff6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -70,
              child: _circle(210, primaryGreen.withValues(alpha: 0.12)),
            ),
            Positioned(
              bottom: -110,
              left: -90,
              child: _circle(250, primaryGreen.withValues(alpha: 0.10)),
            ),
            Positioned(
              top: 120,
              left: -55,
              child: _circle(120, Colors.white.withValues(alpha: 0.65)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 34, 26, 28),
              child: Column(
                children: [
                  const Spacer(),
                  _logo(),
                  const SizedBox(height: 30),
                  const Text(
                    'SISTEM INFORMASI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'KELOMPOK TANI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _desaBadge(),
                  const SizedBox(height: 28),
                  const Text(
                    'Aplikasi pendukung administrasi kelompok tani berbasis mobile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: textGrey,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _identityCard(),
                  const Spacer(),
                  _button(context),
                  const SizedBox(height: 14),
                  Text(
                    'Universitas Yudharta Pasuruan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: darkGreen.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 92,
          height: 92,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGreen, Color(0xff66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.agriculture_rounded,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _desaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Text(
        'Desa Penataan',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: primaryGreen,
        ),
      ),
    );
  }

  Widget _identityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Column(
        children: [
          _InfoItem(
            icon: Icons.phone_android_rounded,
            title: 'Framework',
            text: 'Flutter',
          ),
          SizedBox(height: 13),
          _InfoItem(
            icon: Icons.storage_rounded,
            title: 'Database',
            text: 'Firebase Realtime Database',
          ),
          SizedBox(height: 13),
          _InfoItem(
            icon: Icons.school_rounded,
            title: 'Program Studi',
            text: 'Teknik Informatika',
          ),
        ],
      ),
    );
  }

  Widget _button(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
        icon: const Icon(Icons.login_rounded),
        label: const Text(
          'Masuk ke Aplikasi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
            color: primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, size: 22, color: primaryGreen),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: textGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
