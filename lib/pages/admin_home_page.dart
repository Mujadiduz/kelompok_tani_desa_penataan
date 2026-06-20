import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'jadwal_alat_admin_page.dart';
import 'kelola_alat_page.dart';
import 'kelola_pengumuman_page.dart';
import 'kelola_pupuk_page.dart';
import 'laporan_page.dart';
import 'notifikasi_admin_page.dart';
import 'profil_admin_page.dart';
import 'verifikasi_anggota_page.dart';
import 'verifikasi_peminjaman_page.dart';
import 'verifikasi_pupuk_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color redStatus = Color(0xffDC2626);
  static const Color purpleStatus = Color(0xff7C3AED);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference anggotaRef;
  late final DatabaseReference calonAnggotaRef;
  late final DatabaseReference bantuanPupukRef;
  late final DatabaseReference peminjamanRef;
  late final DatabaseReference notifikasiAdminRef;

  @override
  void initState() {
    super.initState();
    anggotaRef = db.ref('anggota');
    calonAnggotaRef = db.ref('calon_anggota');
    bantuanPupukRef = db.ref('bantuan_pupuk');
    peminjamanRef = db.ref('peminjaman_alat');
    notifikasiAdminRef = db.ref('notifikasi_admin');
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
        final detail = Map<dynamic, dynamic>.from(item);
        final status =
            (detail['status'] ?? 'menunggu').toString().toLowerCase().trim();

        if (status == statusTarget) total++;
      }
    }

    return total;
  }

  int hitungNotifBelumDibaca(dynamic value) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final notif = Map<dynamic, dynamic>.from(item);
        final dibaca = notif['dibaca'];
        final status = (notif['status'] ?? '').toString().toLowerCase().trim();

        if (dibaca == false || status == 'belum_dibaca') total++;
      }
    }

    return total;
  }

  void bukaHalaman(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  String salamWaktu() {
    final jam = DateTime.now().hour;
    if (jam < 11) return 'Selamat pagi';
    if (jam < 15) return 'Selamat siang';
    if (jam < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String tanggalHariIni() {
    final now = DateTime.now();
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${now.day} ${bulan[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: _bottomNavigationBar(),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: anggotaRef.onValue,
          builder: (context, anggotaSnapshot) {
            return StreamBuilder<DatabaseEvent>(
              stream: calonAnggotaRef.onValue,
              builder: (context, calonSnapshot) {
                return StreamBuilder<DatabaseEvent>(
                  stream: bantuanPupukRef.onValue,
                  builder: (context, pupukSnapshot) {
                    return StreamBuilder<DatabaseEvent>(
                      stream: peminjamanRef.onValue,
                      builder: (context, peminjamanSnapshot) {
                        return StreamBuilder<DatabaseEvent>(
                          stream: notifikasiAdminRef.onValue,
                          builder: (context, notifSnapshot) {
                            final anggotaTotal = hitungTotal(
                              anggotaSnapshot.data?.snapshot.value,
                            );

                            final calonTotal = hitungTotal(
                              calonSnapshot.data?.snapshot.value,
                            );

                            final pupukTotal = hitungTotal(
                              pupukSnapshot.data?.snapshot.value,
                            );

                            final peminjamanTotal = hitungTotal(
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

                            final peminjamanMenunggu = hitungStatus(
                              peminjamanSnapshot.data?.snapshot.value,
                              'menunggu',
                            );

                            final notifBelumDibaca = hitungNotifBelumDibaca(
                              notifSnapshot.data?.snapshot.value,
                            );

                            final totalMenunggu =
                                calonMenunggu +
                                pupukMenunggu +
                                peminjamanMenunggu;

                            return RefreshIndicator(
                              color: primaryGreen,
                              onRefresh: () async => setState(() {}),
                              child: CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        16,
                                        18,
                                        0,
                                      ),
                                      child: _headerAdmin(
                                        totalMenunggu: totalMenunggu,
                                        notifBelumDibaca: notifBelumDibaca,
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
                                      child: _priorityPanel(
                                        calonMenunggu: calonMenunggu,
                                        pupukMenunggu: pupukMenunggu,
                                        peminjamanMenunggu: peminjamanMenunggu,
                                      ),
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        24,
                                        18,
                                        0,
                                      ),
                                      child: _sectionTitle(
                                        'Ringkasan Sistem',
                                        Icons.dashboard_customize_rounded,
                                      ),
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
                                      child: _systemSummary(
                                        anggotaTotal: anggotaTotal,
                                        calonTotal: calonTotal,
                                        pupukTotal: pupukTotal,
                                        peminjamanTotal: peminjamanTotal,
                                      ),
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        24,
                                        18,
                                        0,
                                      ),
                                      child: _sectionTitle(
                                        'Manajemen Data',
                                        Icons.apps_rounded,
                                      ),
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
                                      child: _managementGrid(),
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        24,
                                        18,
                                        30,
                                      ),
                                      child: _adminGuidePanel(totalMenunggu),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

  Widget _headerAdmin({
    required int totalMenunggu,
    required int notifBelumDibaca,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff052E16), Color(0xff14532D), Color(0xff2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -34,
            bottom: -46,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 180,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _adminAvatar(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salamWaktu(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Admin Desa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tanggalHariIni(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _notifAdminButton(notifBelumDibaca),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color:
                            totalMenunggu == 0
                                ? Colors.white.withValues(alpha: 0.18)
                                : orangeStatus.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        totalMenunggu == 0
                            ? Icons.check_circle_rounded
                            : Icons.pending_actions_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        totalMenunggu == 0
                            ? 'Seluruh pengajuan sudah diproses. Sistem dalam kondisi aman.'
                            : '$totalMenunggu pengajuan membutuhkan verifikasi admin.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.4,
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

  Widget _adminAvatar() {
    return Container(
      height: 58,
      width: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: const Icon(
        Icons.admin_panel_settings_rounded,
        color: Colors.white,
        size: 33,
      ),
    );
  }

  Widget _notifAdminButton(int total) {
    return InkWell(
      onTap: () => bukaHalaman(const NotifikasiAdminPage()),
      borderRadius: BorderRadius.circular(17),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(Icons.notifications_rounded, color: Colors.white),
          ),
          Positioned(right: -8, top: -8, child: _smallBadge(total)),
        ],
      ),
    );
  }

  Widget _smallBadge(int total) {
    if (total <= 0) return const SizedBox.shrink();

    final text = total > 99 ? '99+' : total.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 23, minHeight: 23),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: redStatus,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _priorityPanel({
    required int calonMenunggu,
    required int pupukMenunggu,
    required int peminjamanMenunggu,
  }) {
    final total = calonMenunggu + pupukMenunggu + peminjamanMenunggu;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              total == 0
                  ? [Colors.white, lightGreen]
                  : [Colors.white, const Color(0xffFFF7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xffE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color:
                      total == 0
                          ? primaryGreen.withValues(alpha: 0.12)
                          : orangeStatus.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  total == 0
                      ? Icons.check_circle_rounded
                      : Icons.priority_high_rounded,
                  color: total == 0 ? primaryGreen : orangeStatus,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prioritas Verifikasi',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Tidak ada data yang membutuhkan tindakan.'
                          : '$total data perlu segera diverifikasi.',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _priorityCard(
                  title: 'Anggota',
                  value: calonMenunggu,
                  icon: Icons.person_add_alt_1_rounded,
                  color: blueStatus,
                  page: const VerifikasiAnggotaPage(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _priorityCard(
                  title: 'Pupuk',
                  value: pupukMenunggu,
                  icon: Icons.eco_rounded,
                  color: primaryGreen,
                  page: const VerifikasiPupukPage(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _priorityCard(
                  title: 'Alat',
                  value: peminjamanMenunggu,
                  icon: Icons.agriculture_rounded,
                  color: orangeStatus,
                  page: const VerifikasiPeminjamanPage(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      onTap: () => bukaHalaman(page),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              value == 0 ? 'Aman' : 'Menunggu',
              style: TextStyle(
                color: value == 0 ? primaryGreen : orangeStatus,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: primaryGreen, size: 21),
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

  Widget _systemSummary({
    required int anggotaTotal,
    required int calonTotal,
    required int pupukTotal,
    required int peminjamanTotal,
  }) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 136,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _summaryCard(
          title: 'Anggota Aktif',
          value: anggotaTotal.toString(),
          subtitle: 'Data anggota resmi',
          icon: Icons.groups_rounded,
          color: primaryGreen,
        ),
        _summaryCard(
          title: 'Calon Anggota',
          value: calonTotal.toString(),
          subtitle: 'Data pendaftaran',
          icon: Icons.person_add_alt_1_rounded,
          color: blueStatus,
        ),
        _summaryCard(
          title: 'Bantuan Pupuk',
          value: pupukTotal.toString(),
          subtitle: 'Total pengajuan',
          icon: Icons.eco_rounded,
          color: const Color(0xff43A047),
        ),
        _summaryCard(
          title: 'Peminjaman Alat',
          value: peminjamanTotal.toString(),
          subtitle: 'Total peminjaman',
          icon: Icons.agriculture_rounded,
          color: orangeStatus,
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _managementGrid() {
    final menus = [
      _AdminMenu(
        title: 'Kelola Pupuk',
        subtitle: 'Stok & jenis pupuk',
        icon: Icons.inventory_2_rounded,
        color: primaryGreen,
        page: const KelolaPupukPage(),
      ),
      _AdminMenu(
        title: 'Kelola Alat',
        subtitle: 'Data alat pertanian',
        icon: Icons.handyman_rounded,
        color: orangeStatus,
        page: const KelolaAlatPage(),
      ),
      _AdminMenu(
        title: 'Jadwal Alat',
        subtitle: 'Pantau pemakaian',
        icon: Icons.calendar_month_rounded,
        color: blueStatus,
        page: const JadwalAlatAdminPage(),
      ),
      _AdminMenu(
        title: 'Pengumuman',
        subtitle: 'Info untuk anggota',
        icon: Icons.campaign_rounded,
        color: purpleStatus,
        page: const KelolaPengumumanPage(),
      ),
    ];

    return GridView.builder(
      itemCount: menus.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 154,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _managementCard(menus[index]),
    );
  }

  Widget _managementCard(_AdminMenu menu) {
    return InkWell(
      onTap: () => bukaHalaman(menu.page),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: menu.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(menu.icon, color: menu.color, size: 28),
            ),
            const Spacer(),
            Text(
              menu.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 14.8,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              menu.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  'Buka Menu',
                  style: TextStyle(
                    color: menu.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: menu.color, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminGuidePanel(int totalMenunggu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            bottom: -35,
            child: Icon(
              Icons.task_alt_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Arah Kerja Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                totalMenunggu == 0
                    ? 'Tidak ada verifikasi yang tertunda. Admin dapat memperbarui data pupuk, alat, jadwal, atau pengumuman desa.'
                    : 'Selesaikan verifikasi yang menunggu terlebih dahulu agar layanan anggota tetap berjalan lancar.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _guideMini(
                    icon: Icons.verified_user_rounded,
                    title: 'Verifikasi',
                    subtitle: 'Cek pengajuan',
                  ),
                  const SizedBox(width: 10),
                  _guideMini(
                    icon: Icons.campaign_rounded,
                    title: 'Informasi',
                    subtitle: 'Update berita desa',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guideMini({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 10.5,
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

  Widget _bottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: const Color(0xff9CA3AF),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            bukaHalaman(const LaporanPage());
          } else if (index == 2) {
            bukaHalaman(const ProfilAdminPage());
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_rounded),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
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

class _AdminMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _AdminMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}
