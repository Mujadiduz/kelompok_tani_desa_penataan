import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../widgets/app_background.dart';
import 'jadwal_alat_admin_page.dart';
import 'kelola_alat_page.dart';
import 'kelola_pengumuman_page.dart';
import 'kelola_pupuk_page.dart';
import 'laporan_page.dart';
import 'notifikasi_admin_page.dart';
import 'profil_admin_page.dart';
import 'reset_password_admin_page.dart';
import 'riwayat_admin_page.dart';
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
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color redStatus = Color(0xffDC2626);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color purpleStatus = Color(0xff7C3AED);

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _anggotaRef;
  late final DatabaseReference _calonAnggotaRef;
  late final DatabaseReference _bantuanPupukRef;
  late final DatabaseReference _peminjamanAlatRef;
  late final DatabaseReference _resetPasswordRef;
  late final DatabaseReference _notifikasiAdminRef;

  final StreamController<_DashboardData> _dashboardController =
      StreamController<_DashboardData>.broadcast();

  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

  final Set<String> _knownAdminNotifKeys = {};
  final Set<String> _shownAdminNotifKeys = {};

  dynamic _anggotaValue;
  dynamic _calonAnggotaValue;
  dynamic _bantuanPupukValue;
  dynamic _peminjamanAlatValue;
  dynamic _resetPasswordValue;
  dynamic _notifikasiAdminValue;

  bool _isDisposed = false;
  bool _adminNotifInitialLoaded = false;

  @override
  void initState() {
    super.initState();

    _anggotaRef = _db.ref('anggota');
    _calonAnggotaRef = _db.ref('calon_anggota');
    _bantuanPupukRef = _db.ref('bantuan_pupuk');
    _peminjamanAlatRef = _db.ref('peminjaman_alat');
    _resetPasswordRef = _db.ref('reset_password');
    _notifikasiAdminRef = _db.ref('notifikasi_admin');

    _listenDashboard();
    _listenLocalAdminNotification();
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

  void _listenDashboard() {
    _subscriptions.addAll([
      _anggotaRef.onValue.listen((event) {
        _anggotaValue = event.snapshot.value;
        _emitDashboard();
      }),
      _calonAnggotaRef.onValue.listen((event) {
        _calonAnggotaValue = event.snapshot.value;
        _emitDashboard();
      }),
      _bantuanPupukRef.onValue.listen((event) {
        _bantuanPupukValue = event.snapshot.value;
        _emitDashboard();
      }),
      _peminjamanAlatRef.onValue.listen((event) {
        _peminjamanAlatValue = event.snapshot.value;
        _emitDashboard();
      }),
      _resetPasswordRef.onValue.listen((event) {
        _resetPasswordValue = event.snapshot.value;
        _emitDashboard();
      }),
      _notifikasiAdminRef.onValue.listen((event) {
        _notifikasiAdminValue = event.snapshot.value;
        _emitDashboard();
      }),
    ]);

    _emitDashboard();
  }

  void _listenLocalAdminNotification() {
    _subscriptions.add(
      _notifikasiAdminRef.onChildAdded.listen((event) async {
        if (_isDisposed) return;

        final key = event.snapshot.key;
        final value = event.snapshot.value;

        if (key == null || key.trim().isEmpty) return;

        if (!_adminNotifInitialLoaded) {
          _knownAdminNotifKeys.add(key);
          return;
        }

        if (_knownAdminNotifKeys.contains(key)) return;
        if (_shownAdminNotifKeys.contains(key)) return;

        _knownAdminNotifKeys.add(key);
        _shownAdminNotifKeys.add(key);

        if (value is! Map) return;

        final data = Map<dynamic, dynamic>.from(value);

        final judul = _text(
          data['judul'],
          fallback: _adminNotificationTitle(data['tipe']),
        );

        final pesan = _text(
          data['pesan'],
          fallback: 'Ada pemberitahuan admin baru di aplikasi TaniGo.',
        );

        await NotificationService.showLocalNotification(
          title: judul,
          body: pesan,
        );
      }),
    );

    Future.delayed(const Duration(milliseconds: 900), () {
      if (_isDisposed) return;
      _adminNotifInitialLoaded = true;
    });
  }

  String _adminNotificationTitle(dynamic tipe) {
    final cleanType = (tipe ?? '').toString().toLowerCase().trim();

    if (cleanType.contains('anggota')) {
      return 'Calon Anggota Baru';
    }

    if (cleanType.contains('pupuk')) {
      return 'Pengajuan Bantuan Pupuk Baru';
    }

    if (cleanType.contains('alat') || cleanType.contains('peminjaman')) {
      return 'Pengajuan Peminjaman Alat Baru';
    }

    if (cleanType.contains('reset') || cleanType.contains('password')) {
      return 'Permintaan Reset Password Baru';
    }

    return 'Notifikasi Admin TaniGo';
  }

  void _emitDashboard() {
    if (_isDisposed || _dashboardController.isClosed) return;

    final data = _DashboardData(
      totalAnggotaAktif: _countAnggotaAktif(_anggotaValue),
      verifikasiAnggotaMenunggu: _countStatus(_calonAnggotaValue, 'menunggu'),
      bantuanPupukMenunggu: _countStatus(_bantuanPupukValue, 'menunggu'),
      peminjamanAlatMenunggu: _countStatus(_peminjamanAlatValue, 'menunggu'),
      resetPasswordMenunggu: _countStatus(_resetPasswordValue, 'menunggu'),
      notifikasiBelumDibaca: _countUnreadNotification(_notifikasiAdminValue),
      latestNotices: _buildLatestNotices(),
    );

    _dashboardController.add(data);
  }

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value == null || value is! Map) return {};
    return Map<dynamic, dynamic>.from(value);
  }

  int _countAnggotaAktif(dynamic value) {
    final data = _asMap(value);
    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;
      final detail = Map<dynamic, dynamic>.from(item);
      final status = _cleanStatus(detail['status']);

      if (status.isEmpty ||
          status == 'aktif' ||
          status == 'disetujui' ||
          status == 'anggota') {
        total++;
      }
    }

    return total;
  }

  int _countStatus(dynamic value, String targetStatus) {
    final data = _asMap(value);
    int total = 0;
    final target = targetStatus.toLowerCase().trim();

    for (final item in data.values) {
      if (item is! Map) continue;
      final detail = Map<dynamic, dynamic>.from(item);
      final status = _cleanStatus(detail['status']);

      if (status == target) total++;
    }

    return total;
  }

  int _countUnreadNotification(dynamic value) {
    final data = _asMap(value);
    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;
      final detail = Map<dynamic, dynamic>.from(item);
      final status = _cleanStatus(detail['status']);
      final dibaca = detail['dibaca'];

      if (dibaca == false || status == 'belum_dibaca') total++;
    }

    return total;
  }

  List<_NoticeItem> _buildLatestNotices() {
    final items = <_NoticeItem>[];

    void addItems({
      required dynamic source,
      required String title,
      required String Function(Map<dynamic, dynamic> data) subtitleBuilder,
      required IconData icon,
      required Color color,
      required Widget page,
      required _NoticeType type,
    }) {
      final data = _asMap(source);

      for (final entry in data.entries) {
        final value = entry.value;
        if (value is! Map) continue;

        final detail = Map<dynamic, dynamic>.from(value);
        final status = _cleanStatus(detail['status']);
        if (status != 'menunggu') continue;

        items.add(
          _NoticeItem(
            title: title,
            subtitle: subtitleBuilder(detail),
            icon: icon,
            color: color,
            page: page,
            type: type,
            date: _readDate(detail),
          ),
        );
      }
    }

    addItems(
      source: _calonAnggotaValue,
      title: 'Verifikasi Anggota',
      subtitleBuilder: (data) {
        final nama = _text(data['nama'], fallback: 'Calon anggota baru');
        final nik = _text(data['nik'], fallback: '-');
        return '$nama • NIK $nik';
      },
      icon: Icons.assignment_ind_rounded,
      color: primaryGreen,
      page: const VerifikasiAnggotaPage(),
      type: _NoticeType.anggota,
    );

    addItems(
      source: _bantuanPupukValue,
      title: 'Bantuan Pupuk',
      subtitleBuilder: (data) {
        final nama = _text(data['nama'], fallback: 'Pengajuan pupuk');
        final jenis = _text(
          data['jenis_pupuk'] ?? data['nama_pupuk'],
          fallback: 'Menunggu verifikasi',
        );
        return '$nama • $jenis';
      },
      icon: Icons.inventory_2_rounded,
      color: primaryGreen,
      page: const VerifikasiPupukPage(),
      type: _NoticeType.pupuk,
    );

    addItems(
      source: _peminjamanAlatValue,
      title: 'Peminjaman Alat',
      subtitleBuilder: (data) {
        final nama = _text(data['nama'], fallback: 'Pengajuan alat');
        final alat = _text(
          data['nama_alat'] ?? data['alat'],
          fallback: 'Menunggu verifikasi',
        );
        return '$nama • $alat';
      },
      icon: Icons.handyman_rounded,
      color: orangeStatus,
      page: const VerifikasiPeminjamanPage(),
      type: _NoticeType.alat,
    );

    addItems(
      source: _resetPasswordValue,
      title: 'Reset Password',
      subtitleBuilder: (data) {
        final nama = _text(data['nama'], fallback: 'Permintaan reset');
        final nik = _text(data['nik'], fallback: '-');
        return '$nama • NIK $nik';
      },
      icon: Icons.lock_reset_rounded,
      color: blueStatus,
      page: const ResetPasswordAdminPage(),
      type: _NoticeType.reset,
    );

    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(6).toList();
  }

  DateTime _readDate(Map<dynamic, dynamic> data) {
    final raw =
        data['tanggal_pengajuan'] ??
        data['created_at'] ??
        data['tanggal'] ??
        data['tanggal_reset'] ??
        data['tanggal_permintaan'] ??
        data['timestamp'] ??
        data['updated_at'];

    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);

    if (raw is int) {
      if (raw.toString().length >= 13) {
        return DateTime.fromMillisecondsSinceEpoch(raw);
      }
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    }

    final parsed = DateTime.tryParse(raw.toString());
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _cleanStatus(dynamic value) {
    return (value ?? '').toString().toLowerCase().trim();
  }

  String _text(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    if (text.isEmpty) return fallback;
    return text;
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

    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  void _openPage(Widget page) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openManagementSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _premiumSheet(
          title: 'Menu Manajemen',
          subtitle: 'Kelola data utama aplikasi TaniGo',
          icon: Icons.grid_view_rounded,
          children: [
            _sheetMenuTile(
              title: 'Kelola Pupuk',
              subtitle: 'Stok dan jenis pupuk',
              icon: Icons.inventory_2_rounded,
              color: primaryGreen,
              page: const KelolaPupukPage(),
            ),
            _divider(),
            _sheetMenuTile(
              title: 'Kelola Alat',
              subtitle: 'Data alat pertanian',
              icon: Icons.precision_manufacturing_rounded,
              color: orangeStatus,
              page: const KelolaAlatPage(),
            ),
            _divider(),
            _sheetMenuTile(
              title: 'Jadwal Alat',
              subtitle: 'Jadwal peminjaman alat',
              icon: Icons.calendar_month_rounded,
              color: blueStatus,
              page: const JadwalAlatAdminPage(),
            ),
            _divider(),
            _sheetMenuTile(
              title: 'Kelola Pengumuman',
              subtitle: 'Informasi untuk anggota',
              icon: Icons.campaign_rounded,
              color: purpleStatus,
              page: const KelolaPengumumanPage(),
            ),
          ],
        );
      },
    );
  }

  void _openPengajuanSheet(_DashboardData data) {
    if (!mounted) return;

    final totalPengajuan =
        data.verifikasiAnggotaMenunggu +
        data.bantuanPupukMenunggu +
        data.peminjamanAlatMenunggu;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _premiumSheet(
          title: 'Pilih Pengajuan',
          subtitle:
              totalPengajuan == 0
                  ? 'Tidak ada pengajuan yang menunggu verifikasi'
                  : '$totalPengajuan pengajuan belum diverifikasi',
          icon: Icons.fact_check_rounded,
          trailing: _sheetTotalBadge(totalPengajuan, orangeStatus),
          children: [
            _sheetMenuTile(
              title: 'Verifikasi Anggota',
              subtitle:
                  data.verifikasiAnggotaMenunggu == 0
                      ? 'Tidak ada calon anggota baru'
                      : '${data.verifikasiAnggotaMenunggu} calon anggota menunggu',
              icon: Icons.assignment_ind_rounded,
              color: blueStatus,
              page: const VerifikasiAnggotaPage(),
              count: data.verifikasiAnggotaMenunggu,
            ),
            _divider(),
            _sheetMenuTile(
              title: 'Verifikasi Bantuan Pupuk',
              subtitle:
                  data.bantuanPupukMenunggu == 0
                      ? 'Tidak ada pengajuan pupuk'
                      : '${data.bantuanPupukMenunggu} bantuan pupuk menunggu',
              icon: Icons.inventory_2_rounded,
              color: primaryGreen,
              page: const VerifikasiPupukPage(),
              count: data.bantuanPupukMenunggu,
            ),
            _divider(),
            _sheetMenuTile(
              title: 'Verifikasi Peminjaman Alat',
              subtitle:
                  data.peminjamanAlatMenunggu == 0
                      ? 'Tidak ada peminjaman alat'
                      : '${data.peminjamanAlatMenunggu} peminjaman alat menunggu',
              icon: Icons.handyman_rounded,
              color: orangeStatus,
              page: const VerifikasiPeminjamanPage(),
              count: data.peminjamanAlatMenunggu,
            ),
          ],
        );
      },
    );
  }

  Widget _premiumSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xffD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _iconBox(icon, primaryGreen),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 18,
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
                if (trailing != null) ...[const SizedBox(width: 8), trailing],
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _sheetMenuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
    int? count,
  }) {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
        _openPage(page);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            _iconBox(icon, color),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (count != null) ...[
              _sheetCountBadge(count, color),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _sheetTotalBadge(int total, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 38, minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        total > 99 ? '99+' : total.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _sheetCountBadge(int total, Color color) {
    final hasData = total > 0;

    return Container(
      constraints: const BoxConstraints(minWidth: 28, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: hasData ? color : const Color(0xffF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              hasData ? color.withValues(alpha: 0.18) : const Color(0xffE5E7EB),
        ),
      ),
      child: Text(
        total > 99 ? '99+' : total.toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: hasData ? Colors.white : textGrey,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: _bottomNavigationBar(),
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
          child: StreamBuilder<_DashboardData>(
            stream: _dashboardController.stream,
            initialData: _DashboardData.empty(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? _DashboardData.empty();

              return RefreshIndicator(
                color: primaryGreen,
                onRefresh: () async => _emitDashboard(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    _header(data),
                    const SizedBox(height: 12),
                    _compactSummary(data),
                    const SizedBox(height: 14),
                    _taskStatusCard(data),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      title: 'Tugas Admin',
                      actionText: 'Menu',
                      onTap: _openManagementSheet,
                    ),
                    const SizedBox(height: 10),
                    _taskList(data),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      title: 'Pemberitahuan Terbaru',
                      actionText: 'Pengajuan',
                      onTap: () => _openPengajuanSheet(data),
                    ),
                    const SizedBox(height: 10),
                    _latestNoticeCard(data.latestNotices),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(_DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _openManagementSheet,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Admin Desa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _todayText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _notificationButton(data.notifikasiBelumDibaca),
        ],
      ),
    );
  }

  Widget _notificationButton(int total) {
    return InkWell(
      onTap: () => _openPage(const NotifikasiAdminPage()),
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
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (total > 0)
              Positioned(right: 1, top: 1, child: _notificationBadge(total)),
          ],
        ),
      ),
    );
  }

  Widget _notificationBadge(int total) {
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

  Widget _compactSummary(_DashboardData data) {
    final totalPengajuan =
        data.verifikasiAnggotaMenunggu +
        data.bantuanPupukMenunggu +
        data.peminjamanAlatMenunggu;

    final items = [
      _SummaryItem(
        title: 'Anggota',
        value: data.totalAnggotaAktif,
        icon: Icons.verified_user_rounded,
        color: primaryGreen,
        onTap: () => _openPage(const VerifikasiAnggotaPage()),
      ),
      _SummaryItem(
        title: 'Pengajuan',
        value: totalPengajuan,
        icon: Icons.fact_check_rounded,
        color: orangeStatus,
        onTap: () => _openPengajuanSheet(data),
      ),
      _SummaryItem(
        title: 'Reset',
        value: data.resetPasswordMenunggu,
        icon: Icons.lock_person_rounded,
        color: blueStatus,
        onTap: () => _openPage(const ResetPasswordAdminPage()),
      ),
      _SummaryItem(
        title: 'Notifikasi',
        value: data.notifikasiBelumDibaca,
        icon: Icons.notifications_none_rounded,
        color: redStatus,
        onTap: () => _openPage(const NotifikasiAdminPage()),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _compactSummaryItem(items[i])),
            if (i != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _compactSummaryItem(_SummaryItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: item.color.withValues(alpha: 0.13)),
        ),
        child: Column(
          children: [
            Icon(item.icon, color: item.color, size: 21),
            const SizedBox(height: 7),
            Text(
              item.value > 99 ? '99+' : item.value.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.color,
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 10.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taskStatusCard(_DashboardData data) {
    final clear = data.totalTugasMenunggu == 0;
    final color = clear ? primaryGreen : orangeStatus;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          _iconBox(
            clear ? Icons.task_alt_rounded : Icons.schedule_rounded,
            color,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clear ? 'Semua tugas selesai.' : 'Status Hari Ini',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  clear
                      ? 'Tidak ada data yang perlu diverifikasi saat ini.'
                      : '${data.totalTugasMenunggu} data masih menunggu verifikasi admin.',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.8,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.totalTugasMenunggu > 99
                  ? '99+'
                  : data.totalTugasMenunggu.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskList(_DashboardData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        children: [
          _taskTile(
            title: 'Verifikasi Anggota',
            subtitle: 'Calon anggota baru',
            count: data.verifikasiAnggotaMenunggu,
            icon: Icons.assignment_ind_rounded,
            color: primaryGreen,
            page: const VerifikasiAnggotaPage(),
          ),
          _divider(),
          _taskTile(
            title: 'Bantuan Pupuk',
            subtitle: 'Pengajuan bantuan pupuk',
            count: data.bantuanPupukMenunggu,
            icon: Icons.inventory_2_rounded,
            color: primaryGreen,
            page: const VerifikasiPupukPage(),
          ),
          _divider(),
          _taskTile(
            title: 'Peminjaman Alat',
            subtitle: 'Pengajuan alat pertanian',
            count: data.peminjamanAlatMenunggu,
            icon: Icons.handyman_rounded,
            color: orangeStatus,
            page: const VerifikasiPeminjamanPage(),
          ),
          _divider(),
          _taskTile(
            title: 'Reset Password',
            subtitle: 'Permintaan pemulihan akun',
            count: data.resetPasswordMenunggu,
            icon: Icons.lock_person_rounded,
            color: blueStatus,
            page: const ResetPasswordAdminPage(),
          ),
        ],
      ),
    );
  }

  Widget _taskTile({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
      onTap: () => _openPage(page),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            _iconBox(icon, color),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 13.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0) _smallBadge(count, color),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _latestNoticeCard(List<_NoticeItem> notices) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: _cardDecoration(radius: 18),
      child:
          notices.isEmpty
              ? _emptyLatestNotice()
              : Column(
                children: [
                  for (int i = 0; i < notices.length; i++) ...[
                    _latestNoticeTile(notices[i]),
                    if (i != notices.length - 1) _divider(),
                  ],
                ],
              ),
    );
  }

  Widget _emptyLatestNotice() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          _iconBox(Icons.done_all_rounded, primaryGreen),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belum ada pemberitahuan baru',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Semua pengajuan menunggu akan tampil di sini.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.8,
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

  Widget _latestNoticeTile(_NoticeItem item) {
    return InkWell(
      onTap: () => _openPage(item.page),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            _iconBox(item.icon, item.color),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 13.8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _newBadge(),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
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
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: item.color),
          ],
        ),
      ),
    );
  }

  Widget _newBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: redStatus.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: redStatus.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'Baru',
        style: TextStyle(
          color: redStatus,
          fontSize: 9.5,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _smallBadge(int total, Color color) {
    final text = total > 99 ? '99+' : total.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 25, minHeight: 23),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
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

  Widget _sectionTitle({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: softGreen.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_rounded, color: primaryGreen, size: 16),
                const SizedBox(width: 5),
                Text(
                  actionText,
                  style: const TextStyle(
                    color: primaryGreen,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: cardBorder);
  }

  Widget _bottomNavigationBar() {
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
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            _openPage(const RiwayatAdminPage());
          } else if (index == 2) {
            _openPage(const LaporanPage());
          } else if (index == 3) {
            _openPage(const ProfilAdminPage());
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _NoticeItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
  final _NoticeType type;
  final DateTime date;

  const _NoticeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
    required this.type,
    required this.date,
  });
}

enum _NoticeType { anggota, pupuk, alat, reset }

class _DashboardData {
  final int totalAnggotaAktif;
  final int verifikasiAnggotaMenunggu;
  final int bantuanPupukMenunggu;
  final int peminjamanAlatMenunggu;
  final int resetPasswordMenunggu;
  final int notifikasiBelumDibaca;
  final List<_NoticeItem> latestNotices;

  const _DashboardData({
    required this.totalAnggotaAktif,
    required this.verifikasiAnggotaMenunggu,
    required this.bantuanPupukMenunggu,
    required this.peminjamanAlatMenunggu,
    required this.resetPasswordMenunggu,
    required this.notifikasiBelumDibaca,
    required this.latestNotices,
  });

  factory _DashboardData.empty() {
    return const _DashboardData(
      totalAnggotaAktif: 0,
      verifikasiAnggotaMenunggu: 0,
      bantuanPupukMenunggu: 0,
      peminjamanAlatMenunggu: 0,
      resetPasswordMenunggu: 0,
      notifikasiBelumDibaca: 0,
      latestNotices: [],
    );
  }

  int get totalTugasMenunggu =>
      verifikasiAnggotaMenunggu +
      bantuanPupukMenunggu +
      peminjamanAlatMenunggu +
      resetPasswordMenunggu;
}
