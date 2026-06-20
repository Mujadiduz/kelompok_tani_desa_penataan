import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'alat_page.dart';
import 'notifikasi_page.dart';
import 'pengumuman_page.dart';
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
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color redStatus = Color(0xffDC2626);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  List<Map<String, dynamic>> ambilDataByNik(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    return data.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) {
          final nikData = (item['nik'] ?? '').toString().trim();
          return nikData == widget.nik.trim();
        })
        .toList()
        .reversed
        .toList();
  }

  List<Map<String, dynamic>> filterStatus(
    List<Map<String, dynamic>> data,
    List<String> statusList,
  ) {
    return data.where((item) {
      final status = (item['status'] ?? 'menunggu').toString().toLowerCase();
      return statusList.contains(status);
    }).toList();
  }

  int hitungNotifBelumDibaca(dynamic value) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final notif = Map<dynamic, dynamic>.from(item);
        final status = (notif['status'] ?? '').toString();
        final dibaca = notif['dibaca'];

        if (status == 'belum_dibaca' || dibaca == false) {
          total++;
        }
      }
    }

    return total;
  }

  List<Map<String, dynamic>> ambilPengumumanAktif(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final item = Map<String, dynamic>.from(entry.value);
              item['id'] = entry.key.toString();
              return item;
            })
            .where((item) {
              final status = (item['status'] ?? '').toString().toLowerCase();
              return status == 'aktif';
            })
            .toList();

    list.sort((a, b) {
      final waktuA = _nilaiWaktuPengumuman(a);
      final waktuB = _nilaiWaktuPengumuman(b);
      return waktuB.compareTo(waktuA);
    });

    return list;
  }

  int _nilaiWaktuPengumuman(Map<String, dynamic> item) {
    final createdAt = item['created_at'] ?? item['createdAt'] ?? item['waktu'];

    if (createdAt is int) return createdAt;
    if (createdAt is double) return createdAt.toInt();

    final tanggal = (item['tanggal'] ?? item['tgl'] ?? '').toString();
    final parsed = DateTime.tryParse(tanggal);
    return parsed?.millisecondsSinceEpoch ?? 0;
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
    final bulan = [
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

  String tanggalPengumuman(Map<String, dynamic> item) {
    final tanggal = (item['tanggal'] ?? item['tgl'] ?? '').toString();
    if (tanggal.trim().isNotEmpty) return tanggal;

    final createdAt = item['created_at'] ?? item['createdAt'] ?? item['waktu'];

    if (createdAt is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
      return '${date.day} ${_namaBulan(date.month)} ${date.year}';
    }

    if (createdAt is double) {
      final date = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());
      return '${date.day} ${_namaBulan(date.month)} ${date.year}';
    }

    return 'Pengumuman desa';
  }

  String _namaBulan(int bulan) {
    const namaBulan = [
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
    return namaBulan[bulan - 1];
  }

  @override
  Widget build(BuildContext context) {
    final bantuanRef = db.ref('bantuan_pupuk');
    final peminjamanRef = db.ref('peminjaman_alat');
    final notifikasiRef = db.ref('notifikasi').child(widget.nik);
    final pengumumanRef = db.ref('pengumuman');

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
                    return StreamBuilder<DatabaseEvent>(
                      stream: pengumumanRef.onValue,
                      builder: (context, pengumumanSnapshot) {
                        final semuaBantuan = ambilDataByNik(
                          bantuanSnapshot.data?.snapshot.value,
                        );

                        final semuaPeminjaman = ambilDataByNik(
                          peminjamanSnapshot.data?.snapshot.value,
                        );

                        final bantuanMenunggu = filterStatus(semuaBantuan, [
                          'menunggu',
                        ]);

                        final peminjamanMenunggu = filterStatus(
                          semuaPeminjaman,
                          ['menunggu'],
                        );

                        final totalMenunggu =
                            bantuanMenunggu.length + peminjamanMenunggu.length;

                        final totalNotif = hitungNotifBelumDibaca(
                          notifSnapshot.data?.snapshot.value,
                        );

                        final pengumumanAktif = ambilPengumumanAktif(
                          pengumumanSnapshot.data?.snapshot.value,
                        );

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _headerPremium(totalMenunggu, totalNotif),
                              const SizedBox(height: 18),
                              _keanggotaanCard(),
                              const SizedBox(height: 18),
                              _ringkasanHariIni(
                                bantuanMenunggu: bantuanMenunggu.length,
                                alatMenunggu: peminjamanMenunggu.length,
                                totalNotif: totalNotif,
                              ),
                              const SizedBox(height: 24),
                              _sectionTitle('Layanan Utama'),
                              const SizedBox(height: 12),
                              _layananGrid(),
                              const SizedBox(height: 24),
                              _sectionTitle('Pengajuan Saya'),
                              const SizedBox(height: 12),
                              _pengajuanSaya(
                                bantuanList: bantuanMenunggu,
                                peminjamanList: peminjamanMenunggu,
                              ),
                              const SizedBox(height: 24),
                              _sectionTitleWithAction(
                                title: 'Pengumuman Terbaru',
                                actionText: 'Lihat Semua',
                                onTap:
                                    () => bukaHalaman(const PengumumanPage()),
                              ),
                              const SizedBox(height: 12),
                              _pengumumanTerbaru(pengumumanAktif),
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
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _headerPremium(int totalMenunggu, int totalNotif) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.26),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            bottom: -42,
            child: Icon(
              Icons.agriculture_rounded,
              size: 170,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _avatarUser(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salamWaktu(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tanggalHariIni(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _notifButton(totalNotif),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(15),
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
                            ? 'Semua pengajuan kamu sedang aman. Silakan gunakan layanan sesuai kebutuhan.'
                            : '$totalMenunggu pengajuan masih menunggu verifikasi admin.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
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

  Widget _avatarUser() {
    final initial =
        widget.nama.trim().isEmpty ? 'A' : widget.nama.trim()[0].toUpperCase();

    return Container(
      height: 58,
      width: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _notifButton(int totalNotif) {
    return InkWell(
      onTap: () => bukaHalaman(NotifikasiPage(nik: widget.nik)),
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
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          Positioned(right: -8, top: -8, child: _notificationBadge(totalNotif)),
        ],
      ),
    );
  }

  Widget _notificationBadge(int total) {
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

  Widget _keanggotaanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: softGreen,
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
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Aktif sebagai anggota kelompok tani\nNIK: ${widget.nik}',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'AKTIF',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ringkasanHariIni({
    required int bantuanMenunggu,
    required int alatMenunggu,
    required int totalNotif,
  }) {
    final totalMenunggu = bantuanMenunggu + alatMenunggu;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              totalMenunggu == 0
                  ? [Colors.white, softGreen]
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
                      totalMenunggu == 0
                          ? primaryGreen.withValues(alpha: 0.12)
                          : orangeStatus.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  totalMenunggu == 0
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  color: totalMenunggu == 0 ? primaryGreen : orangeStatus,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Hari Ini',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalMenunggu == 0
                          ? 'Tidak ada pengajuan yang menunggu.'
                          : '$totalMenunggu pengajuan sedang menunggu admin.',
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
                child: _miniDashboardCard(
                  title: 'Pupuk',
                  value: bantuanMenunggu.toString(),
                  subtitle: 'Menunggu',
                  icon: Icons.eco_rounded,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniDashboardCard(
                  title: 'Alat',
                  value: alatMenunggu.toString(),
                  subtitle: 'Menunggu',
                  icon: Icons.agriculture_rounded,
                  color: orangeStatus,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniDashboardCard(
                  title: 'Notif',
                  value: totalNotif.toString(),
                  subtitle: 'Baru',
                  icon: Icons.notifications_rounded,
                  color: blueStatus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniDashboardCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
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

  Widget _layananGrid() {
    final menus = [
      _HomeMenu(
        title: 'Bantuan Pupuk',
        subtitle: 'Ajukan kebutuhan pupuk',
        icon: Icons.eco_rounded,
        color: primaryGreen,
        page: PupukPage(nama: widget.nama, nik: widget.nik),
      ),
      _HomeMenu(
        title: 'Peminjaman Alat',
        subtitle: 'Pinjam alat pertanian',
        icon: Icons.agriculture_rounded,
        color: orangeStatus,
        page: AlatPage(nama: widget.nama, nik: widget.nik),
      ),
    ];

    return GridView.builder(
      itemCount: menus.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 150,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) => _menuGridCard(menus[index]),
    );
  }

  Widget _menuGridCard(_HomeMenu menu) {
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
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: menu.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(menu.icon, color: menu.color, size: 27),
            ),
            const Spacer(),
            Text(
              menu.title,
              style: const TextStyle(
                color: textDark,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              menu.subtitle,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pengajuanSaya({
    required List<Map<String, dynamic>> bantuanList,
    required List<Map<String, dynamic>> peminjamanList,
  }) {
    final total = bantuanList.length + peminjamanList.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: total == 0 ? softGreen : const Color(0xffFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              total == 0
                  ? primaryGreen.withValues(alpha: 0.22)
                  : const Color(0xffFED7AA),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pengajuanHeader(total),
          const SizedBox(height: 12),
          if (total == 0)
            const Text(
              'Tidak ada pengajuan yang sedang menunggu. Pengajuan yang sudah diproses dapat dilihat pada halaman Riwayat.',
              style: TextStyle(
                color: textGrey,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ...bantuanList.map(
            (item) => _pengajuanItem(
              icon: Icons.grass_rounded,
              color: primaryGreen,
              title: 'Bantuan Pupuk',
              subtitle:
                  '${item['jenis_pupuk'] ?? '-'} • ${item['jumlah_pupuk'] ?? '-'} Kg',
            ),
          ),
          ...peminjamanList.map(
            (item) => _pengajuanItem(
              icon: Icons.agriculture_rounded,
              color: orangeStatus,
              title: 'Peminjaman Alat',
              subtitle:
                  '${item['alat'] ?? item['nama_alat'] ?? '-'} • ${item['tanggal_pinjam'] ?? '-'}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _pengajuanHeader(int total) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color:
                total == 0
                    ? primaryGreen.withValues(alpha: 0.14)
                    : orangeStatus.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            total == 0
                ? Icons.check_circle_rounded
                : Icons.hourglass_top_rounded,
            color: total == 0 ? primaryGreen : orangeStatus,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            total == 0
                ? 'Tidak Ada Pengajuan Menunggu'
                : '$total Pengajuan Menunggu',
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pengajuanItem({
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
                    fontWeight: FontWeight.w900,
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
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pengumumanTerbaru(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: softGreen,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: primaryGreen,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum Ada Pengumuman',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pengumuman dari kelompok tani atau desa akan tampil di sini jika sudah tersedia.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final item = list.first;
    final judul = (item['judul'] ?? 'Pengumuman Desa').toString();
    final isi =
        (item['isi'] ?? item['deskripsi'] ?? item['keterangan'] ?? '-')
            .toString();

    return InkWell(
      onTap: () => bukaHalaman(const PengumumanPage()),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [darkGreen, primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
              right: -24,
              bottom: -34,
              child: Icon(
                Icons.campaign_rounded,
                size: 130,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tanggalPengumuman(item),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Aktif',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  judul,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isi,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Baca pengumuman',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 17,
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _sectionTitleWithAction({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(child: _sectionTitle(title)),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
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
