import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class VerifikasiPupukPage extends StatefulWidget {
  const VerifikasiPupukPage({super.key});

  @override
  State<VerifikasiPupukPage> createState() => _VerifikasiPupukPageState();
}

class _VerifikasiPupukPageState extends State<VerifikasiPupukPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);

  String selectedFilter = 'semua';
  bool isProcessing = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference bantuanPupukRef;
  late final DatabaseReference stokPupukRef;
  late final DatabaseReference notifikasiRef;

  @override
  void initState() {
    super.initState();
    bantuanPupukRef = db.ref('bantuan_pupuk');
    stokPupukRef = db.ref('pupuk');
    notifikasiRef = db.ref('notifikasi');
  }

  double parseDouble(dynamic value) {
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String formatKg(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String normalStatus(Map<String, dynamic> item) {
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
    Map<String, dynamic> dataPupuk,
  ) async {
    try {
      await bantuanPupukRef
          .child(id)
          .update({
            'status': status,
            'tanggal_verifikasi': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));

      final nik = (dataPupuk['nik'] ?? '').toString();
      final jenisPupuk = (dataPupuk['jenis_pupuk'] ?? 'pupuk').toString();

      if (status == 'disetujui') {
        await simpanNotifikasi(
          nik: nik,
          judul: 'Bantuan Pupuk Disetujui',
          pesan:
              'Pengajuan bantuan pupuk $jenisPupuk Anda telah disetujui admin. Silakan menunggu arahan pengambilan.',
          tipe: 'bantuan_pupuk',
        );
      } else if (status == 'ditolak') {
        await simpanNotifikasi(
          nik: nik,
          judul: 'Bantuan Pupuk Ditolak',
          pesan:
              'Pengajuan bantuan pupuk $jenisPupuk Anda ditolak oleh admin. Silakan cek kembali data pengajuan.',
          tipe: 'bantuan_pupuk',
        );
      }

      if (!mounted) return;

      _showSnackBar(
        status == 'disetujui'
            ? 'Pengajuan pupuk berhasil disetujui'
            : 'Pengajuan pupuk berhasil ditolak',
        status == 'disetujui' ? primaryGreen : Colors.red,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengubah status: $e', Colors.red);
    }
  }

  Future<void> tandaiSudahDiambil(
    String idBantuan,
    Map<String, dynamic> dataPupuk,
  ) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final idPupuk = (dataPupuk['id_pupuk'] ?? '').toString();
      final jumlahDiajukan = parseDouble(dataPupuk['jumlah_pupuk']);

      if (idPupuk.isEmpty) {
        throw Exception('ID pupuk tidak ditemukan pada data pengajuan');
      }

      if (jumlahDiajukan <= 0) {
        throw Exception('Jumlah pupuk tidak valid');
      }

      final snapshot = await stokPupukRef
          .child(idPupuk)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Data pupuk tidak ditemukan');
      }

      final pupuk = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final stokSekarang = parseDouble(pupuk['stok']);

      if (stokSekarang < jumlahDiajukan) {
        throw Exception('Stok pupuk tidak mencukupi');
      }

      final stokBaru = stokSekarang - jumlahDiajukan;
      final now = DateTime.now();

      await stokPupukRef
          .child(idPupuk)
          .update({'stok': stokBaru})
          .timeout(const Duration(seconds: 10));

      await bantuanPupukRef
          .child(idBantuan)
          .update({
            'status': 'sudah_diambil',
            'jumlah_pupuk_diambil': jumlahDiajukan,
            'tanggal_pengambilan':
                '${now.year}-${_duaDigit(now.month)}-${_duaDigit(now.day)}',
            'waktu_pengambilan':
                '${_duaDigit(now.hour)}:${_duaDigit(now.minute)}',
            'tanggal_diambil': now.toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));

      final nik = (dataPupuk['nik'] ?? '').toString();
      final jenisPupuk = (dataPupuk['jenis_pupuk'] ?? 'pupuk').toString();

      await simpanNotifikasi(
        nik: nik,
        judul: 'Pupuk Sudah Diambil',
        pesan:
            'Bantuan pupuk $jenisPupuk sebanyak ${formatKg(jumlahDiajukan)} Kg telah ditandai sudah diambil.',
        tipe: 'bantuan_pupuk',
      );

      if (!mounted) return;
      _showSnackBar('Pupuk berhasil ditandai sudah diambil', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menandai pengambilan: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> tampilkanKonfirmasi({
    required String id,
    required String status,
    required Map<String, dynamic> pupuk,
  }) async {
    final nama = (pupuk['nama'] ?? '-').toString();
    final isSetuju = status == 'disetujui';

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            isSetuju ? 'Setujui Bantuan Pupuk?' : 'Tolak Bantuan Pupuk?',
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            isSetuju
                ? 'Pengajuan pupuk dari $nama akan disetujui. Stok pupuk belum dikurangi sampai anggota mengambil pupuk.'
                : 'Pengajuan pupuk dari $nama akan ditolak.',
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
      await updateStatus(id, status, pupuk);
    }
  }

  Future<void> tampilkanKonfirmasiPengambilan({
    required String id,
    required Map<String, dynamic> pupuk,
  }) async {
    final nama = (pupuk['nama'] ?? '-').toString();
    final jenis = (pupuk['jenis_pupuk'] ?? '-').toString();
    final jumlah = (pupuk['jumlah_pupuk'] ?? '-').toString();

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Tandai Sudah Diambil?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Pastikan $nama benar-benar sudah mengambil pupuk $jenis sebanyak $jumlah Kg. Setelah dikonfirmasi, stok pupuk akan dikurangi.',
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
              child: const Text('Sudah Diambil'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (hasil == true) {
      await tandaiSudahDiambil(id, pupuk);
    }
  }

  Map<String, int> hitungStatus(List<MapEntry<String, dynamic>> data) {
    int menunggu = 0;
    int disetujui = 0;
    int ditolak = 0;
    int sudahDiambil = 0;

    for (final entry in data) {
      if (entry.value is Map) {
        final item = Map<String, dynamic>.from(entry.value as Map);
        final status = normalStatus(item);

        if (status == 'menunggu') menunggu++;
        if (status == 'disetujui') disetujui++;
        if (status == 'ditolak') ditolak++;
        if (status == 'sudah_diambil') sudahDiambil++;
      }
    }

    return {
      'semua': data.length,
      'menunggu': menunggu,
      'disetujui': disetujui,
      'ditolak': ditolak,
      'sudah_diambil': sudahDiambil,
    };
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
    if (status == 'disetujui') return blueStatus;
    if (status == 'ditolak') return Colors.red;
    if (status == 'sudah_diambil') return primaryGreen;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return const Color(0xffE3F2FD);
    if (status == 'ditolak') return const Color(0xffFFEBEE);
    if (status == 'sudah_diambil') return lightGreen;
    return const Color(0xffFFF3E0);
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    if (status == 'sudah_diambil') return 'Sudah Diambil';
    return 'Menunggu';
  }

  Color warnaJatah(String statusJatah) {
    if (statusJatah == 'melebihi_jatah') return Colors.red;
    return primaryGreen;
  }

  String teksJatah(String statusJatah) {
    if (statusJatah == 'melebihi_jatah') return 'Melebihi Jatah';
    return 'Sesuai Jatah';
  }

  String ambilLahan(Map<String, dynamic> pupuk) {
    return (pupuk['luas_sawah'] ?? pupuk['jumlah_petak_sawah'] ?? '-')
        .toString();
  }

  String _duaDigit(int value) {
    return value.toString().padLeft(2, '0');
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
      body: Stack(
        children: [
          SafeArea(
            child: StreamBuilder<DatabaseEvent>(
              stream: bantuanPupukRef.onValue,
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

                final jumlahStatus = hitungStatus(semuaData);
                final totalMenunggu = jumlahStatus['menunggu'] ?? 0;
                final totalSemua = jumlahStatus['semua'] ?? 0;
                final totalDisetujui = jumlahStatus['disetujui'] ?? 0;
                final totalDitolak = jumlahStatus['ditolak'] ?? 0;
                final totalSudahDiambil = jumlahStatus['sudah_diambil'] ?? 0;
                final pupukList = filterData(semuaData);

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
                            totalSudahDiambil: totalSudahDiambil,
                          ),
                          const SizedBox(height: 14),
                          if (semuaData.isEmpty)
                            _messageState(
                              icon: Icons.inbox_outlined,
                              title: 'Belum Ada Pengajuan',
                              message: 'Belum ada pengajuan bantuan pupuk.',
                            )
                          else if (pupukList.isEmpty)
                            _messageState(
                              icon: Icons.search_off_rounded,
                              title: 'Data Tidak Ditemukan',
                              message:
                                  'Tidak ada pengajuan pupuk dengan status ini.',
                            )
                          else
                            ...pupukList.map((entry) {
                              final id = entry.key.toString();
                              final pupuk = Map<String, dynamic>.from(
                                entry.value as Map,
                              );

                              return _pupukCard(id, pupuk);
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
              Icons.grass_rounded,
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
                      'Verifikasi Bantuan Pupuk',
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
                    ? 'Semua pengajuan bantuan pupuk sudah diproses.'
                    : '$totalMenunggu pengajuan bantuan pupuk masih menunggu verifikasi admin.',
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
    required int totalSudahDiambil,
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
        label: 'Ditolak',
        value: 'ditolak',
        total: totalDitolak,
        icon: Icons.cancel_rounded,
        color: Colors.red,
      ),
      _FilterItem(
        label: 'Diambil',
        value: 'sudah_diambil',
        total: totalSudahDiambil,
        icon: Icons.inventory_rounded,
        color: primaryGreen,
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
                      'Status Pengajuan',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      aman
                          ? 'Tidak ada pengajuan pupuk yang perlu diverifikasi.'
                          : 'Ada $totalMenunggu pengajuan bantuan pupuk yang belum diverifikasi.',
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

  Widget _pupukCard(String id, Map<String, dynamic> pupuk) {
    final status = normalStatus(pupuk);
    final statusJatah = (pupuk['status_jatah'] ?? 'sesuai_jatah').toString();
    final idPupuk = (pupuk['id_pupuk'] ?? '').toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(pupuk, status),
          const SizedBox(height: 16),
          _infoBox(
            children: [
              _infoRow(Icons.badge_outlined, 'NIK', pupuk['nik'] ?? '-'),
              _infoRow(
                Icons.qr_code_rounded,
                'ID Pupuk',
                idPupuk.isEmpty ? 'Belum ada id_pupuk' : idPupuk,
              ),
              _infoRow(
                Icons.grass_rounded,
                'Jenis Pupuk',
                pupuk['jenis_pupuk'] ?? '-',
              ),
              _infoRow(
                Icons.landscape_rounded,
                'Luas Sawah',
                '${ambilLahan(pupuk)} Ha',
              ),
              _infoRow(
                Icons.scale_rounded,
                'Jatah Pupuk',
                '${pupuk['jatah_pupuk'] ?? '-'} Kg',
              ),
              _infoRow(
                Icons.inventory_2_rounded,
                'Diajukan',
                '${pupuk['jumlah_pupuk'] ?? '-'} Kg',
              ),
              _infoRow(Icons.notes_rounded, 'Catatan', pupuk['catatan'] ?? '-'),
              if (status == 'sudah_diambil') ...[
                _infoRow(
                  Icons.event_available_rounded,
                  'Tanggal Ambil',
                  pupuk['tanggal_pengambilan'] ?? '-',
                ),
                _infoRow(
                  Icons.access_time_rounded,
                  'Waktu Ambil',
                  pupuk['waktu_pengambilan'] ?? '-',
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(
                teksStatus(status),
                warnaStatus(status),
                backgroundStatus(status),
              ),
              _badge(
                teksJatah(statusJatah),
                warnaJatah(statusJatah),
                warnaJatah(statusJatah).withValues(alpha: 0.12),
              ),
            ],
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
                        status: 'ditolak',
                        pupuk: pupuk,
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
                        pupuk: pupuk,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
          if (status == 'disetujui') ...[
            const SizedBox(height: 14),
            _actionButton(
              title: 'Tandai Sudah Diambil',
              icon: Icons.inventory_rounded,
              color: primaryGreen,
              onPressed: () {
                tampilkanKonfirmasiPengambilan(id: id, pupuk: pupuk);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardTop(Map<String, dynamic> pupuk, String status) {
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
                (pupuk['nama'] ?? '-').toString(),
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
                (pupuk['nik'] ?? '-').toString(),
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _badge(
          teksStatus(status),
          warnaStatus(status),
          backgroundStatus(status),
        ),
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

  Widget _badge(String text, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
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
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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
