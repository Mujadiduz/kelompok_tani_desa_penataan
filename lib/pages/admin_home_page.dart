import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'jadwal_alat_admin_page.dart';
import 'kelola_alat_page.dart';
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
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

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

  int hitungMenunggu(dynamic value) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final detail = Map<dynamic, dynamic>.from(item);
        final status = (detail['status'] ?? '').toString().toLowerCase();

        if (status == 'menunggu') total++;
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
        final status = (notif['status'] ?? 'belum_dibaca').toString();
        if (status == 'belum_dibaca') total++;
      }
    }

    return total;
  }

  void bukaHalaman(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
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

                              final calonMenunggu = hitungMenunggu(
                                calonSnapshot.data?.snapshot.value,
                              );

                              final pupukTotal = hitungTotal(
                                pupukSnapshot.data?.snapshot.value,
                              );

                              final pupukMenunggu = hitungMenunggu(
                                pupukSnapshot.data?.snapshot.value,
                              );

                              final peminjamanTotal = hitungTotal(
                                peminjamanSnapshot.data?.snapshot.value,
                              );

                              final peminjamanMenunggu = hitungMenunggu(
                                peminjamanSnapshot.data?.snapshot.value,
                              );

                              final notifBelumDibaca = hitungNotifBelumDibaca(
                                notifSnapshot.data?.snapshot.value,
                              );

                              final totalMenunggu =
                                  calonMenunggu +
                                  pupukMenunggu +
                                  peminjamanMenunggu;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _headerAdmin(totalMenunggu, notifBelumDibaca),
                                  const SizedBox(height: 22),
                                  _sectionTitle('Ringkasan Data'),
                                  const SizedBox(height: 12),
                                  _summaryGrid(
                                    anggotaTotal: anggotaTotal,
                                    totalMenunggu: totalMenunggu,
                                    pupukTotal: pupukTotal,
                                    peminjamanTotal: peminjamanTotal,
                                  ),
                                  const SizedBox(height: 24),
                                  _sectionTitle('Aksi Cepat'),
                                  const SizedBox(height: 12),
                                  _quickAction(),
                                  const SizedBox(height: 24),
                                  _sectionTitle('Menu Admin'),
                                  const SizedBox(height: 12),
                                  _menuAdmin(),
                                  const SizedBox(height: 24),
                                  _sectionTitle('Status Pengajuan'),
                                  const SizedBox(height: 12),
                                  _statusPengajuan(
                                    calonMenunggu: calonMenunggu,
                                    pupukMenunggu: pupukMenunggu,
                                    peminjamanMenunggu: peminjamanMenunggu,
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
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }

  Widget _headerAdmin(int totalMenunggu, int notifBelumDibaca) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            bottom: -28,
            child: Icon(
              Icons.eco_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Admin Desa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Kelompok Tani Desa Penataan',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _notifAdminButton(notifBelumDibaca),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pending_actions_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        totalMenunggu == 0
                            ? 'Tidak ada pengajuan menunggu verifikasi'
                            : '$totalMenunggu pengajuan masih menunggu verifikasi',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

  Widget _notifAdminButton(int total) {
    return InkWell(
      onTap: () => bukaHalaman(const NotifikasiAdminPage()),
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
            ),
            child: const Icon(Icons.notifications_rounded, color: Colors.white),
          ),
          if (total > 0)
            Positioned(
              right: -5,
              top: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 1.4),
                ),
                child: Text(
                  total > 99 ? '99+' : total.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryGrid({
    required int anggotaTotal,
    required int totalMenunggu,
    required int pupukTotal,
    required int peminjamanTotal,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Anggota',
                value: anggotaTotal.toString(),
                subtitle: 'Total anggota aktif',
                icon: Icons.groups_rounded,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Pengajuan',
                value: totalMenunggu.toString(),
                subtitle: 'Menunggu proses',
                icon: Icons.assignment_late_rounded,
                color: const Color(0xffFB8C00),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Bantuan Pupuk',
                value: pupukTotal.toString(),
                subtitle: 'Total pengajuan',
                icon: Icons.grass_rounded,
                color: const Color(0xff43A047),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Peminjaman',
                value: peminjamanTotal.toString(),
                subtitle: 'Total alat dipinjam',
                icon: Icons.agriculture_rounded,
                color: const Color(0xff2F855A),
              ),
            ),
          ],
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
      constraints: const BoxConstraints(minHeight: 148),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction() {
    final actions = [
      _QuickAction(
        title: 'Anggota',
        icon: Icons.person_add_alt_1_rounded,
        page: const VerifikasiAnggotaPage(),
      ),
      _QuickAction(
        title: 'Pupuk',
        icon: Icons.eco_rounded,
        page: const VerifikasiPupukPage(),
      ),
      _QuickAction(
        title: 'Alat',
        icon: Icons.agriculture_rounded,
        page: const VerifikasiPeminjamanPage(),
      ),
      _QuickAction(
        title: 'Laporan',
        icon: Icons.description_rounded,
        page: const LaporanPage(),
      ),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = actions[index];

          return InkWell(
            onTap: () => bukaHalaman(item.page),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 96,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: Colors.white, size: 25),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _menuAdmin() {
    final menus = [
      _MenuAdmin(
        title: 'Verifikasi Anggota',
        subtitle: 'Kelola data calon anggota kelompok tani',
        icon: Icons.person_add_alt_1_rounded,
        page: const VerifikasiAnggotaPage(),
      ),
      _MenuAdmin(
        title: 'Verifikasi Bantuan Pupuk',
        subtitle: 'Cek dan proses pengajuan pupuk subsidi',
        icon: Icons.grass_rounded,
        page: const VerifikasiPupukPage(),
      ),
      _MenuAdmin(
        title: 'Verifikasi Peminjaman Alat',
        subtitle: 'Setujui atau tolak peminjaman alat',
        icon: Icons.agriculture_rounded,
        page: const VerifikasiPeminjamanPage(),
      ),
      _MenuAdmin(
        title: 'Jadwal Alat Pertanian',
        subtitle: 'Pantau jadwal penggunaan alat desa',
        icon: Icons.calendar_month_rounded,
        page: const JadwalAlatAdminPage(),
      ),
      _MenuAdmin(
        title: 'Kelola Alat Pertanian',
        subtitle: 'Tambah dan ubah data alat pertanian',
        icon: Icons.handyman_rounded,
        page: const KelolaAlatPage(),
      ),
      _MenuAdmin(
        title: 'Kelola Data Pupuk',
        subtitle: 'Atur stok dan jenis pupuk subsidi',
        icon: Icons.inventory_2_rounded,
        page: const KelolaPupukPage(),
      ),
    ];

    return Column(
      children:
          menus.map((menu) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _menuCard(menu),
            );
          }).toList(),
    );
  }

  Widget _menuCard(_MenuAdmin menu) {
    return InkWell(
      onTap: () => bukaHalaman(menu.page),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: lightGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(menu.icon, color: primaryGreen, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    menu.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: textGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPengajuan({
    required int calonMenunggu,
    required int pupukMenunggu,
    required int peminjamanMenunggu,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _statusItem(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Calon Anggota',
            total: calonMenunggu,
            color: primaryGreen,
          ),
          const Divider(height: 24),
          _statusItem(
            icon: Icons.eco_rounded,
            title: 'Bantuan Pupuk',
            total: pupukMenunggu,
            color: const Color(0xffFB8C00),
          ),
          const Divider(height: 24),
          _statusItem(
            icon: Icons.agriculture_rounded,
            title: 'Peminjaman Alat',
            total: peminjamanMenunggu,
            color: const Color(0xff2F855A),
          ),
        ],
      ),
    );
  }

  Widget _statusItem({
    required IconData icon,
    required String title,
    required int total,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:
                total > 0 ? const Color(0xffFFF3E0) : const Color(0xffE8F5E9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            total > 0 ? '$total menunggu' : 'Aman',
            style: TextStyle(
              color: total > 0 ? const Color(0xffEF6C00) : primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w800,
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
          fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(22),
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

class _MenuAdmin {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;

  const _MenuAdmin({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });
}

class _QuickAction {
  final String title;
  final IconData icon;
  final Widget page;

  const _QuickAction({
    required this.title,
    required this.icon,
    required this.page,
  });
}
