import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class VerifikasiAnggotaPage extends StatefulWidget {
  const VerifikasiAnggotaPage({super.key});

  @override
  State<VerifikasiAnggotaPage> createState() => _VerifikasiAnggotaPageState();
}

class _VerifikasiAnggotaPageState extends State<VerifikasiAnggotaPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  String selectedFilter = 'semua';

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference calonAnggotaRef;
  late final DatabaseReference anggotaRef;
  late final DatabaseReference notifikasiRef;

  @override
  void initState() {
    super.initState();
    calonAnggotaRef = db.ref('calon_anggota');
    anggotaRef = db.ref('anggota');
    notifikasiRef = db.ref('notifikasi');
  }

  Future<void> setujuiAnggota(String id, Map<String, dynamic> anggota) async {
    try {
      await anggotaRef
          .child(id)
          .set({
            'nama': anggota['nama'] ?? '',
            'nik': anggota['nik'] ?? '',
            'telepon': anggota['telepon'] ?? '',
            'alamat': anggota['alamat'] ?? '',
            'jenis_kelamin': anggota['jenis_kelamin'] ?? '',
            'luas_sawah': anggota['luas_sawah'] ?? '',
            'foto_ktp_base64': anggota['foto_ktp_base64'] ?? '',
            'tanggal_daftar': anggota['tanggal_daftar'] ?? '',
            'tanggal_verifikasi': DateTime.now().toIso8601String(),
            'password': anggota['password'] ?? '',
            'status': 'aktif',
          })
          .timeout(const Duration(seconds: 10));

      await calonAnggotaRef
          .child(id)
          .remove()
          .timeout(const Duration(seconds: 10));

      await _kirimNotifikasiUser(
        nik: (anggota['nik'] ?? '').toString(),
        judul: 'Pendaftaran Disetujui',
        pesan:
            'Selamat, pendaftaran Anda sebagai anggota Kelompok Tani Desa Penataan telah disetujui.',
      );

      if (!mounted) return;
      _showSnackBar('Anggota berhasil disetujui', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menyetujui anggota: $e', Colors.red);
    }
  }

  Future<void> tolakAnggota(String id, Map<String, dynamic> anggota) async {
    try {
      await calonAnggotaRef
          .child(id)
          .update({
            'status': 'ditolak',
            'tanggal_verifikasi': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));

      await _kirimNotifikasiUser(
        nik: (anggota['nik'] ?? '').toString(),
        judul: 'Pendaftaran Ditolak',
        pesan:
            'Mohon maaf, pendaftaran Anda sebagai anggota Kelompok Tani Desa Penataan ditolak oleh admin.',
      );

      if (!mounted) return;
      _showSnackBar('Anggota berhasil ditolak', Colors.red);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menolak anggota: $e', Colors.red);
    }
  }

  Future<void> _kirimNotifikasiUser({
    required String nik,
    required String judul,
    required String pesan,
  }) async {
    if (nik.isEmpty) return;

    await notifikasiRef.child(nik).push().set({
      'judul': judul,
      'pesan': pesan,
      'status': 'belum_dibaca',
      'dibaca': false,
      'tanggal': DateTime.now().toIso8601String(),
      'tipe': 'verifikasi_anggota',
    });
  }

  Future<void> tampilkanKonfirmasi({
    required String id,
    required Map<String, dynamic> anggota,
    required String status,
  }) async {
    final nama = (anggota['nama'] ?? '-').toString();
    final isSetuju = status == 'disetujui';

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            isSetuju ? 'Setujui Anggota?' : 'Tolak Anggota?',
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            isSetuju
                ? 'Data $nama akan disetujui dan masuk sebagai anggota aktif.'
                : 'Pengajuan anggota dari $nama akan ditolak.',
            style: const TextStyle(color: textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSetuju ? primaryGreen : Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(isSetuju ? 'Setujui' : 'Tolak'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (hasil != true) return;

    if (isSetuju) {
      await setujuiAnggota(id, anggota);
    } else {
      await tolakAnggota(id, anggota);
    }
  }

  Uint8List? decodeFoto(String base64Text) {
    try {
      if (base64Text.isEmpty) return null;
      return base64Decode(base64Text);
    } catch (_) {
      return null;
    }
  }

  void lihatFotoKtp(String base64Text) {
    final fotoBytes = decodeFoto(base64Text);

    if (fotoBytes == null) {
      _showSnackBar('Foto KTP tidak tersedia', Colors.red);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: primaryGreen,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Foto KTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.memory(fotoBytes, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String normalStatus(Map<String, dynamic> item) {
    return (item['status'] ?? 'menunggu').toString().toLowerCase().trim();
  }

  int countStatus(List<MapEntry<String, dynamic>> data, String status) {
    if (status == 'semua') return data.length;

    return data.where((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      return normalStatus(item) == status;
    }).length;
  }

  List<MapEntry<String, dynamic>> filterData(
    List<MapEntry<String, dynamic>> data,
  ) {
    if (selectedFilter == 'semua') return data;

    return data.where((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      return normalStatus(item) == selectedFilter;
    }).toList();
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') return primaryGreen;
    if (status == 'ditolak') return Colors.red;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return lightGreen;
    if (status == 'ditolak') return const Color(0xffFFEBEE);
    return const Color(0xffFFF3E0);
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    return 'Menunggu';
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: calonAnggotaRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                children: [
                  _header(0),
                  Expanded(
                    child: _messageState(
                      icon: Icons.error_outline_rounded,
                      title: 'Terjadi Kesalahan',
                      message: snapshot.error.toString(),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _header(0),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    ),
                  ),
                ],
              );
            }

            final rawData = snapshot.data?.snapshot.value;

            List<MapEntry<String, dynamic>> semuaData = [];

            if (rawData is Map) {
              final data = Map<String, dynamic>.from(rawData);
              semuaData = data.entries.toList().reversed.toList();
            }

            final totalSemua = countStatus(semuaData, 'semua');
            final totalMenunggu = countStatus(semuaData, 'menunggu');
            final totalDisetujui = countStatus(semuaData, 'disetujui');
            final totalDitolak = countStatus(semuaData, 'ditolak');
            final anggotaList = filterData(semuaData);

            return Column(
              children: [
                _header(totalMenunggu),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    children: [
                      _statusControlPanel(
                        totalSemua: totalSemua,
                        totalMenunggu: totalMenunggu,
                        totalDisetujui: totalDisetujui,
                        totalDitolak: totalDitolak,
                      ),
                      const SizedBox(height: 14),
                      if (semuaData.isEmpty)
                        _messageState(
                          icon: Icons.inbox_outlined,
                          title: 'Belum Ada Data',
                          message: 'Belum ada data calon anggota yang masuk.',
                        )
                      else if (anggotaList.isEmpty)
                        _messageState(
                          icon: Icons.search_off_rounded,
                          title: 'Data Tidak Ditemukan',
                          message: 'Tidak ada calon anggota dengan status ini.',
                        )
                      else
                        ...anggotaList.map((entry) {
                          final id = entry.key.toString();
                          final anggota = Map<String, dynamic>.from(
                            entry.value as Map,
                          );

                          return _anggotaCard(id, anggota);
                        }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(int totalMenunggu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
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
            right: -22,
            bottom: -38,
            child: Icon(
              Icons.groups_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Verifikasi Anggota',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                totalMenunggu == 0
                    ? 'Semua calon anggota sudah diproses oleh admin.'
                    : '$totalMenunggu calon anggota masih menunggu verifikasi.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusControlPanel({
    required int totalSemua,
    required int totalMenunggu,
    required int totalDisetujui,
    required int totalDitolak,
  }) {
    final aman = totalMenunggu == 0;

    final filters = [
      _FilterItem(
        label: 'Semua',
        value: 'semua',
        total: totalSemua,
        icon: Icons.list_alt_rounded,
        color: primaryGreen,
      ),
      _FilterItem(
        label: 'Menunggu',
        value: 'menunggu',
        total: totalMenunggu,
        icon: Icons.schedule_rounded,
        color: orangeStatus,
      ),
      _FilterItem(
        label: 'Disetujui',
        value: 'disetujui',
        total: totalDisetujui,
        icon: Icons.check_circle_rounded,
        color: primaryGreen,
      ),
      _FilterItem(
        label: 'Ditolak',
        value: 'ditolak',
        total: totalDitolak,
        icon: Icons.cancel_rounded,
        color: Colors.red,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color:
                      aman
                          ? primaryGreen.withValues(alpha: 0.12)
                          : orangeStatus.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  aman ? Icons.verified_rounded : Icons.priority_high_rounded,
                  color: aman ? primaryGreen : orangeStatus,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Verifikasi',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aman
                          ? 'Tidak ada calon anggota yang perlu diverifikasi.'
                          : 'Ada $totalMenunggu calon anggota yang belum diverifikasi.',
                      style: TextStyle(
                        color: aman ? primaryGreen : const Color(0xff92400E),
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: filters.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final item = filters[index];
              final aktif = selectedFilter == item.value;

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedFilter = item.value;
                  });
                },
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        aktif ? item.color : item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color:
                          aktif
                              ? item.color
                              : item.color.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color:
                              aktif
                                  ? Colors.white.withValues(alpha: 0.22)
                                  : item.color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          item.icon,
                          color: aktif ? Colors.white : item.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.total.toString(),
                              style: TextStyle(
                                color: aktif ? Colors.white : item.color,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: aktif ? Colors.white : textGrey,
                                fontSize: 11.5,
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
            },
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
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

  Widget _anggotaCard(String id, Map<String, dynamic> anggota) {
    final status = normalStatus(anggota);
    final fotoKtpBase64 = (anggota['foto_ktp_base64'] ?? '').toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(anggota, status),
          const SizedBox(height: 16),
          _infoBox(
            children: [
              _infoRow(Icons.badge_outlined, 'NIK', anggota['nik'] ?? '-'),
              _infoRow(
                Icons.phone_rounded,
                'Telepon',
                anggota['telepon'] ?? '-',
              ),
              _infoRow(Icons.home_rounded, 'Alamat', anggota['alamat'] ?? '-'),
              _infoRow(
                Icons.wc_rounded,
                'Jenis Kelamin',
                anggota['jenis_kelamin'] ?? '-',
              ),
              _infoRow(
                Icons.landscape_rounded,
                'Luas Sawah',
                '${anggota['luas_sawah'] ?? '-'} Ha',
              ),
              _infoRow(
                Icons.calendar_month_rounded,
                'Tanggal Daftar',
                anggota['tanggal_daftar'] ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(color: primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => lihatFotoKtp(fotoKtpBase64),
              icon: const Icon(Icons.credit_card_rounded),
              label: const Text(
                'Lihat Foto KTP',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (status == 'menunggu') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    title: 'Tolak',
                    icon: Icons.close_rounded,
                    color: Colors.red,
                    onPressed: () {
                      tampilkanKonfirmasi(
                        id: id,
                        anggota: anggota,
                        status: 'ditolak',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    title: 'Setujui',
                    icon: Icons.check_rounded,
                    color: primaryGreen,
                    onPressed: () {
                      tampilkanKonfirmasi(
                        id: id,
                        anggota: anggota,
                        status: 'disetujui',
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardTop(Map<String, dynamic> anggota, String status) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: primaryGreen,
            size: 28,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (anggota['nama'] ?? '-').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (anggota['nik'] ?? '-').toString(),
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _statusBadge(status),
      ],
    );
  }

  Widget _infoBox({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString().isEmpty ? '-' : value.toString(),
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        teksStatus(status).toUpperCase(),
        style: TextStyle(
          color: warnaStatus(status),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 28),
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
                fontWeight: FontWeight.w800,
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffE5E7EB)),
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

class _FilterItem {
  final String label;
  final String value;
  final int total;
  final IconData icon;
  final Color color;

  const _FilterItem({
    required this.label,
    required this.value,
    required this.total,
    required this.icon,
    required this.color,
  });
}
