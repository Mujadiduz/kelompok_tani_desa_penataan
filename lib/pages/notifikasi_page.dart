import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NotifikasiPage extends StatefulWidget {
  final String nik;

  const NotifikasiPage({super.key, required this.nik});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference notifRef;

  @override
  void initState() {
    super.initState();
    notifRef = db.ref('notifikasi').child(widget.nik);
  }

  Future<void> tandaiDibaca(String id) async {
    await notifRef.child(id).update({'status': 'dibaca'});
  }

  IconData iconNotif(String tipe) {
    if (tipe == 'bantuan_pupuk') return Icons.grass_rounded;
    if (tipe == 'peminjaman_alat') return Icons.agriculture_rounded;
    if (tipe == 'keanggotaan') return Icons.groups_rounded;
    return Icons.notifications_rounded;
  }

  Color warnaNotif(String tipe) {
    if (tipe == 'bantuan_pupuk') return primaryGreen;
    if (tipe == 'peminjaman_alat') return const Color(0xffFB8C00);
    if (tipe == 'keanggotaan') return const Color(0xff1976D2);
    return primaryGreen;
  }

  String formatTanggal(String value) {
    if (value.isEmpty) return '-';

    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  List<MapEntry<String, dynamic>> ambilNotif(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);
    return data.entries.toList().reversed.toList();
  }

  Future<void> tandaiSemuaDibaca(List<MapEntry<String, dynamic>> data) async {
    for (final item in data) {
      await notifRef.child(item.key).update({'status': 'dibaca'});
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
                  return (data['status'] ?? 'belum_dibaca') == 'belum_dibaca';
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -36,
            child: Icon(
              Icons.notifications_active_rounded,
              size: 145,
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
                      'Notifikasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (listNotif.isNotEmpty)
                    TextButton(
                      onPressed: () => tandaiSemuaDibaca(listNotif),
                      child: const Text(
                        'Baca Semua',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                belumDibaca == 0
                    ? 'Semua notifikasi sudah dibaca'
                    : '$belumDibaca notifikasi belum dibaca',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Informasi status keanggotaan, bantuan pupuk, dan peminjaman alat.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
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
        message: 'Notifikasi akan muncul ketika ada perubahan status.',
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
    final status = (data['status'] ?? 'belum_dibaca').toString();
    final tanggal = (data['tanggal'] ?? '').toString();
    final belumDibaca = status == 'belum_dibaca';
    final color = warnaNotif(tipe);

    return InkWell(
      onTap: () {
        if (belumDibaca) tandaiDibaca(id);
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                belumDibaca
                    ? color.withValues(alpha: 0.35)
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
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(iconNotif(tipe), color: color, size: 27),
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
                          style: TextStyle(
                            color: textDark,
                            fontSize: 15.5,
                            fontWeight:
                                belumDibaca ? FontWeight.w900 : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (belumDibaca)
                        Container(
                          height: 9,
                          width: 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
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
                  const SizedBox(height: 10),
                  Text(
                    formatTanggal(tanggal),
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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
              height: 86,
              width: 86,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
