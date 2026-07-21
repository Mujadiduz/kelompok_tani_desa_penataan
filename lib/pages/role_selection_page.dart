import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_background.dart';
import 'admin_login_page.dart' as admin_login;
import 'login_page.dart' as user_login;

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color navyColor = Color(0xff17324D);
  static const Color adminBlue = Color(0xff315F9A);
  static const Color tealColor = Color(0xff28766F);
  static const Color amberColor = Color(0xffD97706);

  static const Color softGreen = Color(0xffE4F3E8);
  static const Color softBlue = Color(0xffE4F0F8);
  static const Color softTeal = Color(0xffDCEFED);
  static const Color softAmber = Color(0xffFFF0D2);

  static const Color pageBackground = Color(0xffF5F7F9);
  static const Color cardBorder = Color(0xffE2E7EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  void _openUserLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const user_login.LoginPage(),
      ),
    );
  }

  void _openAdminLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const admin_login.AdminLoginPage(),
      ),
    );
  }

  Future<void> _closeApplication() async {
    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final height = media.size.height;

    final compact = height < 700 || width < 360;
    final horizontalPadding = width < 340 ? 13.0 : 18.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (didPop) {
          return;
        }

        _closeApplication();
      },
      child: Scaffold(
        backgroundColor: pageBackground,
        body: SizedBox.expand(
          child: AppBackground(
            showPattern: false,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _RoleBackground(),
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 12 : 18,
                      horizontalPadding,
                      compact ? 18 : 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            media.size.height -
                            media.padding.top -
                            media.padding.bottom -
                            (compact ? 30 : 42),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 520,
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              _hero(compact),
                              SizedBox(
                                height: compact ? 11 : 15,
                              ),
                              _selectionCard(context, compact),
                              SizedBox(
                                height: compact ? 9 : 12,
                              ),
                              _securityCaption(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? 15 : 18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            navyColor,
            Color(0xff24536A),
            tealColor,
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.22),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              top: -58,
              right: -46,
              child: Container(
                height: 150,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 36,
              bottom: -69,
              child: Container(
                height: 114,
                width: 114,
                decoration: BoxDecoration(
                  color: const Color(
                    0xffFFD582,
                  ).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  height: compact ? 72 : 82,
                  width: compact ? 72 : 82,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: navyColor.withValues(alpha: 0.16),
                        blurRadius: 17,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
                                darkGreen,
                                primaryGreen,
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: compact ? 11 : 14),
                Text(
                  'Selamat Datang di TaniGo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 19 : 21.5,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih jenis akun untuk melanjutkan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: compact ? 10.5 : 11.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionCard(
    BuildContext context,
    bool compact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? 14 : 17,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.065),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              _HeaderIcon(),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masuk Sebagai',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Gunakan menu sesuai hak akses akun.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 15),
          _roleButton(
            icon: Icons.groups_rounded,
            title: 'Anggota Kelompok Tani',
            subtitle:
                'Akses bantuan pupuk, peminjaman alat, dan informasi desa.',
            color: primaryGreen,
            backgroundColor: softGreen,
            onTap: () {
              _openUserLogin(context);
            },
          ),
          const SizedBox(height: 10),
          _roleButton(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Administrator',
            subtitle:
                'Kelola anggota, pengajuan, inventaris, dan laporan.',
            color: adminBlue,
            backgroundColor: softBlue,
            onTap: () {
              _openAdminLogin(context);
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
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 86,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 13.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 9.7,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _securityCaption() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.91),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorder,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: tealColor,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sesi akun tetap tersimpan sampai tombol Logout digunakan.',
              style: TextStyle(
                color: textGrey,
                fontSize: 10.1,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: RoleSelectionPage.softTeal,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.account_circle_rounded,
        color: RoleSelectionPage.tealColor,
        size: 21,
      ),
    );
  }
}

class _RoleBackground extends StatelessWidget {
  const _RoleBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final base = width < height ? width : height;

          final large = (base * 1.02)
              .clamp(285.0, 470.0)
              .toDouble();

          final medium = (base * 0.72)
              .clamp(200.0, 335.0)
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
                        Color(0xffE8F1F9),
                        Color(0xffF2F8F3),
                        Color(0xffFFF5E5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -large * 0.46,
                  right: -large * 0.30,
                  child: _RoleCircle(
                    size: large,
                    color: RoleSelectionPage.softBlue,
                    alpha: 0.96,
                  ),
                ),
                Positioned(
                  top: height * 0.35,
                  left: -medium * 0.58,
                  child: _RoleCircle(
                    size: medium,
                    color: RoleSelectionPage.softGreen,
                    alpha: 0.92,
                  ),
                ),
                Positioned(
                  bottom: -large * 0.52,
                  right: -large * 0.33,
                  child: _RoleCircle(
                    size: large,
                    color: RoleSelectionPage.softAmber,
                    alpha: 0.94,
                  ),
                ),
                Positioned(
                  bottom: -medium * 0.17,
                  left: -medium * 0.53,
                  child: _RoleCircle(
                    size: medium,
                    color: RoleSelectionPage.softTeal,
                    alpha: 0.88,
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

class _RoleCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _RoleCircle({
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}