import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'alat_page.dart';
import 'notifikasi_page.dart';
import 'profil_page.dart';
import 'pupuk_page.dart';
import 'riwayat_page.dart';

class UserHomePage extends StatefulWidget {
  final String nama;
  final String nik;

  const UserHomePage({super.key, required this.nama, required this.nik});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  List<Map<String, dynamic>> ambilDataByNik(dynamic value, String nikUser) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.values
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((item) {
              final nikData = (item['nik'] ?? '').toString().trim();
              return nikData == nikUser.trim();
            })
            .toList();

    return list.reversed.toList();
  }

  List<Map<String, dynamic>> ambilDataMenunggu(dynamic value, String nikUser) {
    return ambilDataByNik(value, nikUser).where((item) {
      final status = (item['status'] ?? 'menunggu').toString().toLowerCase();
      return status == 'menunggu';
    }).toList();
  }

  int hitungNotifBelumDibaca(dynamic value) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final notif = Map<dynamic, dynamic>.from(item);
        final status = (notif['status'] ?? 'belum_dibaca').toString();
        if (status == 'belum_dibaca') {
          total++;
        }
      }
    }

    return total;
  }

  void bukaHalaman(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final bantuanRef = db.ref('bantuan_pupuk');
    final peminjamanRef = db.ref('peminjaman_alat');
    final notifikasiRef = db.ref('notifikasi').child(widget.nik);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: bantuanRef.onValue,
          builder: (context, bantuanSnapshot) {
            return StreamBuilder<DatabaseEvent>(
              stream: peminjamanRef.onValue,
              builder: (context, peminjamanSnapshot) {
                return StreamBuilder<DatabaseEvent>(
                  stream: notifikasiRef.onValue,
                  builder: (context, notifSnapshot) {
                    final semuaBantuan = ambilDataByNik(
                      bantuanSnapshot.data?.snapshot.value,
                      widget.nik,
                    );

                    final semuaPeminjaman = ambilDataByNik(
                      peminjamanSnapshot.data?.snapshot.value,
                      widget.nik,
                    );

                    final bantuanMenunggu = ambilDataMenunggu(
                      bantuanSnapshot.data?.snapshot.value,
                      widget.nik,
                    );

                    final peminjamanMenunggu = ambilDataMenunggu(
                      peminjamanSnapshot.data?.snapshot.value,
                      widget.nik,
                    );

                    final totalMenunggu =
                        bantuanMenunggu.length + peminjamanMenunggu.length;

                    final totalNotifBelumDibaca = hitungNotifBelumDibaca(
                      notifSnapshot.data?.snapshot.value,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _header(totalMenunggu, totalNotifBelumDibaca),
                          const SizedBox(height: 22),
                          _statusCard(),
                          const SizedBox(height: 22),
                          _sectionTitle('Ringkasan Aktivitas'),
                          const SizedBox(height: 12),
                          _summaryGrid(
                            bantuanTotal: semuaBantuan.length,
                            peminjamanTotal: semuaPeminjaman.length,
                            totalMenunggu: totalMenunggu,
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle('Menu Utama'),
                          const SizedBox(height: 12),
                          _quickMenu(),
                          const SizedBox(height: 24),
                          _prosesSection(
                            bantuanList: bantuanMenunggu,
                            peminjamanList: peminjamanMenunggu,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header(int totalMenunggu, int totalNotifBelumDibaca) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -34,
            child: Icon(
              Icons.eco_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.08),
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
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat Datang,',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Sistem Informasi Kelompok Tani Desa Penataan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _notifButton(totalNotifBelumDibaca),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(14),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalMenunggu == 0
                                ? 'Tidak ada pengajuan menunggu'
                                : '$totalMenunggu pengajuan menunggu verifikasi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Bantuan pupuk dan peminjaman alat',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _notifButton(int totalNotifBelumDibaca) {
    return InkWell(
      onTap: () {
        bukaHalaman(NotifikasiPage(nik: widget.nik));
      },
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          if (totalNotifBelumDibaca > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  totalNotifBelumDibaca > 99
                      ? '99+'
                      : totalNotifBelumDibaca.toString(),
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

  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Keanggotaan',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Aktif sebagai anggota kelompok tani\nNIK: ${widget.nik}',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'AKTIF',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid({
    required int bantuanTotal,
    required int peminjamanTotal,
    required int totalMenunggu,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Bantuan',
            value: bantuanTotal.toString(),
            subtitle: 'Lihat pupuk',
            icon: Icons.grass_rounded,
            color: primaryGreen,
            onTap: () {
              bukaHalaman(PupukPage(nama: widget.nama, nik: widget.nik));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            title: 'Peminjaman',
            value: peminjamanTotal.toString(),
            subtitle: 'Lihat alat',
            icon: Icons.agriculture_rounded,
            color: const Color(0xff2F855A),
            onTap: () {
              bukaHalaman(AlatPage(nama: widget.nama, nik: widget.nik));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            title: 'Proses',
            value: totalMenunggu.toString(),
            subtitle: 'Lihat riwayat',
            icon: Icons.hourglass_top_rounded,
            color: orangeStatus,
            onTap: () {
              bukaHalaman(RiwayatPage(nik: widget.nik));
            },
          ),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(13),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: textDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: textGrey, fontSize: 10),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, size: 14, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickMenu() {
    final menus = [
      _HomeMenu(
        title: 'Bantuan Pupuk',
        subtitle: 'Ajukan kebutuhan pupuk subsidi',
        icon: Icons.eco_rounded,
        color: primaryGreen,
        page: PupukPage(nama: widget.nama, nik: widget.nik),
      ),
      _HomeMenu(
        title: 'Peminjaman Alat',
        subtitle: 'Pinjam alat pertanian desa',
        icon: Icons.agriculture_rounded,
        color: const Color(0xffFB8C00),
        page: AlatPage(nama: widget.nama, nik: widget.nik),
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

  Widget _menuCard(_HomeMenu menu) {
    return InkWell(
      onTap: () => bukaHalaman(menu.page),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: menu.color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(menu.icon, color: menu.color, size: 28),
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
                      fontSize: 15,
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

  Widget _prosesSection({
    required List<Map<String, dynamic>> bantuanList,
    required List<Map<String, dynamic>> peminjamanList,
  }) {
    final total = bantuanList.length + peminjamanList.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffFED7AA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _prosesHeader(total),
          const SizedBox(height: 12),
          if (total == 0)
            const Text(
              'Tidak ada pengajuan yang sedang diproses. Data yang sudah disetujui atau ditolak dapat dilihat pada menu Riwayat.',
              style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
            ),
          ...bantuanList.map(
            (item) => _prosesCard(
              icon: Icons.grass_rounded,
              color: primaryGreen,
              title: 'Bantuan Pupuk',
              subtitle:
                  'Jenis: ${item['jenis_pupuk'] ?? '-'} • Jumlah: ${item['jumlah_pupuk'] ?? item['jumlah'] ?? '-'} Kg',
            ),
          ),
          ...peminjamanList.map(
            (item) => _prosesCard(
              icon: Icons.agriculture_rounded,
              color: orangeStatus,
              title: 'Peminjaman Alat',
              subtitle:
                  'Alat: ${item['alat'] ?? item['nama_alat'] ?? '-'} • Pinjam: ${item['tanggal_pinjam'] ?? '-'}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _prosesHeader(int total) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: orangeStatus.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.hourglass_top_rounded, color: orangeStatus),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sedang Diproses',
                style: TextStyle(
                  color: textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                total == 0
                    ? 'Belum ada pengajuan menunggu'
                    : '$total pengajuan menunggu persetujuan admin',
                style: const TextStyle(color: textGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _prosesCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffFDE68A)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: orangeStatus.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Menunggu',
              style: TextStyle(
                color: orangeStatus,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
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

  Widget _bottomNav() {
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
            bukaHalaman(RiwayatPage(nik: widget.nik));
          } else if (index == 2) {
            bukaHalaman(ProfilPage(nama: widget.nama, nik: widget.nik));
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
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

class _HomeMenu {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _HomeMenu({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}
