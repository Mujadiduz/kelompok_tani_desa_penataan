import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class KelolaPupukPage extends StatefulWidget {
  const KelolaPupukPage({super.key});

  @override
  State<KelolaPupukPage> createState() => _KelolaPupukPageState();
}

class _KelolaPupukPageState extends State<KelolaPupukPage> {
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminNavyLight = Color(0xff294762);
  static const Color adminPurple = Color(0xff6256A4);

  static const Color green = Color(0xff2E7D32);
  static const Color blue = Color(0xff326CA3);
  static const Color amber = Color(0xffD98212);
  static const Color red = Color(0xffC83B3B);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softBlue = Color(0xffE9F2FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);
  static const Color softPurple = Color(0xffF0ECFA);

  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference rootRef;
  late final DatabaseReference programRef;
  late final DatabaseReference anggotaRef;

  bool isSaving = false;
  String selectedFilter = 'semua';

  @override
  void initState() {
    super.initState();
    rootRef = db.ref();
    programRef = db.ref('program_bantuan_pupuk');
    anggotaRef = db.ref('anggota');
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

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          (value ?? '').toString().replaceAll(',', '.'),
        ) ??
        0;
  }

  String _normalizeNik(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();
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

  String _inputDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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
      return 'Ditetapkan saat verifikasi';
    }

    if (value % 1 == 0) {
      return '${value.toInt()} Kg';
    }

    return '${value.toStringAsFixed(1)} Kg';
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

  bool _isProgramOpen(_ProgramBantuan program) {
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

  bool _isActiveMember(Map<dynamic, dynamic> member) {
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

  List<_ProgramBantuan> _readPrograms(dynamic value) {
    final programs = <_ProgramBantuan>[];

    for (final entry in _asMap(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final raw = Map<dynamic, dynamic>.from(entry.value as Map);

      programs.add(
        _ProgramBantuan(
          id: entry.key.toString(),
          name: _text(
            raw['nama_program'] ?? raw['judul_program'],
            fallback: 'Program Bantuan Pupuk',
          ),
          period: _text(
            raw['periode'] ?? raw['periode_bantuan'],
            fallback: 'Periode belum ditentukan',
          ),
          fertilizer: _text(
            raw['jenis_pupuk'] ?? raw['nama_pupuk'],
            fallback: 'Pupuk bantuan',
          ),
          packageKg: _number(
            raw['jumlah_paket_kg'] ?? raw['jumlah_kg'],
          ),
          startDate: _parseDate(
            raw['tanggal_mulai'] ?? raw['tanggal_buka'],
          ),
          endDate: _parseDate(
            raw['tanggal_selesai'] ?? raw['tanggal_tutup'],
          ),
          location: _text(
            raw['lokasi_pengambilan'] ?? raw['tempat_pengambilan'],
            fallback: 'Akan ditetapkan admin',
          ),
          description: _text(
            raw['keterangan'] ?? raw['deskripsi'],
            fallback: 'Khusus anggota aktif yang terdaftar.',
          ),
          status: _normalizeProgramStatus(raw['status']),
          updatedAt: _parseDate(
            raw['tanggal_update'] ?? raw['tanggal_dibuat'],
          ),
        ),
      );
    }

    programs.sort((a, b) {
      int rank(_ProgramBantuan program) {
        if (_isProgramOpen(program)) {
          return 0;
        }

        final status = _normalizeProgramStatus(program.status);

        if (status == 'aktif') {
          return 1;
        }

        if (status == 'ditutup') {
          return 2;
        }

        return 3;
      }

      final rankComparison = rank(a).compareTo(rank(b));

      if (rankComparison != 0) {
        return rankComparison;
      }

      final dateA = a.updatedAt ?? a.startDate ?? DateTime(1970);
      final dateB = b.updatedAt ?? b.startDate ?? DateTime(1970);

      return dateB.compareTo(dateA);
    });

    return programs;
  }

  List<Map<dynamic, dynamic>> _readApplications(dynamic value) {
    final applications = <Map<dynamic, dynamic>>[];

    for (final entry in _asMap(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final item = Map<dynamic, dynamic>.from(entry.value as Map);
      item['_id'] = entry.key.toString();
      applications.add(item);
    }

    return applications;
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
      'sedang diproses',
      'menunggu_verifikasi',
      'menunggu verifikasi',
      'belum_diproses',
      'belum diproses',
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

  bool _applicationBelongsToProgram(
    Map<dynamic, dynamic> item,
    _ProgramBantuan program,
  ) {
    final id = _text(
      item['id_program'] ?? item['program_id'],
      fallback: '',
    );

    if (id.isNotEmpty && id == program.id) {
      return true;
    }

    final name = _text(item['nama_program'], fallback: '');
    final period = _text(item['periode'], fallback: '');

    return name.toLowerCase() == program.name.toLowerCase() &&
        period.toLowerCase() == program.period.toLowerCase();
  }

  _ProgramStats _programStats(
    _ProgramBantuan program,
    List<Map<dynamic, dynamic>> applications,
  ) {
    int pending = 0;
    int approved = 0;
    int completed = 0;
    int rejected = 0;

    for (final item in applications) {
      if (!_applicationBelongsToProgram(item, program)) {
        continue;
      }

      switch (_normalizeApplicationStatus(item['status'])) {
        case 'menunggu_verifikasi':
          pending++;
          break;
        case 'disetujui':
          approved++;
          break;
        case 'sudah_diambil':
          completed++;
          break;
        case 'ditolak':
          rejected++;
          break;
      }
    }

    return _ProgramStats(
      pending: pending,
      approved: approved,
      completed: completed,
      rejected: rejected,
    );
  }

  List<_ProgramBantuan> _filterPrograms(List<_ProgramBantuan> programs) {
    switch (selectedFilter) {
      case 'dibuka':
        return programs.where(_isProgramOpen).toList();
      case 'terjadwal':
        return programs.where((program) {
          return _normalizeProgramStatus(program.status) == 'aktif' &&
              !_isProgramOpen(program);
        }).toList();
      case 'ditutup':
      case 'arsip':
        return programs.where((program) {
          return _normalizeProgramStatus(program.status) == selectedFilter;
        }).toList();
      default:
        return programs;
    }
  }

  int _filterCount(List<_ProgramBantuan> programs, String filter) {
    switch (filter) {
      case 'dibuka':
        return programs.where(_isProgramOpen).length;
      case 'terjadwal':
        return programs.where((program) {
          return _normalizeProgramStatus(program.status) == 'aktif' &&
              !_isProgramOpen(program);
        }).length;
      case 'ditutup':
      case 'arsip':
        return programs.where((program) {
          return _normalizeProgramStatus(program.status) == filter;
        }).length;
      default:
        return programs.length;
    }
  }

  Future<void> _refreshData() async {
    await rootRef.get();
  }

  Future<void> _openProgramForm({_ProgramBantuan? program}) async {
    FocusScope.of(context).unfocus();

    final result = await showModalBottomSheet<_ProgramFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: adminNavy.withValues(alpha: 0.52),
      builder: (sheetContext) {
        return _ProgramFormSheet(
          initialProgram: program,
          parseDate: _parseDate,
          inputDate: _inputDate,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    // Tunggu animasi penutupan bottom sheet selesai sebelum parent dibangun ulang.
    await Future<void>.delayed(const Duration(milliseconds: 380));

    if (!mounted) {
      return;
    }

    await _saveProgram(
      programId: program?.id,
      data: result,
    );
  }

  Future<void> _saveProgram({
    required String? programId,
    required _ProgramFormResult data,
  }) async {
    if (isSaving) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final now = DateTime.now().toIso8601String();
      final reference = programId == null
          ? programRef.push()
          : programRef.child(programId);
      final savedProgramId = reference.key ?? programId ?? '';

      await reference.update(<String, dynamic>{
        'nama_program': data.name,
        'periode': data.period,
        'jenis_pupuk': data.fertilizer,
        'jumlah_paket_kg': data.packageKg,
        'jumlah_ditentukan_admin': data.packageKg <= 0,
        'tanggal_mulai': _inputDate(data.startDate),
        'tanggal_selesai': _inputDate(data.endDate),
        'lokasi_pengambilan': data.location,
        'keterangan': data.description,
        'status': data.status,
        if (programId == null) 'tanggal_dibuat': now,
        'tanggal_update': now,
      }).timeout(const Duration(seconds: 15));

      int notificationCount = 0;
      String? notificationWarning;

      if (data.sendNotification && data.status == 'aktif') {
        try {
          notificationCount = await _notifyActiveMembers(
            programId: savedProgramId,
            name: data.name,
            period: data.period,
            fertilizer: data.fertilizer,
            endDate: data.endDate,
            isUpdate: programId != null,
          );
        } catch (_) {
          notificationWarning =
              ' Program tersimpan, tetapi pemberitahuan anggota gagal dikirim.';
        }
      }

      if (!mounted) {
        return;
      }

      var message = programId == null
          ? 'Program bantuan berhasil dibuat.'
          : 'Program bantuan berhasil diperbarui.';

      if (notificationCount > 0) {
        message += ' Pemberitahuan dikirim ke $notificationCount anggota.';
      }

      if (notificationWarning != null) {
        message += notificationWarning;
      }

      _showSnackBar(
        message,
        notificationWarning == null ? adminPurple : amber,
      );
    } catch (error) {
      if (mounted) {
        _showSnackBar(
          'Gagal menyimpan program: $error',
          red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<int> _notifyActiveMembers({
    required String programId,
    required String name,
    required String period,
    required String fertilizer,
    required DateTime endDate,
    required bool isUpdate,
  }) async {
    final snapshot = await anggotaRef.get();
    final updates = <String, dynamic>{};
    final now = DateTime.now().toIso8601String();
    int total = 0;

    for (final entry in _asMap(snapshot.value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final member = Map<dynamic, dynamic>.from(entry.value as Map);

      if (!_isActiveMember(member)) {
        continue;
      }

      final nik = _normalizeNik(member['nik'] ?? entry.key);

      if (nik.isEmpty) {
        continue;
      }

      final key = db.ref('notifikasi').child(nik).push().key;

      if (key == null) {
        continue;
      }

      updates['notifikasi/$nik/$key'] = <String, dynamic>{
        'judul': isUpdate
            ? 'Pembaruan Program Bantuan Pupuk'
            : 'Program Bantuan Pupuk Dibuka',
        'pesan': '$name periode $period untuk $fertilizer dapat diajukan '
            'sampai ${_formatDate(endDate)}.',
        'tipe': 'program_bantuan_pupuk',
        'id_program': programId,
        'status': 'belum_dibaca',
        'dibaca': false,
        'tanggal': now,
      };

      total++;
    }

    if (updates.isNotEmpty) {
      await rootRef.update(updates).timeout(const Duration(seconds: 20));
    }

    return total;
  }

  Future<void> _toggleProgram(_ProgramBantuan program) async {
    final currentlyActive =
        _normalizeProgramStatus(program.status) == 'aktif';
    final targetStatus = currentlyActive ? 'ditutup' : 'aktif';

    if (targetStatus == 'aktif' && program.endDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (today.isAfter(program.endDate!)) {
        _showSnackBar(
          'Batas pengajuan sudah berakhir. Edit tanggal terlebih dahulu.',
          red,
        );
        return;
      }
    }

    final confirmed = await _showConfirmDialog(
      icon: currentlyActive
          ? Icons.pause_circle_outline_rounded
          : Icons.campaign_outlined,
      color: currentlyActive ? amber : green,
      title: currentlyActive ? 'Tutup Program?' : 'Buka Program?',
      message: currentlyActive
          ? 'Program tidak dapat diajukan pengguna setelah ditutup. '
              'Data pengajuan tetap tersimpan.'
          : 'Program akan tampil pada halaman pengguna dan pemberitahuan '
              'dikirim kepada anggota aktif.',
      confirmText: currentlyActive ? 'Tutup Program' : 'Buka & Beritahu',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await programRef.child(program.id).update(<String, dynamic>{
        'status': targetStatus,
        'tanggal_update': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 15));

      int notificationCount = 0;
      String? warning;

      if (targetStatus == 'aktif') {
        try {
          notificationCount = await _notifyActiveMembers(
            programId: program.id,
            name: program.name,
            period: program.period,
            fertilizer: program.fertilizer,
            endDate: program.endDate ?? DateTime.now(),
            isUpdate: false,
          );
        } catch (_) {
          warning = ' Program dibuka, tetapi pemberitahuan gagal dikirim.';
        }
      }

      if (!mounted) {
        return;
      }

      if (targetStatus == 'aktif') {
        _showSnackBar(
          'Program berhasil dibuka. Pemberitahuan dikirim ke '
          '$notificationCount anggota.${warning ?? ''}',
          warning == null ? green : amber,
        );
      } else {
        _showSnackBar('Program berhasil ditutup.', amber);
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Gagal mengubah status program: $error', red);
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _archiveProgram(
    _ProgramBantuan program,
    _ProgramStats stats,
  ) async {
    final confirmed = await _showConfirmDialog(
      icon: Icons.archive_outlined,
      color: red,
      title: 'Arsipkan Program?',
      message: stats.total > 0
          ? 'Program memiliki ${stats.total} pengajuan. Program hanya '
              'disembunyikan dari pengguna dan data pengajuan tidak dihapus.'
          : 'Program disembunyikan dari pengguna dan dipindahkan ke arsip.',
      confirmText: 'Arsipkan',
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      await programRef.child(program.id).update(<String, dynamic>{
        'status': 'arsip',
        'tanggal_arsip': now,
        'tanggal_update': now,
      }).timeout(const Duration(seconds: 15));

      if (mounted) {
        _showSnackBar('Program berhasil diarsipkan.', red);
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Gagal mengarsipkan program: $error', red);
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _restoreProgram(_ProgramBantuan program) async {
    if (isSaving) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await programRef.child(program.id).update(<String, dynamic>{
        'status': 'ditutup',
        'tanggal_update': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 15));

      if (mounted) {
        _showSnackBar(
          'Program dipulihkan sebagai program ditutup.',
          adminPurple,
        );
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Gagal memulihkan program: $error', red);
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String confirmText,
  }) {
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
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    height: 62,
                    width: 62,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: color, size: 31),
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

                      final confirmButton = ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );

                      if (stacked) {
                        return Column(
                          children: <Widget>[
                            cancelButton,
                            const SizedBox(height: 9),
                            confirmButton,
                          ],
                        );
                      }

                      return Row(
                        children: <Widget>[
                          Expanded(child: cancelButton),
                          const SizedBox(width: 10),
                          Expanded(child: confirmButton),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : () => _openProgramForm(),
        backgroundColor: adminPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Program Baru',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const _AdminProgramBackground(),
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
                    final programs = _readPrograms(
                      root['program_bantuan_pupuk'],
                    );
                    final applications = _readApplications(
                      root['bantuan_pupuk'],
                    );
                    final visiblePrograms = _filterPrograms(programs);

                    return RefreshIndicator(
                      color: adminPurple,
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
                          104,
                        ),
                        children: <Widget>[
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 780),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _header(programs.length),
                                  const SizedBox(height: 13),
                                  _summary(programs, applications),
                                  const SizedBox(height: 12),
                                  _filters(programs),
                                  const SizedBox(height: 12),
                                  _noticeCard(),
                                  const SizedBox(height: 17),
                                  _sectionTitle(),
                                  const SizedBox(height: 11),
                                  if (visiblePrograms.isEmpty)
                                    _emptyState()
                                  else
                                    ...visiblePrograms.map((program) {
                                      return _programCard(
                                        program,
                                        _programStats(program, applications),
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
              if (isSaving)
                Positioned.fill(
                  child: ColoredBox(
                    color: adminNavy.withValues(alpha: 0.28),
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
                          color: adminPurple,
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

  Widget _header(int total) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            adminNavy,
            adminNavyLight,
            adminPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.25),
            blurRadius: 23,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          _backButton(),
          const SizedBox(width: 9),
          _iconBox(
            icon: Icons.campaign_outlined,
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
                  'Kelola Program Bantuan',
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
                  'Publikasi bantuan pupuk pemerintah',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffDFE5F0),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Container(
            constraints: const BoxConstraints(minWidth: 45),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: <Widget>[
                Text(
                  total > 99 ? '99+' : total.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'program',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.77),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
    List<_ProgramBantuan> programs,
    List<Map<dynamic, dynamic>> applications,
  ) {
    final activePrograms = programs.where(_isProgramOpen).length;
    final pendingApplications = applications.where((item) {
      return _normalizeApplicationStatus(item['status']) ==
          'menunggu_verifikasi';
    }).length;
    final completedApplications = applications.where((item) {
      return _normalizeApplicationStatus(item['status']) == 'sudah_diambil';
    }).length;

    final items = <_SummaryData>[
      _SummaryData(
        title: 'Program Aktif',
        value: activePrograms,
        icon: Icons.campaign_outlined,
        color: green,
        background: softGreen,
      ),
      _SummaryData(
        title: 'Perlu Verifikasi',
        value: pendingApplications,
        icon: Icons.pending_actions_outlined,
        color: amber,
        background: softAmber,
      ),
      _SummaryData(
        title: 'Tersalurkan',
        value: completedApplications,
        icon: Icons.task_alt_outlined,
        color: blue,
        background: softBlue,
      ),
    ];

    return _card(
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 360 ? 1 : 3;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - 14) / 3;

          return Wrap(
            spacing: 7,
            runSpacing: 7,
            children: items.map((item) {
              return SizedBox(
                width: width,
                child: _summaryItem(item),
              );
            }).toList(),
          );
        },
      ),
      padding: const EdgeInsets.all(9),
    );
  }

  Widget _summaryItem(_SummaryData item) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: item.background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: <Widget>[
          _iconBox(
            icon: item.icon,
            color: item.color,
            background: Colors.white,
            size: 38,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  item.value > 99 ? '99+' : item.value.toString(),
                  style: TextStyle(
                    color: item.color,
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(List<_ProgramBantuan> programs) {
    const items = <_FilterData>[
      _FilterData(
        value: 'semua',
        label: 'Semua',
        icon: Icons.grid_view_rounded,
        color: adminPurple,
      ),
      _FilterData(
        value: 'dibuka',
        label: 'Dibuka',
        icon: Icons.campaign_outlined,
        color: green,
      ),
      _FilterData(
        value: 'terjadwal',
        label: 'Terjadwal',
        icon: Icons.schedule_outlined,
        color: blue,
      ),
      _FilterData(
        value: 'ditutup',
        label: 'Ditutup',
        icon: Icons.pause_circle_outline_rounded,
        color: amber,
      ),
      _FilterData(
        value: 'arsip',
        label: 'Arsip',
        icon: Icons.archive_outlined,
        color: red,
      ),
    ];

    return _card(
      SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final item = items[index];
            final selected = selectedFilter == item.value;

            return InkWell(
              onTap: () {
                setState(() {
                  selectedFilter = item.value;
                });
              },
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? item.color
                      : item.color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? item.color
                        : item.color.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      item.icon,
                      color: selected ? Colors.white : item.color,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.label,
                      style: TextStyle(
                        color: selected ? Colors.white : textDark,
                        fontSize: 9.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _filterCount(programs, item.value).toString(),
                      style: TextStyle(
                        color: selected ? Colors.white : item.color,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      padding: const EdgeInsets.all(9),
    );
  }

  Widget _noticeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softPurple,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: adminPurple.withValues(alpha: 0.12),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.notifications_active_outlined,
            color: adminPurple,
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Program yang dibuka tampil otomatis pada menu Bantuan Pupuk '
              'pengguna. Pemberitahuan dikirim kepada setiap anggota aktif.',
              style: TextStyle(
                color: textGrey,
                fontSize: 10.3,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
              color: adminPurple,
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
                'Daftar Program Bantuan',
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Terhubung langsung dengan pengajuan bantuan pupuk pengguna.',
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

  Widget _programCard(_ProgramBantuan program, _ProgramStats stats) {
    final status = _normalizeProgramStatus(program.status);
    final archived = status == 'arsip';
    final opened = _isProgramOpen(program);
    final color = archived
        ? red
        : opened
            ? green
            : status == 'aktif'
                ? blue
                : amber;
    final label = archived
        ? 'ARSIP'
        : opened
            ? 'DIBUKA'
            : status == 'aktif'
                ? 'TERJADWAL'
                : 'DITUTUP';

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
                  color: color,
                  background: color.withValues(alpha: 0.09),
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
                          fontSize: 13.8,
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
                          fontSize: 9.7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                _statusBadge(label, color),
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
                valueColor: program.packageKg > 0 ? green : adminPurple,
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF5F6FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                program.description,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 9.8,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _statsBar(stats),
            const SizedBox(height: 10),
            if (archived)
              _wideButton(
                title: 'Pulihkan Program',
                icon: Icons.restore_rounded,
                color: adminPurple,
                onPressed: () => _restoreProgram(program),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final buttonWidth = width < 360 ? (width - 8) / 2 : (width - 16) / 3;

                  final actions = <Widget>[
                    SizedBox(
                      width: buttonWidth,
                      child: _actionButton(
                        title: 'Edit',
                        icon: Icons.edit_outlined,
                        color: adminPurple,
                        onPressed: () => _openProgramForm(program: program),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _actionButton(
                        title: status == 'aktif' ? 'Tutup' : 'Buka',
                        icon: status == 'aktif'
                            ? Icons.pause_circle_outline_rounded
                            : Icons.campaign_outlined,
                        color: status == 'aktif' ? amber : green,
                        onPressed: () => _toggleProgram(program),
                      ),
                    ),
                    SizedBox(
                      width: width < 360 ? width : buttonWidth,
                      child: _actionButton(
                        title: 'Arsip',
                        icon: Icons.archive_outlined,
                        color: red,
                        onPressed: () => _archiveProgram(program, stats),
                      ),
                    ),
                  ];

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _statsBar(_ProgramStats stats) {
    final items = <_MiniStatsData>[
      _MiniStatsData('Menunggu', stats.pending, amber, softAmber),
      _MiniStatsData('Disetujui', stats.approved, blue, softBlue),
      _MiniStatsData('Diambil', stats.completed, green, softGreen),
      if (stats.rejected > 0)
        _MiniStatsData('Ditolak', stats.rejected, red, softRed),
    ];

    return _detailBox(
      <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 330 ? 2 : items.length;
            final spacing = 6.0;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items.map((item) {
                return SizedBox(
                  width: itemWidth,
                  child: _miniStats(item),
                );
              }).toList(),
            );
          },
        ),
      ],
      padding: const EdgeInsets.all(8),
    );
  }

  Widget _miniStats(_MiniStatsData item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 3),
      decoration: BoxDecoration(
        color: item.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            item.value.toString(),
            style: TextStyle(
              color: item.color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 7.8,
              fontWeight: FontWeight.w700,
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
      height: 43,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.10),
          foregroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.05),
          disabledForegroundColor: color.withValues(alpha: 0.45),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: BorderSide(color: color.withValues(alpha: 0.12)),
          ),
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.4,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _wideButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
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
          Icon(icon, color: adminPurple, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 9.9,
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
                fontSize: 10.3,
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
    EdgeInsets padding = const EdgeInsets.fromLTRB(12, 12, 12, 3),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
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

  Widget _card(
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(13),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.055),
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
          Icon(Icons.campaign_outlined, color: adminPurple, size: 42),
          SizedBox(height: 12),
          Text(
            'Belum Ada Program Bantuan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 15.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Tekan Program Baru untuk membuat pemberitahuan bantuan pupuk '
            'pemerintah.',
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
            constraints: const BoxConstraints(maxWidth: 780),
            child: Column(
              children: <Widget>[
                _header(0),
                const SizedBox(height: 110),
                if (loading)
                  const CircularProgressIndicator(color: adminPurple)
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
                          style: TextStyle(
                            color: textGrey,
                            fontSize: 10.7,
                          ),
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
}

class _ProgramFormSheet extends StatefulWidget {
  final _ProgramBantuan? initialProgram;
  final DateTime? Function(dynamic value) parseDate;
  final String Function(DateTime date) inputDate;

  const _ProgramFormSheet({
    required this.initialProgram,
    required this.parseDate,
    required this.inputDate,
  });

  @override
  State<_ProgramFormSheet> createState() => _ProgramFormSheetState();
}

class _ProgramFormSheetState extends State<_ProgramFormSheet> {
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminPurple = Color(0xff6256A4);
  static const Color green = Color(0xff2E7D32);
  static const Color red = Color(0xffC83B3B);
  static const Color softPurple = Color(0xffF0ECFA);
  static const Color softRed = Color(0xffFBEAEA);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  late final TextEditingController nameController;
  late final TextEditingController periodController;
  late final TextEditingController fertilizerController;
  late final TextEditingController amountController;
  late final TextEditingController startController;
  late final TextEditingController endController;
  late final TextEditingController locationController;
  late final TextEditingController descriptionController;

  DateTime? startDate;
  DateTime? endDate;
  bool amountByAdmin = true;
  bool sendNotification = true;
  String status = 'ditutup';
  String errorMessage = '';

  @override
  void initState() {
    super.initState();

    final program = widget.initialProgram;

    nameController = TextEditingController(text: program?.name ?? '');
    periodController = TextEditingController(text: program?.period ?? '');
    fertilizerController = TextEditingController(
      text: program?.fertilizer ?? '',
    );
    amountController = TextEditingController(
      text: program != null && program.packageKg > 0
          ? program.packageKg % 1 == 0
              ? program.packageKg.toInt().toString()
              : program.packageKg.toStringAsFixed(1)
          : '',
    );
    startController = TextEditingController(
      text: program?.startDate == null
          ? ''
          : widget.inputDate(program!.startDate!),
    );
    endController = TextEditingController(
      text: program?.endDate == null
          ? ''
          : widget.inputDate(program!.endDate!),
    );
    locationController = TextEditingController(
      text: program?.location == 'Akan ditetapkan admin'
          ? ''
          : program?.location ?? '',
    );
    descriptionController = TextEditingController(
      text: program?.description ?? '',
    );

    startDate = program?.startDate;
    endDate = program?.endDate;
    amountByAdmin = program == null || program.packageKg <= 0;
    sendNotification = program == null;

    final initialStatus = program?.status ?? 'ditutup';
    status = initialStatus == 'aktif' ? 'aktif' : 'ditutup';
  }

  @override
  void dispose() {
    nameController.dispose();
    periodController.dispose();
    fertilizerController.dispose();
    amountController.dispose();
    startController.dispose();
    endController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    FocusScope.of(context).unfocus();

    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? startDate ?? DateTime.now()
          : endDate ?? startDate ?? DateTime.now(),
      firstDate: isStart ? DateTime(2020) : startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Pilih tanggal mulai' : 'Pilih batas akhir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        startDate = DateTime(picked.year, picked.month, picked.day);
        startController.text = widget.inputDate(startDate!);

        if (endDate != null && endDate!.isBefore(startDate!)) {
          endDate = startDate;
          endController.text = widget.inputDate(endDate!);
        }
      } else {
        endDate = DateTime(picked.year, picked.month, picked.day);
        endController.text = widget.inputDate(endDate!);
      }
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final packageKg = amountByAdmin
        ? 0.0
        : double.tryParse(
              amountController.text.trim().replaceAll(',', '.'),
            ) ??
            0;

    String? error;

    if (nameController.text.trim().isEmpty) {
      error = 'Nama program wajib diisi.';
    } else if (periodController.text.trim().isEmpty) {
      error = 'Periode wajib diisi.';
    } else if (fertilizerController.text.trim().isEmpty) {
      error = 'Jenis pupuk wajib diisi.';
    } else if (!amountByAdmin && packageKg <= 0) {
      error = 'Paket bantuan harus lebih dari 0 Kg.';
    } else if (startDate == null) {
      error = 'Tanggal mulai wajib dipilih.';
    } else if (endDate == null) {
      error = 'Tanggal selesai wajib dipilih.';
    } else if (endDate!.isBefore(startDate!)) {
      error = 'Tanggal selesai tidak boleh sebelum tanggal mulai.';
    } else if (locationController.text.trim().isEmpty) {
      error = 'Lokasi pengambilan wajib diisi.';
    } else if (descriptionController.text.trim().isEmpty) {
      error = 'Keterangan program wajib diisi.';
    }

    if (error != null) {
      setState(() {
        errorMessage = error!;
      });
      return;
    }

    Navigator.of(context).pop(
      _ProgramFormResult(
        name: nameController.text.trim(),
        period: periodController.text.trim(),
        fertilizer: fertilizerController.text.trim(),
        packageKg: packageKg,
        startDate: startDate!,
        endDate: endDate!,
        location: locationController.text.trim(),
        description: descriptionController.text.trim(),
        status: status,
        sendNotification: sendNotification && status == 'aktif',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight < 650 ? 0.96 : 0.93;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: sheetHeight,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
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
                        _informationCard(),
                        const SizedBox(height: 14),
                        _input(
                          controller: nameController,
                          label: 'Nama Program',
                          icon: Icons.campaign_outlined,
                          hint: 'Bantuan Pupuk Pemerintah Agustus 2026',
                        ),
                        const SizedBox(height: 11),
                        _input(
                          controller: periodController,
                          label: 'Periode',
                          icon: Icons.calendar_view_month_outlined,
                          hint: 'Agustus 2026',
                        ),
                        const SizedBox(height: 11),
                        _input(
                          controller: fertilizerController,
                          label: 'Jenis Pupuk',
                          icon: Icons.inventory_2_outlined,
                          hint: 'Urea dan NPK',
                        ),
                        const SizedBox(height: 11),
                        _switchCard(
                          title: 'Jumlah ditentukan saat verifikasi',
                          subtitle:
                              'Aktifkan bila jumlah setiap petani ditetapkan admin.',
                          icon: Icons.fact_check_outlined,
                          color: adminPurple,
                          value: amountByAdmin,
                          onChanged: (value) {
                            setState(() {
                              amountByAdmin = value;

                              if (value) {
                                amountController.clear();
                              }
                            });
                          },
                        ),
                        if (!amountByAdmin) ...<Widget>[
                          const SizedBox(height: 11),
                          _input(
                            controller: amountController,
                            label: 'Paket Bantuan (Kg)',
                            icon: Icons.scale_outlined,
                            hint: '50',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                        const SizedBox(height: 11),
                        _dateField(
                          controller: startController,
                          label: 'Tanggal Mulai',
                          icon: Icons.event_available_outlined,
                          onTap: () => _pickDate(true),
                        ),
                        const SizedBox(height: 11),
                        _dateField(
                          controller: endController,
                          label: 'Batas Akhir',
                          icon: Icons.event_busy_outlined,
                          onTap: () => _pickDate(false),
                        ),
                        const SizedBox(height: 11),
                        _input(
                          controller: locationController,
                          label: 'Lokasi Pengambilan',
                          icon: Icons.location_on_outlined,
                          hint: 'Gudang Kelompok Tani',
                        ),
                        const SizedBox(height: 11),
                        _input(
                          controller: descriptionController,
                          label: 'Keterangan dan Syarat',
                          icon: Icons.notes_outlined,
                          hint: 'Khusus anggota aktif yang terdaftar.',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 11),
                        DropdownButtonFormField<String>(
                          value: status,
                          isExpanded: true,
                          decoration: _decoration(
                            label: 'Status Program',
                            icon: Icons.toggle_on_outlined,
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'ditutup',
                              child: Text('Simpan sebagai ditutup'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'aktif',
                              child: Text('Aktifkan program'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              status = value;

                              if (status != 'aktif') {
                                sendNotification = false;
                              }
                            });
                          },
                        ),
                        if (status == 'aktif') ...<Widget>[
                          const SizedBox(height: 11),
                          _switchCard(
                            title: 'Kirim pemberitahuan ke anggota',
                            subtitle:
                                'Notifikasi dikirim kepada seluruh anggota aktif.',
                            icon: Icons.notifications_active_outlined,
                            color: green,
                            value: sendNotification,
                            onChanged: (value) {
                              setState(() {
                                sendNotification = value;
                              });
                            },
                          ),
                        ],
                        if (errorMessage.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 11),
                          _errorCard(errorMessage),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 51,
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: adminPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            icon: Icon(
                              widget.initialProgram == null
                                  ? Icons.add_task_rounded
                                  : Icons.save_as_rounded,
                            ),
                            label: Text(
                              widget.initialProgram == null
                                  ? 'Simpan Program'
                                  : 'Simpan Perubahan',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
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
                icon: widget.initialProgram == null
                    ? Icons.add_task_rounded
                    : Icons.edit_note_outlined,
                color: adminPurple,
                background: softPurple,
                size: 43,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.initialProgram == null
                          ? 'Program Bantuan Baru'
                          : 'Edit Program Bantuan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Atur pemberitahuan dan periode bantuan pupuk',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _informationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[adminNavy, adminPurple],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Program tersimpan di program_bantuan_pupuk. Pengajuan pengguna '
        'tetap masuk ke bantuan_pupuk dan diverifikasi pada halaman '
        'Verifikasi Bantuan Pupuk.',
        style: TextStyle(
          color: Color(0xffE4E8F2),
          fontSize: 10,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction:
          maxLines > 1 ? TextInputAction.done : TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      onTapOutside: (_) {},
      onSubmitted: maxLines > 1
          ? (_) {
              FocusScope.of(context).unfocus();
            }
          : null,
      decoration: _decoration(
        label: label,
        icon: icon,
        hint: hint,
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      onTapOutside: (_) {},
      decoration: _decoration(
        label: label,
        icon: icon,
        hint: 'Pilih tanggal',
        suffixIcon: Icons.arrow_drop_down_rounded,
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.11)),
      ),
      child: Row(
        children: <Widget>[
          _iconBox(
            icon: icon,
            color: color,
            background: Colors.white,
            size: 37,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: softRed,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.error_outline_rounded, color: red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: red,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: adminPurple, size: 20),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, color: textGrey),
      filled: true,
      fillColor: const Color(0xffF8F9FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: adminPurple, width: 1.4),
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
}

class _ProgramBantuan {
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
  final DateTime? updatedAt;

  const _ProgramBantuan({
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
    required this.updatedAt,
  });
}

class _ProgramFormResult {
  final String name;
  final String period;
  final String fertilizer;
  final double packageKg;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String description;
  final String status;
  final bool sendNotification;

  const _ProgramFormResult({
    required this.name,
    required this.period,
    required this.fertilizer,
    required this.packageKg,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.description,
    required this.status,
    required this.sendNotification,
  });
}

class _ProgramStats {
  final int pending;
  final int approved;
  final int completed;
  final int rejected;

  const _ProgramStats({
    required this.pending,
    required this.approved,
    required this.completed,
    required this.rejected,
  });

  int get total => pending + approved + completed + rejected;
}

class _SummaryData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _MiniStatsData {
  final String label;
  final int value;
  final Color color;
  final Color background;

  const _MiniStatsData(
    this.label,
    this.value,
    this.color,
    this.background,
  );
}

class _FilterData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _FilterData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _AdminProgramBackground extends StatelessWidget {
  const _AdminProgramBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            final large = (base * 0.98).clamp(280.0, 470.0).toDouble();
            final medium = (base * 0.68).clamp(190.0, 335.0).toDouble();

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
                          Color(0xff172A46),
                          Color(0xff293E62),
                          Color(0xffE8EAF2),
                          Color(0xffF2F4F8),
                        ],
                        stops: <double>[0, 0.19, 0.45, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.55,
                    right: -large * 0.30,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(0xff6256A4),
                      alpha: 0.22,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.28,
                    left: -medium * 0.57,
                    child: _BackgroundCircle(
                      size: medium,
                      color: const Color(0xff6882A2),
                      alpha: 0.21,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.50,
                    right: -medium * 0.62,
                    child: _BackgroundCircle(
                      size: medium * 1.08,
                      color: const Color(0xffE7E0F6),
                      alpha: 0.80,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.31,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(0xffE2E8F2),
                      alpha: 0.85,
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

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _BackgroundCircle({
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
