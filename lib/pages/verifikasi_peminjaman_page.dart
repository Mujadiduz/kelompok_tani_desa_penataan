import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

const Color _adminNavy = Color(0xff172554);
const Color _adminIndigo = Color(0xff35469C);
const Color _adminPurple = Color(0xff6946C6);
const Color _adminBlue = Color(0xff326FA3);
const Color _adminTeal = Color(0xff167A6B);
const Color _adminGreen = Color(0xff2E7D32);
const Color _adminAmber = Color(0xffD98212);
const Color _adminRed = Color(0xffC83B3B);

const Color _pageBackground = Color(0xffF4F6FB);
const Color _cardBorder = Color(0xffE1E5EF);
const Color _textDark = Color(0xff18212B);
const Color _textGrey = Color(0xff66727F);
const Color _textSoft = Color(0xff8B96A2);

const Color _softPurple = Color(0xffF0EBFC);
const Color _softBlue = Color(0xffEAF3FA);
const Color _softGreen = Color(0xffE9F5EB);
const Color _softAmber = Color(0xffFFF3DD);
const Color _softRed = Color(0xffFBEAEA);

class VerifikasiPeminjamanPage extends StatefulWidget {
  const VerifikasiPeminjamanPage({super.key});

  @override
  State<VerifikasiPeminjamanPage> createState() =>
      _VerifikasiPeminjamanPageState();
}

class _VerifikasiPeminjamanPageState
    extends State<VerifikasiPeminjamanPage> {
  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference peminjamanRef;
  late final DatabaseReference alatRef;

  final TextEditingController _searchController =
      TextEditingController();

  String selectedFilter = 'menunggu';
  String _searchQuery = '';
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();

    peminjamanRef = db.ref('peminjaman_alat');
    alatRef = db.ref('alat_pertanian');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _stringMap(dynamic value) {
    if (value is! Map) {
      return {};
    }

    final source = Map<dynamic, dynamic>.from(value);

    return source.map(
      (key, item) => MapEntry(
        key.toString(),
        item,
      ),
    );
  }

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    final result = value?.toString().trim() ?? '';

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  int _intValue(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  String _normalStatus(
    Map<String, dynamic> item,
  ) {
    final status = _text(
      item['status'],
      fallback: 'menunggu',
    )
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if ({
      '',
      'pending',
      'diajukan',
      'pengajuan',
      'menunggu_verifikasi',
    }.contains(status)) {
      return 'menunggu';
    }

    if ({
      'approved',
      'siap_diambil',
    }.contains(status)) {
      return 'disetujui';
    }

    if ({
      'sedang_dipinjam',
      'digunakan',
    }.contains(status)) {
      return 'dipinjam';
    }

    if ({
      'selesai',
      'sudah_dikembalikan',
      'kembali',
    }.contains(status)) {
      return 'dikembalikan';
    }

    if (status == 'rejected') {
      return 'ditolak';
    }

    return status;
  }

  String _nik(
    Map<String, dynamic> item,
  ) {
    return _text(
      item['nik'] ??
          item['nik_anggota'] ??
          item['nik_user'] ??
          item['nikUser'],
      fallback: '',
    ).replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  String _name(
    Map<String, dynamic> item,
  ) {
    return _text(
      item['nama'] ??
          item['nama_anggota'] ??
          item['nama_user'] ??
          item['namaUser'],
      fallback: 'Anggota',
    );
  }

  String _equipmentName(
    Map<String, dynamic> item,
  ) {
    return _text(
      item['alat'] ??
          item['nama_alat'] ??
          item['namaAlat'] ??
          item['jenis_alat'],
      fallback: 'Alat pertanian',
    );
  }

  String _equipmentId(
    Map<String, dynamic> item,
  ) {
    return _text(
      item['id_alat'] ??
          item['alat_id'] ??
          item['idAlat'],
      fallback: '',
    );
  }

  int _quantity(
    Map<String, dynamic> item,
  ) {
    return _intValue(
      item['jumlah'] ??
          item['jumlah_alat'],
      fallback: 1,
    );
  }

  DateTime _parseDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (value is num) {
      try {
        final number = value.toInt();

        return DateTime.fromMillisecondsSinceEpoch(
          number.toString().length >= 13
              ? number
              : number * 1000,
        ).toLocal();
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final raw = value.toString().trim();

    if (raw.isEmpty || raw == '-') {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return DateTime(
        value.year,
        value.month,
        value.day,
      );
    }

    final raw = value.toString().trim();

    if (raw.isEmpty || raw == '-') {
      return null;
    }

    final dateOnly = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(raw);

    if (dateOnly != null) {
      return DateTime(
        int.parse(dateOnly.group(1)!),
        int.parse(dateOnly.group(2)!),
        int.parse(dateOnly.group(3)!),
      );
    }

    final reverseDate = RegExp(
      r'^(\d{2})[-/](\d{2})[-/](\d{4})$',
    ).firstMatch(raw);

    if (reverseDate != null) {
      return DateTime(
        int.parse(reverseDate.group(3)!),
        int.parse(reverseDate.group(2)!),
        int.parse(reverseDate.group(1)!),
      );
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return null;
    }

    final local = parsed.toLocal();

    return DateTime(
      local.year,
      local.month,
      local.day,
    );
  }

  String _twoDigits(
    int value,
  ) {
    return value.toString().padLeft(2, '0');
  }

  String _databaseDate(
    DateTime date,
  ) {
    return '${date.year}-'
        '${_twoDigits(date.month)}-'
        '${_twoDigits(date.day)}';
  }

  String _time(
    DateTime date,
  ) {
    return '${_twoDigits(date.hour)}:'
        '${_twoDigits(date.minute)}';
  }

  String _displayDate(
    dynamic value,
  ) {
    final date = _parseDate(value);

    if (date == null) {
      return _text(value);
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${_twoDigits(date.day)} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _displayDateTime(
    dynamic value,
  ) {
    final date = _parseDateTime(value);

    if (date.millisecondsSinceEpoch == 0) {
      return '-';
    }

    return '${_twoDigits(date.day)}/'
        '${_twoDigits(date.month)}/'
        '${date.year} • ${_time(date)}';
  }

  String _maskedNik(
    String nik,
  ) {
    final clean = nik.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length <= 4) {
      return nik.isEmpty ? '-' : nik;
    }

    return '•••• •••• •••• '
        '${clean.substring(clean.length - 4)}';
  }

  String _statusText(
    String status,
  ) {
    if (status == 'disetujui') {
      return 'Disetujui';
    }

    if (status == 'dipinjam') {
      return 'Dipinjam';
    }

    if (status == 'dikembalikan') {
      return 'Dikembalikan';
    }

    if (status == 'ditolak') {
      return 'Ditolak';
    }

    return 'Menunggu';
  }

  Color _statusColor(
    String status,
  ) {
    if (status == 'disetujui') {
      return _adminBlue;
    }

    if (status == 'dipinjam') {
      return _adminPurple;
    }

    if (status == 'dikembalikan') {
      return _adminGreen;
    }

    if (status == 'ditolak') {
      return _adminRed;
    }

    return _adminAmber;
  }

  Color _statusBackground(
    String status,
  ) {
    if (status == 'disetujui') {
      return _softBlue;
    }

    if (status == 'dipinjam') {
      return _softPurple;
    }

    if (status == 'dikembalikan') {
      return _softGreen;
    }

    if (status == 'ditolak') {
      return _softRed;
    }

    return _softAmber;
  }

  IconData _statusIcon(
    String status,
  ) {
    if (status == 'disetujui') {
      return Icons.verified_outlined;
    }

    if (status == 'dipinjam') {
      return Icons.outbox_outlined;
    }

    if (status == 'dikembalikan') {
      return Icons.assignment_turned_in_outlined;
    }

    if (status == 'ditolak') {
      return Icons.block_outlined;
    }

    return Icons.schedule_outlined;
  }

  IconData _equipmentIcon(
    String value,
  ) {
    final name = value.toLowerCase();

    if (name.contains('sprayer') ||
        name.contains('semprot')) {
      return Icons.water_drop_outlined;
    }

    if (name.contains('cangkul')) {
      return Icons.handyman_outlined;
    }

    if (name.contains('traktor')) {
      return Icons.agriculture_rounded;
    }

    if (name.contains('pompa')) {
      return Icons.water_outlined;
    }

    if (name.contains('mesin')) {
      return Icons.precision_manufacturing_outlined;
    }

    return Icons.construction_outlined;
  }

  Color _equipmentColor(
    String value,
  ) {
    final name = value.toLowerCase();

    if (name.contains('sprayer') ||
        name.contains('semprot')) {
      return _adminBlue;
    }

    if (name.contains('cangkul')) {
      return _adminAmber;
    }

    if (name.contains('traktor')) {
      return _adminGreen;
    }

    if (name.contains('pompa')) {
      return _adminTeal;
    }

    return _adminPurple;
  }

  List<MapEntry<String, dynamic>> _loanList(
    dynamic value,
  ) {
    if (value is! Map) {
      return [];
    }

    final result =
        <MapEntry<String, dynamic>>[];

    for (final entry
        in Map<dynamic, dynamic>.from(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      result.add(
        MapEntry(
          entry.key.toString(),
          _stringMap(entry.value),
        ),
      );
    }

    result.sort(
      (
        first,
        second,
      ) {
        final firstDate = _parseDateTime(
          first.value['tanggal_pengajuan'] ??
              first.value['tanggal_verifikasi'] ??
              first.value['tanggal_diambil'],
        );

        final secondDate = _parseDateTime(
          second.value['tanggal_pengajuan'] ??
              second.value['tanggal_verifikasi'] ??
              second.value['tanggal_diambil'],
        );

        return secondDate.compareTo(firstDate);
      },
    );

    return result;
  }

  Map<String, int> _statusCounts(
    List<MapEntry<String, dynamic>> data,
  ) {
    final result = <String, int>{
      'semua': data.length,
      'menunggu': 0,
      'disetujui': 0,
      'dipinjam': 0,
      'dikembalikan': 0,
      'ditolak': 0,
    };

    for (final entry in data) {
      final status = _normalStatus(
        entry.value,
      );

      if (result.containsKey(status)) {
        result[status] =
            (result[status] ?? 0) + 1;
      }
    }

    return result;
  }

  List<MapEntry<String, dynamic>> _filteredLoans(
    List<MapEntry<String, dynamic>> data,
  ) {
    final query =
        _searchQuery.trim().toLowerCase();

    return data.where(
      (entry) {
        final item = entry.value;
        final status = _normalStatus(item);

        if (selectedFilter != 'semua' &&
            status != selectedFilter) {
          return false;
        }

        if (query.isEmpty) {
          return true;
        }

        final name =
            _name(item).toLowerCase();

        final nik =
            _nik(item).toLowerCase();

        final equipment =
            _equipmentName(item).toLowerCase();

        final start = _text(
          item['tanggal_pinjam'],
        ).toLowerCase();

        final end = _text(
          item['tanggal_kembali'],
        ).toLowerCase();

        return name.contains(query) ||
            nik.contains(query) ||
            equipment.contains(query) ||
            start.contains(query) ||
            end.contains(query);
      },
    ).toList();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      peminjamanRef.get(),
      alatRef.get(),
    ]);
  }

  _LateResult _calculateLateness(
    String returnDate,
    DateTime actual,
  ) {
    final planned =
        _parseDate(returnDate);

    if (planned == null) {
      return const _LateResult(
        status: 'tidak_diketahui',
        lateDays: 0,
      );
    }

    final plannedDate = DateTime(
      planned.year,
      planned.month,
      planned.day,
    );

    final actualDate = DateTime(
      actual.year,
      actual.month,
      actual.day,
    );

    final difference = actualDate
        .difference(plannedDate)
        .inDays;

    if (difference > 0) {
      return _LateResult(
        status: 'terlambat',
        lateDays: difference,
      );
    }

    return const _LateResult(
      status: 'tepat_waktu',
      lateDays: 0,
    );
  }

  String _returnStatusText(
    Map<String, dynamic> item,
  ) {
    final status = _text(
      item['status_pengembalian'],
      fallback: '',
    ).toLowerCase();

    if (status == 'terlambat') {
      return 'Terlambat '
          '${_intValue(item['jumlah_hari_terlambat'])} hari';
    }

    if (status == 'tepat_waktu') {
      return 'Tepat waktu';
    }

    return 'Belum diketahui';
  }

  Color _returnStatusColor(
    Map<String, dynamic> item,
  ) {
    final status = _text(
      item['status_pengembalian'],
      fallback: '',
    ).toLowerCase();

    if (status == 'terlambat') {
      return _adminRed;
    }

    if (status == 'tepat_waktu') {
      return _adminGreen;
    }

    return _textGrey;
  }

  int _borrowedByEquipmentId(
    String equipmentId,
    Map<dynamic, dynamic> data, {
    required String currentId,
  }) {
    int total = 0;

    for (final entry in data.entries) {
      if (entry.key.toString() == currentId ||
          entry.value is! Map) {
        continue;
      }

      final item =
          _stringMap(entry.value);

      final itemEquipmentId =
          _equipmentId(item);

      final status =
          _normalStatus(item);

      if (itemEquipmentId == equipmentId &&
          status == 'dipinjam') {
        total += _quantity(item);
      }
    }

    return total;
  }

  Future<void> _updateStatus(
    String id,
    String status,
    Map<String, dynamic> item,
  ) async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      await peminjamanRef.child(id).update({
        'status': status,
        'tanggal_verifikasi':
            DateTime.now().toIso8601String(),
      }).timeout(
        const Duration(seconds: 15),
      );

      final nik = _nik(item);

      final equipment =
          _equipmentName(item);

      try {
        if (status == 'disetujui') {
          await NotificationHelper.alatDisetujui(
            nik: nik,
            namaAlat: equipment,
            eventId: '${id}_disetujui',
          );
        } else if (status == 'ditolak') {
          await NotificationHelper.alatDitolak(
            nik: nik,
            namaAlat: equipment,
            eventId: '${id}_ditolak',
          );
        }
      } catch (error) {
        debugPrint(
          'Status peminjaman tersimpan, tetapi notifikasi user gagal: $error',
        );
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        status == 'disetujui'
            ? 'Peminjaman berhasil disetujui.'
            : 'Peminjaman berhasil ditolak.',
        status == 'disetujui'
            ? _adminGreen
            : _adminRed,
      );
    } catch (error) {
      debugPrint(
        'Gagal mengubah status: $error',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal mengubah status peminjaman.',
        _adminRed,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _markBorrowed(
    String id,
    Map<String, dynamic> item,
  ) async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final equipmentId =
          _equipmentId(item);

      final equipmentName =
          _equipmentName(item);

      final quantity =
          _quantity(item);

      final nik =
          _nik(item);

      if (equipmentId.isEmpty) {
        throw Exception(
          'ID alat tidak ditemukan pada data peminjaman.',
        );
      }

      final equipmentSnapshot =
          await alatRef.child(equipmentId).get();

      if (!equipmentSnapshot.exists ||
          equipmentSnapshot.value is! Map) {
        throw Exception(
          'Data alat tidak ditemukan.',
        );
      }

      final loanSnapshot =
          await peminjamanRef.get();

      final equipmentData =
          _stringMap(
        equipmentSnapshot.value,
      );

      final totalUnit = _intValue(
        equipmentData['jumlah_unit'] ??
            equipmentData['stok'] ??
            equipmentData['stok_unit'] ??
            equipmentData['jumlah'],
      );

      final loanData =
          loanSnapshot.exists &&
                  loanSnapshot.value is Map
              ? Map<dynamic, dynamic>.from(
                  loanSnapshot.value as Map,
                )
              : <dynamic, dynamic>{};

      final borrowed =
          _borrowedByEquipmentId(
        equipmentId,
        loanData,
        currentId: id,
      );

      final available =
          totalUnit - borrowed;

      if (available < quantity) {
        throw Exception(
          'Unit tidak mencukupi. Tersedia '
          '${available < 0 ? 0 : available} unit.',
        );
      }

      final now = DateTime.now();

      await peminjamanRef.child(id).update({
        'status': 'dipinjam',
        'tanggal_diambil':
            _databaseDate(now),
        'waktu_diambil':
            _time(now),
        'alat': equipmentName,
      }).timeout(
        const Duration(seconds: 15),
      );

      try {
        await NotificationHelper.alatDipinjam(
          nik: nik,
          namaAlat: equipmentName,
          jumlah: quantity,
          eventId: '${id}_dipinjam',
        );
      } catch (error) {
        debugPrint(
          'Status alat dipinjam tersimpan, tetapi notifikasi user gagal: $error',
        );
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Alat berhasil ditandai dipinjam.',
        _adminGreen,
      );
    } catch (error) {
      debugPrint(
        'Gagal menandai dipinjam: $error',
      );

      if (!mounted) {
        return;
      }

      final message = error
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      _showSnackBar(
        message.isEmpty
            ? 'Gagal menandai alat dipinjam.'
            : message,
        _adminRed,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _markReturned(
    String id,
    Map<String, dynamic> item,
  ) async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final now = DateTime.now();

      final plannedReturn = _text(
        item['tanggal_kembali'],
      );

      final result = _calculateLateness(
        plannedReturn,
        now,
      );

      final nik = _nik(item);

      final equipmentName =
          _equipmentName(item);

      await peminjamanRef.child(id).update({
        'status': 'dikembalikan',
        'tanggal_dikembalikan':
            _databaseDate(now),
        'waktu_dikembalikan':
            _time(now),
        'status_pengembalian':
            result.status,
        'jumlah_hari_terlambat':
            result.lateDays,
      }).timeout(
        const Duration(seconds: 15),
      );

      final additionalMessage =
          result.status == 'terlambat'
              ? ' Pengembalian terlambat '
                  '${result.lateDays} hari.'
              : ' Pengembalian tepat waktu.';

      try {
        await NotificationHelper.alatDikembalikan(
          nik: nik,
          namaAlat: equipmentName,
          pesanTambahan: additionalMessage,
          eventId: '${id}_dikembalikan',
        );
      } catch (error) {
        debugPrint(
          'Status alat dikembalikan tersimpan, tetapi notifikasi user gagal: $error',
        );
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        result.status == 'terlambat'
            ? 'Alat dikembalikan terlambat '
                '${result.lateDays} hari.'
            : 'Alat berhasil dikembalikan tepat waktu.',
        result.status == 'terlambat'
            ? _adminAmber
            : _adminGreen,
      );
    } catch (error) {
      debugPrint(
        'Gagal menandai pengembalian: $error',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal menandai alat dikembalikan.',
        _adminRed,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmVerification({
    required String id,
    required String status,
    required Map<String, dynamic> item,
  }) async {
    final approve =
        status == 'disetujui';

    final memberName =
        _name(item);

    final equipmentName =
        _equipmentName(item);

    final confirmed =
        await _showConfirmDialog(
      icon: approve
          ? Icons.verified_outlined
          : Icons.block_outlined,
      iconColor: approve
          ? _adminGreen
          : _adminRed,
      title: approve
          ? 'Setujui Peminjaman?'
          : 'Tolak Peminjaman?',
      message: approve
          ? 'Pengajuan $equipmentName dari '
              '$memberName akan disetujui.'
          : 'Pengajuan $equipmentName dari '
              '$memberName akan ditolak.',
      confirmText:
          approve ? 'Setujui' : 'Tolak',
      confirmColor: approve
          ? _adminGreen
          : _adminRed,
    );

    if (!mounted ||
        confirmed != true) {
      return;
    }

    await _updateStatus(
      id,
      status,
      item,
    );
  }

  Future<void> _confirmBorrowed({
    required String id,
    required Map<String, dynamic> item,
  }) async {
    final memberName =
        _name(item);

    final equipmentName =
        _equipmentName(item);

    final confirmed =
        await _showConfirmDialog(
      icon: Icons.outbox_outlined,
      iconColor: _adminPurple,
      title: 'Tandai Dipinjam?',
      message:
          'Pastikan $memberName sudah mengambil '
          '$equipmentName. Sistem akan memeriksa '
          'jumlah unit yang masih tersedia.',
      confirmText: 'Ya, Dipinjam',
      confirmColor: _adminPurple,
    );

    if (!mounted ||
        confirmed != true) {
      return;
    }

    await _markBorrowed(
      id,
      item,
    );
  }

  Future<void> _confirmReturned({
    required String id,
    required Map<String, dynamic> item,
  }) async {
    final memberName =
        _name(item);

    final equipmentName =
        _equipmentName(item);

    final confirmed =
        await _showConfirmDialog(
      icon:
          Icons.assignment_turned_in_outlined,
      iconColor: _adminGreen,
      title: 'Tandai Dikembalikan?',
      message:
          'Pastikan $memberName sudah '
          'mengembalikan $equipmentName. '
          'Ketepatan pengembalian akan dihitung.',
      confirmText: 'Ya, Kembali',
      confirmColor: _adminGreen,
    );

    if (!mounted ||
        confirmed != true) {
      return;
    }

    await _markReturned(
      id,
      item,
    );
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
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth =
            MediaQuery.sizeOf(
          dialogContext,
        ).width;

        return Dialog(
          insetPadding:
              EdgeInsets.symmetric(
            horizontal:
                screenWidth < 350 ? 16 : 24,
          ),
          backgroundColor:
              Colors.transparent,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 420,
            ),
            child: Container(
              padding:
                  const EdgeInsets.fromLTRB(
                19,
                22,
                19,
                18,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(24),
                border:
                    Border.all(
                  color: _cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        _adminNavy.withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 28,
                    offset:
                        const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  _dialogIcon(
                    icon: icon,
                    color: iconColor,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: _textDark,
                      fontSize: 17.5,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    message,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      color: _textGrey,
                      fontSize: 10.8,
                      height: 1.45,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 19),
                  LayoutBuilder(
                    builder: (
                      context,
                      constraints,
                    ) {
                      final compact =
                          constraints
                                  .maxWidth <
                              300;

                      final cancelButton =
                          SizedBox(
                        height: 46,
                        child:
                            OutlinedButton(
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop(false);
                          },
                          style: OutlinedButton
                              .styleFrom(
                            foregroundColor:
                                _textGrey,
                            side:
                                const BorderSide(
                              color:
                                  _cardBorder,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          child:
                              const Text(
                            'Batal',
                            style:
                                TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w800,
                            ),
                          ),
                        ),
                      );

                      final confirmButton =
                          SizedBox(
                        height: 46,
                        child:
                            ElevatedButton(
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop(true);
                          },
                          style: ElevatedButton
                              .styleFrom(
                            backgroundColor:
                                confirmColor,
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),
                        ),
                      );

                      if (compact) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double
                                  .infinity,
                              child:
                                  confirmButton,
                            ),
                            const SizedBox(
                              height: 9,
                            ),
                            SizedBox(
                              width: double
                                  .infinity,
                              child:
                                  cancelButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child:
                                cancelButton,
                          ),
                          const SizedBox(
                            width: 9,
                          ),
                          Expanded(
                            child:
                                confirmButton,
                          ),
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

  Widget _dialogIcon({
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(
            alpha: 0.13,
          ),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 32,
      ),
    );
  }

  void _showSnackBar(
    String message,
    Color color,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.fixed,
        ),
      );
  }


  @override
  Widget build(
    BuildContext context,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 340 ? 13.0 : 17.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _VerificationBackground(),
              SafeArea(
                child: StreamBuilder<DatabaseEvent>(
                  stream: peminjamanRef.onValue,
                  builder: (context, snapshot) {
                    final allLoans = _loanList(
                      snapshot.data?.snapshot.value,
                    );
                    final counts = _statusCounts(allLoans);
                    final filteredLoans = _filteredLoans(allLoans);
                    final pending = counts['menunggu'] ?? 0;

                    return RefreshIndicator(
                      color: _adminPurple,
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
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _header(pending),
                                  const SizedBox(height: 13),
                                  _filterPanel(counts),
                                  const SizedBox(height: 10),
                                  _searchField(),
                                  const SizedBox(height: 10),
                                  _pendingInformation(pending),
                                  const SizedBox(height: 16),
                                  _sectionTitle(filteredLoans.length),
                                  const SizedBox(height: 10),
                                  _content(
                                    snapshot: snapshot,
                                    allLoans: allLoans,
                                    filteredLoans: filteredLoans,
                                  ),
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
              if (isProcessing) _processingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int pending) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 13, 14, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _adminNavy,
            Color(0xff294762),
            _adminPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _adminNavy.withValues(alpha: 0.24),
            blurRadius: 23,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              top: -58,
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                _backButton(),
                const SizedBox(width: 10),
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.19),
                    ),
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifikasi Peminjaman',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Aktivitas alat pertanian desa',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xffDFE5F0),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                _headerCounter(pending),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCounter(int total) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 40,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.19),
        ),
      ),
      child: Column(
        children: [
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
            'baru',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.77),
              fontSize: 8.6,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPanel(
    Map<String, int> counts,
  ) {
    final filters = [
      _FilterItem(
        label: 'Menunggu',
        value: 'menunggu',
        total: counts['menunggu'] ?? 0,
        icon: Icons.pending_actions_outlined,
        color: _adminAmber,
      ),
      _FilterItem(
        label: 'Disetujui',
        value: 'disetujui',
        total: counts['disetujui'] ?? 0,
        icon: Icons.verified_outlined,
        color: _adminBlue,
      ),
      _FilterItem(
        label: 'Dipinjam',
        value: 'dipinjam',
        total: counts['dipinjam'] ?? 0,
        icon: Icons.outbox_outlined,
        color: _adminPurple,
      ),
      _FilterItem(
        label: 'Kembali',
        value: 'dikembalikan',
        total: counts['dikembalikan'] ?? 0,
        icon: Icons.assignment_turned_in_outlined,
        color: _adminGreen,
      ),
      _FilterItem(
        label: 'Ditolak',
        value: 'ditolak',
        total: counts['ditolak'] ?? 0,
        icon: Icons.block_outlined,
        color: _adminRed,
      ),
      _FilterItem(
        label: 'Semua',
        value: 'semua',
        total: counts['semua'] ?? 0,
        icon: Icons.grid_view_rounded,
        color: _adminIndigo,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _cardDecoration(radius: 19),
      child: SizedBox(
        height: 39,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final active = selectedFilter == filter.value;

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedFilter = filter.value;
                  });
                },
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? filter.color
                        : filter.color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? filter.color
                          : filter.color.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        color: active ? Colors.white : filter.color,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        filter.label,
                        style: TextStyle(
                          color: active ? Colors.white : _textDark,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 19,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          filter.total > 99
                              ? '99+'
                              : filter.total.toString(),
                          style: TextStyle(
                            color: active ? Colors.white : filter.color,
                            fontSize: 8,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _searchField() {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari nama, NIK, alat, atau tanggal',
          hintStyle: const TextStyle(
            color: _textSoft,
            fontSize: 10.2,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _adminPurple,
            size: 19,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _textGrey,
                    size: 18,
                  ),
                ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.98),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: _adminPurple,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pendingInformation(int pending) {
    final clear = pending == 0;
    final color = clear ? _adminGreen : _adminAmber;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: clear ? _softGreen : _softAmber,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 37,
            width: 37,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              clear
                  ? Icons.task_alt_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              clear
                  ? 'Semua pengajuan peminjaman sudah diproses.'
                  : '$pending pengajuan menunggu keputusan admin.',
              style: const TextStyle(
                color: _textGrey,
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

  Widget _sectionTitle(int count) {
    return Row(
      children: [
        Container(
          height: 31,
          width: 5,
          decoration: BoxDecoration(
            color: _adminPurple,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktivitas Peminjaman',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Verifikasi dan ubah status secara bertahap.',
                style: TextStyle(
                  color: _textGrey,
                  fontSize: 10.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _softPurple,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count data',
            style: const TextStyle(
              color: _adminPurple,
              fontSize: 8.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _content({
    required AsyncSnapshot<DatabaseEvent> snapshot,
    required List<MapEntry<String, dynamic>> allLoans,
    required List<MapEntry<String, dynamic>> filteredLoans,
  }) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: CircularProgressIndicator(
            color: _adminPurple,
            strokeWidth: 2.8,
          ),
        ),
      );
    }

    if (snapshot.hasError) {
      return _messageState(
        icon: Icons.cloud_off_outlined,
        title: 'Data Tidak Dapat Dimuat',
        message:
            'Periksa koneksi internet lalu tarik halaman ke bawah.',
        color: _adminRed,
        background: _softRed,
      );
    }

    if (allLoans.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Peminjaman',
        message:
            'Pengajuan peminjaman alat belum tersedia.',
        color: _adminPurple,
        background: _softPurple,
      );
    }

    if (filteredLoans.isEmpty) {
      return _messageState(
        icon: Icons.search_off_rounded,
        title: 'Data Tidak Ditemukan',
        message:
            'Tidak ada peminjaman yang sesuai dengan filter atau pencarian.',
        color: _adminAmber,
        background: _softAmber,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        const gap = 10.0;
        final itemWidth = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: filteredLoans.map((entry) {
            return SizedBox(
              width: itemWidth,
              child: _loanCard(
                id: entry.key,
                item: entry.value,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _loanCard({
    required String id,
    required Map<String, dynamic> item,
  }) {
    final status = _normalStatus(item);
    final name = _name(item);
    final nik = _nik(item);
    final equipment = _equipmentName(item);
    final equipmentColor = _equipmentColor(equipment);
    final quantity = _quantity(item);

    final startDate = _displayDate(
      item['tanggal_pinjam'] ??
          item['tanggal_mulai'] ??
          item['tanggal_pengambilan'],
    );
    final returnDate = _displayDate(
      item['tanggal_kembali'] ??
          item['tanggal_selesai'] ??
          item['batas_pengembalian'],
    );
    final submittedAt = _displayDateTime(
      item['tanggal_pengajuan'],
    );
    final note = _text(
      item['catatan'],
      fallback: '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: equipmentColor.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _equipmentIcon(equipment),
                  color: equipmentColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 13.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$name • ${_maskedNik(nik)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 10),
          _activityStrip(status),
          const SizedBox(height: 10),
          _dataBox(
            children: [
              _detailRow(
                icon: Icons.date_range_outlined,
                label: 'Jadwal',
                value: '$startDate — $returnDate',
              ),
              _detailRow(
                icon: Icons.inventory_2_outlined,
                label: 'Jumlah',
                value: '$quantity unit',
                valueColor: equipmentColor,
              ),
              _detailRow(
                icon: Icons.schedule_outlined,
                label: 'Diajukan',
                value: submittedAt,
              ),
              if (status == 'dikembalikan')
                _detailRow(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Pengembalian',
                  value: _returnStatusText(item),
                  valueColor: _returnStatusColor(item),
                ),
              if (note.isNotEmpty)
                _detailRow(
                  icon: Icons.notes_outlined,
                  label: 'Catatan',
                  value: note,
                ),
            ],
          ),
          if (_hasActions(status)) ...[
            const SizedBox(height: 10),
            _actionArea(
              id: id,
              item: item,
              status: status,
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityStrip(String status) {
    final labels = const [
      'Diajukan',
      'Disetujui',
      'Dipinjam',
      'Kembali',
    ];

    int currentIndex;
    if (status == 'disetujui') {
      currentIndex = 1;
    } else if (status == 'dipinjam') {
      currentIndex = 2;
    } else if (status == 'dikembalikan') {
      currentIndex = 3;
    } else {
      currentIndex = 0;
    }

    final rejected = status == 'ditolak';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(labels.length, (index) {
              final completed = !rejected && index <= currentIndex;
              final rejectedNode = rejected && index == 0;
              final nodeColor = rejectedNode
                  ? _adminRed
                  : completed
                      ? _adminPurple
                      : _cardBorder;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      height: 23,
                      width: 23,
                      decoration: BoxDecoration(
                        color: nodeColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        rejectedNode
                            ? Icons.close_rounded
                            : completed
                                ? Icons.check_rounded
                                : Icons.circle,
                        color: completed || rejectedNode
                            ? Colors.white
                            : _textSoft,
                        size: completed || rejectedNode ? 11 : 5,
                      ),
                    ),
                    if (index < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 3,
                          ),
                          color: rejected
                              ? _cardBorder
                              : index < currentIndex
                                  ? _adminPurple
                                  : _cardBorder,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Row(
            children: labels.map((label) {
              return Expanded(
                child: Text(
                  rejected && label == 'Diajukan'
                      ? 'Ditolak'
                      : label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: rejected && label == 'Diajukan'
                        ? _adminRed
                        : _textGrey,
                    fontSize: 7.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dataBox({
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        11,
        10,
        11,
        2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _adminPurple,
            size: 15,
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: _textGrey,
                fontSize: 9.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? _textDark,
                fontSize: 10.2,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 89),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _statusColor(status).withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(status),
            color: _statusColor(status),
            size: 10.5,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _statusText(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _statusColor(status),
                fontSize: 7.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActions(
    String status,
  ) {
    return {
      'menunggu',
      'disetujui',
      'dipinjam',
    }.contains(status);
  }

  Widget _actionArea({
    required String id,
    required Map<String, dynamic> item,
    required String status,
  }) {
    if (status == 'menunggu') {
      return LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 300;

          final approveButton = _actionButton(
            label: 'Setujui',
            icon: Icons.check_rounded,
            color: _adminGreen,
            onPressed: () {
              _confirmVerification(
                id: id,
                status: 'disetujui',
                item: item,
              );
            },
          );

          final rejectButton = _actionButton(
            label: 'Tolak',
            icon: Icons.close_rounded,
            color: _adminRed,
            outlined: true,
            onPressed: () {
              _confirmVerification(
                id: id,
                status: 'ditolak',
                item: item,
              );
            },
          );

          if (compact) {
            return Column(
              children: [
                approveButton,
                const SizedBox(height: 8),
                rejectButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: rejectButton),
              const SizedBox(width: 8),
              Expanded(child: approveButton),
            ],
          );
        },
      );
    }

    if (status == 'disetujui') {
      return _actionButton(
        label: 'Tandai Sudah Dipinjam',
        icon: Icons.outbox_outlined,
        color: _adminPurple,
        onPressed: () {
          _confirmBorrowed(
            id: id,
            item: item,
          );
        },
      );
    }

    return _actionButton(
      label: 'Tandai Sudah Dikembalikan',
      icon: Icons.assignment_turned_in_outlined,
      color: _adminGreen,
      onPressed: () {
        _confirmReturned(
          id: id,
          item: item,
        );
      },
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: isProcessing ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(
                  color: color.withValues(alpha: 0.22),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: Icon(icon, size: 16),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: isProcessing ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    color.withValues(alpha: 0.30),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: Icon(icon, size: 16),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 28,
      ),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 10,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _processingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: _adminNavy.withValues(alpha: 0.28),
          alignment: Alignment.center,
          child: Container(
            height: 74,
            width: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: _adminPurple,
              strokeWidth: 2.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: isProcessing
            ? null
            : () {
                FocusScope.of(context).unfocus();
                Navigator.maybePop(context);
              },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: _adminNavy.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 6),
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

class _LateResult {
  final String status;
  final int lateDays;

  const _LateResult({
    required this.status,
    required this.lateDays,
  });
}

class _VerificationBackground extends StatelessWidget {
  const _VerificationBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            final large = (base * 0.98)
                .clamp(280.0, 470.0)
                .toDouble();
            final medium = (base * 0.67)
                .clamp(190.0, 330.0)
                .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xff172A46),
                          Color(0xff294762),
                          Color(0xffE8EBF2),
                          Color(0xffF2F4F8),
                        ],
                        stops: [
                          0,
                          0.18,
                          0.43,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.55,
                    right: -large * 0.30,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(0xff7367B5),
                      alpha: 0.20,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.31,
                    left: -medium * 0.58,
                    child: _BackgroundCircle(
                      size: medium,
                      color: const Color(0xffB9B1DD),
                      alpha: 0.30,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.31,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(0xffE6E3F2),
                      alpha: 0.82,
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