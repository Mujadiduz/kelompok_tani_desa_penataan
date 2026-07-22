import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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

  const UserHomePage({
    super.key,
    required this.nama,
    required this.nik,
  });

  @override
  State<UserHomePage> createState() =>
      _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color deepTeal = Color(0xff0E5F57);
  static const Color tealColor = Color(0xff167A6B);
  static const Color blueColor = Color(0xff326FA3);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color softAmber = Color(0xffFFF3DD);

  static const Color pageBackground = Color(0xffF2F7F5);
  static const Color cardBorder = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  static const Color orangeStatus = Color(0xffD98212);
  static const Color redStatus = Color(0xffC83B3B);
  static const Color purpleStatus = Color(0xff7159B4);

  final FirebaseDatabase db =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

  late final DatabaseReference bantuanRef;
  late final DatabaseReference peminjamanRef;
  late final DatabaseReference notifikasiRef;
  late final DatabaseReference pengumumanRef;

  final StreamController<_UserDashboardData>
      dashboardController =
      StreamController<_UserDashboardData>.broadcast();

  final List<StreamSubscription<DatabaseEvent>>
      subscriptions = [];

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

    notifikasiRef = db
        .ref('notifikasi')
        .child(widget.nik.trim());

    pengumumanRef = db.ref('pengumuman');

    listenDashboardData();
  }

  @override
  void dispose() {
    isDisposed = true;

    for (final subscription in subscriptions) {
      subscription.cancel();
    }

    dashboardController.close();

    super.dispose();
  }

  void listenDashboardData() {
    subscriptions.addAll([
      bantuanRef.onValue.listen(
        (event) {
          bantuanValue = event.snapshot.value;
          emitDashboardData();
        },
      ),
      peminjamanRef.onValue.listen(
        (event) {
          peminjamanValue = event.snapshot.value;
          emitDashboardData();
        },
      ),
      notifikasiRef.onValue.listen(
        (event) {
          notifikasiValue = event.snapshot.value;
          emitDashboardData();
        },
      ),
      pengumumanRef.onValue.listen(
        (event) {
          pengumumanValue = event.snapshot.value;
          emitDashboardData();
        },
      ),
    ]);

    Future<void>.delayed(
      const Duration(milliseconds: 500),
      () {
        if (!isDisposed) {
          emitDashboardData();
        }
      },
    );
  }

  void emitDashboardData() {
    if (isDisposed ||
        dashboardController.isClosed) {
      return;
    }

    final bantuanUser = getDataByNik(
      bantuanValue,
      'pupuk',
    );

    final peminjamanUser = getDataByNik(
      peminjamanValue,
      'alat',
    );

    /*
     * Dashboard hanya menampilkan pengajuan
     * yang masih menunggu atau diproses.
     */
    final bantuanMenunggu = bantuanUser
        .where(
          (item) => isPendingStatus(
            item['status'],
          ),
        )
        .toList();

    final peminjamanMenunggu = peminjamanUser
        .where(
          (item) => isPendingStatus(
            item['status'],
          ),
        )
        .toList();

    final pengajuanMenungguTerbaru = [
      ...bantuanMenunggu,
      ...peminjamanMenunggu,
    ];

    pengajuanMenungguTerbaru.sort(
      (a, b) =>
          timeValue(b).compareTo(timeValue(a)),
    );

    final data = _UserDashboardData(
      bantuanMenunggu: bantuanMenunggu,
      peminjamanMenunggu: peminjamanMenunggu,
      pengajuanMenungguTerbaru:
          pengajuanMenungguTerbaru
              .take(3)
              .toList(),
      totalNotif:
          countUnreadNotif(notifikasiValue),
      informasiAktif:
          getActiveInformation(pengumumanValue),
    );

    dashboardController.add(data);
  }

  bool isPendingStatus(dynamic value) {
    final status = (value ?? 'menunggu')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');

    const pendingStatuses = {
      '',
      'menunggu',
      'pending',
      'diajukan',
      'pengajuan',
      'proses',
      'diproses',
      'sedang_diproses',
      'sedang diproses',
      'menunggu_verifikasi',
      'menunggu verifikasi',
      'belum_diproses',
      'belum diproses',
    };

    return pendingStatuses.contains(status);
  }

  List<Map<String, dynamic>> getDataByNik(
    dynamic value,
    String jenis,
  ) {
    if (value == null || value is! Map) {
      return [];
    }

    final data =
        Map<dynamic, dynamic>.from(value);

    final nikUser = widget.nik.trim();

    final list = data.entries
        .where(
          (entry) => entry.value is Map,
        )
        .map(
          (entry) {
            final item =
                Map<String, dynamic>.from(
              entry.value as Map,
            );

            item['id'] = entry.key.toString();
            item['jenis_data'] = jenis;

            return item;
          },
        )
        .where(
          (item) {
            final nikData =
                (item['nik'] ?? '')
                    .toString()
                    .trim();

            return nikData == nikUser;
          },
        )
        .toList();

    list.sort(
      (a, b) =>
          timeValue(b).compareTo(timeValue(a)),
    );

    return list;
  }

  List<Map<String, dynamic>> filterStatus(
    List<Map<String, dynamic>> data,
    List<String> statusList,
  ) {
    return data.where(
      (item) {
        final status =
            (item['status'] ?? 'menunggu')
                .toString()
                .trim()
                .toLowerCase();

        return statusList.contains(status);
      },
    ).toList();
  }

  int countUnreadNotif(dynamic value) {
    if (value == null || value is! Map) {
      return 0;
    }

    int total = 0;

    final data =
        Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is! Map) continue;

      final notif =
          Map<dynamic, dynamic>.from(item);

      final status =
          (notif['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      final dibaca = notif['dibaca'];

      if (status == 'belum_dibaca' ||
          dibaca == false) {
        total++;
      }
    }

    return total;
  }

  List<Map<String, dynamic>>
      getActiveInformation(dynamic value) {
    if (value == null || value is! Map) {
      return [];
    }

    final data =
        Map<dynamic, dynamic>.from(value);

    final list = data.entries
        .where(
          (entry) => entry.value is Map,
        )
        .map(
          (entry) {
            final item =
                Map<String, dynamic>.from(
              entry.value as Map,
            );

            item['id'] = entry.key.toString();

            return item;
          },
        )
        .where(
          (item) {
            final status =
                (item['status'] ?? '')
                    .toString()
                    .trim()
                    .toLowerCase();

            return status == 'aktif';
          },
        )
        .toList();

    list.sort(
      (a, b) =>
          timeValue(b).compareTo(timeValue(a)),
    );

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

    if (raw is int) {
      return raw;
    }

    if (raw is double) {
      return raw.toInt();
    }

    final parsed = DateTime.tryParse(
      (raw ?? '').toString().trim(),
    );

    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String greeting() {
    final hour = DateTime.now().hour;

    if (hour < 11) {
      return 'Selamat pagi';
    }

    if (hour < 15) {
      return 'Selamat siang';
    }

    if (hour < 18) {
      return 'Selamat sore';
    }

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

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String statusText(String status) {
    final clean =
        status.toLowerCase().trim();

    if (clean == 'disetujui') {
      return 'Disetujui';
    }

    if (clean == 'sudah_diambil') {
      return 'Selesai';
    }

    if (clean == 'dipinjam') {
      return 'Dipinjam';
    }

    if (clean == 'dikembalikan') {
      return 'Selesai';
    }

    if (clean == 'ditolak') {
      return 'Ditolak';
    }

    if (clean == 'proses' ||
        clean == 'diproses' ||
        clean == 'sedang_diproses') {
      return 'Diproses';
    }

    return 'Menunggu';
  }

  Color statusColor(String status) {
    final clean =
        status.toLowerCase().trim();

    if (clean == 'disetujui') {
      return blueColor;
    }

    if (clean == 'sudah_diambil' ||
        clean == 'dikembalikan' ||
        clean == 'selesai') {
      return primaryGreen;
    }

    if (clean == 'dipinjam') {
      return purpleStatus;
    }

    if (clean == 'ditolak') {
      return redStatus;
    }

    return orangeStatus;
  }

  Color statusBg(String status) {
    return statusColor(status).withValues(
      alpha: 0.10,
    );
  }

  String informationLabel(String category) {
    final clean =
        category.toLowerCase().trim();

    if (clean == 'pupuk' ||
        clean == 'penyaluran_pupuk') {
      return 'Penyaluran';
    }

    if (clean == 'alat' ||
        clean == 'jadwal_alat') {
      return 'Jadwal';
    }

    if (clean == 'rapat' ||
        clean == 'agenda') {
      return 'Agenda';
    }

    if (clean == 'panen') {
      return 'Panen';
    }

    if (clean == 'gotong_royong') {
      return 'Kegiatan';
    }

    return 'Informasi';
  }

  IconData informationIcon(String category) {
    final clean =
        category.toLowerCase().trim();

    if (clean == 'pupuk' ||
        clean == 'penyaluran_pupuk') {
      return Icons.inventory_2_outlined;
    }

    if (clean == 'alat' ||
        clean == 'jadwal_alat') {
      return Icons.handyman_outlined;
    }

    if (clean == 'rapat' ||
        clean == 'agenda') {
      return Icons.diversity_3_rounded;
    }

    if (clean == 'panen') {
      return Icons.grass_outlined;
    }

    if (clean == 'gotong_royong') {
      return Icons.volunteer_activism_outlined;
    }

    return Icons.campaign_outlined;
  }

  Color informationColor(String category) {
    final clean =
        category.toLowerCase().trim();

    if (clean == 'pupuk' ||
        clean == 'penyaluran_pupuk') {
      return primaryGreen;
    }

    if (clean == 'alat' ||
        clean == 'jadwal_alat') {
      return orangeStatus;
    }

    if (clean == 'rapat' ||
        clean == 'agenda') {
      return blueColor;
    }

    if (clean == 'panen') {
      return darkGreen;
    }

    if (clean == 'gotong_royong') {
      return purpleStatus;
    }

    return tealColor;
  }

  String informationDate(
    Map<String, dynamic> item,
  ) {
    final raw =
        item['created_at'] ??
        item['createdAt'] ??
        item['waktu'] ??
        item['tanggal'] ??
        item['tgl'];

    if (raw is int) {
      final date =
          DateTime.fromMillisecondsSinceEpoch(raw);

      return '${date.day} '
          '${monthName(date.month)} '
          '${date.year}';
    }

    if (raw is double) {
      final date =
          DateTime.fromMillisecondsSinceEpoch(
        raw.toInt(),
      );

      return '${date.day} '
          '${monthName(date.month)} '
          '${date.year}';
    }

    final parsed = DateTime.tryParse(
      (raw ?? '').toString().trim(),
    );

    if (parsed != null) {
      return '${parsed.day} '
          '${monthName(parsed.month)} '
          '${parsed.year}';
    }

    final tanggal =
        (item['tanggal'] ?? item['tgl'] ?? '')
            .toString()
            .trim();

    if (tanggal.isNotEmpty) {
      return tanggal;
    }

    return 'Aktif';
  }

  String submissionTimeLabel(
    Map<String, dynamic> item,
  ) {
    final timestamp = timeValue(item);

    if (timestamp <= 0) {
      return 'Menunggu verifikasi admin';
    }

    final date =
        DateTime.fromMillisecondsSinceEpoch(
      timestamp,
    );

    final difference =
        DateTime.now().difference(date);

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      return 'Baru diajukan';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }

    if (difference.inDays == 1) {
      return 'Kemarin';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    }

    return '${date.day} '
        '${monthName(date.month)} '
        '${date.year}';
  }

  void openPage(Widget page) {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenWidth = mediaQuery.size.width;

    final horizontalPadding =
        screenWidth < 340 ? 13.0 : 17.0;

    return Scaffold(
      backgroundColor: pageBackground,
      bottomNavigationBar: bottomNav(),
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _UserDashboardBackground(),
                SafeArea(
                  bottom: false,
                  child: StreamBuilder<
                      _UserDashboardData>(
                    stream:
                        dashboardController.stream,
                    initialData:
                        _UserDashboardData.empty(),
                    builder: (
                      context,
                      snapshot,
                    ) {
                      final data =
                          snapshot.data ??
                          _UserDashboardData.empty();

                      return RefreshIndicator(
                        color: tealColor,
                        backgroundColor:
                            Colors.white,
                        onRefresh: () async {
                          emitDashboardData();

                          await Future<void>.delayed(
                            const Duration(
                              milliseconds: 450,
                            ),
                          );
                        },
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior
                                  .manual,
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            13,
                            horizontalPadding,
                            28,
                          ),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 720,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    headerCard(data),
                                    const SizedBox(
                                      height: 13,
                                    ),
                                    statusBanner(data),
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    mainServicesCard(),
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    pendingSubmissionCard(
                                      data,
                                    ),
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    informationCard(
                                      data.informasiAktif,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget headerCard(_UserDashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            deepTeal,
            tealColor,
            Color(0xff248C76),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(
              alpha: 0.23,
            ),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -48,
              top: -58,
              child: Container(
                height: 145,
                width: 145,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 35,
              bottom: -65,
              child: Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: const Color(
                    0xffB9E8D7,
                  ).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    avatarUser(),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting(),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(
                                alpha: 0.78,
                              ),
                              fontSize: 10.8,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.nama,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18.2,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Anggota aktif TaniGo',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(
                                alpha: 0.70,
                              ),
                              fontSize: 9.8,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    notifButton(data.totalNotif),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: headerStatusItem(
                        icon:
                            Icons.verified_user_outlined,
                        label: 'Status Akun',
                        value: 'Aktif',
                        color:
                            const Color(0xffC9F3DC),
                      ),
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                      color: Colors.white.withValues(
                        alpha: 0.18,
                      ),
                    ),
                    Expanded(
                      child: headerStatusItem(
                        icon: Icons
                            .pending_actions_outlined,
                        label: 'Pengajuan',
                        value:
                            '${data.totalMenunggu} diproses',
                        color:
                            const Color(0xffFFE0A5),
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

  Widget avatarUser() {
    final cleanName = widget.nama.trim();

    final initial = cleanName.isEmpty
        ? 'A'
        : cleanName[0].toUpperCase();

    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.95,
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.55,
          ),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: deepTeal,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget headerStatusItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.68,
                  ),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget notifButton(int totalNotif) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () {
          openPage(
            NotifikasiPage(
              nik: widget.nik,
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 46,
          width: 48,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        Colors.white.withValues(
                      alpha: 0.19,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              if (totalNotif > 0)
                Positioned(
                  right: -1,
                  top: -2,
                  child:
                      notificationBadge(totalNotif),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget notificationBadge(int total) {
    final text =
        total > 99 ? '99+' : total.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 19,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: redStatus,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget statusBanner(_UserDashboardData data) {
    final hasPending =
        data.totalMenunggu > 0;

    final color = hasPending
        ? orangeStatus
        : primaryGreen;

    final backgroundColor = hasPending
        ? softAmber
        : softGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(
              alpha: 0.045,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              hasPending
                  ? Icons.hourglass_top_rounded
                  : Icons.task_alt_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasPending
                  ? '${data.totalMenunggu} pengajuan sedang '
                      'menunggu verifikasi admin.'
                  : 'Tidak ada pengajuan menunggu. '
                      'Data selesai tersedia di Riwayat.',
              style: const TextStyle(
                color: textDark,
                fontSize: 10.7,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Icon(
            Icons.chevron_right_rounded,
            color: color,
            size: 21,
          ),
        ],
      ),
    );
  }

  Widget mainServicesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        16,
      ),
      decoration: cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          sectionHeader(
            title: 'Layanan Utama',
            subtitle:
                'Ajukan kebutuhan pertanian melalui TaniGo.',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final narrow =
                  constraints.maxWidth < 315;

              if (narrow) {
                return Column(
                  children: [
                    serviceMenuButton(
                      title: 'Bantuan Pupuk',
                      subtitle:
                          'Ajukan kebutuhan pupuk',
                      icon:
                          Icons.inventory_2_outlined,
                      color: primaryGreen,
                      backgroundColor: softGreen,
                      onTap: () {
                        openPage(
                          PupukPage(
                            nama: widget.nama,
                            nik: widget.nik,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    serviceMenuButton(
                      title: 'Peminjaman Alat',
                      subtitle:
                          'Ajukan alat pertanian',
                      icon: Icons.handyman_outlined,
                      color: orangeStatus,
                      backgroundColor: softAmber,
                      onTap: () {
                        openPage(
                          AlatPage(
                            nama: widget.nama,
                            nik: widget.nik,
                          ),
                        );
                      },
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: serviceMenuButton(
                      title: 'Bantuan Pupuk',
                      subtitle:
                          'Ajukan kebutuhan pupuk',
                      icon:
                          Icons.inventory_2_outlined,
                      color: primaryGreen,
                      backgroundColor: softGreen,
                      onTap: () {
                        openPage(
                          PupukPage(
                            nama: widget.nama,
                            nik: widget.nik,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: serviceMenuButton(
                      title: 'Peminjaman Alat',
                      subtitle:
                          'Ajukan alat pertanian',
                      icon: Icons.handyman_outlined,
                      color: orangeStatus,
                      backgroundColor: softAmber,
                      onTap: () {
                        openPage(
                          AlatPage(
                            nama: widget.nama,
                            nik: widget.nik,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget serviceMenuButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 116,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.93,
                      ),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 29,
                    width: 29,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.84,
                      ),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: color,
                      size: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 12.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 9.8,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget pendingSubmissionCard(
    _UserDashboardData data,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        15,
      ),
      decoration: cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengajuan Diproses',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Hanya pengajuan yang belum selesai.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: softTeal,
                borderRadius:
                    BorderRadius.circular(999),
                child: InkWell(
                  onTap: () {
                    openPage(
                      RiwayatPage(
                        nik: widget.nik,
                      ),
                    );
                  },
                  borderRadius:
                      BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(999),
                      border: Border.all(
                        color: tealColor.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: const Text(
                      'RIWAYAT',
                      style: TextStyle(
                        color: tealColor,
                        fontSize: 8.3,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          pendingSubmissionList(
            data.pengajuanMenungguTerbaru,
          ),
        ],
      ),
    );
  }

  Widget pendingSubmissionList(
    List<Map<String, dynamic>> list,
  ) {
    if (list.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: softGreen,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: primaryGreen.withValues(
              alpha: 0.11,
            ),
          ),
        ),
        child: const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _SmallIconBox(
              icon: Icons.task_alt_rounded,
              color: primaryGreen,
              backgroundColor: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tidak ada pengajuan menunggu',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 12.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Pengajuan yang telah disetujui, ditolak, '
                    'atau selesai dapat dilihat di Riwayat.',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 10.1,
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

    return Column(
      children: [
        for (int index = 0;
            index < list.length;
            index++) ...[
          pendingSubmissionItem(list[index]),
          if (index != list.length - 1)
            const SizedBox(height: 9),
        ],
      ],
    );
  }

  Widget pendingSubmissionItem(
    Map<String, dynamic> item,
  ) {
    final jenis =
        (item['jenis_data'] ?? '').toString();

    final isPupuk = jenis == 'pupuk';

    final color =
        isPupuk ? primaryGreen : orangeStatus;

    final backgroundColor =
        isPupuk ? softGreen : softAmber;

    final title = isPupuk
        ? (item['jenis_pupuk'] ??
                item['nama_pupuk'] ??
                'Bantuan Pupuk')
            .toString()
        : (item['alat'] ??
                item['nama_alat'] ??
                'Peminjaman Alat')
            .toString();

    final description = isPupuk
        ? '${item['jumlah_pupuk'] ?? item['jumlah_kg'] ?? item['jumlah'] ?? '-'} Kg'
        : 'Tanggal pinjam: '
            '${item['tanggal_pinjam'] ?? '-'}';

    final status =
        (item['status'] ?? 'menunggu')
            .toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(
          alpha: 0.75,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 43,
            width: 43,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.93,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPupuk
                  ? Icons.inventory_2_outlined
                  : Icons.handyman_outlined,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isPupuk
                            ? 'Bantuan Pupuk'
                            : 'Peminjaman Alat',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 9.2,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    statusBadge(status),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12.7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      color: color,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        submissionTimeLabel(item),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 9.3,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget informationCard(
    List<Map<String, dynamic>> list,
  ) {
    return Container(
      width: double.infinity,
      decoration: cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              15,
              15,
              15,
              12,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Terbaru',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Pengumuman dari kelompok tani.',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 10.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: softTeal,
                  borderRadius:
                      BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () {
                      openPage(
                        const PengumumanPage(),
                      );
                    },
                    borderRadius:
                        BorderRadius.circular(999),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: const Text(
                        'SEMUA',
                        style: TextStyle(
                          color: tealColor,
                          fontSize: 8.3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                15,
                0,
                15,
                15,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: softTeal,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: const Row(
                  children: [
                    _SmallIconBox(
                      icon: Icons.campaign_outlined,
                      color: tealColor,
                      backgroundColor: Colors.white,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Belum ada informasi terbaru dari admin.',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 10.6,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (final item in list.take(3))
              informationItem(item),
            Material(
              color: softTeal,
              borderRadius:
                  const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              child: InkWell(
                onTap: () {
                  openPage(
                    const PengumumanPage(),
                  );
                },
                borderRadius:
                    const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: tealColor.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.campaign_outlined,
                        color: tealColor,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lihat semua informasi',
                          style: TextStyle(
                            color: tealColor,
                            fontSize: 11.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: tealColor,
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget informationItem(
    Map<String, dynamic> item,
  ) {
    final title =
        (item['judul'] ?? 'Informasi')
            .toString();

    final body =
        (item['isi'] ??
                item['deskripsi'] ??
                item['keterangan'] ??
                '-')
            .toString();

    final category =
        (item['kategori'] ?? 'pengumuman')
            .toString();

    final color =
        informationColor(category);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        15,
        12,
        15,
        12,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: cardBorder,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 41,
            width: 41,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              informationIcon(category),
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  informationLabel(category)
                      .toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 8.7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12.6,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.1,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  informationDate(item),
                  style: const TextStyle(
                    color: textSoft,
                    fontSize: 9.3,
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

  Widget sectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 16.5,
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
    );
  }

  Widget statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: statusBg(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: statusColor(status).withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: Text(
        statusText(status),
        style: TextStyle(
          color: statusColor(status),
          fontSize: 8.1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget bottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: cardBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(
              alpha: 0.10,
            ),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: 0,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: tealColor,
          unselectedItemColor: textSoft,
          selectedLabelStyle:
              const TextStyle(
            fontSize: 10.6,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelStyle:
              const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 1) {
              openPage(
                RiwayatPage(
                  nik: widget.nik,
                ),
              );
            } else if (index == 2) {
              openPage(
                ProfilPage(
                  nama: widget.nama,
                  nik: widget.nik,
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home_outlined,
              ),
              activeIcon: Icon(
                Icons.home_rounded,
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.receipt_long_outlined,
              ),
              activeIcon: Icon(
                Icons.receipt_long_rounded,
              ),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.manage_accounts_outlined,
              ),
              activeIcon: Icon(
                Icons.manage_accounts_rounded,
              ),
              label: 'Profil & Akun',
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.98,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: deepTeal.withValues(
            alpha: 0.055,
          ),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _UserDashboardData {
  final List<Map<String, dynamic>>
      bantuanMenunggu;

  final List<Map<String, dynamic>>
      peminjamanMenunggu;

  final List<Map<String, dynamic>>
      pengajuanMenungguTerbaru;

  final int totalNotif;

  final List<Map<String, dynamic>>
      informasiAktif;

  const _UserDashboardData({
    required this.bantuanMenunggu,
    required this.peminjamanMenunggu,
    required this.pengajuanMenungguTerbaru,
    required this.totalNotif,
    required this.informasiAktif,
  });

  factory _UserDashboardData.empty() {
    return const _UserDashboardData(
      bantuanMenunggu: [],
      peminjamanMenunggu: [],
      pengajuanMenungguTerbaru: [],
      totalNotif: 0,
      informasiAktif: [],
    );
  }

  int get totalMenunggu {
    return bantuanMenunggu.length +
        peminjamanMenunggu.length;
  }
}

class _SmallIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _SmallIconBox({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 37,
      width: 37,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: 0.07),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 19,
      ),
    );
  }
}

class _UserDashboardBackground
    extends StatelessWidget {
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
            final width =
                constraints.maxWidth;

            final height =
                constraints.maxHeight;

            final baseSize =
                width < height ? width : height;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(280.0, 460.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.68)
                    .clamp(190.0, 330.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.42)
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
          color: borderColor.withValues(
            alpha: 0.08,
          ),
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