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
  static const Color softGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color redStatus = Color(0xffDC2626);

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _bantuanRef;
  late final DatabaseReference _peminjamanRef;
  late final DatabaseReference _notifikasiRef;
  late final DatabaseReference _pengumumanRef;

  final StreamController<_UserDashboardData> _dashboardController =
      StreamController<_UserDashboardData>.broadcast();

  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

  dynamic _bantuanValue;
  dynamic _peminjamanValue;
  dynamic _notifikasiValue;
  dynamic _pengumumanValue;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _bantuanRef = _db.ref('bantuan_pupuk');
    _peminjamanRef = _db.ref('peminjaman_alat');
    _notifikasiRef = _db.ref('notifikasi').child(widget.nik.trim());
    _pengumumanRef = _db.ref('pengumuman');

    _listenDashboardData();
  }

  @override
  void dispose() {
    _isDisposed = true;

    for (final sub in _subscriptions) {
      sub.cancel();
    }

    _dashboardController.close();
    super.dispose();
  }

  void _listenDashboardData() {
    _subscriptions.addAll([
      _bantuanRef.onValue.listen((event) {
        _bantuanValue = event.snapshot.value;
        _emitDashboardData();
      }),
      _peminjamanRef.onValue.listen((event) {
        _peminjamanValue = event.snapshot.value;
        _emitDashboardData();
      }),
      _notifikasiRef.onValue.listen((event) {
        _notifikasiValue = event.snapshot.value;
        _emitDashboardData();
      }),
      _pengumumanRef.onValue.listen((event) {
        _pengumumanValue = event.snapshot.value;
        _emitDashboardData();
      }),
    ]);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) _emitDashboardData();
    });
  }

  void _emitDashboardData() {
    if (_isDisposed || _dashboardController.isClosed) return;

    final bantuanUser = _getDataByNik(_bantuanValue);
    final peminjamanUser = _getDataByNik(_peminjamanValue);

    final bantuanMenunggu = _filterStatus(bantuanUser, ['menunggu']);
    final peminjamanMenunggu = _filterStatus(peminjamanUser, ['menunggu']);

    final data = _UserDashboardData(
      bantuanMenunggu: bantuanMenunggu,
      peminjamanMenunggu: peminjamanMenunggu,
      totalNotif: _countUnreadNotif(_notifikasiValue),
      pengumumanAktif: _getActiveAnnouncements(_pengumumanValue),
    );

    _dashboardController.add(data);
  }

  List<Map<String, dynamic>> _getDataByNik(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);
    final nikUser = widget.nik.trim();

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final item = Map<String, dynamic>.from(entry.value);
              item['id'] = entry.key.toString();
              return item;
            })
            .where((item) {
              final nikData = (item['nik'] ?? '').toString().trim();
              return nikData == nikUser;
            })
            .toList();

    list.sort((a, b) => _nilaiWaktu(b).compareTo(_nilaiWaktu(a)));
    return list;
  }

  List<Map<String, dynamic>> _filterStatus(
    List<Map<String, dynamic>> data,
    List<String> statusList,
  ) {
    return data.where((item) {
      final status =
          (item['status'] ?? 'menunggu').toString().toLowerCase().trim();

      return statusList.contains(status);
    }).toList();
  }

  int _countUnreadNotif(dynamic value) {
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

  List<Map<String, dynamic>> _getActiveAnnouncements(dynamic value) {
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
              final status =
                  (item['status'] ?? '').toString().toLowerCase().trim();
              return status == 'aktif';
            })
            .toList();

    list.sort((a, b) => _nilaiWaktu(b).compareTo(_nilaiWaktu(a)));
    return list;
  }

  int _nilaiWaktu(Map<String, dynamic> item) {
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

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _todayText() {
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

  String _announcementDate(Map<String, dynamic> item) {
    final tanggal = (item['tanggal'] ?? item['tgl'] ?? '').toString().trim();
    if (tanggal.isNotEmpty) return tanggal;

    final raw = item['created_at'] ?? item['createdAt'] ?? item['waktu'];

    if (raw is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(raw);
      return '${date.day} ${_monthName(date.month)} ${date.year}';
    }

    if (raw is double) {
      final date = DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      return '${date.day} ${_monthName(date.month)} ${date.year}';
    }

    return 'Pengumuman desa';
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }

  void _openPage(Widget page) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: _bottomNav(),
      body: SafeArea(
        child: StreamBuilder<_UserDashboardData>(
          stream: _dashboardController.stream,
          initialData: _UserDashboardData.empty(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? _UserDashboardData.empty();

            return RefreshIndicator(
              color: primaryGreen,
              onRefresh: () async => _emitDashboardData(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                      child: _headerPremium(data),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: _membershipCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: _todaySummary(data),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                      child: _sectionTitle('Layanan Utama'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: _serviceGrid(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                      child: _sectionTitle('Pengajuan Saya'),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: _mySubmissionCard(data),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                      child: _sectionTitleWithAction(
                        title: 'Pengumuman Terbaru',
                        actionText: 'Lihat Semua',
                        onTap: () => _openPage(const PengumumanPage()),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                      child: _latestAnnouncement(data.pengumumanAktif),
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

  Widget _headerPremium(_UserDashboardData data) {
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
                          _greeting(),
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
                          _todayText(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _notifButton(data.totalNotif),
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
                        data.totalMenunggu == 0
                            ? Icons.check_circle_rounded
                            : Icons.pending_actions_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data.totalMenunggu == 0
                            ? 'Semua pengajuan kamu sedang aman. Silakan gunakan layanan sesuai kebutuhan.'
                            : '${data.totalMenunggu} pengajuan masih menunggu verifikasi admin.',
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
      onTap: () => _openPage(NotifikasiPage(nik: widget.nik)),
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
          if (totalNotif > 0)
            Positioned(
              right: -8,
              top: -8,
              child: _notificationBadge(totalNotif),
            ),
        ],
      ),
    );
  }

  Widget _notificationBadge(int total) {
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

  Widget _membershipCard() {
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

  Widget _todaySummary(_UserDashboardData data) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              data.totalMenunggu == 0
                  ? [Colors.white, softGreen]
                  : [Colors.white, const Color(0xffFFF7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color:
                      data.totalMenunggu == 0
                          ? primaryGreen.withValues(alpha: 0.12)
                          : orangeStatus.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  data.totalMenunggu == 0
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  color: data.totalMenunggu == 0 ? primaryGreen : orangeStatus,
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
                      data.totalMenunggu == 0
                          ? 'Tidak ada pengajuan yang menunggu.'
                          : '${data.totalMenunggu} pengajuan sedang menunggu admin.',
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
                  value: data.bantuanMenunggu.length.toString(),
                  subtitle: 'Menunggu',
                  icon: Icons.eco_rounded,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniDashboardCard(
                  title: 'Alat',
                  value: data.peminjamanMenunggu.length.toString(),
                  subtitle: 'Menunggu',
                  icon: Icons.agriculture_rounded,
                  color: orangeStatus,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniDashboardCard(
                  title: 'Notif',
                  value: data.totalNotif.toString(),
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

  Widget _serviceGrid() {
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              menus.map((menu) {
                return SizedBox(width: itemWidth, child: _serviceCard(menu));
              }).toList(),
        );
      },
    );
  }

  Widget _serviceCard(_HomeMenu menu) {
    return InkWell(
      onTap: () => _openPage(menu.page),
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 150,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _mySubmissionCard(_UserDashboardData data) {
    final total = data.totalMenunggu;

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
          _submissionHeader(total),
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
          ...data.bantuanMenunggu.map(
            (item) => _submissionItem(
              icon: Icons.grass_rounded,
              color: primaryGreen,
              title: 'Bantuan Pupuk',
              subtitle:
                  '${item['jenis_pupuk'] ?? item['nama_pupuk'] ?? '-'} • ${item['jumlah_pupuk'] ?? item['jumlah_kg'] ?? item['jumlah'] ?? '-'} Kg',
            ),
          ),
          ...data.peminjamanMenunggu.map(
            (item) => _submissionItem(
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

  Widget _submissionHeader(int total) {
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

  Widget _submissionItem({
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _latestAnnouncement(List<Map<String, dynamic>> list) {
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
    final title = (item['judul'] ?? 'Pengumuman Desa').toString();
    final body =
        (item['isi'] ?? item['deskripsi'] ?? item['keterangan'] ?? '-')
            .toString();

    return InkWell(
      onTap: () => _openPage(const PengumumanPage()),
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
                        _announcementDate(item),
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
                  title,
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
                  body,
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
                const Row(
                  children: [
                    Text(
                      'Baca pengumuman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
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
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            _openPage(RiwayatPage(nik: widget.nik));
          } else if (index == 2) {
            _openPage(ProfilPage(nama: widget.nama, nik: widget.nik));
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
      border: Border.all(color: cardBorder),
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

class _UserDashboardData {
  final List<Map<String, dynamic>> bantuanMenunggu;
  final List<Map<String, dynamic>> peminjamanMenunggu;
  final int totalNotif;
  final List<Map<String, dynamic>> pengumumanAktif;

  const _UserDashboardData({
    required this.bantuanMenunggu,
    required this.peminjamanMenunggu,
    required this.totalNotif,
    required this.pengumumanAktif,
  });

  factory _UserDashboardData.empty() {
    return const _UserDashboardData(
      bantuanMenunggu: [],
      peminjamanMenunggu: [],
      totalNotif: 0,
      pengumumanAktif: [],
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
