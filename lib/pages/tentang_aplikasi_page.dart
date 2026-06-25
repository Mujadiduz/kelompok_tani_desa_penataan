import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
            children: [
              _header(context),
              const SizedBox(height: 16),
              _appCard(),
              const SizedBox(height: 18),
              _sectionTitle(
                title: 'Fitur Utama',
                subtitle: 'Layanan yang tersedia di aplikasi',
              ),
              const SizedBox(height: 12),
              _featureCard(),
              const SizedBox(height: 18),
              _sectionTitle(
                title: 'Informasi',
                subtitle: 'Ringkasan sistem dan pengembang',
              ),
              const SizedBox(height: 12),
              _infoTile(
                icon: Icons.flag_rounded,
                title: 'Tujuan Aplikasi',
                content:
                    'Membantu administrasi Kelompok Tani Desa Penataan melalui pendataan anggota, pengajuan bantuan pupuk, peminjaman alat, pengumuman, notifikasi, dan laporan.',
                color: primaryGreen,
              ),
              const SizedBox(height: 10),
              _infoTile(
                icon: Icons.code_rounded,
                title: 'Teknologi',
                content:
                    'Dikembangkan menggunakan Flutter sebagai framework aplikasi dan Firebase Realtime Database sebagai penyimpanan data realtime.',
                color: blueStatus,
              ),
              const SizedBox(height: 10),
              _infoTile(
                icon: Icons.school_rounded,
                title: 'Pengembang',
                content:
                    'Mujaddiduz Zaman\nProgram Studi Teknik Informatika\nUniversitas Yudharta Pasuruan',
                color: orangeStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(22),
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
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentang Aplikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Informasi singkat aplikasi TaniGo.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.2,
                    height: 1.3,
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

  Widget _appCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: darkGreen,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'TaniGo',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Sistem Informasi Kelompok Tani Desa Penataan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 12.8,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: softGreen.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.13)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_rounded, color: primaryGreen, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aplikasi skripsi untuk membantu proses administrasi kelompok tani secara digital.',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12.4,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard() {
    final features = [
      _FeatureItem(
        icon: Icons.person_add_alt_1_rounded,
        title: 'Pendaftaran Anggota',
        subtitle: 'Calon anggota dapat mendaftar melalui aplikasi.',
        color: primaryGreen,
      ),
      _FeatureItem(
        icon: Icons.verified_user_rounded,
        title: 'Verifikasi Admin',
        subtitle: 'Admin memproses verifikasi data anggota dan pengajuan.',
        color: blueStatus,
      ),
      _FeatureItem(
        icon: Icons.eco_rounded,
        title: 'Bantuan Pupuk',
        subtitle: 'Anggota dapat mengajukan bantuan pupuk.',
        color: primaryGreen,
      ),
      _FeatureItem(
        icon: Icons.agriculture_rounded,
        title: 'Peminjaman Alat',
        subtitle: 'Anggota dapat mengajukan peminjaman alat pertanian.',
        color: orangeStatus,
      ),
      _FeatureItem(
        icon: Icons.campaign_rounded,
        title: 'Pengumuman',
        subtitle: 'Admin dapat membagikan informasi kepada anggota.',
        color: primaryGreen,
      ),
      _FeatureItem(
        icon: Icons.notifications_rounded,
        title: 'Notifikasi',
        subtitle: 'Anggota menerima pemberitahuan status layanan.',
        color: blueStatus,
      ),
      _FeatureItem(
        icon: Icons.description_rounded,
        title: 'Laporan',
        subtitle: 'Admin dapat melihat rekap data sistem.',
        color: orangeStatus,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          for (int i = 0; i < features.length; i++) ...[
            _featureTile(features[i]),
            if (i != features.length - 1)
              Divider(height: 24, color: cardBorder.withValues(alpha: 0.85)),
          ],
        ],
      ),
    );
  }

  Widget _featureTile(_FeatureItem item) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(item.icon, color: item.color, size: 24),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
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
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12.5,
                    height: 1.45,
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
          height: 34,
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
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
