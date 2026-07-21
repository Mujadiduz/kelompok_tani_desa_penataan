import 'package:flutter/material.dart';

import '../services/session_helper.dart';
import 'admin_home_page.dart';
import 'role_selection_page.dart';
import 'user_home_page.dart';

class SessionGatePage extends StatefulWidget {
  const SessionGatePage({super.key});

  @override
  State<SessionGatePage> createState() =>
      _SessionGatePageState();
}

class _SessionGatePageState extends State<SessionGatePage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color navy = Color(0xff17324D);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    Widget destination = const RoleSelectionPage();

    try {
      final session = await SessionHelper.getSession();

      if (session.isAdmin) {
        destination = const AdminHomePage();
      } else if (session.isUser) {
        destination = UserHomePage(
          nama: session.nama!,
          nik: session.nik!,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Gagal membaca sesi: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    /*
     * Jeda hanya untuk mencegah layar berkedip terlalu cepat.
     * Pemeriksaan sesi sudah selesai sebelum navigasi dijalankan.
     */
    await Future<void>.delayed(
      const Duration(milliseconds: 450),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => destination,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xffF3F7F4),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _SessionGateBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AppLogo(),
                    SizedBox(height: 18),
                    Text(
                      'TaniGo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: navy,
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Sistem Informasi Kelompok Tani',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xff66727F),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 26),
                    SizedBox(
                      height: 27,
                      width: 27,
                      child: CircularProgressIndicator(
                        color: primaryGreen,
                        strokeWidth: 2.8,
                      ),
                    ),
                    SizedBox(height: 11),
                    Text(
                      'Memulihkan sesi akun...',
                      style: TextStyle(
                        color: Color(0xff7A858F),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      width: 104,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(
          color: _SessionGatePageState.primaryGreen
              .withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: _SessionGatePageState.navy
                .withValues(alpha: 0.15),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image.asset(
          'assets/icon/Icon-Apps.png',
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff14532D),
                    _SessionGatePageState.primaryGreen,
                  ],
                ),
              ),
              child: Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: 52,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SessionGateBackground extends StatelessWidget {
  const _SessionGateBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final base = constraints.maxWidth <
                  constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight;

          final large = (base * 1.04)
              .clamp(300.0, 500.0)
              .toDouble();

          final medium = (base * 0.65)
              .clamp(190.0, 320.0)
              .toDouble();

          return ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xffEAF3F9),
                        Color(0xffEFF7F1),
                        Color(0xffFFF4E1),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -large * 0.49,
                  right: -large * 0.32,
                  child: _GateCircle(
                    size: large,
                    color: Color(0xffDCEAF6),
                  ),
                ),
                Positioned(
                  top: constraints.maxHeight * 0.34,
                  left: -medium * 0.57,
                  child: _GateCircle(
                    size: medium,
                    color: Color(0xffDFF0E4),
                  ),
                ),
                Positioned(
                  bottom: -large * 0.52,
                  right: -large * 0.31,
                  child: _GateCircle(
                    size: large,
                    color: Color(0xffFFF0D2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GateCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GateCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        shape: BoxShape.circle,
      ),
    );
  }
}