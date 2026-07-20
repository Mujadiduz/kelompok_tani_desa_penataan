import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class RiwayatPage extends StatefulWidget {
  final String nik;

  const RiwayatPage({
    super.key,
    required this.nik,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color deepTeal = Color(0xff0E5F57);
  static const Color tealColor = Color(0xff167A6B);
  static const Color amberColor = Color(0xffD98212);
  static const Color blueColor = Color(0xff326FA3);
  static const Color purpleColor = Color(0xff7159B4);
  static const Color dangerColor = Color(0xffC83B3B);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softBlue = Color(0xffEAF3FA);
  static const Color softPurple = Color(0xffF1ECFA);
  static const Color softRed = Color(0xffFBEAEA);

  static const Color pageBackground = Color(0xffF2F7F5);
  static const Color cardBorder = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference pupukRef;
  late final DatabaseReference peminjamanRef;

  final Set<String> expandedCards = {};

  // 0 = Pupuk, 1 = Alat.
  int selectedTab = 0;

  @override
  void initState() {
    super.initState();

    pupukRef = db.ref('bantuan_pupuk');
    peminjamanRef = db.ref('peminjaman_alat');
  }

  Future<void> _refreshData() async {
    await Future.wait([
      pupukRef.get(),
      peminjamanRef.get(),
    ]);
  }

  String _normalizeNik(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();
  }

  List<Map<String, dynamic>> _readUserData(
    dynamic value,
    String type,
  ) {
    if (value == null || value is! Map) {
      return [];
    }

    final source = Map<dynamic, dynamic>.from(value);
    final userNik = _normalizeNik(widget.nik);

    final result = source.entries
        .where((entry) => entry.value is Map)
        .map((entry) {
          final item = Map<String, dynamic>.from(
            entry.value as Map,
          );

          item['id_riwayat'] = entry.key.toString();
          item['jenis_riwayat'] = type;

          return item;
        })
        .where((item) {
          return _normalizeNik(item['nik']) == userNik;
        })
        .toList();

    result.sort(
      (a, b) => _mainDate(b).compareTo(
        _mainDate(a),
      ),
    );

    return result;
  }

  dynamic _firstValue(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = item[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty &&
          text != '-' &&
          text.toLowerCase() != 'null') {
        return value;
      }
    }

    return null;
  }

  String _safeText(
    dynamic value, {
    String fallback = '-',
  }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text == '-' ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) {
      return null;
    }

    if (raw is int || raw is double) {
      final int number;

      if (raw is int) {
        number = raw;
      } else {
        number = raw.toInt();
      }

      final milliseconds =
          number.toString().length >= 13
              ? number
              : number * 1000;

      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
      ).toLocal();
    }

    final text = raw.toString().trim();

    if (text.isEmpty || text == '-') {
      return null;
    }

    final parsed = DateTime.tryParse(text);

    if (parsed != null) {
      return parsed.toLocal();
    }

    final clean = text.split(' ').first;
    final slash = clean.split('/');

    if (slash.length == 3) {
      final day = int.tryParse(slash[0]);
      final month = int.tryParse(slash[1]);
      final year = int.tryParse(slash[2]);

      if (day != null &&
          month != null &&
          year != null) {
        return DateTime(year, month, day);
      }
    }

    final dash = clean.split('-');

    if (dash.length == 3 &&
        dash[0].length <= 2) {
      final day = int.tryParse(dash[0]);
      final month = int.tryParse(dash[1]);
      final year = int.tryParse(dash[2]);

      if (day != null &&
          month != null &&
          year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  DateTime _mainDate(
    Map<String, dynamic> item,
  ) {
    final value = _firstValue(
      item,
      [
        'tanggal_pengajuan',
        'created_at',
        'createdAt',
        'tanggal',
        'waktu',
        'tanggal_pinjam',
        'tanggal_diambil',
        'tanggal_pengambilan',
        'tanggal_dikembalikan',
      ],
    );

    return _parseDate(value) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _monthName(int month) {
    const months = [
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

  String _shortMonth(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String _monthLabel(DateTime date) {
    if (date.millisecondsSinceEpoch <= 0) {
      return 'Tanggal Tidak Diketahui';
    }

    return '${_monthName(date.month)} ${date.year}';
  }

  String _formatDate(
    dynamic value, {
    bool includeTime = true,
  }) {
    final date = _parseDate(value);

    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');

    final result =
        '$day ${_monthName(date.month)} ${date.year}';

    if (!includeTime) {
      return result;
    }

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$result • $hour:$minute';
  }

  String _formatTime(DateTime date) {
    if (date.millisecondsSinceEpoch <= 0) {
      return '--:--';
    }

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _cleanStatus(dynamic value) {
    return (value ?? 'menunggu')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');
  }

  bool _isRejected(dynamic value) {
    final status = _cleanStatus(value);

    return status == 'ditolak' ||
        status == 'rejected';
  }

  bool _isCompleted(dynamic value) {
    final status = _cleanStatus(value);

    const completedStatuses = {
      'sudah_diambil',
      'sudah diambil',
      'dikembalikan',
      'selesai',
      'completed',
    };

    return completedStatuses.contains(status);
  }

  Color _statusColor(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return blueColor;
    }

    if (status == 'dipinjam') {
      return purpleColor;
    }

    if (_isCompleted(status)) {
      return primaryGreen;
    }

    if (_isRejected(status)) {
      return dangerColor;
    }

    return amberColor;
  }

  Color _statusBackground(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return softBlue;
    }

    if (status == 'dipinjam') {
      return softPurple;
    }

    if (_isCompleted(status)) {
      return softGreen;
    }

    if (_isRejected(status)) {
      return softRed;
    }

    return softAmber;
  }

  String _statusText(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return 'Disetujui';
    }

    if (status == 'sudah_diambil' ||
        status == 'sudah diambil') {
      return 'Sudah Diambil';
    }

    if (status == 'dipinjam') {
      return 'Dipinjam';
    }

    if (status == 'dikembalikan') {
      return 'Dikembalikan';
    }

    if (status == 'selesai' ||
        status == 'completed') {
      return 'Selesai';
    }

    if (_isRejected(status)) {
      return 'Ditolak';
    }

    const processingStatuses = {
      'proses',
      'diproses',
      'sedang_diproses',
      'sedang diproses',
    };

    if (processingStatuses.contains(status)) {
      return 'Diproses';
    }

    return 'Menunggu';
  }

  String _statusLongText(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return 'Pengajuan sudah disetujui admin';
    }

    if (status == 'sudah_diambil' ||
        status == 'sudah diambil') {
      return 'Bantuan pupuk sudah diambil';
    }

    if (status == 'dipinjam') {
      return 'Alat sedang dipinjam';
    }

    if (status == 'dikembalikan') {
      return 'Alat sudah dikembalikan';
    }

    if (status == 'selesai' ||
        status == 'completed') {
      return 'Aktivitas sudah selesai';
    }

    if (_isRejected(status)) {
      return 'Pengajuan tidak disetujui';
    }

    return 'Menunggu verifikasi admin';
  }

  IconData _statusIcon(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return Icons.verified_rounded;
    }

    if (status == 'sudah_diambil' ||
        status == 'sudah diambil') {
      return Icons.inventory_rounded;
    }

    if (status == 'dipinjam') {
      return Icons.handyman_rounded;
    }

    if (status == 'dikembalikan') {
      return Icons.assignment_turned_in_rounded;
    }

    if (_isCompleted(status)) {
      return Icons.task_alt_rounded;
    }

    if (_isRejected(status)) {
      return Icons.cancel_rounded;
    }

    return Icons.schedule_rounded;
  }

  bool _isPupuk(
    Map<String, dynamic> item,
  ) {
    return (item['jenis_riwayat'] ?? '')
            .toString() ==
        'pupuk';
  }

  String _title(
    Map<String, dynamic> item,
  ) {
    if (_isPupuk(item)) {
      return _safeText(
        _firstValue(
          item,
          [
            'jenis_pupuk',
            'nama_pupuk',
            'pupuk',
          ],
        ),
        fallback: 'Bantuan Pupuk',
      );
    }

    return _safeText(
      _firstValue(
        item,
        [
          'nama_alat',
          'alat',
          'jenis_alat',
        ],
      ),
      fallback: 'Alat Pertanian',
    );
  }

  String _amount(
    Map<String, dynamic> item,
  ) {
    if (_isPupuk(item)) {
      final value = _safeText(
        _firstValue(
          item,
          [
            'jumlah_pupuk',
            'jumlah_kg',
            'jumlah',
          ],
        ),
      );

      if (value == '-') {
        return '-';
      }

      final lowerValue = value.toLowerCase();

      if (lowerValue.contains('kg') ||
          lowerValue.contains('kilo')) {
        return value;
      }

      return '$value Kg';
    }

    final value = _safeText(
      _firstValue(
        item,
        [
          'jumlah_alat',
          'jumlah',
        ],
      ),
      fallback: '1',
    );

    if (value.toLowerCase().contains('unit')) {
      return value;
    }

    return '$value Unit';
  }

  IconData _itemIcon(
    Map<String, dynamic> item,
  ) {
    final title = _title(item).toLowerCase();

    if (_isPupuk(item)) {
      if (title.contains('urea')) {
        return Icons.water_drop_outlined;
      }

      if (title.contains('npk')) {
        return Icons.grain_rounded;
      }

      if (title.contains('organik') ||
          title.contains('kompos')) {
        return Icons.energy_savings_leaf_rounded;
      }

      if (title.contains('za')) {
        return Icons.science_outlined;
      }

      return Icons.inventory_2_outlined;
    }

    if (title.contains('traktor')) {
      return Icons.agriculture_rounded;
    }

    if (title.contains('cangkul')) {
      return Icons.hardware_rounded;
    }

    if (title.contains('sprayer')) {
      return Icons.water_drop_rounded;
    }

    return Icons.precision_manufacturing_outlined;
  }

  String _withUnit(
    dynamic value,
    String unit,
  ) {
    final text = _safeText(value);

    if (text == '-') {
      return '-';
    }

    if (text
        .toLowerCase()
        .contains(unit.toLowerCase())) {
      return text;
    }

    return '$text $unit';
  }

  String _returnStatus(
    Map<String, dynamic> item,
  ) {
    final status = _cleanStatus(
      item['status_pengembalian'],
    );

    if (status == 'terlambat') {
      final days = _safeText(
        item['jumlah_hari_terlambat'],
        fallback: '0',
      );

      return 'Terlambat $days hari';
    }

    if (status == 'tepat_waktu' ||
        status == 'tepat waktu') {
      return 'Tepat waktu';
    }

    return '-';
  }

  Color _returnColor(
    Map<String, dynamic> item,
  ) {
    final status = _cleanStatus(
      item['status_pengembalian'],
    );

    if (status == 'terlambat') {
      return dangerColor;
    }

    if (status == 'tepat_waktu' ||
        status == 'tepat waktu') {
      return primaryGreen;
    }

    return textGrey;
  }

  Map<String, List<Map<String, dynamic>>>
      _groupByMonth(
    List<Map<String, dynamic>> list,
  ) {
    final grouped =
        <String, List<Map<String, dynamic>>>{};

    for (final item in list) {
      final label = _monthLabel(
        _mainDate(item),
      );

      grouped.putIfAbsent(
        label,
        () => [],
      );

      grouped[label]!.add(item);
    }

    return grouped;
  }

  void _toggleCard(String id) {
    setState(() {
      if (expandedCards.contains(id)) {
        expandedCards.remove(id);
      } else {
        expandedCards.add(id);
      }
    });
  }

  List<_DetailItem> _details(
    Map<String, dynamic> item,
  ) {
    final result = <_DetailItem>[
      _DetailItem(
        label: 'Nomor Referensi',
        value: _safeText(
          item['id_riwayat'],
        ),
      ),
      _DetailItem(
        label: _isPupuk(item)
            ? 'Jenis Pupuk'
            : 'Nama Alat',
        value: _title(item),
      ),
      _DetailItem(
        label: _isPupuk(item)
            ? 'Jumlah Diajukan'
            : 'Jumlah Alat',
        value: _amount(item),
      ),
      _DetailItem(
        label: 'Tanggal Pengajuan',
        value: _formatDate(
          _firstValue(
            item,
            [
              'tanggal_pengajuan',
              'created_at',
              'createdAt',
              'tanggal',
              'waktu',
            ],
          ),
        ),
      ),
    ];

    if (_isPupuk(item)) {
      result.addAll([
        _DetailItem(
          label: 'Batas/Jatah Pupuk',
          value: _withUnit(
            _firstValue(
              item,
              [
                'jatah_pupuk',
                'batas_pupuk',
                'jatah',
              ],
            ),
            'Kg',
          ),
        ),
        _DetailItem(
          label: 'Tanggal Disetujui',
          value: _formatDate(
            _firstValue(
              item,
              [
                'tanggal_disetujui',
                'tanggal_persetujuan',
                'waktu_disetujui',
              ],
            ),
          ),
        ),
        _DetailItem(
          label: 'Tanggal Pengambilan',
          value: _formatDate(
            _firstValue(
              item,
              [
                'tanggal_pengambilan',
                'tanggal_diambil',
                'waktu_pengambilan',
              ],
            ),
          ),
        ),
      ]);
    } else {
      result.addAll([
        _DetailItem(
          label: 'Tanggal Pinjam',
          value: _formatDate(
            _firstValue(
              item,
              [
                'tanggal_pinjam',
                'tanggal_mulai',
              ],
            ),
            includeTime: false,
          ),
        ),
        _DetailItem(
          label: 'Rencana Kembali',
          value: _formatDate(
            _firstValue(
              item,
              [
                'tanggal_kembali',
                'tanggal_selesai',
              ],
            ),
            includeTime: false,
          ),
        ),
        _DetailItem(
          label: 'Tanggal Alat Diambil',
          value: _formatDate(
            _firstValue(
              item,
              [
                'tanggal_diambil',
                'tanggal_pengambilan',
              ],
            ),
          ),
        ),
        _DetailItem(
          label: 'Tanggal Dikembalikan',
          value: _formatDate(
            _firstValue(
              item,
              [
                'tanggal_dikembalikan',
                'tanggal_kembali_aktual',
              ],
            ),
          ),
        ),
        _DetailItem(
          label: 'Ketepatan Pengembalian',
          value: _returnStatus(item),
          valueColor: _returnColor(item),
        ),
      ]);
    }

    result.addAll([
      _DetailItem(
        label: 'Status',
        value: _statusText(
          item['status'],
        ),
        valueColor: _statusColor(
          item['status'],
        ),
      ),
      _DetailItem(
        label: 'Catatan',
        value: _safeText(
          _firstValue(
            item,
            [
              'catatan',
              'keterangan',
              'alasan',
              'alasan_penolakan',
            ],
          ),
        ),
      ),
    ]);

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width;

    final horizontalPadding =
        width < 340 ? 13.0 : 17.0;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _RiwayatBackground(),
                SafeArea(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: pupukRef.onValue,
                    builder: (
                      context,
                      pupukSnapshot,
                    ) {
                      return StreamBuilder<
                          DatabaseEvent>(
                        stream:
                            peminjamanRef.onValue,
                        builder: (
                          context,
                          alatSnapshot,
                        ) {
                          if (pupukSnapshot.hasError ||
                              alatSnapshot.hasError) {
                            return _errorView();
                          }

                          final loading =
                              pupukSnapshot
                                          .connectionState ==
                                      ConnectionState
                                          .waiting &&
                                  alatSnapshot
                                          .connectionState ==
                                      ConnectionState
                                          .waiting;

                          if (loading) {
                            return _loadingView();
                          }

                          final pupuk = _readUserData(
                            pupukSnapshot
                                .data
                                ?.snapshot
                                .value,
                            'pupuk',
                          );

                          final alat = _readUserData(
                            alatSnapshot
                                .data
                                ?.snapshot
                                .value,
                            'alat',
                          );

                          final activeList =
                              selectedTab == 0
                                  ? pupuk
                                  : alat;

                          final grouped =
                              _groupByMonth(
                            activeList,
                          );

                          return RefreshIndicator(
                            color: tealColor,
                            backgroundColor:
                                Colors.white,
                            onRefresh: _refreshData,
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
                                28,
                              ),
                              children: [
                                Center(
                                  child:
                                      ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(
                                      maxWidth: 720,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .stretch,
                                      children: [
                                        _header(),
                                        const SizedBox(
                                          height: 13,
                                        ),
                                        _tabSelector(
                                          totalPupuk:
                                              pupuk.length,
                                          totalAlat:
                                              alat.length,
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        _infoBox(),
                                        const SizedBox(
                                          height: 17,
                                        ),
                                        _historyContent(
                                          grouped,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        13,
        14,
        13,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            darkGreen,
            deepTeal,
            tealColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                deepTeal.withValues(alpha: 0.23),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 10),
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.19,
                ),
              ),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Aktivitas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Bantuan pupuk dan peminjaman alat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffD9EEE8),
                    fontSize: 10.1,
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
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.14,
            ),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.21,
              ),
            ),
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

  Widget _tabSelector({
    required int totalPupuk,
    required int totalAlat,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: _cardDecoration(
        radius: 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              title: 'Bantuan Pupuk',
              subtitle: '$totalPupuk data',
              icon:
                  Icons.inventory_2_outlined,
              active: selectedTab == 0,
              color: primaryGreen,
              onTap: () {
                setState(() {
                  selectedTab = 0;
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _tabButton(
              title: 'Peminjaman Alat',
              subtitle: '$totalAlat data',
              icon: Icons
                  .precision_manufacturing_outlined,
              active: selectedTab == 1,
              color: amberColor,
              onTap: () {
                setState(() {
                  selectedTab = 1;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 190),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: active
                ? color
                : color.withValues(alpha: 0.07),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? color
                  : color.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(
                          alpha: 0.18,
                        )
                      : color.withValues(
                          alpha: 0.10,
                        ),
                  borderRadius:
                      BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: active
                      ? Colors.white
                      : color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : textDark,
                        fontSize: 11.2,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: active
                            ? Colors.white
                                .withValues(
                                alpha: 0.75,
                              )
                            : textGrey,
                        fontSize: 9.2,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBox() {
    final color =
        selectedTab == 0
            ? primaryGreen
            : amberColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.touch_app_outlined,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              selectedTab == 0
                  ? 'Riwayat disusun berdasarkan bulan. Tekan kartu untuk melihat jumlah pupuk dan tanggal lengkap.'
                  : 'Riwayat disusun berdasarkan bulan. Tekan kartu untuk melihat jadwal pinjam dan pengembalian.',
              style: const TextStyle(
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

  Widget _historyContent(
    Map<String, List<Map<String, dynamic>>>
        grouped,
  ) {
    if (grouped.isEmpty) {
      return _emptyCard();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            _monthHeader(entry.key),
            const SizedBox(height: 8),
            ...entry.value.map(_historyCard),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Widget _monthHeader(String month) {
    final color =
        selectedTab == 0
            ? primaryGreen
            : amberColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2,
        6,
        2,
        2,
      ),
      child: Row(
        children: [
          Container(
            height: 27,
            width: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              month,
              style: const TextStyle(
                color: textDark,
                fontSize: 13.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(
            Icons.calendar_month_outlined,
            color: textSoft,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _historyCard(
    Map<String, dynamic> item,
  ) {
    final id =
        _safeText(item['id_riwayat']);

    final expanded =
        expandedCards.contains(id);

    final isPupuk = _isPupuk(item);

    final color =
        isPupuk ? primaryGreen : amberColor;

    final background =
        isPupuk ? softGreen : softAmber;

    final date = _mainDate(item);
    final details = _details(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(
        radius: 19,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: () {
            _toggleCard(id);
          },
          borderRadius:
              BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _dateBadge(date, color),
                    const SizedBox(width: 10),
                    Container(
                      height: 43,
                      width: 43,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Icon(
                        _itemIcon(item),
                        color: color,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isPupuk
                                      ? 'Bantuan Pupuk'
                                      : 'Peminjaman Alat',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 9.1,
                                    fontWeight:
                                        FontWeight
                                            .w900,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              _statusBadge(
                                item['status'],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _title(item),
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              color: textDark,
                              fontSize: 12.9,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _amount(item),
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color: textGrey,
                                    fontSize: 10.1,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons
                                    .schedule_outlined,
                                color: textSoft,
                                size: 13,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                _formatTime(date),
                                style:
                                    const TextStyle(
                                  color: textSoft,
                                  fontSize: 9.3,
                                  fontWeight:
                                      FontWeight
                                          .w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Icon(
                      expanded
                          ? Icons
                              .keyboard_arrow_up_rounded
                          : Icons
                              .keyboard_arrow_down_rounded,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Icon(
                      _statusIcon(
                        item['status'],
                      ),
                      color: _statusColor(
                        item['status'],
                      ),
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _statusLongText(
                          item['status'],
                        ),
                        style: TextStyle(
                          color: _statusColor(
                            item['status'],
                          ),
                          fontSize: 10.5,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (expanded) ...[
                  const SizedBox(height: 12),
                  _detailsBox(details),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateBadge(
    DateTime date,
    Color color,
  ) {
    if (date.millisecondsSinceEpoch <= 0) {
      return Container(
        height: 52,
        width: 43,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.calendar_today_outlined,
          color: color,
          size: 18,
        ),
      );
    }

    return Container(
      height: 52,
      width: 43,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            date.day
                .toString()
                .padLeft(2, '0'),
            style: TextStyle(
              color: color,
              fontSize: 15.5,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _shortMonth(date.month),
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(dynamic status) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 88,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _statusColor(status)
              .withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Text(
        _statusText(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 7.7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _detailsBox(
    List<_DetailItem> details,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF9FBFA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: List.generate(
          details.length,
          (index) {
            return _detailRow(
              details[index],
              index == details.length - 1,
            );
          },
        ),
      ),
    );
  }

  Widget _detailRow(
    _DetailItem item,
    bool last,
  ) {
    return Container(
      padding: EdgeInsets.only(
        bottom: last ? 9 : 10,
      ),
      margin: EdgeInsets.only(
        bottom: last ? 0 : 10,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: cardBorder.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              item.label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color:
                    item.valueColor ?? textDark,
                fontSize: 10.7,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard() {
    final color =
        selectedTab == 0
            ? primaryGreen
            : amberColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        22,
        25,
        22,
        24,
      ),
      decoration: _cardDecoration(
        radius: 22,
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius:
                  BorderRadius.circular(22),
            ),
            child: Icon(
              selectedTab == 0
                  ? Icons.inventory_2_outlined
                  : Icons
                      .precision_manufacturing_outlined,
              color: color,
              size: 33,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            selectedTab == 0
                ? 'Belum Ada Riwayat Pupuk'
                : 'Belum Ada Riwayat Alat',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 15.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selectedTab == 0
                ? 'Riwayat bantuan pupuk akan muncul setelah Anda melakukan pengajuan.'
                : 'Riwayat peminjaman alat akan muncul setelah Anda melakukan pengajuan.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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

  Widget _loadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: tealColor,
        strokeWidth: 2.7,
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(
            radius: 22,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: dangerColor,
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'Riwayat Tidak Dapat Dimuat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Periksa koneksi internet lalu buka kembali halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 10.8,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color:
          Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color:
              deepTeal.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.label,
    required this.value,
    this.valueColor,
  });
}

class _RiwayatBackground
    extends StatelessWidget {
  const _RiwayatBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width =
                constraints.maxWidth;

            final height =
                constraints.maxHeight;

            final baseSize =
                width < height ? width : height;

            final large =
                (baseSize * 0.98)
                    .clamp(280.0, 460.0)
                    .toDouble();

            final medium =
                (baseSize * 0.68)
                    .clamp(190.0, 330.0)
                    .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:
                            Alignment.topCenter,
                        end:
                            Alignment.bottomCenter,
                        colors: [
                          Color(0xff0E5F57),
                          Color(0xff177A6B),
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
                    right: -large * 0.29,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(
                        0xff53B69C,
                      ),
                      alpha: 0.20,
                    ),
                  ),
                  Positioned(
                    top: height * 0.30,
                    left: -medium * 0.57,
                    child: _BackgroundCircle(
                      size: medium,
                      color: const Color(
                        0xffA9DCCF,
                      ),
                      alpha: 0.36,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.30,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(
                        0xffDDEFE5,
                      ),
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

class _BackgroundCircle
    extends StatelessWidget {
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