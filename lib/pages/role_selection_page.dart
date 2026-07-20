import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'admin_login_page.dart';
import 'login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color tealColor = Color(0xff28766F);

  static const Color navyColor = Color(0xff17324D);
  static const Color adminBlue = Color(0xff2F5F9A);
  static const Color amberColor = Color(0xffD97706);

  static const Color softGreen = Color(0xffE4F3E8);
  static const Color softBlue = Color(0xffE4F0F8);
  static const Color softAmber = Color(0xffFFF0D2);
  static const Color softTeal = Color(0xffDCEFED);

  static const Color bgColor = Color(0xffF5F7F9);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color borderColor = Color(0xffE2E7EC);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

    final isCompact =
        screenHeight < 700 || screenWidth < 360;

    final horizontalPadding =
        screenWidth < 340 ? 14.0 : 18.0;

    final topPadding = isCompact ? 10.0 : 16.0;
    final bottomPadding = isCompact ? 16.0 : 22.0;

    return Scaffold(
      backgroundColor: bgColor,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _RoleSelectionBackground(),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight =
                          constraints.maxHeight -
                          topPadding -
                          bottomPadding;

                      return SingleChildScrollView(
                        physics:
                            const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          topPadding,
                          horizontalPadding,
                          bottomPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: availableHeight > 0
                                ? availableHeight
                                : 0,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(
                                maxWidth: 500,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    isCompact
                                        ? MainAxisAlignment
                                            .start
                                        : MainAxisAlignment
                                            .center,
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch,
                                children: [
                                  _heroHeader(
                                    isCompact,
                                  ),
                                  SizedBox(
                                    height:
                                        isCompact ? 10 : 13,
                                  ),
                                  _selectionCard(
                                    context,
                                    isCompact,
                                  ),
                                  SizedBox(
                                    height:
                                        isCompact ? 9 : 11,
                                  ),
                                  _securityNote(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroHeader(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isCompact ? 14 : 16,
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              top: -54,
              right: -45,
              child: Container(
                height: 145,
                width: 145,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 34,
              bottom: -66,
              child: Container(
                height: 112,
                width: 112,
                decoration: BoxDecoration(
                  color: const Color(
                    0xffFFD582,
                  ).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: isCompact ? 52 : 58,
                      width: isCompact ? 52 : 58,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: navyColor.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/icon/Icon-Apps.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? 11 : 13,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TaniGo',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  isCompact ? 20 : 22,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Layanan digital kelompok tani',
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(
                                0xffDCE9EC,
                              ),
                              fontSize:
                                  isCompact ? 10.3 : 11,
                              height: 1.3,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xffFFD582,
                        ).withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(
                            0xffFFD582,
                          ).withValues(alpha: 0.24),
                        ),
                      ),
                      child: const Text(
                        'AMAN',
                        style: TextStyle(
                          color: Color(0xffFFE4AC),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: isCompact ? 11 : 13,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.11,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        color: Color(0xffFFD582),
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pilih akses sesuai peran Anda untuk melanjutkan.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.3,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }

  Widget _selectionCard(
    BuildContext context,
    bool isCompact,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isCompact ? 14 : 16,
      ),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _SectionIcon(
                icon:
                    Icons.account_circle_outlined,
                color: adminBlue,
                backgroundColor: softBlue,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Jenis Akses',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pilih sesuai kebutuhan Anda.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: isCompact ? 13 : 15,
          ),
          _roleButton(
            icon: Icons.person_rounded,
            badge: 'ANGGOTA',
            title: 'Pengguna',
            subtitle:
                'Masuk, daftar, atau cek status keanggotaan.',
            helperText: 'Untuk anggota kelompok tani',
            color: primaryGreen,
            backgroundColor: softGreen,
            isCompact: isCompact,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
              );
            },
          ),
          SizedBox(
            height: isCompact ? 9 : 10,
          ),
          _roleButton(
            icon:
                Icons.admin_panel_settings_rounded,
            badge: 'PENGELOLA',
            title: 'Administrator',
            subtitle:
                'Kelola anggota dan data aplikasi.',
            helperText: 'Untuk pengelola resmi',
            color: adminBlue,
            backgroundColor: softBlue,
            isCompact: isCompact,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AdminLoginPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _roleButton({
    required IconData icon,
    required String badge,
    required String title,
    required String subtitle,
    required String helperText,
    required Color color,
    required Color backgroundColor,
    required bool isCompact,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: 'Masuk sebagai $title',
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow =
                  constraints.maxWidth < 330;

              return Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight:
                      isCompact ? 88 : 94,
                ),
                padding: EdgeInsets.all(
                  isCompact ? 11 : 13,
                ),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: color.withValues(
                      alpha: 0.15,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: isCompact ? 45 : 49,
                      width: isCompact ? 45 : 49,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: color.withValues(
                            alpha: 0.09,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 9,
                            offset:
                                const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: isCompact ? 23 : 25,
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? 10 : 12,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color: textDark,
                                    fontSize: 13.8,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors.white
                                      .withValues(
                                    alpha: 0.86,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(999),
                                ),
                                child: Text(
                                  badge,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 7.2,
                                    fontWeight:
                                        FontWeight.w900,
                                    letterSpacing: 0.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines:
                                isNarrow ? 2 : 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textGrey,
                              fontSize: 10.2,
                              height: 1.3,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            helperText,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontSize: 9.3,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: isCompact ? 7 : 9,
                    ),
                    Container(
                      height: isCompact ? 32 : 35,
                      width: isCompact ? 32 : 35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 7,
                            offset:
                                const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _securityNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.91,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(
              alpha: 0.035,
            ),
            blurRadius: 11,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shield_outlined,
            color: primaryGreen,
            size: 17,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pastikan memilih akses sesuai peran Anda.',
              style: TextStyle(
                color: textGrey,
                fontSize: 10.2,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.97,
      ),
      borderRadius: BorderRadius.circular(23),
      border: Border.all(
        color: borderColor,
      ),
      boxShadow: [
        BoxShadow(
          color: navyColor.withValues(
            alpha: 0.065,
          ),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _SectionIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: 0.09),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}

class _RoleSelectionBackground
    extends StatelessWidget {
  const _RoleSelectionBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth =
                constraints.maxWidth;

            final screenHeight =
                constraints.maxHeight;

            final baseSize =
                screenWidth < screenHeight
                    ? screenWidth
                    : screenHeight;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(280.0, 450.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.72)
                    .clamp(210.0, 330.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.43)
                    .clamp(130.0, 210.0)
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
                          Color(0xffF2F8F3),
                          Color(0xffFFF5E4),
                        ],
                        stops: [
                          0,
                          0.53,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -largeCircle * 0.44,
                    right: -largeCircle * 0.29,
                    child: _RoleBackgroundCircle(
                      size: largeCircle,
                      color:
                          RoleSelectionPage.softBlue,
                      borderColor:
                          RoleSelectionPage.adminBlue,
                      alpha: 0.98,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.18,
                    right: -smallCircle * 0.04,
                    child: _RoleBackgroundRing(
                      size: smallCircle,
                      color:
                          RoleSelectionPage.adminBlue,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.31,
                    left: -mediumCircle * 0.58,
                    child: _RoleBackgroundCircle(
                      size: mediumCircle,
                      color:
                          RoleSelectionPage.softGreen,
                      borderColor:
                          RoleSelectionPage
                              .primaryGreen,
                      alpha: 0.95,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.52,
                    right: -smallCircle * 0.56,
                    child: _RoleBackgroundCircle(
                      size: smallCircle * 1.15,
                      color:
                          RoleSelectionPage.softTeal,
                      borderColor:
                          RoleSelectionPage.tealColor,
                      alpha: 0.88,
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.52,
                    right: -largeCircle * 0.32,
                    child: _RoleBackgroundCircle(
                      size: largeCircle * 1.04,
                      color:
                          RoleSelectionPage.softAmber,
                      borderColor:
                          RoleSelectionPage.amberColor,
                      alpha: 0.96,
                    ),
                  ),
                  Positioned(
                    bottom: -mediumCircle * 0.18,
                    left: -mediumCircle * 0.52,
                    child: _RoleBackgroundCircle(
                      size: mediumCircle,
                      color:
                          RoleSelectionPage.softTeal,
                      borderColor:
                          RoleSelectionPage.tealColor,
                      alpha: 0.88,
                    ),
                  ),
                  Positioned(
                    bottom: smallCircle * 0.06,
                    right: -smallCircle * 0.10,
                    child: _RoleBackgroundRing(
                      size: smallCircle,
                      color:
                          RoleSelectionPage.amberColor,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.41,
                    left: 14,
                    child: Transform.rotate(
                      angle: -0.42,
                      child: Container(
                        height: 43,
                        width: 110,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.36,
                          ),
                          borderRadius:
                              BorderRadius.circular(999),
                          border: Border.all(
                            color: RoleSelectionPage
                                .primaryGreen
                                .withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.13,
                    left: 20,
                    child: Transform.rotate(
                      angle: 0.42,
                      child: Container(
                        height: 39,
                        width: 104,
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.36,
                          ),
                          borderRadius:
                              BorderRadius.circular(999),
                          border: Border.all(
                            color: RoleSelectionPage
                                .tealColor
                                .withValues(alpha: 0.09),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 108,
                    left: 28,
                    child: _RoleBackgroundDot(
                      size: 9,
                      color:
                          RoleSelectionPage.adminBlue,
                    ),
                  ),
                  const Positioned(
                    top: 164,
                    left: 62,
                    child: _RoleBackgroundDot(
                      size: 6,
                      color: RoleSelectionPage
                          .primaryGreen,
                    ),
                  ),
                  const Positioned(
                    bottom: 122,
                    right: 48,
                    child: _RoleBackgroundDot(
                      size: 9,
                      color:
                          RoleSelectionPage.amberColor,
                    ),
                  ),
                  const Positioned(
                    bottom: 72,
                    right: 98,
                    child: _RoleBackgroundDot(
                      size: 6,
                      color:
                          RoleSelectionPage.tealColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleBackgroundCircle
    extends StatelessWidget {
  final double size;
  final Color color;
  final Color borderColor;
  final double alpha;

  const _RoleBackgroundCircle({
    required this.size,
    required this.color,
    required this.borderColor,
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
        border: Border.all(
          color: borderColor.withValues(
            alpha: 0.07,
          ),
          width: 2,
        ),
      ),
    );
  }
}

class _RoleBackgroundRing
    extends StatelessWidget {
  final double size;
  final Color color;

  const _RoleBackgroundRing({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }
}

class _RoleBackgroundDot
    extends StatelessWidget {
  final double size;
  final Color color;

  const _RoleBackgroundDot({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        shape: BoxShape.circle,
      ),
    );
  }
}