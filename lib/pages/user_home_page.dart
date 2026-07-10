import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../widgets/app_background.dart';
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
  static const Color deepGreen = Color(0xff0F3D25);
  static const Color softGreen = Color(0xffF3FBF5);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color redStatus = Color(0xffDC2626);
  static const Color purpleStatus = Color(0xff7C3AED);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
  final Set<String> shownNotificationIds = {};
  bool listenerSiap = false;

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
    listenNotifikasiMasuk();
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

  void listenNotifikasiMasuk() {
    subscriptions.add(
      notifikasiRef.onChildAdded.listen((event) {
        // cegah notifikasi lama muncul ulang saat login
        if (!listenerSiap) {
          return;
        }

        if (event.snapshot.value == null) return;
        if (event.snapshot.value is! Map) return;

        final id = event.snapshot.key ?? '';

        if (shownNotificationIds.contains(id)) {
          return;
        }

        final item = Map<dynamic, dynamic>.from(event.snapshot.value as Map);

        final status = (item['status'] ?? '').toString().toLowerCase();

        final dibaca = item['dibaca'];

        if (status == 'belum_dibaca' || dibaca == false) {
          shownNotificationIds.add(id);

          NotificationService.showLocalNotification(
            title: (item['judul'] ?? 'TaniGo').toString(),
            body: (item['pesan'] ?? '').toString(),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text((item['judul'] ?? 'Notifikasi baru').toString()),
                backgroundColor: darkGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }),
    );

    // Firebase pertama kali mengirim semua notif lama.
    // Tunggu selesai dulu, baru aktifkan listener.
    Future.delayed(const Duration(seconds: 2), () {
      if (!isDisposed) {
        listenerSiap = true;
      }
    });
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

    if (clean == 'pupuk' || clean == 'penyaluran_pupuk') return 'Penyaluran';
    if (clean == 'alat' || clean == 'jadwal_alat') return 'Jadwal';
    if (clean == 'rapat' || clean == 'agenda') return 'Agenda';
    if (clean == 'panen') return 'Panen';
    if (clean == 'gotong_royong') return 'Kegiatan';

    return 'Informasi';
  }

  IconData informationIcon(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk' || clean == 'penyaluran_pupuk') {
      return Icons.inventory_2_outlined;
    }

    if (clean == 'alat' || clean == 'jadwal_alat') {
      return Icons.handyman_outlined;
    }

    if (clean == 'rapat' || clean == 'agenda') return Icons.diversity_3_rounded;
    if (clean == 'panen') return Icons.grass_outlined;
    if (clean == 'gotong_royong') return Icons.volunteer_activism_outlined;

    return Icons.campaign_outlined;
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

    return 'Aktif';
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
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    headerCard(data),
                    const SizedBox(height: 12),
                    quickStatusPanel(data),
                    const SizedBox(height: 16),
                    sectionTitle('Layanan Utama'),
                    const SizedBox(height: 10),
                    serviceList(),
                    const SizedBox(height: 16),
                    sectionTitleWithAction(
                      title: 'Status Pengajuan',
                      actionText: 'Riwayat',
                      onTap: () => openPage(RiwayatPage(nik: widget.nik)),
                    ),
                    const SizedBox(height: 10),
                    latestSubmission(data.pengajuanTerbaru),
                    const SizedBox(height: 16),
                    sectionTitleWithAction(
                      title: 'Informasi Terbaru',
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
      ),
    );
  }

  Widget headerCard(_UserDashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deepGreen, darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.23),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                        color: Color(0xffD1FAE5),
                        fontSize: 11.7,
                        fontWeight: FontWeight.w800,
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
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Silakan pilih layanan yang dibutuhkan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _headerMiniInfo(
                    label: 'Status Akun',
                    value: 'Aktif',
                    icon: Icons.verified_outlined,
                  ),
                ),
                Container(
                  height: 34,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: _headerMiniInfo(
                    label: 'Menunggu',
                    value: data.totalMenunggu.toString(),
                    icon: Icons.pending_actions_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerMiniInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        const SizedBox(width: 3),
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xffD1FAE5),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget avatarUser() {
    final initial =
        widget.nama.trim().isEmpty ? 'A' : widget.nama.trim()[0].toUpperCase();

    return Container(
      height: 51,
      width: 51,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withValues(alpha: 0.23)),
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
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 54,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            if (totalNotif > 0)
              Positioned(
                right: 0,
                top: 0,
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
      constraints: const BoxConstraints(minWidth: 23, minHeight: 20),
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
          fontSize: 9.5,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget quickStatusPanel(_UserDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: cardDecoration(radius: 22),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _miniSummaryBox(
                  title: 'Pupuk',
                  value: data.bantuanMenunggu.length.toString(),
                  subtitle: 'menunggu',
                  icon: Icons.inventory_2_outlined,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniSummaryBox(
                  title: 'Alat',
                  value: data.peminjamanMenunggu.length.toString(),
                  subtitle: 'menunggu',
                  icon: Icons.handyman_outlined,
                  color: orangeStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          summaryCard(data),
        ],
      ),
    );
  }

  Widget _miniSummaryBox({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            height: 37,
            width: 37,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
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
                    color: textDark,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$value $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
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

  Widget summaryCard(_UserDashboardData data) {
    final totalMenunggu = data.totalMenunggu;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            totalMenunggu == 0
                ? primaryGreen.withValues(alpha: 0.065)
                : orangeStatus.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              totalMenunggu == 0
                  ? primaryGreen.withValues(alpha: 0.12)
                  : orangeStatus.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 41,
            width: 41,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              totalMenunggu == 0
                  ? Icons.task_alt_rounded
                  : Icons.hourglass_top_rounded,
              color: totalMenunggu == 0 ? primaryGreen : orangeStatus,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalMenunggu == 0
                      ? 'Semua pengajuan aman'
                      : 'Ada pengajuan menunggu',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  totalMenunggu == 0
                      ? 'Belum ada data yang menunggu admin.'
                      : '$totalMenunggu pengajuan sedang diproses admin.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
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

  Widget serviceList() {
    final menus = [
      _HomeMenu(
        title: 'Bantuan Pupuk',
        subtitle: 'Ajukan kebutuhan pupuk dengan mudah.',
        icon: Icons.inventory_2_outlined,
        color: primaryGreen,
        page: PupukPage(nama: widget.nama, nik: widget.nik),
      ),
      _HomeMenu(
        title: 'Peminjaman Alat',
        subtitle: 'Ajukan alat pertanian sesuai jadwal.',
        icon: Icons.handyman_outlined,
        color: orangeStatus,
        page: AlatPage(nama: widget.nama, nik: widget.nik),
      ),
    ];

    return Row(
      children: [
        Expanded(child: serviceCard(menus[0])),
        const SizedBox(width: 11),
        Expanded(child: serviceCard(menus[1])),
      ],
    );
  }

  Widget serviceCard(_HomeMenu menu) {
    return InkWell(
      onTap: () => openPage(menu.page),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 145,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: menu.color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 13,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: menu.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(menu.icon, color: menu.color, size: 24),
            ),
            const Spacer(),
            Text(
              menu.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              menu.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.5,
                height: 1.32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  'Buka',
                  style: TextStyle(
                    color: menu.color,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: menu.color, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget latestSubmission(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return emptyCard(
        icon: Icons.fact_check_outlined,
        title: 'Belum Ada Pengajuan',
        message: 'Pengajuan pupuk dan alat akan tampil di sini.',
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
            : 'Pinjam: ${item['tanggal_pinjam'] ?? '-'}';

    final status = (item['status'] ?? 'menunggu').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: cardDecoration(radius: 19),
      child: Row(
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isPupuk ? Icons.inventory_2_outlined : Icons.handyman_outlined,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPupuk ? 'Bantuan Pupuk' : 'Peminjaman Alat',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.6,
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
                    fontSize: 14.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          statusBadge(status),
        ],
      ),
    );
  }

  Widget informationSection(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return emptyCard(
        icon: Icons.campaign_outlined,
        title: 'Belum Ada Informasi',
        message: 'Pengumuman terbaru dari admin akan tampil di sini.',
      );
    }

    final shown = list.take(3).toList();

    return Container(
      decoration: cardDecoration(radius: 20),
      child: Column(
        children: [
          ...shown.map((item) => informationItem(item)),
          InkWell(
            onTap: () => openPage(const PengumumanPage()),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
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
                        fontSize: 12.8,
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
      padding: const EdgeInsets.all(13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 41,
            width: 41,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(informationIcon(category), color: color, size: 21),
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
                    fontSize: 10,
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
                    fontSize: 13.8,
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
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  informationDate(item),
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.6,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5.5),
      decoration: BoxDecoration(
        color: statusBg(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusText(status),
        style: TextStyle(
          color: statusColor(status),
          fontSize: 9.8,
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
        fontSize: 16.2,
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
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.14)),
            ),
            child: Text(
              actionText,
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 11.6,
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
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration(radius: 20),
      child: Column(
        children: [
          Container(
            height: 57,
            width: 57,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.10)),
            ),
            child: Icon(icon, color: primaryGreen, size: 29),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 14.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12,
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
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11.3,
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
            icon: Icon(Icons.space_dashboard_outlined),
            activeIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  BoxDecoration cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.034),
          blurRadius: 13,
          offset: const Offset(0, 5),
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
