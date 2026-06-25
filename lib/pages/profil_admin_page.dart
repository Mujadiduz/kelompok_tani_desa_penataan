import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/session_helper.dart';
import '../widgets/app_background.dart';
import 'anggota_aktif_page.dart';
import 'data_bantuan_pupuk_page.dart';
import 'data_calon_anggota_page.dart';
import 'data_peminjaman_alat_page.dart';
import 'role_selection_page.dart';
import 'tentang_aplikasi_page.dart';
import 'verifikasi_anggota_page.dart';
import 'verifikasi_peminjaman_page.dart';
import 'verifikasi_pupuk_page.dart';

class ProfilAdminPage extends StatefulWidget {
  const ProfilAdminPage({super.key});

  @override
  State<ProfilAdminPage> createState() => _ProfilAdminPageState();
}

class _ProfilAdminPageState extends State<ProfilAdminPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color redColor = Color(0xffDC2626);

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _anggotaRef;
  late final DatabaseReference _calonRef;
  late final DatabaseReference _pupukRef;
  late final DatabaseReference _peminjamanRef;

  final StreamController<_AdminProfileData> _profileController =
      StreamController<_AdminProfileData>.broadcast();

  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

  dynamic _anggotaValue;
  dynamic _calonValue;
  dynamic _pupukValue;
  dynamic _peminjamanValue;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    _anggotaRef = _db.ref('anggota');
    _calonRef = _db.ref('calon_anggota');
    _pupukRef = _db.ref('bantuan_pupuk');
    _peminjamanRef = _db.ref('peminjaman_alat');

    _listenData();
  }

  @override
  void dispose() {
    _isDisposed = true;

    for (final sub in _subscriptions) {
      sub.cancel();
    }

    _profileController.close();
    super.dispose();
  }

  void _listenData() {
    _subscriptions.addAll([
      _anggotaRef.onValue.listen((event) {
        _anggotaValue = event.snapshot.value;
        _emitData();
      }),
      _calonRef.onValue.listen((event) {
        _calonValue = event.snapshot.value;
        _emitData();
      }),
      _pupukRef.onValue.listen((event) {
        _pupukValue = event.snapshot.value;
        _emitData();
      }),
      _peminjamanRef.onValue.listen((event) {
        _peminjamanValue = event.snapshot.value;
        _emitData();
      }),
    ]);

    _emitData();
  }

  void _emitData() {
    if (_isDisposed || _profileController.isClosed) return;

    _profileController.add(
      _AdminProfileData(
        totalAnggota: _countTotal(_anggotaValue),
        totalCalon: _countTotal(_calonValue),
        totalPupuk: _countTotal(_pupukValue),
        totalPeminjaman: _countTotal(_peminjamanValue),
        calonMenunggu: _countStatus(_calonValue, 'menunggu'),
        pupukMenunggu: _countStatus(_pupukValue, 'menunggu'),
        alatMenunggu: _countStatus(_peminjamanValue, 'menunggu'),
      ),
    );
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

  Future<void> _refreshData() async {
    _emitData();
  }

  void _openPage(Widget page) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Keluar dari Admin?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Anda akan keluar dari halaman administrator dan kembali ke halaman login.',
            style: TextStyle(
              color: textGrey,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);

                Navigator.pop(dialogContext);

                await SessionHelper.clearSession();

                if (!mounted) return;

                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<_AdminProfileData>(
            stream: _profileController.stream,
            initialData: _AdminProfileData.empty(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? _AdminProfileData.empty();

              return RefreshIndicator(
                color: primaryGreen,
                onRefresh: _refreshData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  children: [
                    _header(data),
                    const SizedBox(height: 16),
                    _verificationCard(data),
                    const SizedBox(height: 18),
                    _sectionTitle(
                      title: 'Data Sistem',
                      subtitle: 'Klik kartu untuk melihat data lengkap',
                    ),
                    const SizedBox(height: 12),
                    _statsGrid(data),
                    const SizedBox(height: 18),
                    _sectionTitle(
                      title: 'Pengaturan',
                      subtitle: 'Informasi aplikasi dan sesi admin',
                    ),
                    const SizedBox(height: 12),
                    _menuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang Aplikasi',
                      subtitle: 'Informasi sistem dan fitur aplikasi',
                      color: primaryGreen,
                      onTap: () => _openPage(const TentangAplikasiPage()),
                    ),
                    const SizedBox(height: 10),
                    _logoutTile(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(_AdminProfileData data) {
    final aman = data.totalVerifikasi == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil Admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aman
                      ? 'Semua verifikasi sudah diproses.'
                      : '${data.totalVerifikasi} data perlu diverifikasi.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _headerCounter(data.totalVerifikasi),
        ],
      ),
    );
  }

  Widget _headerCounter(int total) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'cek',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationCard(_AdminProfileData data) {
    final aman = data.totalVerifikasi == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color:
                      aman
                          ? primaryGreen.withValues(alpha: 0.11)
                          : orangeStatus.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(
                  aman ? Icons.done_all_rounded : Icons.pending_actions_rounded,
                  color: aman ? primaryGreen : orangeStatus,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  aman
                      ? 'Tidak ada verifikasi menunggu.'
                      : '${data.totalVerifikasi} verifikasi menunggu keputusan admin.',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _verifyBox(
                  title: 'Anggota',
                  value: data.calonMenunggu,
                  icon: Icons.person_add_alt_1_rounded,
                  color: blueStatus,
                  onTap: () => _openPage(const VerifikasiAnggotaPage()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _verifyBox(
                  title: 'Pupuk',
                  value: data.pupukMenunggu,
                  icon: Icons.eco_rounded,
                  color: primaryGreen,
                  onTap: () => _openPage(const VerifikasiPupukPage()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _verifyBox(
                  title: 'Alat',
                  value: data.alatMenunggu,
                  icon: Icons.agriculture_rounded,
                  color: orangeStatus,
                  onTap: () => _openPage(const VerifikasiPeminjamanPage()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verifyBox({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 7),
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid(_AdminProfileData data) {
    final items = [
      _StatItem(
        title: 'Anggota Aktif',
        value: data.totalAnggota,
        icon: Icons.groups_rounded,
        color: primaryGreen,
        page: const AnggotaAktifPage(),
      ),
      _StatItem(
        title: 'Calon Anggota',
        value: data.totalCalon,
        icon: Icons.person_add_alt_1_rounded,
        color: blueStatus,
        page: const DataCalonAnggotaPage(),
      ),
      _StatItem(
        title: 'Bantuan Pupuk',
        value: data.totalPupuk,
        icon: Icons.eco_rounded,
        color: primaryGreen,
        page: const DataBantuanPupukPage(),
      ),
      _StatItem(
        title: 'Peminjaman Alat',
        value: data.totalPeminjaman,
        icon: Icons.agriculture_rounded,
        color: orangeStatus,
        page: const DataPeminjamanAlatPage(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              items.map((item) {
                return SizedBox(width: itemWidth, child: _statCard(item));
              }).toList(),
        );
      },
    );
  }

  Widget _statCard(_StatItem item) {
    return InkWell(
      onTap: () => _openPage(item.page),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 20),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 23,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 12,
                      height: 1.22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: item.color, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 20),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
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
                      fontSize: 14.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
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
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  Widget _logoutTile() {
    return InkWell(
      onTap: _logout,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: redColor.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: redColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: redColor.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.logout_rounded, color: redColor),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keluar',
                    style: TextStyle(
                      color: redColor,
                      fontSize: 14.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Akhiri sesi admin dan kembali ke login',
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
            Icon(Icons.chevron_right_rounded, color: redColor),
          ],
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
                  fontSize: 11.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _AdminProfileData {
  final int totalAnggota;
  final int totalCalon;
  final int totalPupuk;
  final int totalPeminjaman;
  final int calonMenunggu;
  final int pupukMenunggu;
  final int alatMenunggu;

  const _AdminProfileData({
    required this.totalAnggota,
    required this.totalCalon,
    required this.totalPupuk,
    required this.totalPeminjaman,
    required this.calonMenunggu,
    required this.pupukMenunggu,
    required this.alatMenunggu,
  });

  factory _AdminProfileData.empty() {
    return const _AdminProfileData(
      totalAnggota: 0,
      totalCalon: 0,
      totalPupuk: 0,
      totalPeminjaman: 0,
      calonMenunggu: 0,
      pupukMenunggu: 0,
      alatMenunggu: 0,
    );
  }

  int get totalVerifikasi => calonMenunggu + pupukMenunggu + alatMenunggu;
}

class _StatItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final Widget page;

  const _StatItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.page,
  });
}
