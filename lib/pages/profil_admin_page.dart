import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';
import 'tentang_aplikasi_page.dart';
import 'verifikasi_anggota_page.dart';
import 'verifikasi_peminjaman_page.dart';
import 'verifikasi_pupuk_page.dart';
import 'anggota_aktif_page.dart';
import 'data_bantuan_pupuk_page.dart';
import 'data_peminjaman_alat_page.dart';
import 'data_calon_anggota_page.dart';

class ProfilAdminPage extends StatefulWidget {
  const ProfilAdminPage({super.key});

  @override
  State<ProfilAdminPage> createState() => _ProfilAdminPageState();
}

class _ProfilAdminPageState extends State<ProfilAdminPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color redColor = Color(0xffE53935);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference anggotaRef;
  late final DatabaseReference calonRef;
  late final DatabaseReference pupukRef;
  late final DatabaseReference peminjamanRef;

  @override
  void initState() {
    super.initState();
    anggotaRef = db.ref('anggota');
    calonRef = db.ref('calon_anggota');
    pupukRef = db.ref('bantuan_pupuk');
    peminjamanRef = db.ref('peminjaman_alat');
  }

  int hitungTotal(dynamic value) {
    if (value == null || value is! Map) return 0;
    return value.length;
  }

  int hitungStatus(dynamic value, String statusTarget) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final mapItem = Map<dynamic, dynamic>.from(item);
        final status =
            (mapItem['status'] ?? 'menunggu').toString().toLowerCase().trim();

        if (status == statusTarget) total++;
      }
    }

    return total;
  }

  void _bukaHalaman(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Keluar dari Admin?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Anda akan keluar dari halaman administrator dan kembali ke halaman login.',
            style: TextStyle(color: textGrey, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: anggotaRef.onValue,
          builder: (context, anggotaSnapshot) {
            return StreamBuilder<DatabaseEvent>(
              stream: calonRef.onValue,
              builder: (context, calonSnapshot) {
                return StreamBuilder<DatabaseEvent>(
                  stream: pupukRef.onValue,
                  builder: (context, pupukSnapshot) {
                    return StreamBuilder<DatabaseEvent>(
                      stream: peminjamanRef.onValue,
                      builder: (context, peminjamanSnapshot) {
                        final totalAnggota = hitungTotal(
                          anggotaSnapshot.data?.snapshot.value,
                        );
                        final totalCalon = hitungTotal(
                          calonSnapshot.data?.snapshot.value,
                        );
                        final totalPupuk = hitungTotal(
                          pupukSnapshot.data?.snapshot.value,
                        );
                        final totalPeminjaman = hitungTotal(
                          peminjamanSnapshot.data?.snapshot.value,
                        );

                        final calonMenunggu = hitungStatus(
                          calonSnapshot.data?.snapshot.value,
                          'menunggu',
                        );
                        final pupukMenunggu = hitungStatus(
                          pupukSnapshot.data?.snapshot.value,
                          'menunggu',
                        );
                        final alatMenunggu = hitungStatus(
                          peminjamanSnapshot.data?.snapshot.value,
                          'menunggu',
                        );

                        final totalVerifikasi =
                            calonMenunggu + pupukMenunggu + alatMenunggu;

                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(child: _header(totalVerifikasi)),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  20,
                                  18,
                                  0,
                                ),
                                child: _adminInfoCard(),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  0,
                                ),
                                child: _verificationPanel(
                                  calonMenunggu: calonMenunggu,
                                  pupukMenunggu: pupukMenunggu,
                                  alatMenunggu: alatMenunggu,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  22,
                                  18,
                                  0,
                                ),
                                child: _sectionTitle('Statistik Sistem'),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  0,
                                ),
                                child: _statistikGrid(
                                  totalAnggota: totalAnggota,
                                  totalCalon: totalCalon,
                                  totalPupuk: totalPupuk,
                                  totalPeminjaman: totalPeminjaman,
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  22,
                                  18,
                                  0,
                                ),
                                child: _sectionTitle('Menu Admin'),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  0,
                                ),
                                child: _menuCard(
                                  icon: Icons.info_outline_rounded,
                                  title: 'Tentang Aplikasi',
                                  subtitle:
                                      'Lihat informasi sistem dan fitur aplikasi',
                                  color: primaryGreen,
                                  onTap: () {
                                    _bukaHalaman(const TentangAplikasiPage());
                                  },
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  30,
                                ),
                                child: _logoutCard(),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header(int totalVerifikasi) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff14532D), Color(0xff2E7D32), Color(0xff66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -44,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 165,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Profil Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 86,
                width: 86,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.38),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Administrator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Pengelola Sistem Informasi Kelompok Tani Desa Penataan.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        totalVerifikasi == 0
                            ? Icons.check_circle_rounded
                            : Icons.pending_actions_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        totalVerifikasi == 0
                            ? 'Semua data verifikasi sudah diproses.'
                            : '$totalVerifikasi data masih membutuhkan verifikasi admin.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
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
    );
  }

  Widget _adminInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(21),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: primaryGreen,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Kelompok Tani',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Akses administrator untuk mengelola anggota, bantuan pupuk, alat pertanian, dan laporan.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12.5,
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

  Widget _verificationPanel({
    required int calonMenunggu,
    required int pupukMenunggu,
    required int alatMenunggu,
  }) {
    final total = calonMenunggu + pupukMenunggu + alatMenunggu;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: total == 0 ? const Color(0xffECFDF5) : const Color(0xffFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              total == 0
                  ? primaryGreen.withValues(alpha: 0.18)
                  : orangeStatus.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color:
                      total == 0
                          ? primaryGreen.withValues(alpha: 0.13)
                          : orangeStatus.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  total == 0
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: total == 0 ? primaryGreen : orangeStatus,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Verifikasi',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Semua pengajuan sudah diproses.'
                          : '$total pengajuan masih menunggu keputusan admin.',
                      style: TextStyle(
                        color:
                            total == 0 ? primaryGreen : const Color(0xff92400E),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _miniVerifyCard(
                  title: 'Anggota',
                  value: calonMenunggu.toString(),
                  icon: Icons.person_add_alt_1_rounded,
                  color: blueStatus,
                  onTap: () => _bukaHalaman(const VerifikasiAnggotaPage()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniVerifyCard(
                  title: 'Pupuk',
                  value: pupukMenunggu.toString(),
                  icon: Icons.grass_rounded,
                  color: primaryGreen,
                  onTap: () => _bukaHalaman(const VerifikasiPupukPage()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniVerifyCard(
                  title: 'Alat',
                  value: alatMenunggu.toString(),
                  icon: Icons.agriculture_rounded,
                  color: orangeStatus,
                  onTap: () => _bukaHalaman(const VerifikasiPeminjamanPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniVerifyCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 7),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statistikGrid({
    required int totalAnggota,
    required int totalCalon,
    required int totalPupuk,
    required int totalPeminjaman,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Anggota',
                value: totalAnggota.toString(),
                icon: Icons.groups_rounded,
                color: primaryGreen,
                onTap: () => _bukaHalaman(const AnggotaAktifPage()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Calon',
                value: totalCalon.toString(),
                icon: Icons.person_add_alt_1_rounded,
                color: blueStatus,
                onTap: () => _bukaHalaman(const DataCalonAnggotaPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Bantuan Pupuk',
                value: totalPupuk.toString(),
                icon: Icons.eco_rounded,
                color: primaryGreen,
                onTap: () => _bukaHalaman(const DataBantuanPupukPage()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Peminjaman',
                value: totalPeminjaman.toString(),
                icon: Icons.agriculture_rounded,
                color: orangeStatus,
                onTap: () => _bukaHalaman(const DataPeminjamanAlatPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 124,
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_forward_rounded, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logoutCard() {
    return InkWell(
      onTap: _logout,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffFFEBEE),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: redColor.withValues(alpha: 0.20)),
          boxShadow: [
            BoxShadow(
              color: redColor.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(
              height: 54,
              width: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xffFFCDD2),
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                ),
                child: Icon(Icons.logout_rounded, color: redColor, size: 27),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keluar',
                    style: TextStyle(
                      color: redColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Akhiri sesi admin dan kembali ke halaman login',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: redColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            color: primaryGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
