import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'jadwal_alat_admin_page.dart';
import 'kelola_alat_page.dart';
import 'kelola_pengumuman_page.dart';
import 'kelola_pupuk_page.dart';
import 'notifikasi_admin_page.dart';
import 'profil_admin_page.dart';
import 'reset_password_admin_page.dart';
import 'riwayat_admin_page.dart';
import 'verifikasi_anggota_page.dart';
import 'verifikasi_peminjaman_page.dart';
import 'verifikasi_pupuk_page.dart';
import 'laporan_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF4F7F4);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color redStatus = Color(0xffDC2626);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color blueStatus = Color(0xff2563EB);

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

  dynamic _anggotaValue;
  dynamic _calonAnggotaValue;
  dynamic _bantuanPupukValue;
  dynamic _peminjamanAlatValue;
  dynamic _resetPasswordValue;
  dynamic _notifikasiAdminValue;

  bool _isDisposed = false;

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

  void _emitDashboard() {
    if (_isDisposed || _dashboardController.isClosed) return;

    final verifikasiAnggota = _countStatus(_calonAnggotaValue, 'menunggu');
    final bantuanPupuk = _countStatus(_bantuanPupukValue, 'menunggu');
    final peminjamanAlat = _countStatus(_peminjamanAlatValue, 'menunggu');
    final resetPassword = _countStatus(_resetPasswordValue, 'menunggu');

    final data = _DashboardData(
      totalAnggotaAktif: _countAnggotaAktif(_anggotaValue),
      verifikasiAnggotaMenunggu: verifikasiAnggota,
      bantuanPupukMenunggu: bantuanPupuk,
      peminjamanAlatMenunggu: peminjamanAlat,
      resetPasswordMenunggu: resetPassword,
      notifikasiBelumDibaca: _countUnreadNotification(_notifikasiAdminValue),
    );

    _dashboardController.add(data);
  }

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value == null || value is! Map) return {};
    return Map<dynamic, dynamic>.from(value);
  }

  int _countAnggotaAktif(dynamic value) {
    final data = _asMap(value);
    if (data.isEmpty) return 0;

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
    if (data.isEmpty) return 0;

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
    if (data.isEmpty) return 0;

    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail = Map<dynamic, dynamic>.from(item);
      final status = _cleanStatus(detail['status']);
      final dibaca = detail['dibaca'];

      if (dibaca == false || status == 'belum_dibaca') {
        total++;
      }
    }

    return total;
  }

  String _cleanStatus(dynamic value) {
    return (value ?? '').toString().toLowerCase().trim();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: _bottomNavigationBar(),
      body: SafeArea(
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _header(data),
                  const SizedBox(height: 16),
                  _mainSummary(data),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    title: 'Tugas Admin',
                    subtitle: 'Data yang masih perlu diproses',
                  ),
                  const SizedBox(height: 12),
                  _taskList(data),
                  const SizedBox(height: 18),
                  _sectionTitle(
                    title: 'Manajemen',
                    subtitle: 'Kelola data utama aplikasi',
                  ),
                  const SizedBox(height: 12),
                  _managementList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(_DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12,
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
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _todayText(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
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
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 64,
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(
                Icons.notifications_rounded,
                color: Colors.white,
                size: 23,
              ),
            ),
            if (total > 0)
              Positioned(right: 0, top: 0, child: _notificationBadge(total)),
          ],
        ),
      ),
    );
  }

  Widget _notificationBadge(int total) {
    final text = total > 99 ? '99+' : total.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 26, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: redStatus,
        borderRadius: BorderRadius.circular(99),
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

  Widget _mainSummary(_DashboardData data) {
    final totalPengajuan =
        data.verifikasiAnggotaMenunggu +
        data.bantuanPupukMenunggu +
        data.peminjamanAlatMenunggu;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  title: 'Anggota',
                  value: data.totalAnggotaAktif,
                  icon: Icons.groups_rounded,
                  color: primaryGreen,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  title: 'Pengajuan',
                  value: totalPengajuan,
                  icon: Icons.assignment_rounded,
                  color: orangeStatus,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  title: 'Reset',
                  value: data.resetPasswordMenunggu,
                  icon: Icons.lock_reset_rounded,
                  color: blueStatus,
                  onTap: () => _openPage(const ResetPasswordAdminPage()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  title: 'Notif',
                  value: data.notifikasiBelumDibaca,
                  icon: Icons.notifications_active_rounded,
                  color: redStatus,
                  onTap: () => _openPage(const NotifikasiAdminPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryBox({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 92,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              height: 39,
              width: 39,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
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

  Widget _taskList(_DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _taskStatusHeader(data),
          const SizedBox(height: 12),
          _taskTile(
            title: 'Verifikasi Anggota',
            subtitle: 'Calon anggota baru',
            count: data.verifikasiAnggotaMenunggu,
            icon: Icons.person_add_alt_1_rounded,
            page: const VerifikasiAnggotaPage(),
          ),
          _divider(),
          _taskTile(
            title: 'Bantuan Pupuk',
            subtitle: 'Pengajuan pupuk anggota',
            count: data.bantuanPupukMenunggu,
            icon: Icons.eco_rounded,
            page: const VerifikasiPupukPage(),
          ),
          _divider(),
          _taskTile(
            title: 'Peminjaman Alat',
            subtitle: 'Pengajuan alat pertanian',
            count: data.peminjamanAlatMenunggu,
            icon: Icons.agriculture_rounded,
            page: const VerifikasiPeminjamanPage(),
          ),
          _divider(),
          _taskTile(
            title: 'Reset Password',
            subtitle: 'Permintaan lupa password',
            count: data.resetPasswordMenunggu,
            icon: Icons.lock_reset_rounded,
            page: const ResetPasswordAdminPage(),
          ),
        ],
      ),
    );
  }

  Widget _taskStatusHeader(_DashboardData data) {
    final clear = data.totalTugasMenunggu == 0;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            clear
                ? primaryGreen.withValues(alpha: 0.07)
                : orangeStatus.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color:
              clear
                  ? primaryGreen.withValues(alpha: 0.12)
                  : orangeStatus.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            clear ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            color: clear ? primaryGreen : orangeStatus,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              clear
                  ? 'Semua tugas admin sudah diproses.'
                  : '${data.totalTugasMenunggu} data masih menunggu tindakan admin.',
              style: const TextStyle(
                color: textDark,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
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
    required Widget page,
  }) {
    return InkWell(
      onTap: () => _openPage(page),
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryGreen, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 13.5,
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
            if (count > 0) _smallBadge(count),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: textGrey),
          ],
        ),
      ),
    );
  }

  Widget _managementList() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _menuTile(
            title: 'Kelola Pupuk',
            subtitle: 'Stok dan jenis pupuk',
            icon: Icons.inventory_2_rounded,
            page: const KelolaPupukPage(),
          ),
          _divider(),
          _menuTile(
            title: 'Kelola Alat',
            subtitle: 'Data alat pertanian',
            icon: Icons.handyman_rounded,
            page: const KelolaAlatPage(),
          ),
          _divider(),
          _menuTile(
            title: 'Jadwal Alat',
            subtitle: 'Jadwal peminjaman alat',
            icon: Icons.calendar_month_rounded,
            page: const JadwalAlatAdminPage(),
          ),
          _divider(),
          _menuTile(
            title: 'Pengumuman',
            subtitle: 'Informasi untuk anggota',
            icon: Icons.campaign_rounded,
            page: const KelolaPengumumanPage(),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget page,
  }) {
    return InkWell(
      onTap: () => _openPage(page),
      borderRadius: BorderRadius.circular(13),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: primaryGreen, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 13.5,
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
            const Icon(Icons.chevron_right_rounded, color: textGrey),
          ],
        ),
      ),
    );
  }

  Widget _smallBadge(int total) {
    final text = total > 99 ? '99+' : total.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 25, minHeight: 23),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: redStatus,
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

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 5,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
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
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
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
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _DashboardData {
  final int totalAnggotaAktif;
  final int verifikasiAnggotaMenunggu;
  final int bantuanPupukMenunggu;
  final int peminjamanAlatMenunggu;
  final int resetPasswordMenunggu;
  final int notifikasiBelumDibaca;

  const _DashboardData({
    required this.totalAnggotaAktif,
    required this.verifikasiAnggotaMenunggu,
    required this.bantuanPupukMenunggu,
    required this.peminjamanAlatMenunggu,
    required this.resetPasswordMenunggu,
    required this.notifikasiBelumDibaca,
  });

  factory _DashboardData.empty() {
    return const _DashboardData(
      totalAnggotaAktif: 0,
      verifikasiAnggotaMenunggu: 0,
      bantuanPupukMenunggu: 0,
      peminjamanAlatMenunggu: 0,
      resetPasswordMenunggu: 0,
      notifikasiBelumDibaca: 0,
    );
  }

  int get totalTugasMenunggu =>
      verifikasiAnggotaMenunggu +
      bantuanPupukMenunggu +
      peminjamanAlatMenunggu +
      resetPasswordMenunggu;
}
