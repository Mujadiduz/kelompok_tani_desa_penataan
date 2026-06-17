import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color softGreen = Color(0xFFEAF7EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGreen,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -60,
              child: _circle(180, primaryGreen.withValues(alpha: 0.12)),
            ),
            Positioned(
              bottom: -90,
              left: -80,
              child: _circle(220, primaryGreen.withValues(alpha: 0.10)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 36, 26, 28),
              child: Column(
                children: [
                  const Spacer(),

                  Container(
                    width: 122,
                    height: 122,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: darkGreen.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          color: primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.agriculture_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'SISTEM INFORMASI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: darkGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'KELOMPOK TANI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: darkGreen,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Text(
                      'Desa Penataan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Aplikasi administrasi kelompok tani.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                      color: darkGreen.withValues(alpha: 0.75),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: primaryGreen.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Column(
                      children: [
                        _InfoItem(
                          icon: Icons.phone_android_rounded,
                          text: 'Framework Flutter',
                        ),
                        SizedBox(height: 12),
                        _InfoItem(
                          icon: Icons.storage_rounded,
                          text: 'Firebase Realtime Database',
                        ),
                        SizedBox(height: 12),
                        _InfoItem(
                          icon: Icons.school_rounded,
                          text: 'Universitas Yudharta Pasuruan',
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        'Masuk ke Aplikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    'Kelompok Tani Desa Penataan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: darkGreen.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
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
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: primaryGreen),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF244A27),
            ),
          ),
        ),
      ],
    );
  }
}
