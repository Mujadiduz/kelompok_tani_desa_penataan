import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';

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
  static const Color redStatus = Color(0xffDC2626);

  String selectedFilter = 'semua';
  bool isProcessing = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference bantuanPupukRef;
  late final DatabaseReference pupukRef;

  @override
  void initState() {
    super.initState();
    bantuanPupukRef = db.ref('bantuan_pupuk');
    pupukRef = db.ref('pupuk');
  }

  String _text(dynamic value) {
    if (value == null) return '-';
    final result = value.toString().trim();
    return result.isEmpty ? '-' : result;
  }

  double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String normalStatus(Map<dynamic, dynamic> item) {
    return _text(item['status']).toLowerCase() == '-'
        ? 'menunggu'
        : _text(item['status']).toLowerCase();
  }

  String ambilNik(Map<dynamic, dynamic> item) {
    return _text(
      item['nik'] ??
          item['nik_anggota'] ??
          item['nik_user'] ??
          item['nikUser'] ??
          item['no_nik'],
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

  String ambilJenisPupuk(Map<dynamic, dynamic> item) {
    return _text(
      item['jenis_pupuk'] ??
          item['nama_pupuk'] ??
          item['pupuk'] ??
          item['jenis'],
    );
  }

  double ambilJumlahKg(Map<dynamic, dynamic> item) {
    return _number(
      item['jumlah_kg'] ??
          item['jumlah'] ??
          item['jumlah_pupuk'] ??
          item['jatah_pupuk'] ??
          item['jatah_pupuk_kg'] ??
          item['total_pupuk'],
    );
  }

  String ambilIdPupuk(Map<dynamic, dynamic> item) {
    return _text(
      item['pupuk_id'] ??
          item['id_pupuk'] ??
          item['idPupuk'] ??
          item['key_pupuk'],
    );
  }

  String formatKg(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String formatTanggal(String value) {
    if (value.isEmpty || value == '-') return '-';

    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    if (status == 'sudah_diambil') return 'Sudah Diambil';
    return 'Menunggu';
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') return blueStatus;
    if (status == 'ditolak') return redStatus;
    if (status == 'sudah_diambil') return primaryGreen;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return const Color(0xffE3F2FD);
    if (status == 'ditolak') return const Color(0xffFEE2E2);
    if (status == 'sudah_diambil') return lightGreen;
    return const Color(0xffFFF3E0);
  }

  Map<String, int> hitungStatus(List<MapEntry<String, dynamic>> data) {
    int menunggu = 0;
    int disetujui = 0;
    int ditolak = 0;
    int sudahDiambil = 0;

    for (final entry in data) {
      if (entry.value is Map) {
        final item = Map<dynamic, dynamic>.from(entry.value as Map);
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
      await bantuanPupukRef.child(id).update({
        'status': status,
        'tanggal_verifikasi': DateTime.now().toIso8601String(),
      });

      final nik = ambilNik(item);
      final jenisPupuk = ambilJenisPupuk(item);
      debugPrint('NIK USER UNTUK NOTIF: $nik');
      debugPrint('JENIS PUPUK UNTUK NOTIF: $jenisPupuk');

      if (status == 'disetujui') {
        unawaited(
          NotificationHelper.pupukDisetujui(nik: nik, jenisPupuk: jenisPupuk),
        );
      } else if (status == 'ditolak') {
        unawaited(
          NotificationHelper.pupukDitolak(nik: nik, jenisPupuk: jenisPupuk),
        );
      }

      if (!mounted) return;

      _showSnackBar(
        status == 'disetujui'
            ? 'Pengajuan bantuan pupuk berhasil disetujui'
            : 'Pengajuan bantuan pupuk berhasil ditolak',
        status == 'disetujui' ? primaryGreen : redStatus,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengubah status: $e', redStatus);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> tandaiSudahDiambil(String id, Map<dynamic, dynamic> item) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final status = normalStatus(item);
      final pupukId = ambilIdPupuk(item);
      final jumlahKg = ambilJumlahKg(item);
      final nik = ambilNik(item);
      final jenisPupuk = ambilJenisPupuk(item);

      if (status != 'disetujui') {
        throw Exception('Hanya pengajuan disetujui yang bisa ditandai diambil');
      }

      if (jumlahKg <= 0) {
        throw Exception('Jumlah pupuk tidak valid');
      }

      if (pupukId == '-') {
        throw Exception('ID pupuk tidak ditemukan pada data pengajuan');
      }

      final snapshot = await pupukRef.child(pupukId).get();

      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Data pupuk tidak ditemukan');
      }

      final dataPupuk = Map<dynamic, dynamic>.from(snapshot.value as Map);

      final stokKey =
          dataPupuk.containsKey('stok')
              ? 'stok'
              : dataPupuk.containsKey('stok_kg')
              ? 'stok_kg'
              : dataPupuk.containsKey('jumlah_stok')
              ? 'jumlah_stok'
              : 'stok';

      final stokSaatIni = _number(dataPupuk[stokKey]);

      if (stokSaatIni < jumlahKg) {
        throw Exception(
          'Stok tidak cukup. Stok tersedia ${formatKg(stokSaatIni)} kg, kebutuhan ${formatKg(jumlahKg)} kg',
        );
      }

      final stokBaru = stokSaatIni - jumlahKg;

      await pupukRef.child(pupukId).update({
        stokKey: stokBaru,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await bantuanPupukRef.child(id).update({
        'status': 'sudah_diambil',
        'tanggal_diambil': DateTime.now().toIso8601String(),
      });

      unawaited(
        NotificationHelper.pupukSudahDiambil(
          nik: nik,
          jenisPupuk: jenisPupuk,
          jumlahKg: formatKg(jumlahKg),
        ),
      );

      if (!mounted) return;

      _showSnackBar(
        'Pupuk berhasil ditandai sudah diambil dan stok berkurang',
        primaryGreen,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal memproses: $e', redStatus);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> konfirmasiStatus({
    required String id,
    required String status,
    required Map<dynamic, dynamic> item,
  }) async {
    final nama = ambilNama(item);
    final isSetuju = status == 'disetujui';

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            isSetuju ? 'Setujui Pengajuan?' : 'Tolak Pengajuan?',
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            isSetuju
                ? 'Pengajuan bantuan pupuk dari $nama akan disetujui.'
                : 'Pengajuan bantuan pupuk dari $nama akan ditolak.',
            style: const TextStyle(color: textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSetuju ? primaryGreen : redStatus,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
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

  Future<void> konfirmasiSudahDiambil({
    required String id,
    required Map<dynamic, dynamic> item,
  }) async {
    final nama = ambilNama(item);
    final pupuk = ambilJenisPupuk(item);
    final jumlah = formatKg(ambilJumlahKg(item));

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Tandai Sudah Diambil?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Pastikan $nama sudah mengambil pupuk $pupuk sebanyak $jumlah kg. Stok pupuk akan otomatis berkurang.',
            style: const TextStyle(color: textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ya, Diambil'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (hasil == true) {
      await tandaiSudahDiambil(id, item);
    }
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
      body: Stack(
        children: [
          SafeArea(
            child: StreamBuilder<DatabaseEvent>(
              stream: bantuanPupukRef.onValue,
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

                final totalSemua = jumlahStatus['semua'] ?? 0;
                final totalMenunggu = jumlahStatus['menunggu'] ?? 0;
                final totalDisetujui = jumlahStatus['disetujui'] ?? 0;
                final totalDiambil = jumlahStatus['sudah_diambil'] ?? 0;
                final totalDitolak = jumlahStatus['ditolak'] ?? 0;

                final listPupuk = filterData(semuaData);

                return Column(
                  children: [
                    _headerPage(totalMenunggu),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        children: [
                          _statusPanel(
                            totalSemua: totalSemua,
                            totalMenunggu: totalMenunggu,
                            totalDisetujui: totalDisetujui,
                            totalDiambil: totalDiambil,
                            totalDitolak: totalDitolak,
                          ),
                          const SizedBox(height: 14),
                          if (semuaData.isEmpty)
                            _messageState(
                              icon: Icons.grass_rounded,
                              title: 'Belum Ada Pengajuan',
                              message:
                                  'Data bantuan pupuk anggota belum tersedia.',
                            )
                          else if (listPupuk.isEmpty)
                            _messageState(
                              icon: Icons.search_off_rounded,
                              title: 'Data Tidak Ditemukan',
                              message:
                                  'Tidak ada pengajuan bantuan pupuk dengan status ini.',
                            )
                          else
                            ...listPupuk.map((entry) {
                              final id = entry.key.toString();
                              final item = Map<dynamic, dynamic>.from(
                                entry.value as Map,
                              );

                              return _pupukCard(id, item);
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
        color: primaryGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
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
                  'Verifikasi Bantuan Pupuk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            totalMenunggu == 0
                ? 'Semua pengajuan bantuan pupuk sudah diproses.'
                : '$totalMenunggu pengajuan bantuan pupuk masih menunggu verifikasi.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPanel({
    required int totalSemua,
    required int totalMenunggu,
    required int totalDisetujui,
    required int totalDiambil,
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
        'Diambil',
        'sudah_diambil',
        totalDiambil,
        Icons.task_alt_rounded,
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
            'Status Pengajuan',
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
                onTap: () {
                  setState(() {
                    selectedFilter = item.value;
                  });
                },
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
                        size: 24,
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

  Widget _pupukCard(String id, Map<dynamic, dynamic> item) {
    final nama = ambilNama(item);
    final nik = ambilNik(item);
    final jenisPupuk = ambilJenisPupuk(item);
    final jumlahKg = ambilJumlahKg(item);
    final idPupuk = ambilIdPupuk(item);
    final tanggal = formatTanggal(
      _text(item['tanggal_pengajuan'] ?? item['created_at']),
    );
    final alasan = _text(
      item['alasan'] ?? item['keterangan'] ?? item['catatan'],
    );
    final status = normalStatus(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(title: jenisPupuk, subtitle: nama, status: status),
          const SizedBox(height: 14),
          _infoBox(
            children: [
              _infoRow(Icons.person_rounded, 'Nama', nama),
              _infoRow(Icons.badge_outlined, 'NIK', nik),
              _infoRow(Icons.grass_rounded, 'Jenis Pupuk', jenisPupuk),
              _infoRow(
                Icons.scale_rounded,
                'Jumlah',
                '${formatKg(jumlahKg)} Kg',
                valueColor: jumlahKg <= 0 ? redStatus : textDark,
              ),
              _infoRow(Icons.qr_code_rounded, 'ID Pupuk', idPupuk),
              _infoRow(Icons.calendar_today_rounded, 'Tanggal', tanggal),
              if (status == 'sudah_diambil')
                _infoRow(
                  Icons.task_alt_rounded,
                  'Diambil',
                  formatTanggal(_text(item['tanggal_diambil'])),
                ),
              if (alasan != '-')
                _infoRow(Icons.notes_rounded, 'Keterangan', alasan),
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
                      konfirmasiStatus(id: id, status: 'ditolak', item: item);
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
                      konfirmasiStatus(id: id, status: 'disetujui', item: item);
                    },
                  ),
                ),
              ],
            ),
          ],
          if (status == 'disetujui') ...[
            const SizedBox(height: 15),
            _actionButton(
              title: 'Tandai Sudah Diambil',
              icon: Icons.task_alt_rounded,
              color: primaryGreen,
              onPressed: () {
                konfirmasiSudahDiambil(id: id, item: item);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardTop({
    required String title,
    required String subtitle,
    required String status,
  }) {
    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.grass_rounded, color: primaryGreen, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title == '-' ? 'Bantuan Pupuk' : title,
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
                subtitle,
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
            width: 104,
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
      onTap: () => Navigator.pop(context),
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
              decoration: const BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
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
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 10,
          offset: const Offset(0, 5),
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
