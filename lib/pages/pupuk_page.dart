import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class PupukPage extends StatefulWidget {
  final String nama;
  final String nik;

  const PupukPage({
    super.key,
    required this.nama,
    required this.nik,
  });

  @override
  State<PupukPage> createState() => _PupukPageState();
}

class _PupukPageState extends State<PupukPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color teal = Color(0xff167A6B);
  static const Color deepTeal = Color(0xff0E5F57);

  static const Color amber = Color(0xffD98212);
  static const Color blue = Color(0xff326FA3);
  static const Color red = Color(0xffC83B3B);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color softBlue = Color(0xffEAF3FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);

  static const Color pageBackground = Color(0xffF2F7F5);
  static const Color cardBorder = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference rootRef;
  late final DatabaseReference bantuanPupukRef;
  late final DatabaseReference notifikasiAdminRef;

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    rootRef = db.ref();
    bantuanPupukRef = db.ref('bantuan_pupuk');
    notifikasiAdminRef = db.ref('notifikasi_admin');
  }

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value is! Map) {
      return <dynamic, dynamic>{};
    }

    return Map<dynamic, dynamic>.from(value);
  }

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    final result = value?.toString().trim() ?? '';

    if (result.isEmpty ||
        result == '-' ||
        result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  String _normalizeNik(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          (value ?? '').toString().replaceAll(',', '.'),
        ) ??
        0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }

    if (value is num) {
      final rawNumber = value.toInt();
      final milliseconds = rawNumber.toString().length >= 13
          ? rawNumber
          : rawNumber * 1000;

      try {
        final parsed = DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
        ).toLocal();

        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        return null;
      }
    }

    final raw = value.toString().trim();

    if (raw.isEmpty || raw == '-') {
      return null;
    }

    final dateOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);

    if (dateOnly != null) {
      final year = int.tryParse(dateOnly.group(1)!);
      final month = int.tryParse(dateOnly.group(2)!);
      final day = int.tryParse(dateOnly.group(3)!);

      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(raw);

    if (slash != null) {
      final day = int.tryParse(slash.group(1)!);
      final month = int.tryParse(slash.group(2)!);
      final year = int.tryParse(slash.group(3)!);

      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return null;
    }

    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _monthName(int month) {
    const months = <String>[
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);

    if (date == null) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthName(date.month)} ${date.year}';
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return 'Belum ditentukan';
    }

    if (start != null && end == null) {
      return 'Mulai ${_formatDate(start)}';
    }

    if (start == null && end != null) {
      return 'Sampai ${_formatDate(end)}';
    }

    return '${_formatDate(start)} – ${_formatDate(end)}';
  }

  String _formatKg(double value) {
    if (value <= 0) {
      return 'Menunggu penetapan admin';
    }

    if (value % 1 == 0) {
      return '${value.toInt()} Kg';
    }

    return '${value.toStringAsFixed(1)} Kg';
  }

  String _sensorNik(String value) {
    final cleanNik = _normalizeNik(value);

    if (cleanNik.length <= 4) {
      return value;
    }

    return '•••• •••• •••• '
        '${cleanNik.substring(cleanNik.length - 4)}';
  }

  Map<dynamic, dynamic>? _findMember(dynamic value) {
    final targetNik = _normalizeNik(widget.nik);

    if (targetNik.isEmpty) {
      return null;
    }

    for (final entry in _asMap(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final member = Map<dynamic, dynamic>.from(entry.value as Map);
      final memberNik = _normalizeNik(member['nik'] ?? entry.key);

      if (memberNik == targetNik) {
        return member;
      }
    }

    return null;
  }

  bool _isActiveMember(Map<dynamic, dynamic>? member) {
    if (member == null) {
      return false;
    }

    final status = _text(
      member['status'],
      fallback: 'aktif',
    ).toLowerCase();

    const inactiveStatuses = <String>{
      'nonaktif',
      'tidak aktif',
      'ditolak',
      'diblokir',
      'keluar',
    };

    return !inactiveStatuses.contains(status);
  }

  String _memberName(Map<dynamic, dynamic>? member) {
    return _text(
      member?['nama'],
      fallback: widget.nama,
    );
  }

  String _memberAddress(Map<dynamic, dynamic>? member) {
    if (member == null) {
      return '-';
    }

    return _text(
      member['alamat'] ?? member['alamat_lengkap'] ?? member['desa'],
    );
  }

  String _memberLandArea(Map<dynamic, dynamic>? member) {
    if (member == null) {
      return '-';
    }

    final description = _text(member['keterangan_luas_lahan']);

    if (description != '-') {
      return description;
    }

    final direct = _text(member['luas_lahan'] ?? member['luas_sawah']);

    if (direct != '-') {
      final lower = direct.toLowerCase();

      if (lower.contains('ha') ||
          lower.contains('m²') ||
          lower.contains('m2') ||
          lower.contains('meter')) {
        return direct;
      }

      return '$direct ${_text(member['satuan_lahan'], fallback: 'Ha')}';
    }

    final meter = _text(member['luas_meter_m2']);

    if (meter != '-') {
      return '$meter m²';
    }

    return '-';
  }

  String _normalizeProgramStatus(dynamic value) {
    final status = _text(
      value,
      fallback: 'ditutup',
    ).toLowerCase().replaceAll('-', '_');

    if (<String>{'buka', 'dibuka', 'open', 'tersedia'}.contains(status)) {
      return 'aktif';
    }

    if (<String>{'tutup', 'closed', 'nonaktif'}.contains(status)) {
      return 'ditutup';
    }

    if (status == 'archived') {
      return 'arsip';
    }

    return status;
  }

  List<_UserProgram> _readPrograms(dynamic value) {
    final programs = <_UserProgram>[];

    for (final entry in _asMap(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final raw = Map<dynamic, dynamic>.from(entry.value as Map);
      final status = _normalizeProgramStatus(raw['status']);

      if (<String>{'arsip', 'dihapus', 'deleted'}.contains(status)) {
        continue;
      }

      programs.add(
        _UserProgram(
          id: entry.key.toString(),
          name: _text(
            raw['nama_program'] ?? raw['judul_program'] ?? raw['nama_bantuan'],
            fallback: 'Program Bantuan Pupuk',
          ),
          period: _text(
            raw['periode'] ?? raw['periode_bantuan'] ?? raw['bulan_program'],
            fallback: 'Periode belum ditentukan',
          ),
          fertilizer: _text(
            raw['jenis_pupuk'] ?? raw['nama_pupuk'] ?? raw['pupuk'],
            fallback: 'Pupuk bantuan',
          ),
          packageKg: _number(
            raw['jumlah_paket_kg'] ??
                raw['jumlah_kg'] ??
                raw['jumlah_pupuk'] ??
                raw['jumlah'],
          ),
          startDate: _parseDate(
            raw['tanggal_mulai'] ??
                raw['mulai_pengajuan'] ??
                raw['tanggal_buka'],
          ),
          endDate: _parseDate(
            raw['tanggal_selesai'] ??
                raw['batas_pengajuan'] ??
                raw['tanggal_tutup'],
          ),
          location: _text(
            raw['lokasi_pengambilan'] ?? raw['tempat_pengambilan'],
            fallback: 'Akan ditetapkan admin',
          ),
          description: _text(
            raw['keterangan'] ?? raw['deskripsi'] ?? raw['syarat'],
            fallback: 'Khusus anggota kelompok tani yang terdaftar.',
          ),
          status: status,
          raw: raw,
        ),
      );
    }

    programs.sort((a, b) {
      final aOpen = _isProgramOpen(a);
      final bOpen = _isProgramOpen(b);

      if (aOpen != bOpen) {
        return bOpen ? 1 : -1;
      }

      final dateA = a.startDate ?? DateTime(1970);
      final dateB = b.startDate ?? DateTime(1970);

      return dateB.compareTo(dateA);
    });

    return programs;
  }

  bool _isProgramOpen(_UserProgram program) {
    if (_normalizeProgramStatus(program.status) != 'aktif') {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (program.startDate != null && today.isBefore(program.startDate!)) {
      return false;
    }

    if (program.endDate != null && today.isAfter(program.endDate!)) {
      return false;
    }

    return true;
  }

  String _programAvailabilityText(_UserProgram program) {
    final status = _normalizeProgramStatus(program.status);

    if (status != 'aktif') {
      return 'Program sedang ditutup oleh admin.';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (program.startDate != null && today.isBefore(program.startDate!)) {
      return 'Program mulai berlaku pada ${_formatDate(program.startDate)}.';
    }

    if (program.endDate != null && today.isAfter(program.endDate!)) {
      return 'Masa pengajuan berakhir pada ${_formatDate(program.endDate)}.';
    }

    return 'Program sedang dibuka dan dapat diajukan.';
  }

  List<Map<String, dynamic>> _readUserApplications(dynamic value) {
    final applications = <Map<String, dynamic>>[];
    final targetNik = _normalizeNik(widget.nik);

    for (final entry in _asMap(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(entry.value as Map);
      final applicationNik = _normalizeNik(
        item['nik'] ?? item['nik_anggota'] ?? item['nik_user'],
      );

      if (applicationNik != targetNik) {
        continue;
      }

      item['id_pengajuan'] = entry.key.toString();
      applications.add(item);
    }

    return applications;
  }

  Map<String, dynamic>? _findExistingApplication(
    _UserProgram program,
    List<Map<String, dynamic>> applications,
  ) {
    for (final item in applications) {
      final programId = _text(
        item['id_program'] ?? item['program_id'],
        fallback: '',
      );

      if (programId.isNotEmpty && programId == program.id) {
        return item;
      }

      final name = _text(item['nama_program'], fallback: '');
      final period = _text(item['periode'], fallback: '');

      if (name.toLowerCase() == program.name.toLowerCase() &&
          period.toLowerCase() == program.period.toLowerCase()) {
        return item;
      }
    }

    return null;
  }

  bool _requiresRecipientList(_UserProgram program) {
    bool enabled(dynamic value) {
      return value == true || value.toString().toLowerCase() == 'true';
    }

    return enabled(program.raw['khusus_penerima_terdaftar']) ||
        enabled(program.raw['gunakan_daftar_penerima']) ||
        enabled(program.raw['khusus_daftar_penerima']);
  }

  bool _isRegisteredRecipient(_UserProgram program) {
    if (!_requiresRecipientList(program)) {
      return true;
    }

    final recipients =
        program.raw['daftar_penerima'] ?? program.raw['penerima'];
    final targetNik = _normalizeNik(widget.nik);

    if (recipients is Map) {
      for (final entry in recipients.entries) {
        if (_normalizeNik(entry.key) == targetNik) {
          return true;
        }

        if (entry.value is Map) {
          final item = Map<dynamic, dynamic>.from(entry.value as Map);

          if (_normalizeNik(item['nik'] ?? item['nik_anggota']) == targetNik) {
            return true;
          }
        } else if (_normalizeNik(entry.value) == targetNik) {
          return true;
        }
      }
    }

    if (recipients is List) {
      for (final value in recipients) {
        if (value is Map) {
          final item = Map<dynamic, dynamic>.from(value);

          if (_normalizeNik(item['nik'] ?? item['nik_anggota']) == targetNik) {
            return true;
          }
        } else if (_normalizeNik(value) == targetNik) {
          return true;
        }
      }
    }

    return false;
  }

  String _normalizeApplicationStatus(dynamic value) {
    final status = (value ?? 'menunggu_verifikasi')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');

    const pendingStatuses = <String>{
      '',
      'menunggu',
      'pending',
      'diajukan',
      'pengajuan',
      'proses',
      'diproses',
      'sedang_diproses',
      'menunggu_verifikasi',
      'belum_diproses',
    };

    if (pendingStatuses.contains(status)) {
      return 'menunggu_verifikasi';
    }

    if (<String>{'approved', 'siap_diambil', 'siap diambil'}
        .contains(status)) {
      return 'disetujui';
    }

    if (status == 'rejected') {
      return 'ditolak';
    }

    if (<String>{'diambil', 'selesai', 'completed'}.contains(status)) {
      return 'sudah_diambil';
    }

    return status;
  }

  String _applicationStatusText(dynamic value) {
    switch (_normalizeApplicationStatus(value)) {
      case 'disetujui':
        return 'Siap Diambil';
      case 'ditolak':
        return 'Ditolak';
      case 'sudah_diambil':
        return 'Sudah Diambil';
      default:
        return 'Menunggu Verifikasi';
    }
  }

  String _applicationStatusDescription(dynamic value) {
    switch (_normalizeApplicationStatus(value)) {
      case 'disetujui':
        return 'Bantuan disetujui. Periksa jadwal dan lokasi pengambilan.';
      case 'ditolak':
        return 'Pengajuan belum dapat disetujui oleh admin.';
      case 'sudah_diambil':
        return 'Bantuan telah diterima dan tercatat di sistem.';
      default:
        return 'Pengajuan sedang diperiksa oleh admin kelompok tani.';
    }
  }

  Color _applicationStatusColor(dynamic value) {
    switch (_normalizeApplicationStatus(value)) {
      case 'disetujui':
        return blue;
      case 'ditolak':
        return red;
      case 'sudah_diambil':
        return primaryGreen;
      default:
        return amber;
    }
  }

  Color _applicationStatusBackground(dynamic value) {
    switch (_normalizeApplicationStatus(value)) {
      case 'disetujui':
        return softBlue;
      case 'ditolak':
        return softRed;
      case 'sudah_diambil':
        return softGreen;
      default:
        return softAmber;
    }
  }

  IconData _applicationStatusIcon(dynamic value) {
    switch (_normalizeApplicationStatus(value)) {
      case 'disetujui':
        return Icons.inventory_outlined;
      case 'ditolak':
        return Icons.cancel_outlined;
      case 'sudah_diambil':
        return Icons.task_alt_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  IconData _fertilizerIcon(String value) {
    final name = value.toLowerCase();

    if (name.contains('urea')) {
      return Icons.water_drop_outlined;
    }

    if (name.contains('npk')) {
      return Icons.grain_rounded;
    }

    if (name.contains('organik') || name.contains('kompos')) {
      return Icons.energy_savings_leaf_rounded;
    }

    if (name.contains('za')) {
      return Icons.science_outlined;
    }

    return Icons.inventory_2_outlined;
  }

  Future<void> _refreshData() async {
    await rootRef.get();
  }

  Future<void> _openApplicationSheet({
    required _UserProgram program,
    required Map<dynamic, dynamic>? member,
  }) async {
    FocusScope.of(context).unfocus();

    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: darkGreen.withValues(alpha: 0.48),
      builder: (sheetContext) {
        return _ApplicationFormSheet(
          program: program,
          memberName: _memberName(member),
          memberNik: _sensorNik(widget.nik),
          memberLandArea: _memberLandArea(member),
          memberAddress: _memberAddress(member),
          formatKg: _formatKg,
          formatRange: _formatRange,
          fertilizerIcon: _fertilizerIcon,
        );
      },
    );

    if (note == null || !mounted) {
      return;
    }

    // Hindari membuka dialog ketika animasi penutupan bottom sheet belum selesai.
    await Future<void>.delayed(const Duration(milliseconds: 380));

    if (!mounted) {
      return;
    }

    final confirmed = await _showConfirmDialog(program.name);

    if (confirmed != true || !mounted) {
      return;
    }

    await _submitApplication(
      program: program,
      member: member,
      note: note,
    );
  }

  Future<bool?> _showConfirmDialog(String programName) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: softGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: primaryGreen,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Kirim Pengajuan?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Pengajuan $programName akan dikirim kepada admin untuk '
                    'diverifikasi.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 21),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 285;

                      final cancelButton = OutlinedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: cardBorder),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      );

                      final sendButton = ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Kirim',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      );

                      if (stacked) {
                        return Column(
                          children: <Widget>[
                            cancelButton,
                            const SizedBox(height: 9),
                            sendButton,
                          ],
                        );
                      }

                      return Row(
                        children: <Widget>[
                          Expanded(child: cancelButton),
                          const SizedBox(width: 10),
                          Expanded(child: sendButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitApplication({
    required _UserProgram program,
    required Map<dynamic, dynamic>? member,
    required String note,
  }) async {
    if (isSubmitting) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final currentSnapshot = await bantuanPupukRef.get();
      final currentApplications = _readUserApplications(currentSnapshot.value);
      final duplicate = _findExistingApplication(program, currentApplications);

      if (duplicate != null) {
        throw Exception(
          'Anda sudah mengajukan bantuan pada program ini.',
        );
      }

      if (!_isProgramOpen(program)) {
        throw Exception(
          'Program tidak sedang dibuka. Muat ulang halaman dan periksa '
          'tanggal program.',
        );
      }

      if (!_isActiveMember(member)) {
        throw Exception(
          'NIK Anda belum tercatat sebagai anggota aktif.',
        );
      }

      if (!_isRegisteredRecipient(program)) {
        throw Exception(
          'NIK Anda tidak termasuk dalam daftar penerima program.',
        );
      }

      final applicantName = _memberName(member);
      final now = DateTime.now().toIso8601String();
      final reference = bantuanPupukRef.push();
      final applicationId = reference.key ?? '';

      await reference.set(<String, dynamic>{
        'id_program': program.id,
        'program_id': program.id,
        'nama_program': program.name,
        'periode': program.period,
        'nama': applicantName,
        'nik': _normalizeNik(widget.nik),
        'jenis_pupuk': program.fertilizer,

        // Field kompatibilitas untuk halaman lama dan riwayat.
        'id_pupuk': program.id,
        'jumlah_paket_kg': program.packageKg,
        'jumlah_diajukan': program.packageKg,
        'jumlah_pupuk': program.packageKg,
        'jumlah_kg': program.packageKg,

        // Jumlah final ditetapkan admin saat verifikasi.
        'jumlah_disetujui': 0,
        'jumlah_final_kg': 0,

        'luas_lahan_snapshot': _memberLandArea(member),
        'alamat_snapshot': _memberAddress(member),

        'catatan_user': note,
        'catatan': note,
        'keterangan': note,
        'catatan_admin': '',

        'status': 'menunggu_verifikasi',
        'status_penyaluran': 'menunggu_verifikasi',

        'tanggal_pengajuan': now,
        'tanggal_disetujui': '',
        'tanggal_verifikasi': '',
        'tanggal_pengambilan': '',
        'tanggal_diambil': '',

        'lokasi_pengambilan':
            program.location == 'Akan ditetapkan admin' ? '' : program.location,
      }).timeout(const Duration(seconds: 15));

      try {
        await notifikasiAdminRef.push().set(<String, dynamic>{
          'judul': 'Pengajuan Bantuan Pupuk Baru',
          'pesan': '$applicantName mengajukan ${program.name} periode '
              '${program.period}.',
          'tipe': 'bantuan_pupuk',
          'id_pengajuan': applicationId,
          'id_program': program.id,
          'nik': _normalizeNik(widget.nik),
          'status': 'belum_dibaca',
          'dibaca': false,
          'tanggal': now,
        }).timeout(const Duration(seconds: 10));
      } catch (_) {
        // Pengajuan tetap berhasil walaupun notifikasi admin gagal dibuat.
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Pengajuan bantuan berhasil dikirim.',
        primaryGreen,
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          error.toString().replaceAll('Exception: ', ''),
          red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 350 ? 12.0 : 16.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const _UserPupukBackground(),
              SafeArea(
                child: StreamBuilder<DatabaseEvent>(
                  stream: rootRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _statePage(
                        horizontalPadding,
                        loading: true,
                      );
                    }

                    if (snapshot.hasError) {
                      return _statePage(horizontalPadding);
                    }

                    final root = _asMap(snapshot.data?.snapshot.value);
                    final member = _findMember(root['anggota']);
                    final memberActive = _isActiveMember(member);
                    final programs = _readPrograms(
                      root['program_bantuan_pupuk'],
                    );
                    final applications = _readUserApplications(
                      root['bantuan_pupuk'],
                    );

                    return RefreshIndicator(
                      color: teal,
                      backgroundColor: Colors.white,
                      onRefresh: _refreshData,
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.manual,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          28,
                        ),
                        children: <Widget>[
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _header(),
                                  const SizedBox(height: 13),
                                  _memberCard(member, memberActive),
                                  const SizedBox(height: 12),
                                  _flowCard(),
                                  const SizedBox(height: 17),
                                  _sectionTitle(),
                                  const SizedBox(height: 11),
                                  if (programs.isEmpty)
                                    _emptyState()
                                  else
                                    ...programs.map((program) {
                                      return _programCard(
                                        program: program,
                                        member: member,
                                        memberActive: memberActive,
                                        application: _findExistingApplication(
                                          program,
                                          applications,
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (isSubmitting)
                Positioned.fill(
                  child: ColoredBox(
                    color: darkGreen.withValues(alpha: 0.28),
                    child: Center(
                      child: Container(
                        height: 74,
                        width: 74,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          color: teal,
                          strokeWidth: 2.8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[darkGreen, deepTeal, teal],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _backButton(),
          const SizedBox(width: 9),
          _iconBox(
            icon: Icons.energy_savings_leaf_outlined,
            color: Colors.white,
            background: Colors.white.withValues(alpha: 0.14),
            size: 46,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bantuan Pupuk Pemerintah',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Khusus anggota petani yang terdaftar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffD7EEE7),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCard(
    Map<dynamic, dynamic>? member,
    bool active,
  ) {
    final color = active ? primaryGreen : red;

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _iconBox(
                icon: active
                    ? Icons.verified_user_outlined
                    : Icons.person_off_outlined,
                color: color,
                background: color.withValues(alpha: 0.09),
                size: 45,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Status Kelayakan',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active ? 'Anggota Aktif' : 'Belum Memenuhi Syarat',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(
                active ? 'TERDAFTAR' : 'TIDAK AKTIF',
                color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailBox(<Widget>[
            _detailRow(
              Icons.person_outline_rounded,
              'Nama',
              _memberName(member),
            ),
            _detailRow(
              Icons.badge_outlined,
              'NIK',
              _sensorNik(widget.nik),
            ),
            _detailRow(
              Icons.landscape_outlined,
              'Luas Lahan',
              _memberLandArea(member),
            ),
            _detailRow(
              Icons.home_work_outlined,
              'Alamat',
              _memberAddress(member),
            ),
          ]),
          if (!active) ...<Widget>[
            const SizedBox(height: 10),
            _noticeCard(
              message: 'NIK Anda belum ditemukan sebagai anggota aktif. '
                  'Hubungi pengurus kelompok tani.',
              color: red,
              icon: Icons.info_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _flowCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.route_outlined, color: teal, size: 18),
              SizedBox(width: 7),
              Text(
                'Alur Bantuan',
                style: TextStyle(
                  color: textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Expanded(
                child: _flowItem(Icons.send_outlined, 'Ajukan'),
              ),
              _flowLine(),
              Expanded(
                child: _flowItem(Icons.fact_check_outlined, 'Verifikasi'),
              ),
              _flowLine(),
              Expanded(
                child: _flowItem(Icons.inventory_outlined, 'Pengambilan'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _flowItem(IconData icon, String title) {
    return Column(
      children: <Widget>[
        _iconBox(
          icon: icon,
          color: teal,
          background: softTeal,
          size: 34,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: textDark,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _flowLine() {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(left: 5, right: 5, bottom: 20),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _sectionTitle() {
    return const Row(
      children: <Widget>[
        SizedBox(
          width: 5,
          height: 31,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: teal,
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ),
        ),
        SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Program Bantuan',
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pilih program pemerintah yang sedang dibuka.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 10.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _programCard({
    required _UserProgram program,
    required Map<dynamic, dynamic>? member,
    required bool memberActive,
    required Map<String, dynamic>? application,
  }) {
    final programOpen = _isProgramOpen(program);
    final registeredRecipient = _isRegisteredRecipient(program);
    final canApply = memberActive &&
        programOpen &&
        registeredRecipient &&
        application == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _iconBox(
                  icon: _fertilizerIcon(program.fertilizer),
                  color: primaryGreen,
                  background: softGreen,
                  size: 49,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        program.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        program.period,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                _statusBadge(
                  programOpen ? 'DIBUKA' : 'TIDAK AKTIF',
                  programOpen ? primaryGreen : amber,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailBox(<Widget>[
              _detailRow(
                Icons.inventory_2_outlined,
                'Jenis Pupuk',
                program.fertilizer,
              ),
              _detailRow(
                Icons.scale_outlined,
                'Paket Bantuan',
                _formatKg(program.packageKg),
                valueColor: primaryGreen,
              ),
              _detailRow(
                Icons.date_range_outlined,
                'Masa Pengajuan',
                _formatRange(program.startDate, program.endDate),
              ),
              _detailRow(
                Icons.location_on_outlined,
                'Lokasi',
                program.location,
              ),
            ]),
            const SizedBox(height: 10),
            _noticeCard(
              message: program.description,
              color: teal,
              icon: Icons.info_outline_rounded,
              useNeutralText: true,
            ),
            const SizedBox(height: 11),
            if (application != null)
              _applicationStatusCard(application)
            else ...<Widget>[
              _eligibilityCard(
                program: program,
                memberActive: memberActive,
                registeredRecipient: registeredRecipient,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton.icon(
                  onPressed: canApply
                      ? () {
                          _openApplicationSheet(
                            program: program,
                            member: member,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        primaryGreen.withValues(alpha: 0.27),
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.82),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: Icon(
                    canApply
                        ? Icons.send_outlined
                        : Icons.lock_outline_rounded,
                    size: 19,
                  ),
                  label: Text(
                    _buttonText(
                      memberActive: memberActive,
                      programOpen: programOpen,
                      registeredRecipient: registeredRecipient,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eligibilityCard({
    required _UserProgram program,
    required bool memberActive,
    required bool registeredRecipient,
  }) {
    if (!memberActive) {
      return _noticeCard(
        message: 'Pengajuan tidak dapat dilakukan karena status anggota '
            'tidak aktif.',
        color: red,
        icon: Icons.person_off_outlined,
      );
    }

    if (!registeredRecipient) {
      return _noticeCard(
        message: 'NIK Anda tidak termasuk dalam daftar penerima program ini.',
        color: red,
        icon: Icons.list_alt_outlined,
      );
    }

    if (!_isProgramOpen(program)) {
      return _noticeCard(
        message: _programAvailabilityText(program),
        color: amber,
        icon: Icons.event_busy_outlined,
      );
    }

    return _noticeCard(
      message: 'Anda memenuhi persyaratan dan program sedang dibuka.',
      color: primaryGreen,
      icon: Icons.verified_user_outlined,
    );
  }

  String _buttonText({
    required bool memberActive,
    required bool programOpen,
    required bool registeredRecipient,
  }) {
    if (!memberActive) {
      return 'Anggota Tidak Aktif';
    }

    if (!registeredRecipient) {
      return 'Tidak Terdaftar';
    }

    if (!programOpen) {
      return 'Program Tidak Berlaku';
    }

    return 'Ajukan Bantuan';
  }

  Widget _applicationStatusCard(Map<String, dynamic> application) {
    final status = application['status'];
    final normalizedStatus = _normalizeApplicationStatus(status);
    final color = _applicationStatusColor(status);
    final finalAmount = _number(
      application['jumlah_disetujui'] ?? application['jumlah_final_kg'],
    );
    final adminNote = _text(
      application['catatan_admin'] ?? application['alasan_penolakan'],
      fallback: '',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _applicationStatusBackground(status),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _iconBox(
                icon: _applicationStatusIcon(status),
                color: color,
                background: Colors.white,
                size: 38,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _applicationStatusText(status),
                      style: TextStyle(
                        color: color,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _applicationStatusDescription(status),
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 9.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (normalizedStatus == 'disetujui' ||
              normalizedStatus == 'sudah_diambil') ...<Widget>[
            const SizedBox(height: 10),
            _detailBox(
              <Widget>[
                _detailRow(
                  Icons.scale_outlined,
                  'Jumlah Final',
                  finalAmount > 0
                      ? _formatKg(finalAmount)
                      : 'Belum ditetapkan',
                  valueColor: color,
                ),
                _detailRow(
                  Icons.calendar_month_outlined,
                  'Pengambilan',
                  _formatDate(application['tanggal_pengambilan']),
                  valueColor: color,
                ),
                _detailRow(
                  Icons.location_on_outlined,
                  'Lokasi',
                  _text(
                    application['lokasi_pengambilan'],
                    fallback: 'Belum ditentukan',
                  ),
                  valueColor: color,
                ),
              ],
              white: true,
            ),
          ],
          if (adminNote.isNotEmpty) ...<Widget>[
            const SizedBox(height: 9),
            Text(
              adminNote,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: teal, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? textDark,
                fontSize: 10.4,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox(
    List<Widget> children, {
    bool white = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 3),
      decoration: BoxDecoration(
        color: white ? Colors.white : const Color(0xffF9FBFA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _noticeCard({
    required String message,
    required Color color,
    required IconData icon,
    bool useNeutralText = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: useNeutralText ? textGrey : color,
                fontSize: 9.7,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 100),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color color,
    required Color background,
    required double size,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.055),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.maybePop(context);
        },
        borderRadius: BorderRadius.circular(14),
        child: _iconBox(
          icon: Icons.arrow_back_rounded,
          color: Colors.white,
          background: Colors.white.withValues(alpha: 0.14),
          size: 42,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return _card(
      const Column(
        children: <Widget>[
          Icon(Icons.event_busy_outlined, color: primaryGreen, size: 42),
          SizedBox(height: 12),
          Text(
            'Belum Ada Program Aktif',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 15.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Program bantuan akan tampil setelah dibuat dan dibuka oleh admin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 10.8,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statePage(double horizontalPadding, {bool loading = false}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        28,
      ),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: <Widget>[
                _header(),
                const SizedBox(height: 110),
                if (loading)
                  const CircularProgressIndicator(color: teal)
                else
                  _card(
                    const Column(
                      children: <Widget>[
                        Icon(Icons.cloud_off_outlined, color: red, size: 42),
                        SizedBox(height: 12),
                        Text(
                          'Program Tidak Dapat Dimuat',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Periksa koneksi internet lalu buka kembali halaman '
                          'ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textGrey, fontSize: 10.7),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ApplicationFormSheet extends StatefulWidget {
  final _UserProgram program;
  final String memberName;
  final String memberNik;
  final String memberLandArea;
  final String memberAddress;
  final String Function(double value) formatKg;
  final String Function(DateTime? start, DateTime? end) formatRange;
  final IconData Function(String value) fertilizerIcon;

  const _ApplicationFormSheet({
    required this.program,
    required this.memberName,
    required this.memberNik,
    required this.memberLandArea,
    required this.memberAddress,
    required this.formatKg,
    required this.formatRange,
    required this.fertilizerIcon,
  });

  @override
  State<_ApplicationFormSheet> createState() =>
      _ApplicationFormSheetState();
}

class _ApplicationFormSheetState extends State<_ApplicationFormSheet> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color teal = Color(0xff167A6B);
  static const Color deepTeal = Color(0xff0E5F57);
  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color cardBorder = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight < 650 ? 0.96 : 0.90;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: sheetHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: <Widget>[
                  _header(),
                  Expanded(
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.manual,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                      children: <Widget>[
                        _programCard(),
                        const SizedBox(height: 13),
                        _memberCard(),
                        const SizedBox(height: 13),
                        _informationCard(),
                        const SizedBox(height: 13),
                        TextField(
                          controller: noteController,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          onTapOutside: (_) {},
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            labelText: 'Catatan Tambahan (Opsional)',
                            prefixIcon: const Icon(
                              Icons.notes_outlined,
                              color: teal,
                            ),
                            filled: true,
                            fillColor: const Color(0xffF8FAF9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: cardBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: teal,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              Navigator.of(context).pop(
                                noteController.text.trim(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text(
                              'Lanjut Konfirmasi',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 43,
            height: 5,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _iconBox(
                icon: Icons.edit_note_outlined,
                color: primaryGreen,
                background: softGreen,
                size: 43,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Ajukan Bantuan',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Periksa data sebelum dikirim',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _programCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[darkGreen, deepTeal, teal],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _iconBox(
                icon: widget.fertilizerIcon(widget.program.fertilizer),
                color: Colors.white,
                background: Colors.white.withValues(alpha: 0.14),
                size: 45,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.program.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _programInfo('Periode', widget.program.period),
          _programInfo('Jenis Pupuk', widget.program.fertilizer),
          _programInfo(
            'Paket Bantuan',
            widget.formatKg(widget.program.packageKg),
          ),
          _programInfo(
            'Masa Pengajuan',
            widget.formatRange(
              widget.program.startDate,
              widget.program.endDate,
            ),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _programInfo(String label, String value, {bool last = false}) {
    return Container(
      padding: EdgeInsets.only(bottom: last ? 0 : 8),
      margin: EdgeInsets.only(bottom: last ? 0 : 8),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.13),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberCard() {
    return _card(
      Column(
        children: <Widget>[
          _memberRow('Nama', widget.memberName),
          _memberRow('NIK', widget.memberNik),
          _memberRow('Luas Lahan', widget.memberLandArea),
          _memberRow('Alamat', widget.memberAddress),
        ],
      ),
    );
  }

  Widget _memberRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: textDark,
                fontSize: 10.4,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withValues(alpha: 0.11)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: teal, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Jumlah final, tanggal, dan lokasi pengambilan akan ditetapkan '
              'setelah pengajuan diverifikasi admin.',
              style: TextStyle(
                color: textGrey,
                fontSize: 10.1,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: cardBorder),
      ),
      child: child,
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color color,
    required Color background,
    required double size,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _UserProgram {
  final String id;
  final String name;
  final String period;
  final String fertilizer;
  final double packageKg;
  final DateTime? startDate;
  final DateTime? endDate;
  final String location;
  final String description;
  final String status;
  final Map<dynamic, dynamic> raw;

  const _UserProgram({
    required this.id,
    required this.name,
    required this.period,
    required this.fertilizer,
    required this.packageKg,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.description,
    required this.status,
    required this.raw,
  });
}

class _UserPupukBackground extends StatelessWidget {
  const _UserPupukBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            final large = (base * 0.98).clamp(280.0, 460.0).toDouble();
            final medium = (base * 0.68).clamp(190.0, 330.0).toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Color(0xff0E5F57),
                          Color(0xff177A6B),
                          Color(0xffDDEFEA),
                          Color(0xffF2F7F5),
                        ],
                        stops: <double>[0, 0.19, 0.44, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.55,
                    right: -large * 0.29,
                    child: _UserBackgroundCircle(
                      size: large,
                      color: const Color(0xff53B69C),
                      alpha: 0.20,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.30,
                    left: -medium * 0.57,
                    child: _UserBackgroundCircle(
                      size: medium,
                      color: const Color(0xffA9DCCF),
                      alpha: 0.36,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.50,
                    right: -medium * 0.61,
                    child: _UserBackgroundCircle(
                      size: medium * 1.08,
                      color: const Color(0xffE7F2F7),
                      alpha: 0.83,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.30,
                    child: _UserBackgroundCircle(
                      size: large,
                      color: const Color(0xffDDEFE5),
                      alpha: 0.80,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserBackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _UserBackgroundCircle({
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}
