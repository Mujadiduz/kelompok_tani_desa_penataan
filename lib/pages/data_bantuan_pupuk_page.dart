import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class DataBantuanPupukPage extends StatefulWidget {
  const DataBantuanPupukPage({super.key});

  @override
  State<DataBantuanPupukPage> createState() =>
      _DataBantuanPupukPageState();
}

class _DataBantuanPupukPageState
    extends State<DataBantuanPupukPage> {
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminIndigo = Color(0xff435987);
  static const Color adminPurple = Color(0xff6256A4);

  static const Color green = Color(0xff2E7D32);
  static const Color blue = Color(0xff326CA3);
  static const Color amber = Color(0xffD98212);
  static const Color red = Color(0xffC83B3B);

  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softBlue = Color(0xffE9F2FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);
  static const Color softPurple = Color(0xffF0ECFA);

  final TextEditingController _searchController =
      TextEditingController();

  final DatabaseReference _bantuanRef =
      FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('bantuan_pupuk');

  String _searchQuery = '';
  String _selectedFilter = 'semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _bantuanRef.get();
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }

    return Map<String, dynamic>.from(value);
  }

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    final result = (value ?? '').toString().trim();

    if (result.isEmpty ||
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
          (value ?? '')
              .toString()
              .replaceAll(',', '.')
              .trim(),
        ) ??
        0;
  }

  String _normalStatus(
    Map<String, dynamic> item,
  ) {
    final value = _text(
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
      'proses',
      'diproses',
      'menunggu_verifikasi',
      'belum_diproses',
    }.contains(value)) {
      return 'menunggu';
    }

    if ({
      'approved',
      'siap_diambil',
      'siap_ambil',
    }.contains(value)) {
      return 'disetujui';
    }

    if ({
      'diambil',
      'selesai',
      'completed',
      'sudah_diserahkan',
    }.contains(value)) {
      return 'sudah_diambil';
    }

    if (value == 'rejected') {
      return 'ditolak';
    }

    return value;
  }

  String _memberName(
    Map<String, dynamic> item,
  ) {
    return _text(
      item['nama'] ??
          item['nama_anggota'] ??
          item['nama_user'],
      fallback: 'Anggota',
    );
  }

  String _fertilizerName(
    Map<String, dynamic> item,
  ) {
    return _text(
      item['jenis_pupuk'] ??
          item['nama_pupuk'] ??
          item['pupuk'] ??
          item['jenis'],
      fallback: 'Pupuk bantuan',
    );
  }

  String _programName(
    Map<String, dynamic> item,
  ) {
    return _text(
      item['nama_program'] ??
          item['program_bantuan'] ??
          item['judul_program'],
      fallback: 'Program Bantuan Pupuk',
    );
  }

  String _period(
    Map<String, dynamic> item,
  ) {
    return _text(
      item['periode'] ??
          item['periode_bantuan'] ??
          item['bulan_program'],
      fallback: '-',
    );
  }

  String _amount(
    Map<String, dynamic> item,
  ) {
    final value = _number(
      item['jumlah_disetujui'] ??
          item['jumlah_final_kg'] ??
          item['jumlah_diajukan'] ??
          item['jumlah_paket_kg'] ??
          item['jumlah_pupuk'] ??
          item['jumlah_kg'] ??
          item['jumlah'],
    );

    if (value <= 0) {
      return '-';
    }

    final text = value % 1 == 0
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

    return '$text kg';
  }

  DateTime _dateValue(
    Map<String, dynamic> item,
  ) {
    final raw = item['tanggal_pengajuan'] ??
        item['tanggal'] ??
        item['created_at'] ??
        item['waktu_pengajuan'] ??
        item['timestamp'];

    if (raw is num) {
      try {
        final value = raw.toInt();

        return DateTime.fromMillisecondsSinceEpoch(
          value.toString().length >= 13
              ? value
              : value * 1000,
        ).toLocal();
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return DateTime.tryParse(
          (raw ?? '').toString().trim(),
        )?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _dateText(
    Map<String, dynamic> item,
  ) {
    final date = _dateValue(item);

    if (date.millisecondsSinceEpoch == 0) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _maskedNik(dynamic value) {
    final nik = _text(
      value,
      fallback: '',
    ).replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (nik.isEmpty) {
      return '•••• •••• •••• ----';
    }

    final lastFour = nik.length >= 4
        ? nik.substring(nik.length - 4)
        : nik;

    return '•••• •••• •••• $lastFour';
  }

  String _statusText(String status) {
    if (status == 'disetujui') {
      return 'Disetujui';
    }

    if (status == 'sudah_diambil') {
      return 'Diambil';
    }

    if (status == 'ditolak') {
      return 'Ditolak';
    }

    return 'Menunggu';
  }

  Color _statusColor(String status) {
    if (status == 'disetujui') {
      return blue;
    }

    if (status == 'sudah_diambil') {
      return green;
    }

    if (status == 'ditolak') {
      return red;
    }

    return amber;
  }

  Color _statusBackground(String status) {
    if (status == 'disetujui') {
      return softBlue;
    }

    if (status == 'sudah_diambil') {
      return softGreen;
    }

    if (status == 'ditolak') {
      return softRed;
    }

    return softAmber;
  }

  List<Map<String, dynamic>> _applications(
    dynamic value,
  ) {
    if (value is! Map) {
      return <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];

    for (final entry
        in Map<dynamic, dynamic>.from(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final item = _map(entry.value);
      item['id'] = entry.key.toString();
      result.add(item);
    }

    result.sort(
      (first, second) => _dateValue(
        second,
      ).compareTo(
        _dateValue(first),
      ),
    );

    return result;
  }

  List<Map<String, dynamic>> _filteredApplications(
    List<Map<String, dynamic>> source,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    return source.where((item) {
      final status = _normalStatus(item);

      if (_selectedFilter != 'semua' &&
          status != _selectedFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final combined = <dynamic>[
        item['nama'],
        item['nama_anggota'],
        item['nik'],
        item['jenis_pupuk'],
        item['nama_pupuk'],
        item['nama_program'],
        item['periode'],
        item['status'],
        item['tanggal_pengajuan'],
        item['catatan'],
        item['catatan_user'],
        item['catatan_admin'],
      ].map(
        (value) => _text(
          value,
          fallback: '',
        ).toLowerCase(),
      ).join(' ');

      return combined.contains(query);
    }).toList();
  }

  int _statusCount(
    List<Map<String, dynamic>> source,
    String status,
  ) {
    return source.where(
      (item) => _normalStatus(item) == status,
    ).length;
  }

  Future<void> _showDetail(
    Map<String, dynamic> item,
  ) async {
    final screenSize = MediaQuery.sizeOf(context);
    final status = _normalStatus(item);
    final statusColor = _statusColor(status);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:
          adminNavy.withValues(alpha: 0.48),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.84,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  10,
                  18,
                  22,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 42,
                        decoration: BoxDecoration(
                          color: cardBorder,
                          borderRadius:
                              BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _iconBox(
                          icon: Icons.eco_outlined,
                          color: statusColor,
                          background:
                              _statusBackground(status),
                          size: 48,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _memberName(item),
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: textDark,
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _maskedNik(item['nik']),
                                style: const TextStyle(
                                  color: textGrey,
                                  fontSize: 10.3,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailRow(
                      icon: Icons.badge_outlined,
                      label: 'NIK',
                      value: _text(item['nik']),
                    ),
                    _detailRow(
                      icon: Icons.campaign_outlined,
                      label: 'Program',
                      value: _programName(item),
                    ),
                    _detailRow(
                      icon: Icons.eco_outlined,
                      label: 'Jenis Pupuk',
                      value: _fertilizerName(item),
                    ),
                    _detailRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Jumlah',
                      value: _amount(item),
                    ),
                    _detailRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Tanggal Pengajuan',
                      value: _dateText(item),
                    ),
                    _detailRow(
                      icon: Icons.event_repeat_outlined,
                      label: 'Periode',
                      value: _period(item),
                    ),
                    _detailRow(
                      icon: Icons.place_outlined,
                      label: 'Lokasi Pengambilan',
                      value: _text(
                        item['lokasi_pengambilan'] ??
                            item['tempat_pengambilan'],
                      ),
                    ),
                    _detailRow(
                      icon: Icons.notes_outlined,
                      label: 'Catatan Anggota',
                      value: _text(
                        item['catatan_user'] ??
                            item['catatan'] ??
                            item['keterangan'],
                      ),
                    ),
                    _detailRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Catatan Admin',
                      value: _text(
                        item['catatan_admin'] ??
                            item['pesan_admin'] ??
                            item['alasan_penolakan'],
                      ),
                      last: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: adminPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Tutup',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 350
        ? 12.0
        : screenWidth >= 700
            ? 22.0
            : 16.0;

    return Scaffold(
      backgroundColor: pageBackground,
      body: AppBackground(
        showPattern: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _FertilizerBackground(),
            SafeArea(
              child: StreamBuilder<DatabaseEvent>(
                stream: _bantuanRef.onValue,
                builder: (context, snapshot) {
                  final applications =
                      _applications(
                    snapshot.data?.snapshot.value,
                  );

                  final filtered =
                      _filteredApplications(
                    applications,
                  );

                  return RefreshIndicator(
                    color: adminPurple,
                    backgroundColor: Colors.white,
                    onRefresh: _refreshData,
                    child: ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        28,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(
                              maxWidth: 840,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                _header(
                                  applications.length,
                                ),
                                const SizedBox(height: 10),
                                _summary(
                                  total:
                                      applications.length,
                                  waiting: _statusCount(
                                    applications,
                                    'menunggu',
                                  ),
                                  approved: _statusCount(
                                    applications,
                                    'disetujui',
                                  ),
                                  completed: _statusCount(
                                    applications,
                                    'sudah_diambil',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _searchBox(),
                                const SizedBox(height: 8),
                                _filterBar(),
                                const SizedBox(height: 15),
                                _sectionTitle(
                                  filtered.length,
                                ),
                                const SizedBox(height: 9),
                                if (snapshot
                                        .connectionState ==
                                    ConnectionState.waiting)
                                  _loadingState()
                                else if (snapshot.hasError)
                                  _emptyState(
                                    icon:
                                        Icons.cloud_off_outlined,
                                    title:
                                        'Data Gagal Dimuat',
                                    message:
                                        'Periksa koneksi lalu tarik halaman ke bawah.',
                                  )
                                else if (filtered.isEmpty)
                                  _emptyState(
                                    icon: Icons
                                        .inventory_2_outlined,
                                    title:
                                        'Data Tidak Ditemukan',
                                    message:
                                        applications.isEmpty
                                            ? 'Belum ada data bantuan pupuk.'
                                            : 'Coba gunakan pencarian atau filter lain.',
                                  )
                                else
                                  LayoutBuilder(
                                    builder: (
                                      context,
                                      constraints,
                                    ) {
                                      final columns =
                                          constraints
                                                      .maxWidth >=
                                                  700
                                              ? 2
                                              : 1;

                                      const gap = 9.0;

                                      final itemWidth =
                                          columns == 2
                                              ? (constraints
                                                          .maxWidth -
                                                      gap) /
                                                  2
                                              : constraints
                                                  .maxWidth;

                                      return Wrap(
                                        spacing: gap,
                                        runSpacing: gap,
                                        children:
                                            filtered.map(
                                          (item) {
                                            return SizedBox(
                                              width:
                                                  itemWidth,
                                              child: _dataCard(
                                                item,
                                              ),
                                            );
                                          },
                                        ).toList(),
                                      );
                                    },
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
          ],
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            adminNavy,
            adminIndigo,
            adminPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color:
                adminNavy.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 10),
          _iconBox(
            icon: Icons.inventory_2_outlined,
            color: Colors.white,
            background:
                Colors.white.withValues(alpha: 0.14),
            size: 46,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Bantuan Pupuk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Cek riwayat bantuan anggota',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffE5E7FF),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(
              minWidth: 42,
              minHeight: 32,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.14),
              borderRadius:
                  BorderRadius.circular(99),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                total > 999
                    ? '999+'
                    : total.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary({
    required int total,
    required int waiting,
    required int approved,
    required int completed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 430;

        final columns = compact ? 2 : 4;
        final gap = compact ? 7.0 : 8.0;

        final width =
            (constraints.maxWidth -
                    gap * (columns - 1)) /
                columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _summaryItem(
                label: 'Total',
                value: total,
                icon:
                    Icons.assignment_outlined,
                color: adminPurple,
                background: softPurple,
              ),
            ),
            SizedBox(
              width: width,
              child: _summaryItem(
                label: 'Menunggu',
                value: waiting,
                icon: Icons.schedule_outlined,
                color: amber,
                background: softAmber,
              ),
            ),
            SizedBox(
              width: width,
              child: _summaryItem(
                label: 'Disetujui',
                value: approved,
                icon: Icons.verified_outlined,
                color: blue,
                background: softBlue,
              ),
            ),
            SizedBox(
              width: width,
              child: _summaryItem(
                label: 'Diambil',
                value: completed,
                icon: Icons.done_all_outlined,
                color: green,
                background: softGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 69,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 8,
      ),
      decoration: _cardDecoration(radius: 16),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value > 999
                ? '999+'
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
              fontSize: 8.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 48,
      decoration: _cardDecoration(radius: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText:
              'Cari nama, NIK, pupuk, status...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: adminPurple,
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
                    color: textGrey,
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
          hintStyle: const TextStyle(
            color: textGrey,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _filterBar() {
    const filters = <Map<String, String>>[
      {
        'value': 'semua',
        'label': 'Semua',
      },
      {
        'value': 'menunggu',
        'label': 'Menunggu',
      },
      {
        'value': 'disetujui',
        'label': 'Disetujui',
      },
      {
        'value': 'sudah_diambil',
        'label': 'Diambil',
      },
      {
        'value': 'ditolak',
        'label': 'Ditolak',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((item) {
          final value = item['value']!;
          final selected =
              _selectedFilter == value;

          return Padding(
            padding:
                const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              selected: selected,
              showCheckmark: false,
              label: Text(item['label']!),
              selectedColor: adminPurple,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected
                    ? adminPurple
                    : cardBorder,
              ),
              visualDensity:
                  const VisualDensity(
                horizontal: -3,
                vertical: -3,
              ),
              materialTapTargetSize:
                  MaterialTapTargetSize.shrinkWrap,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : textGrey,
                fontSize: 9.3,
                fontWeight: FontWeight.w900,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = value;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionTitle(int count) {
    return Row(
      children: [
        Container(
          height: 29,
          width: 5,
          decoration: BoxDecoration(
            color: adminPurple,
            borderRadius:
                BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Bantuan',
                style: TextStyle(
                  color: textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Ketuk kartu untuk melihat detail.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 9.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: softPurple,
            borderRadius:
                BorderRadius.circular(99),
          ),
          child: Text(
            '$count data',
            style: const TextStyle(
              color: adminPurple,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataCard(
    Map<String, dynamic> item,
  ) {
    final status = _normalStatus(item);
    final color = _statusColor(status);

    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          _showDetail(item);
        },
        borderRadius:
            BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration:
              _cardDecoration(radius: 18),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _iconBox(
                icon: Icons.eco_outlined,
                color: color,
                background:
                    _statusBackground(status),
                size: 42,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _memberName(item),
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 12.6,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskedNik(item['nik']),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 9.4,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _miniInfo(
                          icon: Icons.eco_outlined,
                          text:
                              _fertilizerName(item),
                          color: green,
                        ),
                        _miniInfo(
                          icon: Icons
                              .inventory_2_outlined,
                          text: _amount(item),
                          color: amber,
                        ),
                        _miniInfo(
                          icon: Icons
                              .calendar_month_outlined,
                          text: _dateText(item),
                          color: blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: textGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius:
            BorderRadius.circular(99),
      ),
      child: Text(
        _statusText(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 7.1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _miniInfo({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius:
            BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 10.5,
          ),
          const SizedBox(width: 3),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 120,
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : const BorderSide(
                  color: cardBorder,
                ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _iconBox(
            icon: icon,
            color: adminPurple,
            background: softPurple,
            size: 34,
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
                    fontSize: 8.8,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 10.6,
                    height: 1.35,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 98,
          margin:
              const EdgeInsets.only(bottom: 9),
          decoration:
              _cardDecoration(radius: 18),
          alignment: Alignment.center,
          child:
              const CircularProgressIndicator(
            color: adminPurple,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration:
          _cardDecoration(radius: 20),
      child: Column(
        children: [
          _iconBox(
            icon: icon,
            color: adminPurple,
            background: softPurple,
            size: 62,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 9.6,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          Navigator.maybePop(context);
        },
        borderRadius:
            BorderRadius.circular(14),
        child: _iconBox(
          icon: Icons.arrow_back_rounded,
          color: Colors.white,
          background:
              Colors.white.withValues(
            alpha: 0.14,
          ),
          size: 42,
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
        borderRadius:
            BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color:
          Colors.white.withValues(alpha: 0.98),
      borderRadius:
          BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color:
              adminNavy.withValues(alpha: 0.045),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class _FertilizerBackground extends StatelessWidget {
  const _FertilizerBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortest =
                constraints.maxWidth <
                        constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;

            final large = (shortest * 1.05)
                .clamp(290.0, 500.0)
                .toDouble();

            return Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xff172A46),
                        Color(0xff435987),
                        Color(0xffE5E7F1),
                        Color(0xffF2F4F8),
                      ],
                      stops: [
                        0,
                        0.16,
                        0.42,
                        1,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -large * 0.56,
                  right: -large * 0.28,
                  child: Container(
                    height: large,
                    width: large,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xff8D7AD0,
                      ).withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}