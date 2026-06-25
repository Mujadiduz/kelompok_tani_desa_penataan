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
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menyetujui anggota.', redStatus);
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
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
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menolak anggota.', redStatus);
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> tampilkanKonfirmasi({
    required String id,
    required Map<String, dynamic> anggota,
    required String status,
  }) async {
    final nama = ambilNama(anggota);
    final isSetuju = status == 'disetujui';

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            isSetuju ? 'Setujui Anggota?' : 'Tolak Anggota?',
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            isSetuju
                ? 'Data $nama akan disetujui dan masuk sebagai anggota aktif.'
                : 'Pengajuan anggota dari $nama akan ditolak.',
            style: const TextStyle(
              color: textGrey,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSetuju ? primaryGreen : redStatus,
                foregroundColor: Colors.white,
                elevation: 0,
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
                  padding: const EdgeInsets.all(16),
                  color: darkGreen,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Foto KTP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(dialogContext),
                        borderRadius: BorderRadius.circular(99),
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
    return const Color(0xffFEF3C7);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            SafeArea(
              child: StreamBuilder<DatabaseEvent>(
                stream: calonAnggotaRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
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
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
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
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                      children: [
                        _header(totalMenunggu),
                        const SizedBox(height: 16),
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
                color: Colors.black.withValues(alpha: 0.22),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verifikasi Anggota',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalMenunggu == 0
                      ? 'Semua calon anggota sudah diproses.'
                      : '$totalMenunggu calon anggota menunggu verifikasi.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.2,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
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
      constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'cek',
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

  Widget _statusControlPanel({
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
        Icons.list_alt_rounded,
        blueStatus,
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
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: GridView.builder(
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
              setState(() => selectedFilter = item.value);
            },
            borderRadius: BorderRadius.circular(17),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: aktif ? item.color : item.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color:
                      aktif ? item.color : item.color.withValues(alpha: 0.18),
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
    );
  }

  Widget _anggotaCard(String id, Map<String, dynamic> anggota) {
    final status = normalStatus(anggota);
    final fotoKtpBase64 = _text(anggota['foto_ktp_base64']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(anggota, status),
          const SizedBox(height: 14),
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
                formatTanggal(anggota['tanggal_daftar']),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: BorderSide(color: primaryGreen.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              onPressed: () => lihatFotoKtp(fotoKtpBase64),
              icon: const Icon(Icons.credit_card_rounded),
              label: const Text(
                'Lihat Foto KTP',
                style: TextStyle(fontWeight: FontWeight.w900),
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
        CircleAvatar(
          radius: 25,
          backgroundColor: softGreen,
          child: const Icon(
            Icons.person_rounded,
            color: primaryGreen,
            size: 27,
          ),
        ),
        const SizedBox(width: 12),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ambilNik(anggota),
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 4),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _text(value),
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
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
        border: Border.all(color: warnaStatus(status).withValues(alpha: 0.12)),
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
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.40),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
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
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: const BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryGreen, size: 38),
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
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 16,
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
