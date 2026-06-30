import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class VerifikasiPupukPage extends StatefulWidget {
  const VerifikasiPupukPage({super.key});

  @override
  State<VerifikasiPupukPage> createState() => _VerifikasiPupukPageState();
}

class _VerifikasiPupukPageState extends State<VerifikasiPupukPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);
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
    final status = _text(item['status']).toLowerCase();
    return status == '-' ? 'menunggu' : status;
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

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    if (status == 'sudah_diambil') return 'Diambil';
    return 'Menunggu';
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') return blueStatus;
    if (status == 'ditolak') return redStatus;
    if (status == 'sudah_diambil') return primaryGreen;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return const Color(0xffEFF6FF);
    if (status == 'ditolak') return const Color(0xffFEE2E2);
    if (status == 'sudah_diambil') return softGreen;
    return const Color(0xffFFF7ED);
  }

  IconData iconPupuk(String pupuk) {
    final nama = pupuk.toLowerCase();

    if (nama.contains('urea')) return Icons.water_drop_outlined;
    if (nama.contains('npk')) return Icons.grain_rounded;
    if (nama.contains('organik')) return Icons.energy_savings_leaf_rounded;
    if (nama.contains('kompos')) return Icons.local_florist_rounded;
    if (nama.contains('za')) return Icons.science_rounded;

    return Icons.spa_rounded;
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
      if (entry.value is! Map) return false;
      final item = Map<dynamic, dynamic>.from(entry.value as Map);
      return normalStatus(item) == selectedFilter;
    }).toList();
  }

  Future<void> refreshData() async {
    await bantuanPupukRef.get();
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

      await pupukRef.child(pupukId).update({
        stokKey: stokSaatIni - jumlahKg,
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

    final hasil = await _showConfirmDialog(
      icon: isSetuju ? Icons.verified_rounded : Icons.block_rounded,
      iconColor: isSetuju ? primaryGreen : redStatus,
      title: isSetuju ? 'Setujui Pengajuan?' : 'Tolak Pengajuan?',
      message:
          isSetuju
              ? 'Pengajuan bantuan pupuk dari $nama akan disetujui.'
              : 'Pengajuan bantuan pupuk dari $nama akan ditolak.',
      confirmText: isSetuju ? 'Setujui' : 'Tolak',
      confirmColor: isSetuju ? primaryGreen : redStatus,
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

    final hasil = await _showConfirmDialog(
      icon: Icons.task_alt_rounded,
      iconColor: primaryGreen,
      title: 'Tandai Sudah Diambil?',
      message:
          'Pastikan $nama sudah mengambil pupuk $pupuk sebanyak $jumlah kg. Stok pupuk akan otomatis berkurang.',
      confirmText: 'Ya, Diambil',
      confirmColor: primaryGreen,
    );

    if (!mounted) return;

    if (hasil == true) {
      await tandaiSudahDiambil(id, item);
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(icon, color: iconColor, size: 32),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12.7,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 21),
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
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
        child: Stack(
          children: [
            SafeArea(
              child: StreamBuilder<DatabaseEvent>(
                stream: bantuanPupukRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        _headerPage(0),
                        const SizedBox(height: 16),
                        _messageState(
                          icon: Icons.error_outline_rounded,
                          title: 'Terjadi Kesalahan',
                          message: snapshot.error.toString(),
                        ),
                      ],
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        _headerPage(0),
                        const SizedBox(height: 120),
                        const Center(
                          child: CircularProgressIndicator(color: primaryGreen),
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
                  final listPupuk = filterData(semuaData);

                  return RefreshIndicator(
                    color: primaryGreen,
                    backgroundColor: Colors.white,
                    onRefresh: refreshData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        _headerPage(jumlahStatus['menunggu'] ?? 0),
                        const SizedBox(height: 12),
                        _filterPanel(
                          totalSemua: jumlahStatus['semua'] ?? 0,
                          totalMenunggu: jumlahStatus['menunggu'] ?? 0,
                          totalDisetujui: jumlahStatus['disetujui'] ?? 0,
                          totalDiambil: jumlahStatus['sudah_diambil'] ?? 0,
                          totalDitolak: jumlahStatus['ditolak'] ?? 0,
                        ),
                        const SizedBox(height: 12),
                        _infoStatus(jumlahStatus['menunggu'] ?? 0),
                        const SizedBox(height: 14),
                        _sectionTitle(
                          title: 'Daftar Pengajuan',
                          subtitle:
                              selectedFilter == 'semua'
                                  ? 'Semua data bantuan pupuk anggota'
                                  : 'Filter: ${teksStatus(selectedFilter)}',
                        ),
                        const SizedBox(height: 12),
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
                  );
                },
              ),
            ),
            if (isProcessing)
              Container(
                color: Colors.black.withValues(alpha: 0.18),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verifikasi Bantuan Pupuk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola pengajuan pupuk anggota',
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _headerCounter(totalMenunggu),
        ],
      ),
    );
  }

  Widget _headerCounter(int total) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            total > 99 ? '99+' : total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'baru',
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

  Widget _filterPanel({
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
        Icons.dashboard_customize_rounded,
        blueStatus,
      ),
      _FilterItem(
        'Menunggu',
        'menunggu',
        totalMenunggu,
        Icons.pending_actions_rounded,
        orangeStatus,
      ),
      _FilterItem(
        'Setuju',
        'disetujui',
        totalDisetujui,
        Icons.verified_rounded,
        primaryGreen,
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
        Icons.block_rounded,
        redStatus,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _cardDecoration(radius: 18),
      child: GridView.builder(
        itemCount: filters.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.98,
        ),
        itemBuilder: (context, index) {
          final item = filters[index];
          final aktif = selectedFilter == item.value;

          return InkWell(
            onTap: () => setState(() => selectedFilter = item.value),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: aktif ? item.color : item.color.withValues(alpha: 0.075),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color:
                      aktif ? item.color : item.color.withValues(alpha: 0.13),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: aktif ? Colors.white : item.color,
                      size: 20,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.total > 99 ? '99+' : item.total.toString(),
                      style: TextStyle(
                        color: aktif ? Colors.white : item.color,
                        fontSize: 17,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: aktif ? Colors.white : textDark,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoStatus(int totalMenunggu) {
    final clear = totalMenunggu == 0;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: (clear ? primaryGreen : orangeStatus).withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (clear ? primaryGreen : orangeStatus).withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            clear ? Icons.task_alt_rounded : Icons.info_outline_rounded,
            color: clear ? primaryGreen : orangeStatus,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              clear
                  ? 'Semua pengajuan bantuan pupuk sudah diproses.'
                  : '$totalMenunggu pengajuan bantuan pupuk masih menunggu verifikasi.',
              style: TextStyle(
                color: clear ? primaryGreen : orangeStatus,
                fontSize: 12.2,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 32,
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
                  fontSize: 15.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(title: jenisPupuk, subtitle: nama, nik: nik, status: status),
          const SizedBox(height: 12),
          _dataBox(
            children: [
              _infoRow(Icons.badge_outlined, 'NIK', sensorNik(nik)),
              _infoRow(Icons.grass_rounded, 'Pupuk', jenisPupuk),
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
                _infoRow(Icons.notes_rounded, 'Catatan', alasan),
            ],
          ),
          if (status == 'menunggu') ...[
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
    required String nik,
    required String status,
  }) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(iconPupuk(title), color: primaryGreen, size: 25),
        ),
        const SizedBox(width: 11),
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
                  fontSize: 15.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$subtitle • ${sensorNik(nik)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _statusBadge(status),
      ],
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: warnaStatus(status).withValues(alpha: 0.15)),
      ),
      child: Text(
        teksStatus(status),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: warnaStatus(status),
          fontSize: 9.8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _dataBox({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 3),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(15),
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
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? textDark,
                fontSize: 11.8,
                height: 1.35,
                fontWeight: FontWeight.w900,
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
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.40),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: isProcessing ? null : onPressed,
        icon: Icon(icon, size: 18),
        label: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
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
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 15.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.4,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.032),
          blurRadius: 12,
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
