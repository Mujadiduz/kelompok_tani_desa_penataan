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
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminNavyLight = Color(0xff294762);
  static const Color adminPurple = Color(0xff6256A4);

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color orangeStatus = Color(0xffD98212);
  static const Color blueStatus = Color(0xff326CA3);
  static const Color redColor = Color(0xffC83B3B);

  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _rootRef;

  @override
  void initState() {
    super.initState();
    _rootRef = _db.ref();
  }

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value is! Map) {
      return <dynamic, dynamic>{};
    }

    return Map<dynamic, dynamic>.from(value);
  }

  Iterable<dynamic> _records(dynamic value) {
    if (value is Map) {
      return Map<dynamic, dynamic>.from(value).values;
    }

    if (value is List) {
      return value.where((item) => item != null);
    }

    return const <dynamic>[];
  }

  String _normalStatus(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  bool _isPendingStatus(dynamic value) {
    final status = _normalStatus(value);

    return {
      '',
      'menunggu',
      'pending',
      'diajukan',
      'pengajuan',
      'proses',
      'diproses',
      'sedang_diproses',
      'verifikasi',
      'diverifikasi',
      'menunggu_verifikasi',
      'belum_diproses',
    }.contains(status);
  }

  int _countTotal(dynamic value) {
    int total = 0;

    for (final item in _records(value)) {
      if (item is Map) {
        total++;
      }
    }

    return total;
  }

  int _countAnggotaAktif(dynamic value) {
    int total = 0;

    const inactiveStatuses = {
      'nonaktif',
      'non_aktif',
      'inactive',
      'ditolak',
      'rejected',
      'dihapus',
      'deleted',
      'keluar',
    };

    for (final item in _records(value)) {
      if (item is! Map) {
        continue;
      }

      final detail = Map<dynamic, dynamic>.from(item);
      final status = _normalStatus(detail['status']);

      /*
       * Node anggota adalah sumber anggota aktif.
       * Data tanpa status atau dengan istilah lama tetap dihitung,
       * kecuali statusnya jelas menyatakan tidak aktif.
       */
      if (!inactiveStatuses.contains(status)) {
        total++;
      }
    }

    return total;
  }

  int _countPending(dynamic value) {
    int total = 0;

    for (final item in _records(value)) {
      if (item is! Map) {
        continue;
      }

      final detail = Map<dynamic, dynamic>.from(item);

      if (_isPendingStatus(detail['status'])) {
        total++;
      }
    }

    return total;
  }

  _AdminProfileData _buildProfileData(dynamic value) {
    final root = _asMap(value);

    final anggota = root['anggota'];
    final calon = root['calon_anggota'];
    final pupuk = root['bantuan_pupuk'];
    final peminjaman = root['peminjaman_alat'];

    return _AdminProfileData(
      totalAnggota: _countAnggotaAktif(anggota),
      totalCalon: _countTotal(calon),
      totalPupuk: _countTotal(pupuk),
      totalPeminjaman: _countTotal(peminjaman),
      calonMenunggu: _countPending(calon),
      pupukMenunggu: _countPending(pupuk),
      alatMenunggu: _countPending(peminjaman),
    );
  }

  Future<void> _refreshData() async {
    await _rootRef.get();
  }

  void _openPage(Widget page) {
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: adminNavy.withValues(alpha: 0.17),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xffFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    color: redColor,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 13),
                const Text(
                  'Keluar dari TaniGo?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Sesi admin akan diakhiri dan Anda akan '
                  'kembali ke halaman pemilihan pengguna.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.2,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 19),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(
                            color: cardBorder,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);

                          await SessionHelper.clearSession();

                          if (!mounted) {
                            return;
                          }

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RoleSelectionPage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: redColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 350 ? 13.0 : 17.0;

    return Scaffold(
      backgroundColor: pageBackground,
      body: AppBackground(
        showPattern: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _AdminProfileBackground(),
            SafeArea(
              child: StreamBuilder<DatabaseEvent>(
                stream: _rootRef.onValue,
                builder: (context, snapshot) {
                  final data = _buildProfileData(
                    snapshot.data?.snapshot.value,
                  );

                  return RefreshIndicator(
                    color: adminPurple,
                    backgroundColor: Colors.white,
                    onRefresh: _refreshData,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        13,
                        horizontalPadding,
                        30,
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
                                  CrossAxisAlignment.stretch,
                              children: [
                                _header(data),
                                const SizedBox(height: 13),
                                _verificationCard(data),
                                const SizedBox(height: 16),
                                _sectionTitle(
                                  title: 'Data Sistem',
                                  subtitle:
                                      'Pilih menu untuk melihat data lengkap',
                                ),
                                const SizedBox(height: 10),
                                _statsGrid(data),
                                const SizedBox(height: 17),
                                _sectionTitle(
                                  title: 'Pengaturan',
                                  subtitle:
                                      'Informasi aplikasi dan sesi admin',
                                ),
                                const SizedBox(height: 10),
                                _menuTile(
                                  icon: Icons.info_rounded,
                                  title: 'Tentang Aplikasi',
                                  subtitle:
                                      'Informasi sistem dan fitur aplikasi',
                                  color: primaryGreen,
                                  onTap: () => _openPage(
                                    const TentangAplikasiPage(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _logoutTile(),
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
    );
  }

  Widget _header(_AdminProfileData data) {
    final aman = data.totalVerifikasi == 0;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            adminNavy,
            adminNavyLight,
            adminPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.23),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.19),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              if (data.totalVerifikasi > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: _smallNotificationBadge(
                    data.totalVerifikasi,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil Admin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.8,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aman
                      ? 'Semua tugas verifikasi sudah selesai'
                      : '${data.totalVerifikasi} data perlu diverifikasi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xffE3E8F1),
                    fontSize: 9.8,
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

  Widget _backButton() {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 17,
        ),
      ),
    );
  }

  Widget _smallNotificationBadge(int total) {
    final text = total > 99
        ? '99+'
        : total.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 19,
        minHeight: 19,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: redColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: redColor.withValues(alpha: 0.30),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.3,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }


  Widget _verificationCard(_AdminProfileData data) {
    final aman = data.totalVerifikasi == 0;
    final color = aman ? primaryGreen : orangeStatus;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        13,
        13,
        13,
        12,
      ),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  aman
                      ? Icons.task_alt_rounded
                      : Icons.pending_actions_rounded,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  aman
                      ? 'Tidak ada verifikasi yang menunggu.'
                      : '${data.totalVerifikasi} verifikasi menunggu keputusan admin.',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 11.7,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: _verifyBox(
                  title: 'Anggota',
                  value: data.calonMenunggu,
                  icon:
                      Icons.person_add_alt_1_rounded,
                  color: blueStatus,
                  onTap: () => _openPage(
                    const VerifikasiAnggotaPage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _verifyBox(
                  title: 'Pupuk',
                  value: data.pupukMenunggu,
                  icon:
                      Icons.inventory_2_rounded,
                  color: primaryGreen,
                  onTap: () => _openPage(
                    const VerifikasiPupukPage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _verifyBox(
                  title: 'Alat',
                  value: data.alatMenunggu,
                  icon:
                      Icons.handyman_rounded,
                  color: orangeStatus,
                  onTap: () => _openPage(
                    const VerifikasiPeminjamanPage(),
                  ),
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
    final text = value > 99
        ? '99+'
        : value.toString();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 69,
          padding: const EdgeInsets.fromLTRB(
            9,
            9,
            9,
            8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -3,
                right: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.4,
                    ),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7.8,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 19,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 9.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsGrid(_AdminProfileData data) {
    final items = [
      _StatItem(
        title: 'Anggota Aktif',
        value: data.totalAnggota,
        icon: Icons.verified_user_rounded,
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
        icon: Icons.inventory_2_rounded,
        color: primaryGreen,
        page: const DataBantuanPupukPage(),
      ),
      _StatItem(
        title: 'Peminjaman Alat',
        value: data.totalPeminjaman,
        icon: Icons.handyman_rounded,
        color: orangeStatus,
        page: const DataPeminjamanAlatPage(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 560 ? 2 : 4;

        const gap = 9.0;

        final itemWidth =
            (constraints.maxWidth -
                    gap * (columns - 1)) /
                columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _statCard(item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statCard(_StatItem item) {
    final countText = item.value > 99
        ? '99+'
        : item.value.toString();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => _openPage(item.page),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          height: 86,
          padding: const EdgeInsets.fromLTRB(
            11,
            11,
            9,
            11,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: item.color.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: adminNavy.withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 41,
                width: 41,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      countText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.color,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 10.5,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: item.color,
                size: 14,
              ),
            ],
          ),
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
    return Material(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            11,
            11,
            10,
            11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: adminNavy.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(13),
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
                        fontSize: 9.6,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutTile() {
    return Material(
      color: const Color(0xffFFF7F7),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            11,
            11,
            10,
            11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: redColor.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: redColor.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                child: const Icon(
                  Icons.logout_rounded,
                  color: redColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keluar',
                      style: TextStyle(
                        color: redColor,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Akhiri sesi admin dan kembali ke halaman awal',
                      style: TextStyle(
                        color: Color(0xff991B1B),
                        fontSize: 9.7,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: redColor,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          height: 33,
          width: 4,
          decoration: BoxDecoration(
            color: adminPurple,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 9.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: adminNavy.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}


class _AdminProfileBackground extends StatelessWidget {
  const _AdminProfileBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final base = width < height ? width : height;

            final large = (base * 1.02)
                .clamp(290.0, 500.0)
                .toDouble();

            final medium = (base * 0.70)
                .clamp(200.0, 345.0)
                .toDouble();

            final small = (base * 0.42)
                .clamp(125.0, 205.0)
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
                          0.20,
                          0.46,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.56,
                    right: -large * 0.31,
                    child: _ProfileBackgroundCircle(
                      size: large,
                      color: const Color(0xff6256A4),
                      alpha: 0.22,
                    ),
                  ),
                  Positioned(
                    top: -small * 0.10,
                    left: -small * 0.24,
                    child: _ProfileBackgroundRing(
                      size: small,
                      color: Colors.white,
                      alpha: 0.11,
                    ),
                  ),
                  Positioned(
                    top: height * 0.28,
                    left: -medium * 0.57,
                    child: _ProfileBackgroundCircle(
                      size: medium,
                      color: const Color(0xff54779A),
                      alpha: 0.14,
                    ),
                  ),
                  Positioned(
                    top: height * 0.50,
                    right: -medium * 0.64,
                    child: _ProfileBackgroundCircle(
                      size: medium * 1.08,
                      color: const Color(0xffE8E1F7),
                      alpha: 0.38,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.53,
                    left: -large * 0.31,
                    child: _ProfileBackgroundCircle(
                      size: large,
                      color: const Color(0xffDCEDE8),
                      alpha: 0.34,
                    ),
                  ),
                  const Positioned(
                    top: 88,
                    right: 18,
                    child: _ProfileWatermark(
                      icon: Icons.manage_accounts_rounded,
                      size: 68,
                      color: Colors.white,
                      alpha: 0.050,
                      angle: -0.14,
                    ),
                  ),
                  const Positioned(
                    bottom: 118,
                    left: 18,
                    child: _ProfileWatermark(
                      icon: Icons.admin_panel_settings_outlined,
                      size: 60,
                      color: Color(0xff6256A4),
                      alpha: 0.030,
                      angle: 0.16,
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

class _ProfileBackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _ProfileBackgroundCircle({
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ProfileBackgroundRing extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _ProfileBackgroundRing({
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: alpha),
          width: 2,
        ),
      ),
    );
  }
}

class _ProfileWatermark extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double alpha;
  final double angle;

  const _ProfileWatermark({
    required this.icon,
    required this.size,
    required this.color,
    required this.alpha,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Icon(
        icon,
        size: size,
        color: color.withValues(alpha: alpha),
      ),
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