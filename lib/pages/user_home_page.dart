import 'dart:async';

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
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color redStatus = Color(0xffDC2626);
  static const Color purpleStatus = Color(0xff7C3AED);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference bantuanRef;
  late final DatabaseReference peminjamanRef;
  late final DatabaseReference notifikasiRef;
  late final DatabaseReference pengumumanRef;

  final StreamController<_UserDashboardData> dashboardController =
      StreamController<_UserDashboardData>.broadcast();

  final List<StreamSubscription<DatabaseEvent>> subscriptions = [];

  dynamic bantuanValue;
  dynamic peminjamanValue;
  dynamic notifikasiValue;
  dynamic pengumumanValue;

  bool isDisposed = false;

  @override
  void initState() {
    super.initState();

    bantuanRef = db.ref('bantuan_pupuk');
    peminjamanRef = db.ref('peminjaman_alat');
    notifikasiRef = db.ref('notifikasi').child(widget.nik.trim());
    pengumumanRef = db.ref('pengumuman');

    listenDashboardData();
  }

  @override
  void dispose() {
    isDisposed = true;

    for (final sub in subscriptions) {
      sub.cancel();
    }

    dashboardController.close();
    super.dispose();
  }

  void listenDashboardData() {
    subscriptions.addAll([
      bantuanRef.onValue.listen((event) {
        bantuanValue = event.snapshot.value;
        emitDashboardData();
      }),
      peminjamanRef.onValue.listen((event) {
        peminjamanValue = event.snapshot.value;
        emitDashboardData();
      }),
      notifikasiRef.onValue.listen((event) {
        notifikasiValue = event.snapshot.value;
        emitDashboardData();
      }),
      pengumumanRef.onValue.listen((event) {
        pengumumanValue = event.snapshot.value;
        emitDashboardData();
      }),
    ]);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!isDisposed) emitDashboardData();
    });
  }

  void emitDashboardData() {
    if (isDisposed || dashboardController.isClosed) return;

    final bantuanUser = getDataByNik(bantuanValue, 'pupuk');
    final peminjamanUser = getDataByNik(peminjamanValue, 'alat');

    final semuaPengajuan = [...bantuanUser, ...peminjamanUser];
    semuaPengajuan.sort((a, b) => timeValue(b).compareTo(timeValue(a)));

    final data = _UserDashboardData(
      bantuanMenunggu: filterStatus(bantuanUser, ['menunggu']),
      peminjamanMenunggu: filterStatus(peminjamanUser, ['menunggu']),
      pengajuanTerbaru: semuaPengajuan.take(3).toList(),
      totalNotif: countUnreadNotif(notifikasiValue),
      informasiAktif: getActiveInformation(pengumumanValue),
    );

    dashboardController.add(data);
  }

  List<Map<String, dynamic>> getDataByNik(dynamic value, String jenis) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);
    final nikUser = widget.nik.trim();

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final item = Map<String, dynamic>.from(entry.value as Map);
              item['id'] = entry.key.toString();
              item['jenis_data'] = jenis;
              return item;
            })
            .where((item) {
              final nikData = (item['nik'] ?? '').toString().trim();
              return nikData == nikUser;
            })
            .toList();

    list.sort((a, b) => timeValue(b).compareTo(timeValue(a)));
    return list;
  }

  List<Map<String, dynamic>> filterStatus(
    List<Map<String, dynamic>> data,
    List<String> statusList,
  ) {
    return data.where((item) {
      final status =
          (item['status'] ?? 'menunggu').toString().toLowerCase().trim();
      return statusList.contains(status);
    }).toList();
  }

  int countUnreadNotif(dynamic value) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is! Map) continue;

      final notif = Map<dynamic, dynamic>.from(item);
      final status = (notif['status'] ?? '').toString().toLowerCase().trim();
      final dibaca = notif['dibaca'];

      if (status == 'belum_dibaca' || dibaca == false) total++;
    }

    return total;
  }

  List<Map<String, dynamic>> getActiveInformation(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final item = Map<String, dynamic>.from(entry.value as Map);
              item['id'] = entry.key.toString();
              return item;
            })
            .where((item) {
              final status =
                  (item['status'] ?? '').toString().toLowerCase().trim();
              return status == 'aktif';
            })
            .toList();

    list.sort((a, b) => timeValue(b).compareTo(timeValue(a)));
    return list;
  }

  int timeValue(Map<String, dynamic> item) {
    final raw =
        item['created_at'] ??
        item['createdAt'] ??
        item['waktu'] ??
        item['tanggal'] ??
        item['tgl'] ??
        item['tanggal_pengajuan'] ??
        item['tanggalPengajuan'] ??
        item['tanggal_pinjam'] ??
        item['tanggalPinjam'];

    if (raw is int) return raw;
    if (raw is double) return raw.toInt();

    final parsed = DateTime.tryParse((raw ?? '').toString().trim());
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String todayText() {
    final now = DateTime.now();

    const months = [
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

    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String formatTanggal(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    return '${parsed.day} ${monthName(parsed.month)} ${parsed.year}';
  }

  String monthName(int month) {
    const months = [
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

    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  String statusText(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'disetujui') return 'Disetujui';
    if (clean == 'sudah_diambil') return 'Selesai';
    if (clean == 'dipinjam') return 'Dipinjam';
    if (clean == 'dikembalikan') return 'Selesai';
    if (clean == 'ditolak') return 'Ditolak';

    return 'Menunggu';
  }

  Color statusColor(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'disetujui') return blueStatus;
    if (clean == 'sudah_diambil') return primaryGreen;
    if (clean == 'dipinjam') return purpleStatus;
    if (clean == 'dikembalikan') return primaryGreen;
    if (clean == 'ditolak') return redStatus;

    return orangeStatus;
  }

  Color statusBg(String status) {
    return statusColor(status).withValues(alpha: 0.10);
  }

  String informationLabel(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk' || clean == 'penyaluran_pupuk') {
      return 'Penyaluran Pupuk';
    }

    if (clean == 'alat' || clean == 'jadwal_alat') {
      return 'Jadwal Alat';
    }

    if (clean == 'rapat' || clean == 'agenda') return 'Agenda';
    if (clean == 'panen') return 'Panen';
    if (clean == 'gotong_royong') return 'Gotong Royong';

    return 'Pengumuman';
  }

  IconData informationIcon(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk' || clean == 'penyaluran_pupuk') {
      return Icons.eco_rounded;
    }

    if (clean == 'alat' || clean == 'jadwal_alat') {
      return Icons.agriculture_rounded;
    }

    if (clean == 'rapat' || clean == 'agenda') return Icons.groups_rounded;
    if (clean == 'panen') return Icons.grass_rounded;
    if (clean == 'gotong_royong') return Icons.handshake_rounded;

    return Icons.campaign_rounded;
  }

  Color informationColor(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk' || clean == 'penyaluran_pupuk') return primaryGreen;
    if (clean == 'alat' || clean == 'jadwal_alat') return orangeStatus;
    if (clean == 'rapat' || clean == 'agenda') return blueStatus;
    if (clean == 'panen') return darkGreen;
    if (clean == 'gotong_royong') return purpleStatus;

    return primaryGreen;
  }

  String informationDate(Map<String, dynamic> item) {
    final raw =
        item['created_at'] ??
        item['createdAt'] ??
        item['waktu'] ??
        item['tanggal'] ??
        item['tgl'];

    if (raw is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(raw);
      return '${date.day} ${monthName(date.month)} ${date.year}';
    }

    if (raw is double) {
      final date = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      return '${date.day} ${monthName(date.month)} ${date.year}';
    }

    final parsed = DateTime.tryParse((raw ?? '').toString().trim());
    if (parsed != null) {
      return '${parsed.day} ${monthName(parsed.month)} ${parsed.year}';
    }

    final tanggal = (item['tanggal'] ?? item['tgl'] ?? '').toString().trim();
    if (tanggal.isNotEmpty) return tanggal;

    return 'Informasi aktif';
  }

  void openPage(Widget page) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: bottomNav(),
      body: SafeArea(
        child: StreamBuilder<_UserDashboardData>(
          stream: dashboardController.stream,
          initialData: _UserDashboardData.empty(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? _UserDashboardData.empty();

            return RefreshIndicator(
              color: primaryGreen,
              onRefresh: () async => emitDashboardData(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  headerCard(data),
                  const SizedBox(height: 12),
                  memberCard(),
                  const SizedBox(height: 12),
                  summaryCard(data),
                  const SizedBox(height: 18),
                  sectionTitle('Layanan Utama'),
                  const SizedBox(height: 10),
                  serviceList(),
                  const SizedBox(height: 18),
                  sectionTitleWithAction(
                    title: 'Status Pengajuan Terbaru',
                    actionText: 'Riwayat',
                    onTap: () => openPage(RiwayatPage(nik: widget.nik)),
                  ),
                  const SizedBox(height: 10),
                  latestSubmission(data.pengajuanTerbaru),
                  const SizedBox(height: 18),
                  sectionTitleWithAction(
                    title: 'Informasi Kelompok Tani',
                    actionText: 'Lihat Semua',
                    onTap: () => openPage(const PengumumanPage()),
                  ),
                  const SizedBox(height: 10),
                  informationSection(data.informasiAktif),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget headerCard(_UserDashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          avatarUser(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Anggota Kelompok Tani',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          notifButton(data.totalNotif),
        ],
      ),
    );
  }

  Widget avatarUser() {
    final initial =
        widget.nama.trim().isEmpty ? 'A' : widget.nama.trim()[0].toUpperCase();

    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget notifButton(int totalNotif) {
    return InkWell(
      onTap: () => openPage(NotifikasiPage(nik: widget.nik)),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 58,
        height: 54,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
            if (totalNotif > 0)
              Positioned(
                right: 1,
                top: 1,
                child: notificationBadge(totalNotif),
              ),
          ],
        ),
      ),
    );
  }

  Widget notificationBadge(int total) {
    final text = total > 99 ? '99+' : total.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 21),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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

  Widget memberCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Keanggotaan',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Akun sudah aktif dan terverifikasi.',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(99),
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

  Widget summaryCard(_UserDashboardData data) {
    final totalMenunggu = data.totalMenunggu;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color:
                      totalMenunggu == 0
                          ? primaryGreen.withValues(alpha: 0.11)
                          : orangeStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  totalMenunggu == 0
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: totalMenunggu == 0 ? primaryGreen : orangeStatus,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  totalMenunggu == 0
                      ? 'Tidak ada pengajuan yang menunggu.'
                      : '$totalMenunggu pengajuan sedang menunggu admin.',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: miniSummary(
                  title: 'Pengajuan',
                  value: totalMenunggu.toString(),
                  subtitle: 'Menunggu',
                  icon: Icons.assignment_rounded,
                  color: orangeStatus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: miniSummary(
                  title: 'Notifikasi',
                  value: data.totalNotif.toString(),
                  subtitle: 'Baru',
                  icon: Icons.notifications_rounded,
                  color: blueStatus,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: miniSummary(
                  title: 'Informasi',
                  value: data.informasiAktif.length.toString(),
                  subtitle: 'Aktif',
                  icon: Icons.campaign_rounded,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget miniSummary({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 98,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget serviceList() {
    final menus = [
      _HomeMenu(
        title: 'Bantuan Pupuk',
        subtitle: 'Ajukan kebutuhan pupuk pertanian.',
        icon: Icons.eco_rounded,
        color: primaryGreen,
        page: PupukPage(nama: widget.nama, nik: widget.nik),
      ),
      _HomeMenu(
        title: 'Peminjaman Alat',
        subtitle: 'Ajukan peminjaman alat pertanian.',
        icon: Icons.agriculture_rounded,
        color: orangeStatus,
        page: AlatPage(nama: widget.nama, nik: widget.nik),
      ),
    ];

    return Column(children: menus.map((menu) => serviceCard(menu)).toList());
  }

  Widget serviceCard(_HomeMenu menu) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => openPage(menu.page),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: cardDecoration(),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: menu.color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(menu.icon, color: menu.color, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.title,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu.subtitle,
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
              Icon(Icons.chevron_right_rounded, color: menu.color, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  Widget latestSubmission(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return emptyCard(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Belum Ada Pengajuan',
        message:
            'Pengajuan bantuan pupuk dan peminjaman alat akan tampil di sini.',
      );
    }

    return Column(children: list.map((item) => submissionCard(item)).toList());
  }

  Widget submissionCard(Map<String, dynamic> item) {
    final jenis = (item['jenis_data'] ?? '').toString();
    final isPupuk = jenis == 'pupuk';
    final color = isPupuk ? primaryGreen : orangeStatus;

    final title =
        isPupuk
            ? (item['jenis_pupuk'] ?? item['nama_pupuk'] ?? 'Bantuan Pupuk')
                .toString()
            : (item['alat'] ?? item['nama_alat'] ?? 'Peminjaman Alat')
                .toString();

    final subtitle =
        isPupuk
            ? '${item['jumlah_pupuk'] ?? item['jumlah_kg'] ?? item['jumlah'] ?? '-'} Kg'
            : 'Tanggal pinjam: ${item['tanggal_pinjam'] ?? '-'}';

    final status = (item['status'] ?? 'menunggu').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPupuk ? Icons.eco_rounded : Icons.agriculture_rounded,
              color: color,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPupuk ? 'Bantuan Pupuk' : 'Peminjaman Alat',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          statusBadge(status),
        ],
      ),
    );
  }

  Widget informationSection(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return emptyCard(
        icon: Icons.campaign_rounded,
        title: 'Belum Ada Informasi',
        message:
            'Informasi kelompok tani akan tampil di sini setelah admin menambahkan data.',
      );
    }

    final shown = list.take(3).toList();

    return Container(
      decoration: cardDecoration(),
      child: Column(
        children: [
          ...shown.map((item) => informationItem(item)),
          InkWell(
            onTap: () => openPage(const PengumumanPage()),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Lihat semua informasi',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: primaryGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget informationItem(Map<String, dynamic> item) {
    final title = (item['judul'] ?? 'Informasi').toString();
    final body =
        (item['isi'] ?? item['deskripsi'] ?? item['keterangan'] ?? '-')
            .toString();
    final category = (item['kategori'] ?? 'pengumuman').toString();
    final color = informationColor(category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(informationIcon(category), color: color, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  informationLabel(category).toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  informationDate(item),
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11,
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

  Widget statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: statusBg(status),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        statusText(status),
        style: TextStyle(
          color: statusColor(status),
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 17,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget sectionTitleWithAction({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(child: sectionTitle(title)),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(99),
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

  Widget emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, color: primaryGreen, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, -5),
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
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            openPage(RiwayatPage(nik: widget.nik));
          } else if (index == 2) {
            openPage(ProfilPage(nama: widget.nama, nik: widget.nik));
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

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _UserDashboardData {
  final List<Map<String, dynamic>> bantuanMenunggu;
  final List<Map<String, dynamic>> peminjamanMenunggu;
  final List<Map<String, dynamic>> pengajuanTerbaru;
  final int totalNotif;
  final List<Map<String, dynamic>> informasiAktif;

  const _UserDashboardData({
    required this.bantuanMenunggu,
    required this.peminjamanMenunggu,
    required this.pengajuanTerbaru,
    required this.totalNotif,
    required this.informasiAktif,
  });

  factory _UserDashboardData.empty() {
    return const _UserDashboardData(
      bantuanMenunggu: [],
      peminjamanMenunggu: [],
      pengajuanTerbaru: [],
      totalNotif: 0,
      informasiAktif: [],
    );
  }

  int get totalMenunggu => bantuanMenunggu.length + peminjamanMenunggu.length;
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
