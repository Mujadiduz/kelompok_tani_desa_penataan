import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
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
  State<AdminHomePage> createState() =>
      _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  static const Color primaryGreen = Color(0xff2E7D32);

  static const Color adminNavy = Color(0xff172A46);
  static const Color adminNavyLight = Color(0xff294762);
  static const Color adminPurple = Color(0xff6256A4);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softBlue = Color(0xffE9F2FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softPurple = Color(0xffF0ECFA);
  static const Color softRed = Color(0xffFBEAEA);

  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  static const Color redStatus = Color(0xffC83B3B);
  static const Color orangeStatus = Color(0xffD98212);
  static const Color blueStatus = Color(0xff326CA3);
  static const Color purpleStatus = Color(0xff725BB4);

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  final FirebaseDatabase _db =
      FirebaseDatabase.instanceFor(
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

  final StreamController<_DashboardData>
      _dashboardController =
      StreamController<_DashboardData>.broadcast();

  final List<StreamSubscription<DatabaseEvent>>
      _subscriptions = [];


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

    for (final subscription in _subscriptions) {
      subscription.cancel();
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

    Future<void>.delayed(
      const Duration(milliseconds: 450),
      () {
        if (!_isDisposed) {
          _emitDashboard();
        }
      },
    );
  }

  void _emitDashboard() {
    if (_isDisposed ||
        _dashboardController.isClosed) {
      return;
    }

    final data = _DashboardData(
      totalAnggotaAktif:
          _countAnggotaAktif(_anggotaValue),
      verifikasiAnggotaMenunggu:
          _countPendingCalonAnggota(),
      bantuanPupukMenunggu:
          _countPending(_bantuanPupukValue),
      peminjamanAlatMenunggu:
          _countPending(_peminjamanAlatValue),
      resetPasswordMenunggu:
          _countPending(_resetPasswordValue),
      notifikasiBelumDibaca:
          _countUnreadNotification(
        _notifikasiAdminValue,
      ),
      latestNotices: _buildLatestNotices(),
    );

    _dashboardController.add(data);
  }

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value == null || value is! Map) {
      return {};
    }

    return Map<dynamic, dynamic>.from(value);
  }

  String _cleanStatus(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');
  }

  bool _isPendingStatus(dynamic value) {
    final status = _cleanStatus(value);

    if (status.isEmpty) {
      return true;
    }

    const pendingStatuses = {
      'menunggu',
      'pending',
      'diajukan',
      'pengajuan',
      'proses',
      'diproses',
      'sedang_diproses',
      'sedang diproses',
      'verifikasi',
      'diverifikasi',
      'menunggu_verifikasi',
      'menunggu verifikasi',
      'belum_diproses',
      'belum diproses',
    };

    return pendingStatuses.contains(status);
  }

  String _normalisasiNik(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();
  }

  Set<String> _nikAnggotaAktif() {
    final result = <String>{};
    final data = _asMap(_anggotaValue);

    for (final value in data.values) {
      if (value is! Map) continue;

      final detail =
          Map<dynamic, dynamic>.from(value);

      final nik = _normalisasiNik(
        detail['nik'],
      );

      if (nik.isNotEmpty) {
        result.add(nik);
      }
    }

    return result;
  }

  bool _sudahMenjadiAnggota(
    Map<dynamic, dynamic> calon,
  ) {
    final nikCalon =
        _normalisasiNik(calon['nik']);

    if (nikCalon.isEmpty) {
      return false;
    }

    return _nikAnggotaAktif().contains(nikCalon);
  }

  int _countAnggotaAktif(dynamic value) {
    final data = _asMap(value);

    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail =
          Map<dynamic, dynamic>.from(item);

      final status =
          _cleanStatus(detail['status']);

      if (status.isEmpty ||
          status == 'aktif' ||
          status == 'disetujui' ||
          status == 'anggota') {
        total++;
      }
    }

    return total;
  }

  int _countPending(dynamic value) {
    final data = _asMap(value);

    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail =
          Map<dynamic, dynamic>.from(item);

      if (_isPendingStatus(detail['status'])) {
        total++;
      }
    }

    return total;
  }

  int _countPendingCalonAnggota() {
    final data = _asMap(_calonAnggotaValue);

    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail =
          Map<dynamic, dynamic>.from(item);

      if (!_isPendingStatus(detail['status'])) {
        continue;
      }

      /*
       * Walaupun data lama pada calon_anggota
       * masih berstatus menunggu, data tidak lagi
       * muncul jika NIK sudah berada pada node anggota.
       */
      if (_sudahMenjadiAnggota(detail)) {
        continue;
      }

      total++;
    }

    return total;
  }

  int _countUnreadNotification(dynamic value) {
    final data = _asMap(value);

    int total = 0;

    for (final item in data.values) {
      if (item is! Map) continue;

      final detail =
          Map<dynamic, dynamic>.from(item);

      final status =
          _cleanStatus(detail['status']);

      final dibaca = detail['dibaca'];

      if (dibaca == false ||
          status == 'belum_dibaca') {
        total++;
      }
    }

    return total;
  }

  List<_NoticeItem> _buildLatestNotices() {
    final items = <_NoticeItem>[];

    void addItems({
      required dynamic source,
      required String title,
      required String Function(
        Map<dynamic, dynamic> data,
      ) subtitleBuilder,
      required IconData icon,
      required Color color,
      required Widget page,
      bool Function(
        Map<dynamic, dynamic> data,
      )? additionalFilter,
    }) {
      final data = _asMap(source);

      for (final entry in data.entries) {
        final value = entry.value;

        if (value is! Map) continue;

        final detail =
            Map<dynamic, dynamic>.from(value);

        if (!_isPendingStatus(
          detail['status'],
        )) {
          continue;
        }

        if (additionalFilter != null &&
            !additionalFilter(detail)) {
          continue;
        }

        items.add(
          _NoticeItem(
            id: entry.key.toString(),
            title: title,
            subtitle:
                subtitleBuilder(detail),
            icon: icon,
            color: color,
            page: page,
            date: _readDate(detail),
          ),
        );
      }
    }

    addItems(
      source: _calonAnggotaValue,
      title: 'Verifikasi Anggota',
      subtitleBuilder: (data) {
        final nama = _text(
          data['nama'],
          fallback: 'Calon anggota baru',
        );

        final nik = _text(
          data['nik'],
          fallback: '-',
        );

        return '$nama • NIK $nik';
      },
      icon: Icons.assignment_ind_outlined,
      color: blueStatus,
      page: const VerifikasiAnggotaPage(),
      additionalFilter: (data) {
        return !_sudahMenjadiAnggota(data);
      },
    );

    addItems(
      source: _bantuanPupukValue,
      title: 'Bantuan Pupuk',
      subtitleBuilder: (data) {
        final nama = _text(
          data['nama'],
          fallback: 'Pengajuan pupuk',
        );

        final jenis = _text(
          data['jenis_pupuk'] ??
              data['nama_pupuk'],
          fallback: 'Menunggu verifikasi',
        );

        return '$nama • $jenis';
      },
      icon: Icons.inventory_2_outlined,
      color: primaryGreen,
      page: const VerifikasiPupukPage(),
    );

    addItems(
      source: _peminjamanAlatValue,
      title: 'Peminjaman Alat',
      subtitleBuilder: (data) {
        final nama = _text(
          data['nama'],
          fallback: 'Pengajuan alat',
        );

        final alat = _text(
          data['nama_alat'] ?? data['alat'],
          fallback: 'Menunggu verifikasi',
        );

        return '$nama • $alat';
      },
      icon: Icons.handyman_outlined,
      color: orangeStatus,
      page: const VerifikasiPeminjamanPage(),
    );

    addItems(
      source: _resetPasswordValue,
      title: 'Reset Password',
      subtitleBuilder: (data) {
        final nama = _text(
          data['nama'],
          fallback: 'Permintaan reset',
        );

        final nik = _text(
          data['nik'],
          fallback: '-',
        );

        return '$nama • NIK $nik';
      },
      icon: Icons.lock_reset_outlined,
      color: purpleStatus,
      page: const ResetPasswordAdminPage(),
    );

    items.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return items.take(6).toList();
  }

  DateTime _readDate(
    Map<dynamic, dynamic> data,
  ) {
    final raw =
        data['tanggal_pengajuan'] ??
        data['tanggal_daftar'] ??
        data['created_at'] ??
        data['createdAt'] ??
        data['tanggal'] ??
        data['tanggal_reset'] ??
        data['tanggal_permintaan'] ??
        data['timestamp'] ??
        data['updated_at'];

    if (raw == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (raw is int) {
      if (raw.toString().length >= 13) {
        return DateTime.fromMillisecondsSinceEpoch(
          raw,
        );
      }

      return DateTime.fromMillisecondsSinceEpoch(
        raw * 1000,
      );
    }

    if (raw is double) {
      final number = raw.toInt();

      if (number.toString().length >= 13) {
        return DateTime.fromMillisecondsSinceEpoch(
          number,
        );
      }

      return DateTime.fromMillisecondsSinceEpoch(
        number * 1000,
      );
    }

    final parsed =
        DateTime.tryParse(raw.toString());

    return parsed ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    final text =
        (value ?? '').toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String _greeting() {
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

    return '${days[now.weekday - 1]}, '
        '${now.day} '
        '${months[now.month - 1]} '
        '${now.year}';
  }

  String _relativeTime(DateTime date) {
    if (date.millisecondsSinceEpoch <= 0) {
      return 'Menunggu verifikasi';
    }

    final difference =
        DateTime.now().difference(date);

    if (difference.isNegative ||
        difference.inMinutes < 1) {
      return 'Baru saja';
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

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ??
        false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openPage(Widget page) async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  Future<void> _openManagementPage(
    Widget page,
  ) async {
    if (!mounted) return;

    /*
     * Jangan tutup drawer sebelum membuka halaman Kelola.
     * Route baru ditampilkan di atas halaman admin yang drawer-nya
     * masih terbuka. Saat halaman Kelola ditutup, drawer langsung
     * terlihat kembali tanpa kilatan Dashboard Admin.
     */
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push(
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

    final drawerWidth =
        (screenWidth * 0.84)
            .clamp(270.0, 330.0)
            .toDouble();

    return StreamBuilder<_DashboardData>(
      stream: _dashboardController.stream,
      initialData: _DashboardData.empty(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            _DashboardData.empty();

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: pageBackground,
          drawerEnableOpenDragGesture: true,
          drawerEdgeDragWidth: 34,
          drawer: SizedBox(
            width: drawerWidth,
            child: _managementDrawer(data),
          ),
          bottomNavigationBar:
              _bottomNavigationBar(),
          body: SizedBox.expand(
            child: AppBackground(
              showPattern: false,
              child: SizedBox.expand(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _AdminDashboardBackground(),
                    SafeArea(
                      bottom: false,
                      child: RefreshIndicator(
                        color: adminPurple,
                        backgroundColor:
                            Colors.white,
                        onRefresh: () async {
                          _emitDashboard();

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
                            12,
                            horizontalPadding,
                            28,
                          ),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 760,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    _header(data),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    _compactOperationalSummary(
                                      data,
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    _statusBanner(data),
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    _verificationCard(
                                      data,
                                    ),
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    _latestPendingCard(
                                      data.latestNotices,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(_DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        13,
        13,
        13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            adminNavy,
            adminNavyLight,
            adminPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(
              alpha: 0.23,
            ),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -58,
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.07,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 42,
              bottom: -62,
              child: Container(
                height: 105,
                width: 105,
                decoration: BoxDecoration(
                  color: const Color(
                    0xffB9ACFF,
                  ).withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(15),
                  child: InkWell(
                    onTap: _openDrawer,
                    borderRadius:
                        BorderRadius.circular(15),
                    child: Container(
                      height: 45,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.13,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color:
                              Colors.white.withValues(
                            alpha: 0.19,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 47,
                  width: 47,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.95,
                    ),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons
                        .admin_panel_settings_rounded,
                    color: adminNavy,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Colors.white.withValues(
                            alpha: 0.77,
                          ),
                          fontSize: 10.6,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Administrator TaniGo',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.2,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _todayText(),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              Colors.white.withValues(
                            alpha: 0.69,
                          ),
                          fontSize: 9.5,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),

                _notificationIndicator(
                  data.notifikasiBelumDibaca,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationIndicator(int total) {
    return Semantics(
      button: true,
      label: total > 0
          ? 'Buka notifikasi admin, $total belum dibaca'
          : 'Buka notifikasi admin',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () {
            _openPage(
              const NotifikasiAdminPage(),
            );
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.13,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.19,
                ),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                if (total > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _notificationBadge(total),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationBadge(int total) {
    final text = total > 99
        ? '99+'
        : total.toString();

    final width = text.length == 1
        ? 18.0
        : text.length == 2
            ? 22.0
            : 27.0;

    return Container(
      width: width,
      height: 18,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
      ),
      decoration: BoxDecoration(
        color: redStatus,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: redStatus.withValues(
              alpha: 0.28,
            ),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 7.8,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _compactOperationalSummary(
    _DashboardData data,
  ) {
    final totalVerifikasi =
        data.totalVerifikasiMenunggu;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        11,
        10,
        11,
        10,
      ),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(
              left: 2,
              bottom: 9,
            ),
            child: Text(
              'Ringkasan',
              style: TextStyle(
                color: textDark,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _smallSummaryItem(
                  title: 'Anggota',
                  value: data.totalAnggotaAktif,
                  icon:
                      Icons.verified_user_outlined,
                  color: primaryGreen,
                  backgroundColor: softGreen,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _smallSummaryItem(
                  title: 'Verifikasi',
                  value: totalVerifikasi,
                  icon:
                      Icons.fact_check_outlined,
                  color: orangeStatus,
                  backgroundColor: softAmber,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _smallSummaryItem(
                  title: 'Reset',
                  value:
                      data.resetPasswordMenunggu,
                  icon:
                      Icons.lock_reset_outlined,
                  color: purpleStatus,
                  backgroundColor: softPurple,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _smallSummaryItem(
                  title: 'Notif',
                  value:
                      data.notifikasiBelumDibaca,
                  icon:
                      Icons.notifications_outlined,
                  color: redStatus,
                  backgroundColor: softRed,
                  onTap: () {
                    _openPage(
                      const NotifikasiAdminPage(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallSummaryItem({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    VoidCallback? onTap,
  }) {
    final content = Container(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 5),
          Text(
            value > 99 ? '99+' : value.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 8.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: content,
      ),
    );
  }

  Widget _statusBanner(_DashboardData data) {
    final clear =
        data.totalTugasMenunggu == 0;

    final color =
        clear ? primaryGreen : orangeStatus;

    final backgroundColor =
        clear ? softGreen : softAmber;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            backgroundColor.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(
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
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              clear
                  ? Icons.task_alt_rounded
                  : Icons.hourglass_top_rounded,
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
                  clear
                      ? 'Semua tugas telah diproses'
                      : 'Ada tugas menunggu verifikasi',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  clear
                      ? 'Data selesai tersedia di halaman Riwayat.'
                      : '${data.totalTugasMenunggu} data perlu diperiksa admin.',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.3,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Container(
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 30,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.88,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.totalTugasMenunggu > 99
                  ? '99+'
                  : data.totalTugasMenunggu.toString(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationCard(_DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        5,
      ),
      decoration: _cardDecoration(radius: 23),
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
                      'Tugas Verifikasi',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Hanya data yang belum selesai.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: softAmber,
                  borderRadius:
                      BorderRadius.circular(999),
                ),
                child: Text(
                  '${data.totalTugasMenunggu} TUGAS',
                  style: const TextStyle(
                    color: orangeStatus,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _taskTile(
            title: 'Verifikasi Anggota',
            subtitle:
                'Calon anggota yang mendaftar online',
            count:
                data.verifikasiAnggotaMenunggu,
            icon: Icons.assignment_ind_outlined,
            color: blueStatus,
            backgroundColor: softBlue,
            onTap: () {
              _openPage(
                const VerifikasiAnggotaPage(),
              );
            },
          ),
          _divider(),
          _taskTile(
            title: 'Bantuan Pupuk',
            subtitle:
                'Pengajuan bantuan pupuk anggota',
            count:
                data.bantuanPupukMenunggu,
            icon: Icons.inventory_2_outlined,
            color: primaryGreen,
            backgroundColor: softGreen,
            onTap: () {
              _openPage(
                const VerifikasiPupukPage(),
              );
            },
          ),
          _divider(),
          _taskTile(
            title: 'Peminjaman Alat',
            subtitle:
                'Pengajuan alat pertanian anggota',
            count:
                data.peminjamanAlatMenunggu,
            icon: Icons.handyman_outlined,
            color: orangeStatus,
            backgroundColor: softAmber,
            onTap: () {
              _openPage(
                const VerifikasiPeminjamanPage(),
              );
            },
          ),
          _divider(),
          _taskTile(
            title: 'Reset Password',
            subtitle:
                'Permintaan pemulihan akun anggota',
            count:
                data.resetPasswordMenunggu,
            icon: Icons.lock_reset_outlined,
            color: purpleStatus,
            backgroundColor: softPurple,
            onTap: () {
              _openPage(
                const ResetPasswordAdminPage(),
              );
            },
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
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: color.withValues(
                      alpha: 0.09,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 12.8,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 10.2,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              _countBadge(count, color),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countBadge(int count, Color color) {
    final hasData = count > 0;

    return Container(
      constraints: const BoxConstraints(
        minWidth: 27,
        minHeight: 25,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: hasData
            ? color
            : const Color(0xffF0F2F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: hasData
              ? Colors.white
              : textGrey,
          fontSize: 9.5,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _latestPendingCard(
    List<_NoticeItem> notices,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        15,
        15,
        15,
        5,
      ),
      decoration: _cardDecoration(radius: 23),
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
                      'Pengajuan Terbaru',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Data baru yang menunggu proses.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: softBlue,
                borderRadius:
                    BorderRadius.circular(999),
                child: InkWell(
                  onTap: () {
                    _openPage(
                      const RiwayatAdminPage(),
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
                        color: blueStatus.withValues(
                          alpha: 0.11,
                        ),
                      ),
                    ),
                    child: const Text(
                      'RIWAYAT',
                      style: TextStyle(
                        color: blueStatus,
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
          const SizedBox(height: 10),
          if (notices.isEmpty)
            _emptyLatestNotice()
          else
            for (int index = 0;
                index < notices.length;
                index++) ...[
              _latestNoticeTile(
                notices[index],
              ),
              if (index != notices.length - 1)
                _divider(),
            ],
        ],
      ),
    );
  }

  Widget _emptyLatestNotice() {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(13),
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
          _SmallContainerIcon(
            icon: Icons.done_all_rounded,
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
                    fontSize: 12.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Data yang telah diverifikasi tersedia di halaman Riwayat.',
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

  Widget _latestNoticeTile(
    _NoticeItem item,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          _openPage(item.page);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 11,
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 12.7,
                              fontWeight:
                                  FontWeight.w900,
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
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 10.3,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: item.color,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _relativeTime(item.date),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.color,
                              fontSize: 9.1,
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
              const SizedBox(width: 7),
              Icon(
                Icons.chevron_right_rounded,
                color: item.color,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: softRed,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: redStatus.withValues(alpha: 0.12),
        ),
      ),
      child: const Text(
        'BARU',
        style: TextStyle(
          color: redStatus,
          fontSize: 7.2,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _managementDrawer(
    _DashboardData data,
  ) {
    return Drawer(
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _drawerHeader(),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .manual,
                padding: const EdgeInsets.fromLTRB(
                  12,
                  14,
                  12,
                  20,
                ),
                children: [
                  const _DrawerSectionLabel(
                    label: 'KELOLA DATA',
                  ),
                  _drawerTile(
                    title: 'Kelola Pupuk',
                    subtitle:
                        'Atur stok dan jenis pupuk',
                    icon:
                        Icons.inventory_2_outlined,
                    color: primaryGreen,
                    onTap: () {
                      _openManagementPage(
                        const KelolaPupukPage(),
                      );
                    },
                  ),
                  _drawerTile(
                    title: 'Kelola Alat',
                    subtitle:
                        'Atur data alat pertanian',
                    icon: Icons
                        .precision_manufacturing_outlined,
                    color: orangeStatus,
                    onTap: () {
                      _openManagementPage(
                        const KelolaAlatPage(),
                      );
                    },
                  ),
                  _drawerTile(
                    title: 'Kelola Pengumuman',
                    subtitle:
                        'Buat informasi untuk anggota',
                    icon:
                        Icons.campaign_outlined,
                    color: purpleStatus,
                    onTap: () {
                      _openManagementPage(
                        const KelolaPengumumanPage(),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: softBlue,
                      borderRadius:
                          BorderRadius.circular(16),
                      border: Border.all(
                        color: blueStatus.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.swipe_right_alt_rounded,
                          color: blueStatus,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Geser dari sisi kiri layar untuk membuka menu kelola ini.',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 10.2,
                              height: 1.4,
                              fontWeight:
                                  FontWeight.w600,
                            ),
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
      ),
    );
  }

  Widget _drawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        17,
        15,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            adminNavy,
            adminNavyLight,
            adminPurple,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(27),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.95,
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: adminNavy,
              size: 26,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Data',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Manajemen data utama TaniGo',
                  style: TextStyle(
                    color: Color(0xffDFE6F1),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _closeDrawer,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 37,
                width: 37,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 7,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.055),
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(
                  alpha: 0.09,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 12.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 9.7,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavigationBar() {
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
            color: adminNavy.withValues(
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
          selectedItemColor: adminPurple,
          unselectedItemColor: textSoft,
          selectedLabelStyle:
              const TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w900,
          ),
          unselectedLabelStyle:
              const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 1) {
              _openPage(
                const RiwayatAdminPage(),
              );
            } else if (index == 2) {
              _openPage(
                const LaporanPage(),
              );
            } else if (index == 3) {
              _openPage(
                const ProfilAdminPage(),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.space_dashboard_outlined,
              ),
              activeIcon: Icon(
                Icons.space_dashboard_rounded,
              ),
              label: 'Dashboard',
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
                Icons.bar_chart_outlined,
              ),
              activeIcon: Icon(
                Icons.bar_chart_rounded,
              ),
              label: 'Laporan',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_outline_rounded,
              ),
              activeIcon: Icon(
                Icons.person_rounded,
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      color: cardBorder,
    );
  }

  BoxDecoration _cardDecoration({
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
          color: adminNavy.withValues(
            alpha: 0.06,
          ),
          blurRadius: 16,
          offset: const Offset(0, 7),
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

  int get totalVerifikasiMenunggu {
    return verifikasiAnggotaMenunggu +
        bantuanPupukMenunggu +
        peminjamanAlatMenunggu;
  }

  int get totalTugasMenunggu {
    return totalVerifikasiMenunggu +
        resetPasswordMenunggu;
  }
}

class _NoticeItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
  final DateTime date;

  const _NoticeItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
    required this.date,
  });
}

class _SmallContainerIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _SmallContainerIcon({
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

class _DrawerSectionLabel extends StatelessWidget {
  final String label;

  const _DrawerSectionLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        9,
        5,
        9,
        8,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _AdminHomePageState.textSoft,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AdminDashboardBackground
    extends StatelessWidget {
  const _AdminDashboardBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final baseSize =
                width < height ? width : height;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(280.0, 470.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.67)
                    .clamp(190.0, 330.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.40)
                    .clamp(120.0, 200.0)
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
                          Color(0xff172A46),
                          Color(0xff263E61),
                          Color(0xffE8EAF2),
                          Color(0xffF2F4F8),
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
                    top: -largeCircle * 0.55,
                    right: -largeCircle * 0.30,
                    child: _AdminBackgroundCircle(
                      size: largeCircle,
                      color:
                          const Color(0xff6256A4),
                      alpha: 0.22,
                      borderColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.13,
                    left: -smallCircle * 0.22,
                    child: _AdminBackgroundRing(
                      size: smallCircle,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: height * 0.26,
                    left: -mediumCircle * 0.56,
                    child: _AdminBackgroundCircle(
                      size: mediumCircle,
                      color:
                          const Color(0xff54779A),
                      alpha: 0.21,
                      borderColor:
                          const Color(0xff54779A),
                    ),
                  ),
                  Positioned(
                    top: height * 0.47,
                    right:
                        -mediumCircle * 0.62,
                    child: _AdminBackgroundCircle(
                      size: mediumCircle * 1.08,
                      color:
                          const Color(0xffE8E1F7),
                      alpha: 0.76,
                      borderColor:
                          const Color(0xff725BB4),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -largeCircle * 0.52,
                    left: -largeCircle * 0.31,
                    child: _AdminBackgroundCircle(
                      size: largeCircle,
                      color:
                          const Color(0xffDCEDE8),
                      alpha: 0.76,
                      borderColor:
                          const Color(0xff28766F),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -mediumCircle * 0.36,
                    right:
                        -mediumCircle * 0.42,
                    child: _AdminBackgroundCircle(
                      size: mediumCircle,
                      color:
                          const Color(0xffE7EDF6),
                      alpha: 0.86,
                      borderColor:
                          const Color(0xff326CA3),
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

class _AdminBackgroundCircle
    extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  final Color borderColor;

  const _AdminBackgroundCircle({
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

class _AdminBackgroundRing
    extends StatelessWidget {
  final double size;
  final Color color;

  const _AdminBackgroundRing({
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