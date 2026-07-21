import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({
    super.key,
  });

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color deepTeal = Color(0xff0E5F57);
  static const Color teal = Color(0xff167A6B);
  static const Color tealLight = Color(0xff248C76);
  static const Color blue = Color(0xff326FA3);
  static const Color amber = Color(0xffD98212);
  static const Color purple = Color(0xff7159B4);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color softBlue = Color(0xffEAF3FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softPurple = Color(0xffF0ECFA);

  static const Color pageBackground = Color(0xffF2F7F5);
  static const Color cardBorder = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 340 ? 13.0 : 17.0;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _UserDashboardBackground(),
                SafeArea(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      13,
                      horizontalPadding,
                      30,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 720,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              _header(context),
                              const SizedBox(height: 14),
                              _identityCard(),
                              const SizedBox(height: 14),
                              _summaryCard(),
                              const SizedBox(height: 14),
                              _featureCard(),
                              const SizedBox(height: 14),
                              _developerCard(),
                              const SizedBox(height: 14),
                              _footerCard(),
                              const SizedBox(height: 12),
                              _copyrightCaption(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepTeal,
            teal,
            tealLight,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -38,
              top: -45,
              child: Container(
                height: 105,
                width: 105,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tentang TaniGo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Informasi aplikasi dan pengembang',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xffD1FAE5),
                          fontSize: 10.7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        17,
        16,
        16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepTeal,
            teal,
            tealLight,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.23),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            Positioned(
              right: -58,
              top: -72,
              child: Container(
                height: 170,
                width: 170,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -42,
              bottom: -82,
              child: Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  color: const Color(0xffB9E8D7)
                      .withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      height: 67,
                      width: 67,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.60),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: deepTeal.withValues(alpha: 0.13),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        color: deepTeal,
                        size: 35,
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SISTEM INFORMASI',
                            style: TextStyle(
                              color: Color(0xffBFF2D4),
                              fontSize: 8.8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'TaniGo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Kelompok Tani Desa Penataan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xffD1FAE5),
                              fontSize: 10.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Color(0xffC9F3DC),
                        size: 17,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aplikasi administrasi digital untuk mendukung '
                          'pelayanan kelompok tani.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                const Row(
                  children: [
                    Expanded(
                      child: _IdentityStatus(
                        icon: Icons.phone_android_rounded,
                        label: 'Platform',
                        value: 'Mobile',
                        color: Color(0xffC9F3DC),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _IdentityStatus(
                        icon: Icons.cloud_done_outlined,
                        label: 'Penyimpanan',
                        value: 'Digital',
                        color: Color(0xffBFDDF5),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _IdentityStatus(
                        icon: Icons.groups_rounded,
                        label: 'Pengguna',
                        value: 'Admin & Anggota',
                        color: Color(0xffFFE0A5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        15,
      ),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.description_outlined,
            title: 'Ringkasan Aplikasi',
            subtitle:
                'Tujuan dan cara kerja TaniGo secara singkat.',
            color: teal,
            backgroundColor: softTeal,
          ),
          const SizedBox(height: 13),
          _infoRow(
            icon: Icons.flag_outlined,
            title: 'Tujuan',
            content:
                'TaniGo membantu proses administrasi kelompok tani '
                'agar lebih tertata, mudah dipantau, dan efisien.',
            color: primaryGreen,
            backgroundColor: softGreen,
          ),
          const SizedBox(height: 9),
          _infoRow(
            icon: Icons.touch_app_outlined,
            title: 'Penggunaan',
            content:
                'Aplikasi dirancang dengan alur sederhana agar mudah '
                'digunakan oleh admin maupun anggota.',
            color: blue,
            backgroundColor: softBlue,
          ),
          const SizedBox(height: 9),
          _infoRow(
            icon: Icons.security_outlined,
            title: 'Pendekatan Sistem',
            content:
                'Data dikelola secara digital untuk mendukung pelayanan, '
                'pencatatan, dan pemantauan yang lebih rapi.',
            color: amber,
            backgroundColor: softAmber,
          ),
        ],
      ),
    );
  }

  Widget _featureCard() {
    const features = [
      _FeatureItem(
        icon: Icons.dashboard_customize_rounded,
        title: 'Tampilan Sederhana',
        subtitle: 'Menu dibuat ringkas dan mudah dikenali.',
        color: primaryGreen,
        backgroundColor: softGreen,
      ),
      _FeatureItem(
        icon: Icons.fact_check_outlined,
        title: 'Data Lebih Tertata',
        subtitle: 'Informasi administrasi tersimpan lebih rapi.',
        color: blue,
        backgroundColor: softBlue,
      ),
      _FeatureItem(
        icon: Icons.notifications_active_outlined,
        title: 'Informasi Cepat',
        subtitle: 'Pemberitahuan dapat diterima secara langsung.',
        color: amber,
        backgroundColor: softAmber,
      ),
      _FeatureItem(
        icon: Icons.receipt_long_outlined,
        title: 'Rekap Digital',
        subtitle: 'Mendukung pencatatan dan pelaporan aplikasi.',
        color: purple,
        backgroundColor: softPurple,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        15,
      ),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.auto_awesome_rounded,
            title: 'Keunggulan Sistem',
            subtitle:
                'Fitur utama yang mendukung administrasi digital.',
            color: purple,
            backgroundColor: softPurple,
          ),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, constraints) {
              final useGrid = constraints.maxWidth >= 330;

              if (!useGrid) {
                return Column(
                  children: [
                    for (int index = 0;
                        index < features.length;
                        index++) ...[
                      _featureTile(features[index]),
                      if (index != features.length - 1)
                        const SizedBox(height: 9),
                    ],
                  ],
                );
              }

              final itemWidth =
                  (constraints.maxWidth - 9) / 2;

              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  for (final item in features)
                    SizedBox(
                      width: itemWidth,
                      child: _featureTile(item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _developerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        15,
      ),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.code_rounded,
            title: 'Informasi Pengembang',
            subtitle:
                'Identitas akademik pengembangan aplikasi.',
            color: blue,
            backgroundColor: softBlue,
          ),
          const SizedBox(height: 13),
          _developerRow(
            icon: Icons.person_outline_rounded,
            label: 'Nama Pengembang',
            value: 'Mujaddiduz Zaman',
            color: teal,
          ),
          _divider(),
          _developerRow(
            icon: Icons.school_outlined,
            label: 'Program Studi',
            value: 'Teknik Informatika',
            color: blue,
          ),
          _divider(),
          _developerRow(
            icon: Icons.account_balance_outlined,
            label: 'Perguruan Tinggi',
            value: 'Universitas Yudharta Pasuruan',
            color: amber,
          ),
        ],
      ),
    );
  }

  Widget _footerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepTeal,
            teal,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digitalisasi untuk Kelompok Tani',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TaniGo dikembangkan sebagai media pendukung '
                  'administrasi kelompok tani yang lebih modern.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 10.5,
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

  Widget _copyrightCaption() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.agriculture_outlined,
          color: textSoft,
          size: 14,
        ),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            'TaniGo • Sistem Informasi Kelompok Tani',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSoft,
              fontSize: 9.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.08),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10.2,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.11),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.3,
                    height: 1.42,
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

  Widget _featureTile(_FeatureItem item) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 125,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.color.withValues(alpha: 0.11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 41,
            width: 41,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.93),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 21,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 12.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 9.9,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _developerRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            height: 41,
            width: 41,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12.8,
                    height: 1.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 12,
      color: cardBorder,
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 20,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: deepTeal.withValues(alpha: 0.055),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _IdentityStatus extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _IdentityStatus({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.6,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 7.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
  });
}

class _UserDashboardBackground extends StatelessWidget {
  const _UserDashboardBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final baseSize =
                width < height ? width : height;

            final largeCircle = (baseSize * 0.98)
                .clamp(280.0, 460.0)
                .toDouble();

            final mediumCircle = (baseSize * 0.68)
                .clamp(190.0, 330.0)
                .toDouble();

            final smallCircle = (baseSize * 0.42)
                .clamp(120.0, 205.0)
                .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xff0E5F57),
                          Color(0xff177A6B),
                          Color(0xffDDEFEA),
                          Color(0xffF2F7F5),
                        ],
                        stops: [
                          0,
                          0.22,
                          0.49,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -largeCircle * 0.54,
                    right: -largeCircle * 0.29,
                    child: _DashboardCircle(
                      size: largeCircle,
                      color: const Color(0xff53B69C),
                      alpha: 0.20,
                      borderColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.12,
                    left: -smallCircle * 0.24,
                    child: _DashboardRing(
                      size: smallCircle,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: height * 0.28,
                    left: -mediumCircle * 0.57,
                    child: _DashboardCircle(
                      size: mediumCircle,
                      color: const Color(0xffA9DCCF),
                      alpha: 0.38,
                      borderColor:
                          const Color(0xff167A6B),
                    ),
                  ),
                  Positioned(
                    top: height * 0.48,
                    right: -mediumCircle * 0.61,
                    child: _DashboardCircle(
                      size: mediumCircle * 1.08,
                      color: const Color(0xffE6F2F8),
                      alpha: 0.84,
                      borderColor:
                          const Color(0xff326FA3),
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.52,
                    left: -largeCircle * 0.30,
                    child: _DashboardCircle(
                      size: largeCircle,
                      color: const Color(0xffDDEFE5),
                      alpha: 0.82,
                      borderColor:
                          const Color(0xff2E7D32),
                    ),
                  ),
                  Positioned(
                    bottom: -mediumCircle * 0.36,
                    right: -mediumCircle * 0.43,
                    child: _DashboardCircle(
                      size: mediumCircle,
                      color: const Color(0xffEAF3FA),
                      alpha: 0.88,
                      borderColor:
                          const Color(0xff326FA3),
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

class _DashboardCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  final Color borderColor;

  const _DashboardCircle({
    required this.size,
    required this.color,
    required this.alpha,
    required this.borderColor,
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
          color: borderColor.withValues(alpha: 0.08),
          width: 2,
        ),
      ),
    );
  }
}

class _DashboardRing extends StatelessWidget {
  final double size;
  final Color color;

  const _DashboardRing({
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
