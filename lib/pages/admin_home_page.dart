import 'dart:async';

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
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color redStatus = Color(0xffDC2626);

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _anggotaRef;
  late final DatabaseReference _calonAnggotaRef;
  late final DatabaseReference _bantuanPupukRef;
  late final DatabaseReference _peminjamanAlatRef;
  late final DatabaseReference _notifikasiAdminRef;

  final StreamController<_DashboardData> _dashboardController =
      StreamController<_DashboardData>.broadcast();

  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

  dynamic _anggotaValue;
  dynamic _calonAnggotaValue;
  dynamic _bantuanPupukValue;
  dynamic _peminjamanAlatValue;
  dynamic _notifikasiAdminValue;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _anggotaRef = _db.ref('anggota');
    _calonAnggotaRef = _db.ref('calon_anggota');
    _bantuanPupukRef = _db.ref('bantuan_pupuk');
    _peminjamanAlatRef = _db.ref('peminjaman_alat');
    _notifikasiAdminRef = _db.ref('notifikasi_admin');

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
      _anggotaRef.onValue.listen((event) {
        _anggotaValue = event.snapshot.value;
        _emitDashboardData();
      }),
      _calonAnggotaRef.onValue.listen((event) {
        _calonAnggotaValue = event.snapshot.value;
        _emitDashboardData();
      }),
      _bantuanPupukRef.onValue.listen((event) {
        _bantuanPupukValue = event.snapshot.value;
        _emitDashboardData();
      }),
      _peminjamanAlatRef.onValue.listen((event) {
        _peminjamanAlatValue = event.snapshot.value;
        _emitDashboardData();
      }),
      _notifikasiAdminRef.onValue.listen((event) {
        _notifikasiAdminValue = event.snapshot.value;
        _emitDashboardData();
      }),
    ]);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isDisposed) _emitDashboardData();
    });
  }

  void _emitDashboardData() {
    if (_isDisposed || _dashboardController.isClosed) return;

    final data = _DashboardData(
      totalAnggota: _countTotal(_anggotaValue),
      calonAnggotaMenunggu: _countStatus(_calonAnggotaValue, 'menunggu'),
      bantuanPupukMenunggu: _countStatus(_bantuanPupukValue, 'menunggu'),
      peminjamanAlatMenunggu: _countStatus(_peminjamanAlatValue, 'menunggu'),
      notifikasiBelumDibaca: _countUnreadNotif(_notifikasiAdminValue),
      aktivitas: _buildLatestActivities(),
    );

    _dashboardController.add(data);
  }

  int _countTotal(dynamic value) {
    if (value == null || value is! Map) return 0;
    return value.length;
  }

  int _countStatus(dynamic value, String targetStatus) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is! Map) continue;
      final detail = Map<dynamic, dynamic>.from(item);
      final status =
          (detail['status'] ?? 'menunggu').toString().toLowerCase().trim();

      if (status == targetStatus) total++;
    }

    return total;
  }

  int _countUnreadNotif(dynamic value) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is! Map) continue;
      final notif = Map<dynamic, dynamic>.from(item);
      final dibaca = notif['dibaca'];
      final status = (notif['status'] ?? '').toString().toLowerCase().trim();

      if (dibaca == false || status == 'belum_dibaca') total++;
    }

    return total;
  }

  List<_ActivityItem> _buildLatestActivities() {
    final activities = <_ActivityItem>[];

    activities.addAll(
      _extractActivities(
        value: _calonAnggotaValue,
        type: _ActivityType.anggota,
        fallbackTitle: 'Calon anggota baru',
        icon: Icons.person_add_alt_1_rounded,
        color: blueStatus,
      ),
    );

    activities.addAll(
      _extractActivities(
        value: _bantuanPupukValue,
        type: _ActivityType.pupuk,
        fallbackTitle: 'Pengajuan bantuan pupuk',
        icon: Icons.eco_rounded,
        color: primaryGreen,
      ),
    );

    activities.addAll(
      _extractActivities(
        value: _peminjamanAlatValue,
        type: _ActivityType.alat,
        fallbackTitle: 'Pengajuan peminjaman alat',
        icon: Icons.agriculture_rounded,
        color: orangeStatus,
      ),
    );

    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities.take(5).toList();
  }

  List<_ActivityItem> _extractActivities({
    required dynamic value,
    required _ActivityType type,
    required String fallbackTitle,
    required IconData icon,
    required Color color,
  }) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);
    final result = <_ActivityItem>[];

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail = Map<dynamic, dynamic>.from(item);
      final nama = _safeText(detail['nama']);
      final nik = _safeText(detail['nik']);
      final status = _safeText(detail['status'], fallback: 'menunggu');

      final date = _parseDate(
        detail['created_at'] ??
            detail['createdAt'] ??
            detail['tanggal_pengajuan'] ??
            detail['tanggalPengajuan'] ??
            detail['tanggal_daftar'] ??
            detail['tanggalDaftar'] ??
            detail['tanggal_pinjam'] ??
            detail['tanggalPinjam'],
      );

      String title = fallbackTitle;
      String subtitle = 'Status: ${_formatStatus(status)}';

      if (type == _ActivityType.anggota) {
        title = nama.isEmpty ? fallbackTitle : nama;
        subtitle = nik.isEmpty ? 'Pendaftaran anggota' : 'NIK $nik';
      } else if (type == _ActivityType.pupuk) {
        title = nama.isEmpty ? fallbackTitle : nama;
        subtitle = 'Mengajukan bantuan pupuk';
      } else if (type == _ActivityType.alat) {
        final alat = _safeText(detail['nama_alat'] ?? detail['alat']);
        title = nama.isEmpty ? fallbackTitle : nama;
        subtitle =
            alat.isEmpty ? 'Mengajukan peminjaman alat' : 'Meminjam $alat';
      }

      result.add(
        _ActivityItem(
          title: title,
          subtitle: subtitle,
          status: status,
          date: date,
          icon: icon,
          color: color,
        ),
      );
    }

    return result;
  }

  String _safeText(dynamic value, {String fallback = ''}) {
    return (value ?? fallback).toString().trim();
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    try {
      return DateTime.parse(value.toString().trim());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _formatStatus(String status) {
    final clean = status.toLowerCase().trim().replaceAll('_', ' ');
    if (clean.isEmpty) return 'Menunggu';

    return clean
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
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

    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _openPage(Widget page) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Color _statusColor(String status) {
    final clean = status.toLowerCase().trim();

    if (clean == 'disetujui') return primaryGreen;
    if (clean == 'ditolak') return redStatus;
    if (clean == 'sudah_diambil') return blueStatus;
    if (clean == 'dipinjam') return orangeStatus;
    if (clean == 'dikembalikan') return primaryGreen;

    return orangeStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: _bottomNavigationBar(),
      body: SafeArea(
        child: StreamBuilder<_DashboardData>(
          stream: _dashboardController.stream,
          initialData: _DashboardData.empty(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? _DashboardData.empty();

            return RefreshIndicator(
              color: primaryGreen,
              onRefresh: () async => _emitDashboardData(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                      child: _headerAdmin(data),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                      child: _systemSummary(data),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                      child: _actionPanel(data),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                      child: _sectionTitle(
                        title: 'Menu Administrasi',
                        subtitle: 'Kelola data utama kelompok tani',
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: _menuGrid(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
                      child: _latestActivity(data.aktivitas),
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

  Widget _headerAdmin(_DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
            right: -24,
            bottom: -38,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: 0.055),
            ),
          ),
          Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 4),
                    Text(
                      _todayText(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _notificationButton(data.notifikasiBelumDibaca),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notificationButton(int total) {
    return InkWell(
      onTap: () => _openPage(const NotifikasiAdminPage()),
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          if (total > 0) Positioned(right: -7, top: -7, child: _badge(total)),
        ],
      ),
    );
  }

  Widget _systemSummary(_DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Ringkasan Sistem',
          subtitle: 'Pantauan data utama secara realtime',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: _summaryCard(
                    title: 'Total Anggota',
                    value: data.totalAnggota,
                    icon: Icons.groups_rounded,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _summaryCard(
                    title: 'Verifikasi Anggota',
                    value: data.calonAnggotaMenunggu,
                    icon: Icons.person_add_alt_1_rounded,
                    color: blueStatus,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _summaryCard(
                    title: 'Bantuan Pupuk',
                    value: data.bantuanPupukMenunggu,
                    icon: Icons.eco_rounded,
                    color: primaryGreen,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _summaryCard(
                    title: 'Peminjaman Alat',
                    value: data.peminjamanAlatMenunggu,
                    icon: Icons.agriculture_rounded,
                    color: orangeStatus,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12.4,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPanel(_DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color:
                      data.totalMenunggu == 0
                          ? primaryGreen.withValues(alpha: 0.11)
                          : orangeStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  data.totalMenunggu == 0
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: data.totalMenunggu == 0 ? primaryGreen : orangeStatus,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktivitas yang Memerlukan Tindakan',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.totalMenunggu == 0
                          ? 'Semua pengajuan sudah diproses.'
                          : '${data.totalMenunggu} data menunggu verifikasi admin.',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12.2,
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
          _actionTile(
            title: 'Verifikasi Calon Anggota',
            subtitle: 'Periksa pendaftaran anggota baru',
            count: data.calonAnggotaMenunggu,
            icon: Icons.person_add_alt_1_rounded,
            color: blueStatus,
            page: const VerifikasiAnggotaPage(),
          ),
          const SizedBox(height: 10),
          _actionTile(
            title: 'Verifikasi Bantuan Pupuk',
            subtitle: 'Setujui atau tolak pengajuan pupuk',
            count: data.bantuanPupukMenunggu,
            icon: Icons.eco_rounded,
            color: primaryGreen,
            page: const VerifikasiPupukPage(),
          ),
          const SizedBox(height: 10),
          _actionTile(
            title: 'Verifikasi Peminjaman Alat',
            subtitle: 'Kelola permintaan peminjaman alat',
            count: data.peminjamanAlatMenunggu,
            icon: Icons.agriculture_rounded,
            color: orangeStatus,
            page: const VerifikasiPeminjamanPage(),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      onTap: () => _openPage(page),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              height: 43,
              width: 43,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(width: 12),
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
                      fontSize: 13.3,
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
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              _badge(count),
            ] else ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.8),
                size: 24,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _menuGrid() {
    final menus = [
      _AdminMenu(
        title: 'Kelola Pupuk',
        subtitle: 'Stok dan jenis pupuk',
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
        subtitle: 'Jadwal peminjaman',
        icon: Icons.calendar_month_rounded,
        color: blueStatus,
        page: const JadwalAlatAdminPage(),
      ),
      _AdminMenu(
        title: 'Pengumuman',
        subtitle: 'Informasi anggota',
        icon: Icons.campaign_rounded,
        color: primaryGreen,
        page: const KelolaPengumumanPage(),
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
                return SizedBox(width: itemWidth, child: _menuCard(menu));
              }).toList(),
        );
      },
    );
  }

  Widget _menuCard(_AdminMenu menu) {
    return InkWell(
      onTap: () => _openPage(menu.page),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 142,
        padding: const EdgeInsets.all(15),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 47,
              width: 47,
              decoration: BoxDecoration(
                color: menu.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(menu.icon, color: menu.color, size: 26),
            ),
            const Spacer(),
            Text(
              menu.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 14.2,
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
                fontSize: 11.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _latestActivity(List<_ActivityItem> activities) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            title: 'Aktivitas Terbaru',
            subtitle: 'Maksimal 5 data terakhir dari sistem',
          ),
          const SizedBox(height: 14),
          if (activities.isEmpty)
            _emptyState()
          else
            ListView.separated(
              itemCount: activities.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder:
                  (_, __) => Divider(
                    height: 18,
                    color: cardBorder.withValues(alpha: 0.75),
                  ),
              itemBuilder: (context, index) {
                return _activityTile(activities[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _activityTile(_ActivityItem item) {
    return Row(
      children: [
        Container(
          height: 43,
          width: 43,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(item.status).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _formatStatus(item.status),
            style: TextStyle(
              color: _statusColor(item.status),
              fontSize: 10.4,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: softGreen.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(color: cardBorder),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: primaryGreen,
              size: 31,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Belum Ada Aktivitas',
            style: TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Aktivitas anggota, bantuan pupuk, dan peminjaman alat akan tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(int total) {
    final text = total > 99 ? '99+' : total.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
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

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 5,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            _openPage(const LaporanPage());
          } else if (index == 2) {
            _openPage(const ProfilAdminPage());
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

enum _ActivityType { anggota, pupuk, alat }

class _DashboardData {
  final int totalAnggota;
  final int calonAnggotaMenunggu;
  final int bantuanPupukMenunggu;
  final int peminjamanAlatMenunggu;
  final int notifikasiBelumDibaca;
  final List<_ActivityItem> aktivitas;

  const _DashboardData({
    required this.totalAnggota,
    required this.calonAnggotaMenunggu,
    required this.bantuanPupukMenunggu,
    required this.peminjamanAlatMenunggu,
    required this.notifikasiBelumDibaca,
    required this.aktivitas,
  });

  factory _DashboardData.empty() {
    return const _DashboardData(
      totalAnggota: 0,
      calonAnggotaMenunggu: 0,
      bantuanPupukMenunggu: 0,
      peminjamanAlatMenunggu: 0,
      notifikasiBelumDibaca: 0,
      aktivitas: [],
    );
  }

  int get totalMenunggu =>
      calonAnggotaMenunggu + bantuanPupukMenunggu + peminjamanAlatMenunggu;
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.icon,
    required this.color,
  });
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
