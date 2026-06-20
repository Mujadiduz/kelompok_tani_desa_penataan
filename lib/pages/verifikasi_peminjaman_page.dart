import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class VerifikasiPeminjamanPage extends StatefulWidget {
  const VerifikasiPeminjamanPage({super.key});

  @override
  State<VerifikasiPeminjamanPage> createState() =>
      _VerifikasiPeminjamanPageState();
}

class _VerifikasiPeminjamanPageState extends State<VerifikasiPeminjamanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color purpleStatus = Color(0xff7B1FA2);

  String selectedFilter = 'semua';
  bool isProcessing = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference peminjamanRef;
  late final DatabaseReference alatRef;
  late final DatabaseReference notifikasiRef;

  @override
  void initState() {
    super.initState();
    peminjamanRef = db.ref('peminjaman_alat');
    alatRef = db.ref('alat_pertanian');
    notifikasiRef = db.ref('notifikasi');
  }

  String normalStatus(Map<dynamic, dynamic> item) {
    return (item['status'] ?? 'menunggu').toString().toLowerCase().trim();
  }

  Future<void> simpanNotifikasi({
    required String nik,
    required String judul,
    required String pesan,
    required String tipe,
  }) async {
    if (nik.trim().isEmpty || nik == '-') return;

    await notifikasiRef.child(nik).push().set({
      'judul': judul,
      'pesan': pesan,
      'tipe': tipe,
      'status': 'belum_dibaca',
      'dibaca': false,
      'tanggal': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateStatus(
    String id,
    String status,
    Map<dynamic, dynamic> item,
  ) async {
    try {
      await peminjamanRef
          .child(id)
          .update({
            'status': status,
            'tanggal_verifikasi': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));

      final nik = (item['nik'] ?? '').toString();
      final alat = (item['alat'] ?? item['nama_alat'] ?? 'alat').toString();

      if (status == 'disetujui') {
        await simpanNotifikasi(
          nik: nik,
          judul: 'Peminjaman Alat Disetujui',
          pesan:
              'Pengajuan peminjaman $alat telah disetujui admin. Silakan menunggu arahan pengambilan alat.',
          tipe: 'peminjaman_alat',
        );
      } else if (status == 'ditolak') {
        await simpanNotifikasi(
          nik: nik,
          judul: 'Peminjaman Alat Ditolak',
          pesan:
              'Pengajuan peminjaman $alat ditolak oleh admin. Silakan cek kembali data pengajuan.',
          tipe: 'peminjaman_alat',
        );
      }

      if (!mounted) return;

      _showSnackBar(
        status == 'disetujui'
            ? 'Peminjaman berhasil disetujui'
            : 'Peminjaman berhasil ditolak',
        status == 'disetujui' ? primaryGreen : Colors.red,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengubah status: $e', Colors.red);
    }
  }

  Future<void> tandaiDipinjam(String id, Map<dynamic, dynamic> item) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final idAlat = (item['id_alat'] ?? '').toString();
      final namaAlat = (item['alat'] ?? item['nama_alat'] ?? '').toString();
      final jumlahPinjam =
          int.tryParse(
            (item['jumlah'] ?? item['jumlah_alat'] ?? 1).toString(),
          ) ??
          1;

      if (idAlat.isEmpty) {
        throw Exception('ID alat tidak ditemukan pada data peminjaman');
      }

      final alatSnapshot = await alatRef
          .child(idAlat)
          .get()
          .timeout(const Duration(seconds: 10));

      final pinjamSnapshot = await peminjamanRef.get().timeout(
        const Duration(seconds: 10),
      );

      if (!alatSnapshot.exists || alatSnapshot.value == null) {
        throw Exception('Data alat tidak ditemukan');
      }

      final dataAlat = Map<dynamic, dynamic>.from(alatSnapshot.value as Map);
      final totalUnit =
          int.tryParse((dataAlat['jumlah_unit'] ?? 0).toString()) ?? 0;

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
        throw Exception('Stok alat tidak mencukupi');
      }

      final now = DateTime.now();

      await peminjamanRef
          .child(id)
          .update({
            'status': 'dipinjam',
            'tanggal_diambil': _formatTanggal(now),
            'waktu_diambil': _formatWaktu(now),
            'alat': namaAlat,
          })
          .timeout(const Duration(seconds: 10));

      final nik = (item['nik'] ?? '').toString();

      await simpanNotifikasi(
        nik: nik,
        judul: 'Alat Sudah Dipinjam',
        pesan:
            'Peminjaman $namaAlat sebanyak $jumlahPinjam unit telah ditandai sedang dipinjam.',
        tipe: 'peminjaman_alat',
      );

      if (!mounted) return;
      _showSnackBar('Alat berhasil ditandai dipinjam', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menandai dipinjam: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> tandaiDikembalikan(String id, Map<dynamic, dynamic> item) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final now = DateTime.now();
      final tanggalKembali = (item['tanggal_kembali'] ?? '').toString();
      final hasil = _hitungKeterlambatan(tanggalKembali, now);
      final nik = (item['nik'] ?? '').toString();
      final alat = (item['alat'] ?? item['nama_alat'] ?? 'alat').toString();

      await peminjamanRef
          .child(id)
          .update({
            'status': 'dikembalikan',
            'tanggal_dikembalikan': _formatTanggal(now),
            'waktu_dikembalikan': _formatWaktu(now),
            'status_pengembalian': hasil.status,
            'jumlah_hari_terlambat': hasil.hariTerlambat,
          })
          .timeout(const Duration(seconds: 10));

      final pesanTerlambat =
          hasil.status == 'terlambat'
              ? ' Pengembalian terlambat ${hasil.hariTerlambat} hari.'
              : ' Pengembalian tepat waktu.';

      await simpanNotifikasi(
        nik: nik,
        judul: 'Peminjaman Selesai',
        pesan: 'Alat $alat telah ditandai sudah dikembalikan.$pesanTerlambat',
        tipe: 'peminjaman_alat',
      );

      if (!mounted) return;
      _showSnackBar('Alat berhasil ditandai dikembalikan', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menandai pengembalian: $e', Colors.red);
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
        final itemIdAlat = (item['id_alat'] ?? '').toString();
        final status = normalStatus(item);

        if (itemIdAlat == idAlat && status == 'dipinjam') {
          final jumlah =
              int.tryParse(
                (item['jumlah'] ?? item['jumlah_alat'] ?? 1).toString(),
              ) ??
              1;
          total += jumlah;
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
    final nama = (item['nama'] ?? '-').toString();

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isSetuju = status == 'disetujui';

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            isSetuju ? 'Setujui Peminjaman?' : 'Tolak Peminjaman?',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
          content: Text(
            isSetuju
                ? 'Pengajuan peminjaman dari $nama akan disetujui. Alat belum dianggap dipinjam sampai admin menekan tombol Tandai Dipinjam.'
                : 'Pengajuan peminjaman dari $nama akan ditolak.',
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

    if (hasil == true) {
      await updateStatus(id, status, item);
    }
  }

  Future<void> konfirmasiDipinjam({
    required String id,
    required Map<dynamic, dynamic> item,
  }) async {
    final nama = (item['nama'] ?? '-').toString();
    final alat = (item['alat'] ?? item['nama_alat'] ?? '-').toString();

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Tandai Dipinjam?',
            style: TextStyle(fontWeight: FontWeight.w800, color: textDark),
          ),
          content: Text(
            'Pastikan $nama sudah mengambil alat $alat. Setelah dikonfirmasi, status berubah menjadi Dipinjam.',
            style: const TextStyle(color: textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tandai Dipinjam'),
            ),
          ],
        );
      },
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
    final nama = (item['nama'] ?? '-').toString();
    final alat = (item['alat'] ?? item['nama_alat'] ?? '-').toString();

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Tandai Dikembalikan?',
            style: TextStyle(fontWeight: FontWeight.w800, color: textDark),
          ),
          content: Text(
            'Pastikan $nama sudah mengembalikan alat $alat. Sistem akan menyimpan tanggal pengembalian aktual dan menghitung keterlambatan.',
            style: const TextStyle(color: textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tandai Dikembalikan'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (hasil == true) {
      await tandaiDikembalikan(id, item);
    }
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
      final item = Map<dynamic, dynamic>.from(entry.value as Map);
      return normalStatus(item) == selectedFilter;
    }).toList();
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') return blueStatus;
    if (status == 'dipinjam') return purpleStatus;
    if (status == 'dikembalikan') return primaryGreen;
    if (status == 'ditolak') return Colors.red;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return const Color(0xffE3F2FD);
    if (status == 'dipinjam') return const Color(0xffF3E5F5);
    if (status == 'dikembalikan') return lightGreen;
    if (status == 'ditolak') return const Color(0xffFFEBEE);
    return const Color(0xffFFF3E0);
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'dipinjam') return 'Dipinjam';
    if (status == 'dikembalikan') return 'Dikembalikan';
    if (status == 'ditolak') return 'Ditolak';
    return 'Menunggu';
  }

  IconData iconAlat(String alat) {
    final namaAlat = alat.toLowerCase();

    if (namaAlat.contains('sprayer')) return Icons.water_drop_rounded;
    if (namaAlat.contains('cangkul')) return Icons.construction_rounded;
    if (namaAlat.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  String _formatTanggal(DateTime date) {
    return '${date.year}-${_duaDigit(date.month)}-${_duaDigit(date.day)}';
  }

  String _formatWaktu(DateTime date) {
    return '${_duaDigit(date.hour)}:${_duaDigit(date.minute)}';
  }

  String _duaDigit(int value) {
    return value.toString().padLeft(2, '0');
  }

  DateTime? _parseTanggal(String value) {
    try {
      final clean = value.trim();

      if (clean.contains('-')) {
        final parts = clean.split('-');

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
    final status = (item['status_pengembalian'] ?? '').toString();

    if (status == 'terlambat') {
      return 'Terlambat ${item['jumlah_hari_terlambat'] ?? 0} hari';
    }

    if (status == 'tepat_waktu') {
      return 'Tepat waktu';
    }

    return 'Belum diketahui';
  }

  Color warnaPengembalian(Map<dynamic, dynamic> item) {
    final status = (item['status_pengembalian'] ?? '').toString();

    if (status == 'terlambat') return Colors.red;
    if (status == 'tepat_waktu') return primaryGreen;

    return textGrey;
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
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

                final jumlahStatus = hitungStatus(semuaData);
                final totalMenunggu = jumlahStatus['menunggu'] ?? 0;
                final totalSemua = jumlahStatus['semua'] ?? 0;
                final totalDisetujui = jumlahStatus['disetujui'] ?? 0;
                final totalDipinjam = jumlahStatus['dipinjam'] ?? 0;
                final totalDikembalikan = jumlahStatus['dikembalikan'] ?? 0;
                final totalDitolak = jumlahStatus['ditolak'] ?? 0;
                final peminjamanList = filterData(semuaData);

                return Column(
                  children: [
                    _headerPage(totalMenunggu),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        children: [
                          _statusControlPanel(
                            totalSemua: totalSemua,
                            totalMenunggu: totalMenunggu,
                            totalDisetujui: totalDisetujui,
                            totalDipinjam: totalDipinjam,
                            totalDikembalikan: totalDikembalikan,
                            totalDitolak: totalDitolak,
                          ),
                          const SizedBox(height: 14),
                          if (semuaData.isEmpty)
                            _messageState(
                              icon: Icons.inventory_2_outlined,
                              title: 'Belum Ada Pengajuan',
                              message: 'Data peminjaman alat belum tersedia.',
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
    );
  }

  Widget _headerPage(int totalMenunggu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -36,
            child: Icon(
              Icons.agriculture_rounded,
              size: 135,
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
                      'Verifikasi Peminjaman',
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
                    ? 'Semua pengajuan peminjaman alat sudah diproses.'
                    : '$totalMenunggu pengajuan peminjaman alat masih menunggu verifikasi admin.',
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
    required int totalDipinjam,
    required int totalDikembalikan,
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
        color: blueStatus,
      ),
      _FilterItem(
        label: 'Dipinjam',
        value: 'dipinjam',
        total: totalDipinjam,
        icon: Icons.output_rounded,
        color: purpleStatus,
      ),
      _FilterItem(
        label: 'Kembali',
        value: 'dikembalikan',
        total: totalDikembalikan,
        icon: Icons.assignment_turned_in_rounded,
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
                      'Status Peminjaman',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aman
                          ? 'Tidak ada pengajuan alat yang perlu diverifikasi.'
                          : 'Ada $totalMenunggu pengajuan peminjaman alat yang belum diverifikasi.',
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


  Widget _peminjamanCard(String id, Map<dynamic, dynamic> item) {
    final nama = (item['nama'] ?? '-').toString();
    final nik = (item['nik'] ?? '-').toString();
    final alat = (item['alat'] ?? item['nama_alat'] ?? '-').toString();
    final idAlat = (item['id_alat'] ?? '-').toString();
    final jumlah = (item['jumlah'] ?? item['jumlah_alat'] ?? '1').toString();
    final tanggalPinjam = (item['tanggal_pinjam'] ?? '-').toString();
    final tanggalKembali = (item['tanggal_kembali'] ?? '-').toString();
    final catatan = (item['catatan'] ?? '-').toString();
    final status = normalStatus(item);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(alat: alat, nama: nama, status: status),
          const SizedBox(height: 16),
          _infoBox(
            children: [
              _infoRow(Icons.person_rounded, 'Nama', nama),
              _infoRow(Icons.badge_outlined, 'NIK', nik),
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
                  (item['tanggal_diambil'] ?? '-').toString(),
                ),
                _infoRow(
                  Icons.access_time_rounded,
                  'Waktu Diambil',
                  (item['waktu_diambil'] ?? '-').toString(),
                ),
              ],
              if (status == 'dikembalikan') ...[
                _infoRow(
                  Icons.event_repeat_rounded,
                  'Tanggal Kembali',
                  (item['tanggal_dikembalikan'] ?? '-').toString(),
                ),
                _infoRow(
                  Icons.access_time_rounded,
                  'Waktu Kembali',
                  (item['waktu_dikembalikan'] ?? '-').toString(),
                ),
                _infoRow(
                  Icons.timer_outlined,
                  'Ketepatan',
                  teksPengembalian(item),
                  valueColor: warnaPengembalian(item),
                ),
              ],
              _infoRow(Icons.notes_rounded, 'Catatan', catatan),
            ],
          ),
          if (status == 'menunggu') ...[
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            _actionButton(
              title: 'Tandai Dipinjam',
              icon: Icons.inventory_rounded,
              color: primaryGreen,
              onPressed: () {
                konfirmasiDipinjam(id: id, item: item);
              },
            ),
          ],
          if (status == 'dipinjam') ...[
            const SizedBox(height: 16),
            _actionButton(
              title: 'Tandai Dikembalikan',
              icon: Icons.assignment_turned_in_rounded,
              color: primaryGreen,
              onPressed: () {
                konfirmasiDikembalikan(id: id, item: item);
              },
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
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alat,
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
                nama,
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
          fontWeight: FontWeight.w800,
        ),
      ),
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
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: isProcessing ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
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

class _HasilKeterlambatan {
  final String status;
  final int hariTerlambat;

  const _HasilKeterlambatan({
    required this.status,
    required this.hariTerlambat,
  });
}
