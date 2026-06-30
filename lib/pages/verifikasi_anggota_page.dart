import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class VerifikasiAnggotaPage extends StatefulWidget {
  const VerifikasiAnggotaPage({super.key});

  @override
  State<VerifikasiAnggotaPage> createState() => _VerifikasiAnggotaPageState();
}

class _VerifikasiAnggotaPageState extends State<VerifikasiAnggotaPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color redStatus = Color(0xffDC2626);
  static const Color blueStatus = Color(0xff2563EB);

  String selectedFilter = 'semua';
  bool isProcessing = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference calonAnggotaRef;
  late final DatabaseReference anggotaRef;

  @override
  void initState() {
    super.initState();
    calonAnggotaRef = db.ref('calon_anggota');
    anggotaRef = db.ref('anggota');
  }

  String _text(dynamic value) {
    if (value == null) return '-';
    final result = value.toString().trim();
    return result.isEmpty ? '-' : result;
  }

  String ambilNik(Map<String, dynamic> item) {
    return _text(item['nik'] ?? item['nik_anggota'] ?? item['nik_user']);
  }

  String ambilNama(Map<String, dynamic> item) {
    return _text(item['nama'] ?? item['nama_anggota'] ?? item['nama_user']);
  }

  String normalStatus(Map<String, dynamic> item) {
    final status = _text(item['status']).toLowerCase();
    return status == '-' ? 'menunggu' : status;
  }

  Future<void> setujuiAnggota(String id, Map<String, dynamic> anggota) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final nik = ambilNik(anggota);
      final nama = ambilNama(anggota);

      await anggotaRef.child(id).set({
        'nama': nama,
        'nik': nik,
        'telepon': _text(anggota['telepon']),
        'alamat': _text(anggota['alamat']),
        'jenis_kelamin': _text(anggota['jenis_kelamin']),
        'luas_sawah': _text(anggota['luas_sawah']),
        'foto_ktp_base64': _text(anggota['foto_ktp_base64']),
        'tanggal_daftar': _text(anggota['tanggal_daftar']),
        'tanggal_verifikasi': DateTime.now().toIso8601String(),
        'password': _text(anggota['password']),
        'status': 'aktif',
      });

      await calonAnggotaRef.child(id).remove();

      unawaited(NotificationHelper.anggotaDisetujui(nik: nik, nama: nama));

      if (!mounted) return;
      _showSnackBar('Anggota berhasil disetujui.', primaryGreen);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Gagal menyetujui anggota.', redStatus);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> tolakAnggota(String id, Map<String, dynamic> anggota) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final nik = ambilNik(anggota);
      final nama = ambilNama(anggota);

      await calonAnggotaRef.child(id).update({
        'status': 'ditolak',
        'tanggal_verifikasi': DateTime.now().toIso8601String(),
      });

      unawaited(NotificationHelper.anggotaDitolak(nik: nik, nama: nama));

      if (!mounted) return;
      _showSnackBar('Anggota berhasil ditolak.', redStatus);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Gagal menolak anggota.', redStatus);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> tampilkanKonfirmasi({
    required String id,
    required Map<String, dynamic> anggota,
    required String status,
  }) async {
    final nama = ambilNama(anggota);
    final isSetuju = status == 'disetujui';
    final color = isSetuju ? primaryGreen : redStatus;

    final hasil = await showDialog<bool>(
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
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.16)),
                  ),
                  child: Icon(
                    isSetuju ? Icons.verified_rounded : Icons.block_rounded,
                    color: color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  isSetuju ? 'Setujui Anggota?' : 'Tolak Anggota?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isSetuju
                      ? 'Data $nama akan dipindahkan menjadi anggota aktif.'
                      : 'Pengajuan anggota dari $nama akan ditolak.',
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
                          side: const BorderSide(color: borderColor),
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
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: Icon(
                          isSetuju ? Icons.check_rounded : Icons.close_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isSetuju ? 'Setujui' : 'Tolak',
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
      if (base64Text.isEmpty || base64Text == '-') return null;
      return base64Decode(base64Text);
    } catch (_) {
      return null;
    }
  }

  void lihatFotoKtp(String base64Text) {
    final fotoBytes = decodeFoto(base64Text);

    if (fotoBytes == null) {
      _showSnackBar('Foto KTP tidak tersedia.', redStatus);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  color: darkGreen,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.badge_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Foto KTP Calon Anggota',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(dialogContext),
                        borderRadius: BorderRadius.circular(99),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, color: Colors.white),
                        ),
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

  int countStatus(List<MapEntry<String, dynamic>> data, String status) {
    if (status == 'semua') return data.length;

    return data.where((entry) {
      if (entry.value is! Map) return false;
      final item = Map<String, dynamic>.from(entry.value as Map);
      return normalStatus(item) == status;
    }).length;
  }

  List<MapEntry<String, dynamic>> filterData(
    List<MapEntry<String, dynamic>> data,
  ) {
    if (selectedFilter == 'semua') return data;

    return data.where((entry) {
      if (entry.value is! Map) return false;
      final item = Map<String, dynamic>.from(entry.value as Map);
      return normalStatus(item) == selectedFilter;
    }).toList();
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui' || status == 'aktif') return primaryGreen;
    if (status == 'ditolak') return redStatus;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui' || status == 'aktif') return softGreen;
    if (status == 'ditolak') return const Color(0xffFEE2E2);
    return const Color(0xffFFF7ED);
  }

  String teksStatus(String status) {
    if (status == 'disetujui' || status == 'aktif') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    return 'Menunggu';
  }

  String formatTanggal(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty || text == '-') return '-';

    try {
      final date = DateTime.parse(text).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day-$month-$year';
    } catch (_) {
      return text;
    }
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
                stream: calonAnggotaRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        _header(0),
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
                        _header(0),
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

                  final totalSemua = countStatus(semuaData, 'semua');
                  final totalMenunggu = countStatus(semuaData, 'menunggu');
                  final totalDisetujui = countStatus(semuaData, 'disetujui');
                  final totalDitolak = countStatus(semuaData, 'ditolak');
                  final anggotaList = filterData(semuaData);

                  return RefreshIndicator(
                    color: primaryGreen,
                    onRefresh: () async => calonAnggotaRef.get(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                      children: [
                        _header(totalMenunggu),
                        const SizedBox(height: 12),
                        _filterPanel(
                          totalSemua: totalSemua,
                          totalMenunggu: totalMenunggu,
                          totalDisetujui: totalDisetujui,
                          totalDitolak: totalDitolak,
                        ),
                        const SizedBox(height: 12),
                        _infoBox(totalMenunggu),
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
                            message:
                                'Tidak ada calon anggota dengan status ini.',
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

  Widget _header(int totalMenunggu) {
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
          InkWell(
            onTap: isProcessing ? null : () => Navigator.pop(context),
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
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verifikasi Anggota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Kelola calon anggota baru',
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
        'Disetujui',
        'disetujui',
        totalDisetujui,
        Icons.verified_rounded,
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
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.78,
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

  Widget _infoBox(int totalMenunggu) {
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
                  ? 'Semua data calon anggota sudah diproses.'
                  : '$totalMenunggu calon anggota masih menunggu verifikasi.',
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

  Widget _anggotaCard(String id, Map<String, dynamic> anggota) {
    final status = normalStatus(anggota);
    final fotoKtpBase64 = _text(anggota['foto_ktp_base64']);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(anggota, status),
          const SizedBox(height: 12),
          _dataCalonBox(anggota),
          const SizedBox(height: 12),
          _ktpButton(fotoKtpBase64),
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
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.person_search_rounded,
            color: primaryGreen,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ambilNama(anggota),
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
                'NIK ${sensorNik(ambilNik(anggota))}',
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

  Widget _dataCalonBox(Map<String, dynamic> anggota) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 3),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _infoRow(Icons.phone_rounded, 'Telepon', anggota['telepon']),
          _infoRow(Icons.home_rounded, 'Alamat', anggota['alamat']),
          _infoRow(Icons.wc_rounded, 'Kelamin', anggota['jenis_kelamin']),
          _infoRow(
            Icons.landscape_rounded,
            'Luas Sawah',
            '${_text(anggota['luas_sawah'])} Ha',
            valueColor: primaryGreen,
          ),
          _infoRow(
            Icons.calendar_month_rounded,
            'Daftar',
            formatTanggal(anggota['tanggal_daftar']),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    dynamic value, {
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
              _text(value),
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

  Widget _ktpButton(String fotoKtpBase64) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: BorderSide(color: primaryGreen.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () => lihatFotoKtp(fotoKtpBase64),
        icon: const Icon(Icons.badge_rounded, size: 18),
        label: const Text(
          'Lihat Foto KTP',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
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

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
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
      border: Border.all(color: borderColor),
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
