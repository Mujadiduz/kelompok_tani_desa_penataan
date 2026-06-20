import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NotifikasiAdminPage extends StatefulWidget {
  const NotifikasiAdminPage({super.key});

  @override
  State<NotifikasiAdminPage> createState() => _NotifikasiAdminPageState();
}

class _NotifikasiAdminPageState extends State<NotifikasiAdminPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color redStatus = Color(0xffDC2626);

  final DatabaseReference notifRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('notifikasi_admin');

  List<MapEntry<String, dynamic>> ambilNotif(dynamic value) {
    if (value == null || value is! Map) return [];
    final data = Map<String, dynamic>.from(value);
    return data.entries.toList().reversed.toList();
  }

  bool isBelumDibaca(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase().trim();
    final dibaca = data['dibaca'];
    return status == 'belum_dibaca' || dibaca == false;
  }

  Future<void> tandaiDibaca(String id) async {
    await notifRef.child(id).update({'status': 'dibaca', 'dibaca': true});
  }

  Future<void> tandaiSemuaDibaca(List<MapEntry<String, dynamic>> data) async {
    for (final item in data) {
      await notifRef.child(item.key).update({
        'status': 'dibaca',
        'dibaca': true,
      });
    }
  }

  IconData iconNotif(String tipe) {
    if (tipe == 'anggota' || tipe == 'verifikasi_anggota') {
      return Icons.person_add_alt_1_rounded;
    }
    if (tipe == 'bantuan_pupuk') return Icons.eco_rounded;
    if (tipe == 'peminjaman_alat') return Icons.agriculture_rounded;
    return Icons.notifications_rounded;
  }

  Color warnaNotif(String tipe) {
    if (tipe == 'anggota' || tipe == 'verifikasi_anggota') {
      return const Color(0xff1976D2);
    }
    if (tipe == 'bantuan_pupuk') return primaryGreen;
    if (tipe == 'peminjaman_alat') return orangeStatus;
    return primaryGreen;
  }

  String formatTanggal(String value) {
    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.isEmpty ? '-' : value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: notifRef.onValue,
          builder: (context, snapshot) {
            final listNotif = ambilNotif(snapshot.data?.snapshot.value);

            final belumDibaca =
                listNotif.where((entry) {
                  final data = Map<String, dynamic>.from(entry.value as Map);
                  return isBelumDibaca(data);
                }).length;

            return Column(
              children: [
                _header(context, belumDibaca, listNotif),
                Expanded(child: _buildContent(snapshot, listNotif)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    int belumDibaca,
    List<MapEntry<String, dynamic>> listNotif,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -28,
            bottom: -42,
            child: Icon(
              Icons.admin_panel_settings_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(context),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Notifikasi Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (listNotif.isNotEmpty)
                    TextButton(
                      onPressed:
                          belumDibaca == 0
                              ? null
                              : () => tandaiSemuaDibaca(listNotif),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      child: const Text(
                        'Baca Semua',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      belumDibaca == 0
                          ? 'Semua Notifikasi Dibaca'
                          : 'Ada Notifikasi Baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _unreadBadge(belumDibaca),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                belumDibaca == 0
                    ? 'Tidak ada pemberitahuan baru yang perlu diperiksa admin.'
                    : '$belumDibaca notifikasi belum dibaca dari pengajuan anggota, pupuk, atau alat.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unreadBadge(int total) {
    final text = total > 99 ? '99+' : total.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 54, minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: total > 0 ? redStatus : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow:
            total > 0
                ? [
                  BoxShadow(
                    color: redStatus.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
                : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            total > 0 ? text : '0',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'baru',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> snapshot,
    List<MapEntry<String, dynamic>> listNotif,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    if (snapshot.hasError) {
      return _emptyState(
        icon: Icons.error_outline_rounded,
        title: 'Terjadi Kesalahan',
        message: snapshot.error.toString(),
      );
    }

    if (listNotif.isEmpty) {
      return _emptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Belum Ada Notifikasi',
        message: 'Notifikasi admin akan muncul saat ada pengajuan baru.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      itemCount: listNotif.length,
      itemBuilder: (context, index) {
        final id = listNotif[index].key;
        final data = Map<String, dynamic>.from(listNotif[index].value as Map);
        return _notifCard(id, data);
      },
    );
  }

  Widget _notifCard(String id, Map<String, dynamic> data) {
    final judul = (data['judul'] ?? '-').toString();
    final pesan = (data['pesan'] ?? '-').toString();
    final tipe = (data['tipe'] ?? '').toString();
    final tanggal = (data['tanggal'] ?? '').toString();
    final belumDibaca = isBelumDibaca(data);
    final color = warnaNotif(tipe);

    return InkWell(
      onTap: () {
        if (belumDibaca) tandaiDibaca(id);
      },
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: belumDibaca ? color.withValues(alpha: 0.055) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                belumDibaca
                    ? color.withValues(alpha: 0.36)
                    : const Color(0xffE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(iconNotif(tipe), color: color, size: 28),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          judul,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textDark,
                            fontSize: 15.5,
                            fontWeight:
                                belumDibaca ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (belumDibaca) ...[
                        const SizedBox(width: 8),
                        Container(
                          height: 9,
                          width: 9,
                          decoration: const BoxDecoration(
                            color: redStatus,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pesan,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: color),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          formatTanggal(tanggal),
                          style: const TextStyle(
                            color: textGrey,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              belumDibaca
                                  ? redStatus.withValues(alpha: 0.10)
                                  : lightGreen,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          belumDibaca ? 'Belum dibaca' : 'Dibaca',
                          style: TextStyle(
                            color: belumDibaca ? redStatus : primaryGreen,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
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
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 88,
              width: 88,
              decoration: const BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryGreen, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: textGrey,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
