import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class VerifikasiPeminjamanPage extends StatefulWidget {
  const VerifikasiPeminjamanPage({super.key});

  @override
  State<VerifikasiPeminjamanPage> createState() =>
      _VerifikasiPeminjamanPageState();
}

class _VerifikasiPeminjamanPageState extends State<VerifikasiPeminjamanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color purpleStatus = Color(0xff7B1FA2);
  static const Color redStatus = Color(0xffDC2626);

  String selectedFilter = 'semua';
  bool isProcessing = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference peminjamanRef;
  late final DatabaseReference alatRef;

  @override
  void initState() {
    super.initState();
    peminjamanRef = db.ref('peminjaman_alat');
    alatRef = db.ref('alat_pertanian');
  }

  Future<void> refreshData() async {
    await peminjamanRef.get();
  }

  String _text(dynamic value) {
    if (value == null) return '-';
    final result = value.toString().trim();
    return result.isEmpty ? '-' : result;
  }

  int _intValue(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  String normalStatus(Map<dynamic, dynamic> item) {
    final status = _text(item['status']).toLowerCase();
    return status == '-' ? 'menunggu' : status;
  }

  String ambilNik(Map<dynamic, dynamic> item) {
    return _text(
      item['nik'] ?? item['nik_anggota'] ?? item['nik_user'] ?? item['nikUser'],
    );
  }

  String ambilNama(Map<dynamic, dynamic> item) {
    return _text(
      item['nama'] ??
          item['nama_anggota'] ??
          item['nama_user'] ??
          item['namaUser'],
    );
  }

  String ambilNamaAlat(Map<dynamic, dynamic> item) {
    return _text(
      item['alat'] ??
          item['nama_alat'] ??
          item['namaAlat'] ??
          item['jenis_alat'],
    );
  }

  String ambilIdAlat(Map<dynamic, dynamic> item) {
    return _text(item['id_alat'] ?? item['alat_id'] ?? item['idAlat']);
  }

  int ambilJumlah(Map<dynamic, dynamic> item) {
    return _intValue(item['jumlah'] ?? item['jumlah_alat'], fallback: 1);
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'dipinjam') return 'Dipinjam';
    if (status == 'dikembalikan') return 'Dikembalikan';
    if (status == 'ditolak') return 'Ditolak';
    return 'Menunggu';
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') return blueStatus;
    if (status == 'dipinjam') return purpleStatus;
    if (status == 'dikembalikan') return primaryGreen;
    if (status == 'ditolak') return redStatus;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return const Color(0xffE3F2FD);
    if (status == 'dipinjam') return const Color(0xffF3E5F5);
    if (status == 'dikembalikan') return lightGreen;
    if (status == 'ditolak') return const Color(0xffFEE2E2);
    return const Color(0xffFFF3E0);
  }

  IconData iconAlat(String alat) {
    final namaAlat = alat.toLowerCase();

    if (namaAlat.contains('sprayer')) return Icons.water_drop_rounded;
    if (namaAlat.contains('cangkul')) return Icons.construction_rounded;
    if (namaAlat.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  String _duaDigit(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _formatTanggal(DateTime date) {
    return '${date.year}-${_duaDigit(date.month)}-${_duaDigit(date.day)}';
  }

  String _formatWaktu(DateTime date) {
    return '${_duaDigit(date.hour)}:${_duaDigit(date.minute)}';
  }

  DateTime? _parseTanggal(String value) {
    try {
      final clean = value.trim();

      if (clean.isEmpty || clean == '-') return null;

      if (clean.contains('-')) {
        final parts = clean.split('-');

        if (parts.length != 3) return null;

        if (parts[0].length == 4) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (clean.contains('/')) {
        final parts = clean.split('/');

        if (parts.length != 3) return null;

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  _HasilKeterlambatan _hitungKeterlambatan(
    String tanggalKembali,
    DateTime aktual,
  ) {
    final rencanaKembali = _parseTanggal(tanggalKembali);

    if (rencanaKembali == null) {
      return const _HasilKeterlambatan(
        status: 'tidak_diketahui',
        hariTerlambat: 0,
      );
    }

    final rencana = DateTime(
      rencanaKembali.year,
      rencanaKembali.month,
      rencanaKembali.day,
    );

    final tanggalAktual = DateTime(aktual.year, aktual.month, aktual.day);
    final selisih = tanggalAktual.difference(rencana).inDays;

    if (selisih > 0) {
      return _HasilKeterlambatan(status: 'terlambat', hariTerlambat: selisih);
    }

    return const _HasilKeterlambatan(status: 'tepat_waktu', hariTerlambat: 0);
  }

  String teksPengembalian(Map<dynamic, dynamic> item) {
    final status = _text(item['status_pengembalian']).toLowerCase();

    if (status == 'terlambat') {
      return 'Terlambat ${item['jumlah_hari_terlambat'] ?? 0} hari';
    }

    if (status == 'tepat_waktu') {
      return 'Tepat waktu';
    }

    return 'Belum diketahui';
  }

  Color warnaPengembalian(Map<dynamic, dynamic> item) {
    final status = _text(item['status_pengembalian']).toLowerCase();

    if (status == 'terlambat') return redStatus;
    if (status == 'tepat_waktu') return primaryGreen;

    return textGrey;
  }

  Map<String, int> hitungStatus(List<MapEntry<String, dynamic>> data) {
    int menunggu = 0;
    int disetujui = 0;
    int dipinjam = 0;
    int dikembalikan = 0;
    int ditolak = 0;

    for (final entry in data) {
      if (entry.value is Map) {
        final item = Map<dynamic, dynamic>.from(entry.value as Map);
        final status = normalStatus(item);

        if (status == 'menunggu') menunggu++;
        if (status == 'disetujui') disetujui++;
        if (status == 'dipinjam') dipinjam++;
        if (status == 'dikembalikan') dikembalikan++;
        if (status == 'ditolak') ditolak++;
      }
    }

    return {
      'semua': data.length,
      'menunggu': menunggu,
      'disetujui': disetujui,
      'dipinjam': dipinjam,
      'dikembalikan': dikembalikan,
      'ditolak': ditolak,
    };
  }

  List<MapEntry<String, dynamic>> filterData(
    List<MapEntry<String, dynamic>> data,
  ) {
    if (selectedFilter == 'semua') return data;

    return data.where((entry) {
      if (entry.value is! Map) return false;
      final item = Map<dynamic, dynamic>.from(entry.value as Map);
      return normalStatus(item) == selectedFilter;
    }).toList();
  }

  Future<void> updateStatus(
    String id,
    String status,
    Map<dynamic, dynamic> item,
  ) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      await peminjamanRef.child(id).update({
        'status': status,
        'tanggal_verifikasi': DateTime.now().toIso8601String(),
      });

      final nik = ambilNik(item);
      final namaAlat = ambilNamaAlat(item);

      if (status == 'disetujui') {
        unawaited(
          NotificationHelper.alatDisetujui(nik: nik, namaAlat: namaAlat),
        );
      } else if (status == 'ditolak') {
        unawaited(NotificationHelper.alatDitolak(nik: nik, namaAlat: namaAlat));
      }

      if (!mounted) return;

      _showSnackBar(
        status == 'disetujui'
            ? 'Peminjaman berhasil disetujui'
            : 'Peminjaman berhasil ditolak',
        status == 'disetujui' ? primaryGreen : redStatus,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengubah status: $e', redStatus);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> tandaiDipinjam(String id, Map<dynamic, dynamic> item) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final idAlat = ambilIdAlat(item);
      final namaAlat = ambilNamaAlat(item);
      final jumlahPinjam = ambilJumlah(item);
      final nik = ambilNik(item);

      if (idAlat == '-') {
        throw Exception('ID alat tidak ditemukan pada data peminjaman');
      }

      final alatSnapshot = await alatRef.child(idAlat).get();

      if (!alatSnapshot.exists || alatSnapshot.value == null) {
        throw Exception('Data alat tidak ditemukan');
      }

      final pinjamSnapshot = await peminjamanRef.get();

      final dataAlat = Map<dynamic, dynamic>.from(alatSnapshot.value as Map);

      final totalUnit = _intValue(
        dataAlat['jumlah_unit'] ??
            dataAlat['stok'] ??
            dataAlat['stok_unit'] ??
            dataAlat['jumlah'],
      );

      final peminjamanData =
          pinjamSnapshot.exists && pinjamSnapshot.value is Map
              ? Map<dynamic, dynamic>.from(pinjamSnapshot.value as Map)
              : <dynamic, dynamic>{};

      final sedangDipinjam = _hitungSedangDipinjamById(
        idAlat,
        peminjamanData,
        currentId: id,
      );

      final sisaTersedia = totalUnit - sedangDipinjam;

      if (sisaTersedia < jumlahPinjam) {
        throw Exception(
          'Stok alat tidak mencukupi. Tersedia $sisaTersedia unit.',
        );
      }

      final now = DateTime.now();

      await peminjamanRef.child(id).update({
        'status': 'dipinjam',
        'tanggal_diambil': _formatTanggal(now),
        'waktu_diambil': _formatWaktu(now),
        'alat': namaAlat,
      });

      unawaited(
        NotificationHelper.alatDipinjam(
          nik: nik,
          namaAlat: namaAlat,
          jumlah: jumlahPinjam,
        ),
      );

      if (!mounted) return;
      _showSnackBar('Alat berhasil ditandai dipinjam', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menandai dipinjam: $e', redStatus);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> tandaiDikembalikan(String id, Map<dynamic, dynamic> item) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final now = DateTime.now();
      final tanggalKembali = _text(item['tanggal_kembali']);
      final hasil = _hitungKeterlambatan(tanggalKembali, now);
      final nik = ambilNik(item);
      final namaAlat = ambilNamaAlat(item);

      await peminjamanRef.child(id).update({
        'status': 'dikembalikan',
        'tanggal_dikembalikan': _formatTanggal(now),
        'waktu_dikembalikan': _formatWaktu(now),
        'status_pengembalian': hasil.status,
        'jumlah_hari_terlambat': hasil.hariTerlambat,
      });

      final pesanTambahan =
          hasil.status == 'terlambat'
              ? ' Pengembalian terlambat ${hasil.hariTerlambat} hari.'
              : ' Pengembalian tepat waktu.';

      unawaited(
        NotificationHelper.alatDikembalikan(
          nik: nik,
          namaAlat: namaAlat,
          pesanTambahan: pesanTambahan,
        ),
      );

      if (!mounted) return;
      _showSnackBar('Alat berhasil ditandai dikembalikan', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menandai pengembalian: $e', redStatus);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  int _hitungSedangDipinjamById(
    String idAlat,
    Map<dynamic, dynamic> data, {
    required String currentId,
  }) {
    int total = 0;

    for (final entry in data.entries) {
      if (entry.key.toString() == currentId) continue;

      if (entry.value is Map) {
        final item = Map<dynamic, dynamic>.from(entry.value as Map);
        final itemIdAlat = ambilIdAlat(item);
        final status = normalStatus(item);

        if (itemIdAlat == idAlat && status == 'dipinjam') {
          total += ambilJumlah(item);
        }
      }
    }

    return total;
  }

  Future<void> tampilkanKonfirmasi({
    required String id,
    required String status,
    required Map<dynamic, dynamic> item,
  }) async {
    final nama = ambilNama(item);
    final isSetuju = status == 'disetujui';

    final hasil = await _showConfirmDialog(
      icon: isSetuju ? Icons.check_circle_rounded : Icons.cancel_rounded,
      iconColor: isSetuju ? primaryGreen : redStatus,
      title: isSetuju ? 'Setujui Peminjaman?' : 'Tolak Peminjaman?',
      message:
          isSetuju
              ? 'Pengajuan peminjaman dari $nama akan disetujui.'
              : 'Pengajuan peminjaman dari $nama akan ditolak.',
      confirmText: isSetuju ? 'Setujui' : 'Tolak',
      confirmColor: isSetuju ? primaryGreen : redStatus,
    );

    if (!mounted) return;

    if (hasil == true) {
      await updateStatus(id, status, item);
    }
  }

  Future<void> konfirmasiDipinjam({
    required String id,
    required Map<dynamic, dynamic> item,
  }) async {
    final nama = ambilNama(item);
    final alat = ambilNamaAlat(item);

    final hasil = await _showConfirmDialog(
      icon: Icons.output_rounded,
      iconColor: primaryGreen,
      title: 'Tandai Dipinjam?',
      message:
          'Pastikan $nama sudah mengambil alat $alat. Status akan berubah menjadi dipinjam.',
      confirmText: 'Ya, Dipinjam',
      confirmColor: primaryGreen,
    );

    if (!mounted) return;

    if (hasil == true) {
      await tandaiDipinjam(id, item);
    }
  }

  Future<void> konfirmasiDikembalikan({
    required String id,
    required Map<dynamic, dynamic> item,
  }) async {
    final nama = ambilNama(item);
    final alat = ambilNamaAlat(item);

    final hasil = await _showConfirmDialog(
      icon: Icons.assignment_turned_in_rounded,
      iconColor: primaryGreen,
      title: 'Tandai Dikembalikan?',
      message: 'Pastikan $nama sudah mengembalikan alat $alat.',
      confirmText: 'Ya, Kembali',
      confirmColor: primaryGreen,
    );

    if (!mounted) return;

    if (hasil == true) {
      await tandaiDikembalikan(id, item);
    }
  }

  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 34),
                ),
                const SizedBox(height: 16),
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
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(
                          confirmText,
                          style: const TextStyle(fontWeight: FontWeight.w900),
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

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pesan,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: StreamBuilder<DatabaseEvent>(
                stream: peminjamanRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        _headerPage(0),
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
                        _headerPage(0),
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: primaryGreen,
                            ),
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

                  final jumlahStatus = hitungStatus(semuaData);

                  final totalSemua = jumlahStatus['semua'] ?? 0;
                  final totalMenunggu = jumlahStatus['menunggu'] ?? 0;
                  final totalDisetujui = jumlahStatus['disetujui'] ?? 0;
                  final totalDipinjam = jumlahStatus['dipinjam'] ?? 0;
                  final totalDikembalikan = jumlahStatus['dikembalikan'] ?? 0;
                  final totalDitolak = jumlahStatus['ditolak'] ?? 0;

                  final peminjamanList = filterData(semuaData);

                  return Column(
                    children: [
                      _headerPage(totalMenunggu),
                      Expanded(
                        child: RefreshIndicator(
                          color: primaryGreen,
                          backgroundColor: Colors.white,
                          onRefresh: refreshData,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                            children: [
                              _statusPanel(
                                totalSemua: totalSemua,
                                totalMenunggu: totalMenunggu,
                                totalDisetujui: totalDisetujui,
                                totalDipinjam: totalDipinjam,
                                totalDikembalikan: totalDikembalikan,
                                totalDitolak: totalDitolak,
                              ),
                              const SizedBox(height: 14),
                              _sectionTitle(
                                title: 'Daftar Peminjaman',
                                subtitle:
                                    selectedFilter == 'semua'
                                        ? 'Semua data peminjaman alat anggota'
                                        : 'Filter: ${teksStatus(selectedFilter)}',
                              ),
                              const SizedBox(height: 12),
                              if (semuaData.isEmpty)
                                _messageState(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'Belum Ada Pengajuan',
                                  message:
                                      'Data peminjaman alat belum tersedia.',
                                )
                              else if (peminjamanList.isEmpty)
                                _messageState(
                                  icon: Icons.search_off_rounded,
                                  title: 'Data Tidak Ditemukan',
                                  message:
                                      'Tidak ada peminjaman alat dengan status ini.',
                                )
                              else
                                ...peminjamanList.map((entry) {
                                  final id = entry.key.toString();
                                  final item = Map<dynamic, dynamic>.from(
                                    entry.value as Map,
                                  );

                                  return _peminjamanCard(id, item);
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.20),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerPage(int totalMenunggu) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [darkGreen, primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _backButton(),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Verifikasi Peminjaman',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (totalMenunggu > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      '$totalMenunggu Baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      totalMenunggu == 0
                          ? 'Semua pengajuan peminjaman alat sudah diproses.'
                          : '$totalMenunggu pengajuan peminjaman alat masih menunggu verifikasi.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _statusPanel({
    required int totalSemua,
    required int totalMenunggu,
    required int totalDisetujui,
    required int totalDipinjam,
    required int totalDikembalikan,
    required int totalDitolak,
  }) {
    final filters = [
      _FilterItem(
        'Semua',
        'semua',
        totalSemua,
        Icons.list_alt_rounded,
        primaryGreen,
      ),
      _FilterItem(
        'Menunggu',
        'menunggu',
        totalMenunggu,
        Icons.schedule_rounded,
        orangeStatus,
      ),
      _FilterItem(
        'Setuju',
        'disetujui',
        totalDisetujui,
        Icons.check_circle_rounded,
        blueStatus,
      ),
      _FilterItem(
        'Dipinjam',
        'dipinjam',
        totalDipinjam,
        Icons.output_rounded,
        purpleStatus,
      ),
      _FilterItem(
        'Kembali',
        'dikembalikan',
        totalDikembalikan,
        Icons.assignment_turned_in_rounded,
        primaryGreen,
      ),
      _FilterItem(
        'Ditolak',
        'ditolak',
        totalDitolak,
        Icons.cancel_rounded,
        redStatus,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Status',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            totalMenunggu == 0
                ? 'Tidak ada pengajuan yang perlu diverifikasi.'
                : 'Ada $totalMenunggu pengajuan yang belum diproses.',
            style: TextStyle(
              color: totalMenunggu == 0 ? primaryGreen : orangeStatus,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: filters.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final item = filters[index];
              final aktif = selectedFilter == item.value;

              return InkWell(
                onTap: () => setState(() => selectedFilter = item.value),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color:
                        aktif ? item.color : item.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          aktif
                              ? item.color
                              : item.color.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: aktif ? Colors.white : item.color,
                        size: 23,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 5,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(20),
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
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
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
      ],
    );
  }

  Widget _peminjamanCard(String id, Map<dynamic, dynamic> item) {
    final nama = ambilNama(item);
    final nik = ambilNik(item);
    final alat = ambilNamaAlat(item);
    final idAlat = ambilIdAlat(item);
    final jumlah = ambilJumlah(item).toString();
    final tanggalPinjam = _text(item['tanggal_pinjam']);
    final tanggalKembali = _text(item['tanggal_kembali']);
    final catatan = _text(item['catatan']);
    final status = normalStatus(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(alat: alat, nama: nama, status: status),
          const SizedBox(height: 14),
          _infoBox(
            children: [
              _infoRow(Icons.person_rounded, 'Nama', nama),
              _infoRow(Icons.badge_outlined, 'NIK', nik),
              _infoRow(Icons.handyman_rounded, 'Alat', alat),
              _infoRow(Icons.qr_code_rounded, 'ID Alat', idAlat),
              _infoRow(Icons.inventory_2_rounded, 'Jumlah', '$jumlah Unit'),
              _infoRow(
                Icons.calendar_today_rounded,
                'Tanggal Pinjam',
                tanggalPinjam,
              ),
              _infoRow(
                Icons.event_available_rounded,
                'Rencana Kembali',
                tanggalKembali,
              ),
              if (status == 'dipinjam' || status == 'dikembalikan') ...[
                _infoRow(
                  Icons.output_rounded,
                  'Tanggal Diambil',
                  _text(item['tanggal_diambil']),
                ),
                _infoRow(
                  Icons.access_time_rounded,
                  'Waktu Diambil',
                  _text(item['waktu_diambil']),
                ),
              ],
              if (status == 'dikembalikan') ...[
                _infoRow(
                  Icons.event_repeat_rounded,
                  'Tanggal Kembali',
                  _text(item['tanggal_dikembalikan']),
                ),
                _infoRow(
                  Icons.access_time_rounded,
                  'Waktu Kembali',
                  _text(item['waktu_dikembalikan']),
                ),
                _infoRow(
                  Icons.timer_outlined,
                  'Ketepatan',
                  teksPengembalian(item),
                  valueColor: warnaPengembalian(item),
                ),
              ],
              if (catatan != '-')
                _infoRow(Icons.notes_rounded, 'Catatan', catatan),
            ],
          ),
          if (status == 'menunggu') ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    title: 'Tolak',
                    icon: Icons.close_rounded,
                    color: redStatus,
                    onPressed: () {
                      tampilkanKonfirmasi(
                        id: id,
                        status: 'ditolak',
                        item: item,
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
                        status: 'disetujui',
                        item: item,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
          if (status == 'disetujui') ...[
            const SizedBox(height: 15),
            _actionButton(
              title: 'Tandai Dipinjam',
              icon: Icons.inventory_rounded,
              color: primaryGreen,
              onPressed: () => konfirmasiDipinjam(id: id, item: item),
            ),
          ],
          if (status == 'dipinjam') ...[
            const SizedBox(height: 15),
            _actionButton(
              title: 'Tandai Dikembalikan',
              icon: Icons.assignment_turned_in_rounded,
              color: primaryGreen,
              onPressed: () => konfirmasiDikembalikan(id: id, item: item),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardTop({
    required String alat,
    required String nama,
    required String status,
  }) {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(iconAlat(alat), color: primaryGreen, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alat == '-' ? 'Peminjaman Alat' : alat,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nama,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12.5,
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

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: warnaStatus(status).withValues(alpha: 0.18)),
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

  Widget _infoBox({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 4),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
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
              value.isEmpty ? '-' : value,
              style: TextStyle(
                color: valueColor ?? textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isProcessing ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
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
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
                border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
              ),
              child: Icon(icon, color: primaryGreen, size: 40),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
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

  const _FilterItem(this.label, this.value, this.total, this.icon, this.color);
}

class _HasilKeterlambatan {
  final String status;
  final int hariTerlambat;

  const _HasilKeterlambatan({
    required this.status,
    required this.hariTerlambat,
  });
}
