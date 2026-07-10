import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color deepGreen = Color(0xff0F3D24);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color orangeStatus = Color(0xffF59E0B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6FAF7),
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              _header(context),
              const SizedBox(height: 14),
              _identityCard(),
              const SizedBox(height: 16),
              _sectionTitle(
                title: 'Ringkasan Aplikasi',
                subtitle: 'Informasi singkat dan mudah dipahami',
              ),
              const SizedBox(height: 10),
              _summaryCard(),
              const SizedBox(height: 16),
              _sectionTitle(
                title: 'Keunggulan Sistem',
                subtitle: 'Dibuat untuk mendukung administrasi digital',
              ),
              const SizedBox(height: 10),
              _valueCard(),
              const SizedBox(height: 16),
              _sectionTitle(
                title: 'Informasi Pengembang',
                subtitle: 'Identitas akademik aplikasi',
              ),
              const SizedBox(height: 10),
              _developerCard(),
              const SizedBox(height: 16),
              _footerCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 47,
            width: 47,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentang Aplikasi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Informasi resmi aplikasi TaniGo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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

  Widget _identityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Container(
            height: 82,
            width: 82,
            decoration: BoxDecoration(
              color: deepGreen,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: deepGreen.withValues(alpha: 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 43,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'TaniGo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sistem Informasi Kelompok Tani Desa Penataan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.15)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: primaryGreen, size: 18),
                SizedBox(width: 7),
                Text(
                  'Aplikasi Administrasi Digital',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 12,
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

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            icon: Icons.flag_rounded,
            title: 'Tujuan',
            content:
                'TaniGo dibuat untuk membantu proses administrasi kelompok tani agar lebih tertata, mudah dipantau, dan efisien.',
            color: primaryGreen,
          ),
          _divider(),
          _infoRow(
            icon: Icons.phone_android_rounded,
            title: 'Penggunaan',
            content:
                'Aplikasi ini dirancang dengan tampilan sederhana sehingga dapat digunakan oleh admin dan anggota dengan mudah.',
            color: blueStatus,
          ),
          _divider(),
          _infoRow(
            icon: Icons.security_rounded,
            title: 'Pendekatan Sistem',
            content:
                'Data dikelola secara digital untuk mendukung proses pelayanan dan pencatatan yang lebih rapi.',
            color: orangeStatus,
          ),
        ],
      ),
    );
  }

  Widget _valueCard() {
    final values = [
      _ValueItem(
        icon: Icons.dashboard_customize_rounded,
        title: 'Tampilan Sederhana',
        subtitle: 'Menu dibuat ringkas dan mudah dikenali.',
        color: primaryGreen,
      ),
      _ValueItem(
        icon: Icons.fact_check_rounded,
        title: 'Data Lebih Tertata',
        subtitle: 'Membantu admin memantau kebutuhan administrasi.',
        color: blueStatus,
      ),
      _ValueItem(
        icon: Icons.notifications_active_rounded,
        title: 'Informasi Cepat',
        subtitle: 'Mendukung pemberitahuan secara langsung.',
        color: orangeStatus,
      ),
      _ValueItem(
        icon: Icons.description_rounded,
        title: 'Rekap Digital',
        subtitle: 'Mendukung pencatatan dan pelaporan aplikasi.',
        color: primaryGreen,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          for (int i = 0; i < values.length; i++) ...[
            _valueTile(values[i]),
            if (i != values.length - 1) _divider(),
          ],
        ],
      ),
    );
  }

  Widget _developerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.person_rounded,
            title: 'Nama Pengembang',
            content: 'Mujaddiduz Zaman',
            color: primaryGreen,
          ),
          _divider(),
          _infoRow(
            icon: Icons.school_rounded,
            title: 'Program Studi',
            content: 'Teknik Informatika',
            color: blueStatus,
          ),
          _divider(),
          _infoRow(
            icon: Icons.account_balance_rounded,
            title: 'Perguruan Tinggi',
            content: 'Universitas Yudharta Pasuruan',
            color: orangeStatus,
          ),
        ],
      ),
    );
  }

  Widget _footerCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'TaniGo dikembangkan sebagai media pendukung digitalisasi administrasi kelompok tani.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 12.3,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBox(icon, color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12.3,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _valueTile(_ValueItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _iconBox(item.icon, item.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.8,
                    height: 1.35,
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

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 35,
          width: 5,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }

  Widget _divider() {
    return Divider(height: 24, color: cardBorder.withValues(alpha: 0.85));
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 15,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _ValueItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ValueItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
