import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'alat_form_page.dart';

class KoordinasiJadwalPage extends StatefulWidget {
  final String idAlat;
  final String namaAlat;
  final String nama;
  final String nik;

  const KoordinasiJadwalPage({
    super.key,
    required this.idAlat,
    required this.namaAlat,
    required this.nama,
    required this.nik,
  });

  @override
  State<KoordinasiJadwalPage> createState() =>
      _KoordinasiJadwalPageState();
}

class _KoordinasiJadwalPageState extends State<KoordinasiJadwalPage> {
  static const Color primary = Color(0xff2E7D32);
  static const Color dark = Color(0xff14532D);
  static const Color teal = Color(0xff167A6B);
  static const Color deepTeal = Color(0xff0E5F57);
  static const Color blue = Color(0xff326FA3);
  static const Color amber = Color(0xffD98212);
  static const Color red = Color(0xffC83B3B);

  static const Color background = Color(0xffF2F7F5);
  static const Color border = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);

  static const List<String> _monthNames = [
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

  static const List<String> _dayNames = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  final DateTime _now = DateTime.now();

  DateTime? _selectedDate;

  final DatabaseReference _loanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('peminjaman_alat');

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value is! Map) {
      return {};
    }

    return Map<dynamic, dynamic>.from(value);
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

  String _normalizedStatus(dynamic value) {
    final status = _text(
      value,
      fallback: '',
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

  DateTime? _parseDate(dynamic value) {
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

    if (value is num) {
      try {
        final number = value.toInt();

        final date = DateTime.fromMillisecondsSinceEpoch(
          number.toString().length >= 13
              ? number
              : number * 1000,
        ).toLocal();

        return DateTime(
          date.year,
          date.month,
          date.day,
        );
      } catch (_) {
        return null;
      }
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

  DateTime _dateOnly(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  String _databaseDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')} '
        '${_monthNames[value.month - 1]} ${value.year}';
  }

  String _maskedNik(String value) {
    final clean = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length <= 4) {
      return value;
    }

    return '•••• •••• •••• '
        '${clean.substring(clean.length - 4)}';
  }

  int _daysInCurrentMonth() {
    return DateTime(
      _now.year,
      _now.month + 1,
      0,
    ).day;
  }

  int _firstWeekdayOffset() {
    return DateTime(
          _now.year,
          _now.month,
          1,
        ).weekday -
        1;
  }

  String _currentMonthLabel() {
    return '${_monthNames[_now.month - 1]} ${_now.year}';
  }

  List<Map<String, dynamic>> _loanList(dynamic value) {
    final result = <Map<String, dynamic>>[];

    for (final entry in _asMap(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(
        entry.value as Map,
      );

      item['id_peminjaman'] = entry.key.toString();

      result.add(item);
    }

    return result;
  }

  bool _sameEquipment(Map<String, dynamic> item) {
    final itemId = _text(
      item['id_alat'] ??
          item['alat_id'] ??
          item['idAlat'],
      fallback: '',
    );

    if (itemId.isNotEmpty) {
      return itemId == widget.idAlat;
    }

    final itemName = _text(
      item['alat'] ??
          item['nama_alat'] ??
          item['namaAlat'],
      fallback: '',
    );

    return itemName.toLowerCase().trim() ==
        widget.namaAlat.toLowerCase().trim();
  }

  bool _blocksSchedule(String status) {
    return {
      'menunggu',
      'disetujui',
      'dipinjam',
    }.contains(status);
  }

  Map<String, dynamic>? _loanOnDate(
    DateTime date,
    List<Map<String, dynamic>> loans,
  ) {
    final target = _dateOnly(date);

    for (final item in loans) {
      if (!_sameEquipment(item)) {
        continue;
      }

      final status = _normalizedStatus(
        item['status'],
      );

      if (!_blocksSchedule(status)) {
        continue;
      }

      final start = _parseDate(
        item['tanggal_pinjam'] ??
            item['tanggal_mulai'] ??
            item['tanggal_pengambilan'],
      );

      final end = _parseDate(
            item['tanggal_kembali'] ??
                item['tanggal_selesai'] ??
                item['batas_pengembalian'],
          ) ??
          start;

      if (start == null || end == null) {
        continue;
      }

      final from = _dateOnly(start);
      final until = _dateOnly(end);

      final afterStart =
          target.isAtSameMomentAs(from) ||
              target.isAfter(from);

      final beforeEnd =
          target.isAtSameMomentAs(until) ||
              target.isBefore(until);

      if (afterStart && beforeEnd) {
        return item;
      }
    }

    return null;
  }

  bool _isPast(DateTime date) {
    return _dateOnly(date).isBefore(
      _dateOnly(_now),
    );
  }

  bool _canSelect(
    DateTime date,
    List<Map<String, dynamic>> loans,
  ) {
    if (_isPast(date)) {
      return false;
    }

    return _loanOnDate(
          date,
          loans,
        ) ==
        null;
  }

  String _dateMessage(
    DateTime date,
    List<Map<String, dynamic>> loans,
  ) {
    if (_isPast(date)) {
      return 'Tanggal sudah lewat.';
    }

    final item = _loanOnDate(
      date,
      loans,
    );

    if (item == null) {
      return 'Tanggal tersedia.';
    }

    final status = _normalizedStatus(
      item['status'],
    );

    if (status == 'menunggu') {
      return 'Tanggal sedang menunggu persetujuan admin.';
    }

    if (status == 'disetujui') {
      return 'Tanggal sudah disetujui untuk peminjaman lain.';
    }

    return 'Tanggal sedang digunakan oleh peminjam lain.';
  }

  _DateVisual _dateVisual(
    DateTime date,
    List<Map<String, dynamic>> loans,
  ) {
    if (_isPast(date)) {
      return const _DateVisual(
        color: Color(0xffCBD5E1),
        background: Color(0xffF1F4F6),
        foreground: Color(0xff8B96A2),
      );
    }

    final item = _loanOnDate(
      date,
      loans,
    );

    if (item == null) {
      return const _DateVisual(
        color: primary,
        background: softGreen,
        foreground: primary,
      );
    }

    final status = _normalizedStatus(
      item['status'],
    );

    if (status == 'menunggu') {
      return const _DateVisual(
        color: amber,
        background: softAmber,
        foreground: amber,
      );
    }

    return const _DateVisual(
      color: red,
      background: softRed,
      foreground: red,
    );
  }

  int _countRequests(
    List<Map<String, dynamic>> loans,
    String targetStatus,
  ) {
    int total = 0;

    for (final item in loans) {
      if (_sameEquipment(item) &&
          _normalizedStatus(item['status']) ==
              targetStatus) {
        total++;
      }
    }

    return total;
  }

  int _countAvailableDates(
    List<Map<String, dynamic>> loans,
  ) {
    int total = 0;

    for (
      int day = 1;
      day <= _daysInCurrentMonth();
      day++
    ) {
      final date = DateTime(
        _now.year,
        _now.month,
        day,
      );

      if (_canSelect(date, loans)) {
        total++;
      }
    }

    return total;
  }

  int _countUsedDates(
    List<Map<String, dynamic>> loans,
  ) {
    int total = 0;

    for (
      int day = 1;
      day <= _daysInCurrentMonth();
      day++
    ) {
      final date = DateTime(
        _now.year,
        _now.month,
        day,
      );

      if (_loanOnDate(date, loans) != null) {
        total++;
      }
    }

    return total;
  }

  IconData _equipmentIcon(String value) {
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

  Color _equipmentColor(String value) {
    final name = value.toLowerCase();

    if (name.contains('sprayer') ||
        name.contains('semprot')) {
      return blue;
    }

    if (name.contains('cangkul')) {
      return amber;
    }

    if (name.contains('traktor')) {
      return primary;
    }

    return teal;
  }

  Future<void> _refresh() async {
    await _loanRef.get();
  }

  void _selectDate(
    DateTime date,
    List<Map<String, dynamic>> loans,
  ) {
    if (!_canSelect(date, loans)) {
      _showSnackBar(
        _dateMessage(date, loans),
        _isPast(date)
            ? textGrey
            : amber,
      );

      return;
    }

    setState(() {
      final selected = _selectedDate;

      if (selected != null &&
          _dateOnly(selected).isAtSameMomentAs(
            _dateOnly(date),
          )) {
        _selectedDate = null;
      } else {
        _selectedDate = date;
      }
    });
  }

  void _continueToForm() {
    FocusScope.of(context).unfocus();

    final selected = _selectedDate;

    if (selected == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlatFormPage(
          idAlat: widget.idAlat,
          namaAlat: widget.namaAlat,
          tanggalDipilih:
              _databaseDate(selected),
          nama: widget.nama,
          nik: widget.nik,
        ),
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
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final horizontalPadding =
        screenWidth < 350
            ? 12.0
            : screenWidth >= 700
                ? 22.0
                : 16.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: background,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _ScheduleBackground(),
                SafeArea(
                  child:
                      StreamBuilder<DatabaseEvent>(
                    stream: _loanRef.onValue,
                    builder: (
                      context,
                      snapshot,
                    ) {
                      final loans = _loanList(
                        snapshot
                            .data?.snapshot.value,
                      );

                      final availableDates =
                          _countAvailableDates(
                        loans,
                      );

                      final pendingRequests =
                          _countRequests(
                        loans,
                        'menunggu',
                      );

                      final usedDates =
                          _countUsedDates(
                        loans,
                      );

                      return RefreshIndicator(
                        color: teal,
                        backgroundColor:
                            Colors.white,
                        onRefresh: _refresh,
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior
                                  .manual,
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding:
                              EdgeInsets.fromLTRB(
                            horizontalPadding,
                            12,
                            horizontalPadding,
                            112,
                          ),
                          children: [
                            Center(
                              child:
                                  ConstrainedBox(
                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 760,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    _header(),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    _identityAndEquipment(),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    _stepCard(),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    _compactSummary(
                                      available:
                                          availableDates,
                                      pending:
                                          pendingRequests,
                                      used: usedDates,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    _legendCard(),
                                    const SizedBox(
                                      height: 17,
                                    ),
                                    _sectionTitle(),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    if (snapshot
                                            .connectionState ==
                                        ConnectionState
                                            .waiting)
                                      _loadingCalendar()
                                    else if (snapshot
                                        .hasError)
                                      _errorCard()
                                    else
                                      _calendarCard(
                                        loans,
                                      ),
                                    if (_selectedDate !=
                                        null) ...[
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      _selectedDateCard(),
                                    ],
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomButton(),
    );
  }

  Widget _header() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final compact =
            constraints.maxWidth < 370;

        return Container(
          padding: EdgeInsets.all(
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                dark,
                deepTeal,
                teal,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius:
                BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: deepTeal.withValues(
                  alpha: 0.23,
                ),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              _backButton(),
              SizedBox(
                width: compact ? 9 : 11,
              ),
              _iconBox(
                Icons.calendar_month_outlined,
                Colors.white,
                Colors.white.withValues(
                  alpha: 0.14,
                ),
                compact ? 43 : 47,
              ),
              SizedBox(
                width: compact ? 9 : 11,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Jadwal',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tentukan tanggal mulai peminjaman',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Color(0xffD7EEE7),
                        fontSize: 10.2,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _identityAndEquipment() {
    final equipmentColor =
        _equipmentColor(widget.namaAlat);

    return _card(
      LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final compact =
              constraints.maxWidth < 360;

          final applicant = _detailBlock(
            icon: Icons.person_outline_rounded,
            color: primary,
            itemBackground: softGreen,
            label: 'Pemohon',
            title: widget.nama,
            subtitle:
                'NIK ${_maskedNik(widget.nik)}',
          );

          final equipment = _detailBlock(
            icon: _equipmentIcon(
              widget.namaAlat,
            ),
            color: equipmentColor,
            itemBackground:
                equipmentColor.withValues(
              alpha: 0.09,
            ),
            label: 'Alat Dipilih',
            title: widget.namaAlat,
            subtitle:
                'Inventaris Desa Penataan',
          );

          if (compact) {
            return Column(
              children: [
                applicant,
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  color: border,
                ),
                const SizedBox(height: 10),
                equipment,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(child: applicant),
              Container(
                width: 1,
                height: 52,
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                color: border,
              ),
              Expanded(child: equipment),
            ],
          );
        },
      ),
    );
  }

  Widget _detailBlock({
    required IconData icon,
    required Color color,
    required Color itemBackground,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _iconBox(
          icon,
          color,
          itemBackground,
          43,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 9.4,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 12.5,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 8.9,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepCard() {
    return _card(
      Column(
        children: [
          Row(
            children: [
              _stepCircle('1', true),
              _stepLine(true),
              _stepCircle('2', true),
              _stepLine(false),
              _stepCircle('3', false),
              _stepLine(false),
              _stepCircle('4', false),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: teal,
                size: 17,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tahap 2 • Pilih tanggal yang masih tersedia',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 10.4,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
    );
  }

  Widget _stepCircle(
    String text,
    bool active,
  ) {
    return Container(
      height: 27,
      width: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? teal
            : const Color(0xffEFF3F2),
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? teal : border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active
              ? Colors.white
              : textSoft,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: active
              ? teal.withValues(alpha: 0.48)
              : const Color(0xffE4EAE8),
          borderRadius:
              BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _compactSummary({
    required int available,
    required int pending,
    required int used,
  }) {
    return _card(
      LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final gap =
              constraints.maxWidth < 350
                  ? 6.0
                  : 8.0;

          final itemWidth =
              (constraints.maxWidth -
                      gap * 2) /
                  3;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              SizedBox(
                width: itemWidth,
                child: _summaryItem(
                  'Tersedia',
                  available,
                  Icons
                      .event_available_outlined,
                  primary,
                  softGreen,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _summaryItem(
                  'Menunggu',
                  pending,
                  Icons.schedule_outlined,
                  amber,
                  softAmber,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _summaryItem(
                  'Terpakai',
                  used,
                  Icons.event_busy_outlined,
                  red,
                  softRed,
                ),
              ),
            ],
          );
        },
      ),
      padding: const EdgeInsets.all(9),
    );
  }

  Widget _summaryItem(
    String label,
    int value,
    IconData icon,
    Color color,
    Color itemBackground,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 67,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: itemBackground,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            value > 99
                ? '99+'
                : value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 14.5,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 8.2,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendCard() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: softTeal,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              teal.withValues(alpha: 0.11),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: teal,
                size: 17,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Keterangan warna jadwal',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 10.4,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _LegendItem(
                color: primary,
                label: 'Tersedia',
              ),
              _LegendItem(
                color: amber,
                label: 'Menunggu',
              ),
              _LegendItem(
                color: red,
                label: 'Terpakai',
              ),
              _LegendItem(
                color: Color(0xffAEB8C2),
                label: 'Sudah lewat',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle() {
    return const Row(
      children: [
        SizedBox(
          width: 5,
          height: 31,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: teal,
              borderRadius:
                  BorderRadius.all(
                Radius.circular(99),
              ),
            ),
          ),
        ),
        SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Kalender Peminjaman',
                style: TextStyle(
                  color: textDark,
                  fontSize: 14.5,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Ketuk tanggal hijau untuk memilih jadwal.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 9.7,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _calendarCard(
    List<Map<String, dynamic>> loans,
  ) {
    final offset = _firstWeekdayOffset();

    final totalCells =
        offset + _daysInCurrentMonth();

    return _card(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(
                Icons.calendar_month_outlined,
                teal,
                softTeal,
                40,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentMonthLabel(),
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Jadwal untuk bulan berjalan',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 9.2,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _weekdayHeader(),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final spacing =
                  constraints.maxWidth < 340
                      ? 4.0
                      : 6.0;

              final cellWidth =
                  (constraints.maxWidth -
                          spacing * 6) /
                      7;

              final cellHeight = cellWidth
                  .clamp(39.0, 52.0)
                  .toDouble();

              final ratio =
                  cellWidth / cellHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: ratio,
                ),
                itemBuilder: (
                  context,
                  index,
                ) {
                  if (index < offset) {
                    return const SizedBox
                        .shrink();
                  }

                  final day =
                      index - offset + 1;

                  final date = DateTime(
                    _now.year,
                    _now.month,
                    day,
                  );

                  return _dateCell(
                    date,
                    loans,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _weekdayHeader() {
    return Row(
      children: _dayNames.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: const TextStyle(
                color: textGrey,
                fontSize: 9.2,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _dateCell(
    DateTime date,
    List<Map<String, dynamic>> loans,
  ) {
    final visual = _dateVisual(
      date,
      loans,
    );

    final canSelect = _canSelect(
      date,
      loans,
    );

    final selected =
        _selectedDate != null &&
            _dateOnly(_selectedDate!)
                .isAtSameMomentAs(
              _dateOnly(date),
            );

    final isToday = _dateOnly(_now)
        .isAtSameMomentAs(
      _dateOnly(date),
    );

    final itemBackground =
        selected
            ? teal
            : visual.background;

    final foreground =
        selected
            ? Colors.white
            : visual.foreground;

    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          _selectDate(
            date,
            loans,
          );
        },
        borderRadius:
            BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: itemBackground,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? teal
                  : isToday
                      ? visual.color
                      : visual.color
                          .withValues(
                          alpha: 0.13,
                        ),
              width:
                  selected || isToday
                      ? 1.4
                      : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color:
                          teal.withValues(
                        alpha: 0.22,
                      ),
                      blurRadius: 8,
                      offset:
                          const Offset(
                        0,
                        4,
                      ),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: foreground,
                  fontSize: 11.2,
                  height: 1,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: 3),
                Container(
                  height: 3,
                  width: 3,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : visual.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ] else if (!canSelect &&
                  !_isPast(date)) ...[
                const SizedBox(height: 3),
                Container(
                  height: 3,
                  width: 3,
                  decoration: BoxDecoration(
                    color: foreground,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedDateCard() {
    final selected = _selectedDate!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              primary.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        children: [
          _iconBox(
            Icons
                .check_circle_outline_rounded,
            primary,
            Colors.white,
            40,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal Dipilih',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 9.3,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _displayDate(selected),
                  style: const TextStyle(
                    color: primary,
                    fontSize: 12.3,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Batalkan pilihan',
            onPressed: () {
              setState(() {
                _selectedDate = null;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: textGrey,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCalendar() {
    return _card(
      Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius:
                        BorderRadius.circular(
                      99,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          const SizedBox(
            height: 28,
            width: 28,
            child:
                CircularProgressIndicator(
              color: teal,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Memuat jadwal peminjaman...',
            style: TextStyle(
              color: textGrey,
              fontSize: 9.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
    );
  }

  Widget _errorCard() {
    return _card(
      Column(
        children: [
          _iconBox(
            Icons.cloud_off_outlined,
            red,
            softRed,
            62,
          ),
          const SizedBox(height: 12),
          const Text(
            'Jadwal Tidak Dapat Dimuat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 14.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Periksa koneksi internet lalu tarik halaman ke bawah.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey,
              fontSize: 9.8,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 26,
      ),
    );
  }

  Widget _bottomButton() {
    final active = _selectedDate != null;

    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: deepTeal.withValues(alpha: 0.13),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            9,
            14,
            12,
          ),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 760,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton.icon(
                  onPressed: active
                      ? _continueToForm
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        teal.withValues(alpha: 0.28),
                    disabledForegroundColor:
                        Colors.white.withValues(alpha: 0.86),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: Icon(
                    active
                        ? Icons.arrow_forward_rounded
                        : Icons.event_available_outlined,
                    size: 19,
                  ),
                  label: Text(
                    active
                        ? 'Lanjut Isi Data'
                        : 'Pilih Tanggal Terlebih Dahulu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.maybePop(context);
        },
        borderRadius:
            BorderRadius.circular(14),
        child: _iconBox(
          Icons.arrow_back_rounded,
          Colors.white,
          Colors.white.withValues(
            alpha: 0.14,
          ),
          42,
        ),
      ),
    );
  }

  Widget _iconBox(
    IconData icon,
    Color color,
    Color iconBackground,
    double size,
  ) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: iconBackground,
        borderRadius:
            BorderRadius.circular(
          size * 0.32,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    );
  }

  Widget _card(
    Widget child, {
    EdgeInsets padding =
        const EdgeInsets.all(13),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.98,
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(
              alpha: 0.05,
            ),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DateVisual {
  final Color color;
  final Color background;
  final Color foreground;

  const _DateVisual({
    required this.color,
    required this.background,
    required this.foreground,
  });
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.72,
        ),
        borderRadius:
            BorderRadius.circular(99),
        border: Border.all(
          color:
              color.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 8,
            width: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color ==
                      const Color(
                        0xffAEB8C2,
                      )
                  ? const Color(
                      0xff66727F,
                    )
                  : color,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleBackground extends StatelessWidget {
  const _ScheduleBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final base =
                constraints.maxWidth <
                        constraints.maxHeight
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
                      gradient:
                          LinearGradient(
                        begin:
                            Alignment.topCenter,
                        end: Alignment
                            .bottomCenter,
                        colors: [
                          Color(0xff0E5F57),
                          Color(0xff167A6B),
                          Color(0xffDDEFEA),
                          Color(0xffF2F7F5),
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
                      color: const Color(
                        0xff58B89F,
                      ),
                      alpha: 0.20,
                    ),
                  ),
                  Positioned(
                    top:
                        constraints.maxHeight *
                            0.31,
                    left: -medium * 0.58,
                    child: _BackgroundCircle(
                      size: medium,
                      color: const Color(
                        0xffA7DACD,
                      ),
                      alpha: 0.34,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.31,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(
                        0xffDDEFE6,
                      ),
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
        color: color.withValues(
          alpha: alpha,
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}