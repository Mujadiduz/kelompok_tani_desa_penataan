import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class AnggotaAktifPage extends StatefulWidget {
  const AnggotaAktifPage({super.key});

  @override
  State<AnggotaAktifPage> createState() =>
      _AnggotaAktifPageState();
}

class _AnggotaAktifPageState extends State<AnggotaAktifPage> {
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminIndigo = Color(0xff435987);
  static const Color adminPurple = Color(0xff6256A4);

  static const Color green = Color(0xff2E7D32);
  static const Color blue = Color(0xff326CA3);

  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softBlue = Color(0xffE9F2FA);
  static const Color softPurple = Color(0xffF0ECFA);

  final TextEditingController _searchController =
      TextEditingController();

  final DatabaseReference _anggotaRef =
      FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  String _searchQuery = '';
  String _selectedFilter = 'semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _anggotaRef.get();
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

  String _status(Map<String, dynamic> item) {
    return _text(
      item['status'],
      fallback: '',
    ).toLowerCase();
  }

  String _genderRaw(Map<String, dynamic> item) {
    return _text(
      item['jenis_kelamin'] ??
          item['jenisKelamin'],
      fallback: '',
    ).toLowerCase();
  }

  String _genderText(Map<String, dynamic> item) {
    final value = _genderRaw(item);

    if (value == 'laki-laki' ||
        value == 'laki laki' ||
        value == 'pria') {
      return 'Laki-laki';
    }

    if (value == 'perempuan' ||
        value == 'wanita') {
      return 'Perempuan';
    }

    return '-';
  }

  String _phone(Map<String, dynamic> item) {
    return _text(
      item['telepon'] ??
          item['no_hp'] ??
          item['nomor_hp'],
    );
  }

  String _landArea(Map<String, dynamic> item) {
    final raw = _text(
      item['luas_lahan'] ??
          item['luas_sawah'],
      fallback: '',
    );

    if (raw.isEmpty) {
      return '-';
    }

    final lower = raw.toLowerCase();

    if (lower.contains('ha') ||
        lower.contains('m²') ||
        lower.contains('m2') ||
        lower.contains('meter')) {
      return raw;
    }

    return '$raw ha';
  }

  String _registrationDate(
    Map<String, dynamic> item,
  ) {
    final raw = _text(
      item['tanggal_daftar'] ??
          item['tanggal_verifikasi'] ??
          item['created_at'] ??
          item['tanggal'],
      fallback: '',
    );

    if (raw.isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return raw;
    }

    return '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/'
        '${parsed.year}';
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

  List<Map<String, dynamic>> _members(
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
      final status = _status(item);

      if (status.isNotEmpty &&
          status != 'aktif' &&
          status != 'anggota' &&
          status != 'disetujui') {
        continue;
      }

      item['id'] = entry.key.toString();
      result.add(item);
    }

    result.sort(
      (first, second) => _text(
        first['nama'],
      ).toLowerCase().compareTo(
            _text(
              second['nama'],
            ).toLowerCase(),
          ),
    );

    return result;
  }

  List<Map<String, dynamic>> _filteredMembers(
    List<Map<String, dynamic>> source,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    return source.where((item) {
      final gender = _genderRaw(item);

      if (_selectedFilter == 'laki' &&
          gender != 'laki-laki' &&
          gender != 'laki laki' &&
          gender != 'pria') {
        return false;
      }

      if (_selectedFilter == 'perempuan' &&
          gender != 'perempuan' &&
          gender != 'wanita') {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final combined = <dynamic>[
        item['nama'],
        item['nik'],
        item['alamat'],
        item['telepon'],
        item['no_hp'],
        item['nomor_hp'],
        item['jenis_kelamin'],
        item['luas_lahan'],
        item['luas_sawah'],
      ].map(
        (value) => _text(
          value,
          fallback: '',
        ).toLowerCase(),
      ).join(' ');

      return combined.contains(query);
    }).toList();
  }

  int _maleCount(List<Map<String, dynamic>> source) {
    return source.where((item) {
      final value = _genderRaw(item);

      return value == 'laki-laki' ||
          value == 'laki laki' ||
          value == 'pria';
    }).length;
  }

  int _femaleCount(
    List<Map<String, dynamic>> source,
  ) {
    return source.where((item) {
      final value = _genderRaw(item);

      return value == 'perempuan' ||
          value == 'wanita';
    }).length;
  }

  Future<void> _showMemberDetail(
    Map<String, dynamic> item,
  ) async {
    final screenSize = MediaQuery.sizeOf(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: adminNavy.withValues(alpha: 0.48),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenSize.height * 0.82,
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
                          icon: Icons.person_outline_rounded,
                          color: green,
                          background: softGreen,
                          size: 48,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                _text(item['nama']),
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
                        _activeBadge(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailRow(
                      icon: Icons.badge_outlined,
                      label: 'NIK',
                      value: _text(item['nik']),
                    ),
                    _detailRow(
                      icon: Icons.phone_outlined,
                      label: 'Nomor Telepon',
                      value: _phone(item),
                    ),
                    _detailRow(
                      icon: Icons.wc_outlined,
                      label: 'Jenis Kelamin',
                      value: _genderText(item),
                    ),
                    _detailRow(
                      icon: Icons.home_outlined,
                      label: 'Alamat',
                      value: _text(item['alamat']),
                    ),
                    _detailRow(
                      icon: Icons.landscape_outlined,
                      label: 'Luas Lahan',
                      value: _landArea(item),
                    ),
                    _detailRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Tanggal Daftar',
                      value: _registrationDate(item),
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
            const _MemberBackground(),
            SafeArea(
              child: StreamBuilder<DatabaseEvent>(
                stream: _anggotaRef.onValue,
                builder: (context, snapshot) {
                  final members = _members(
                    snapshot.data?.snapshot.value,
                  );

                  final filtered =
                      _filteredMembers(members);

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
                                _header(members.length),
                                const SizedBox(height: 10),
                                _summary(
                                  total: members.length,
                                  male:
                                      _maleCount(members),
                                  female:
                                      _femaleCount(members),
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
                                    icon:
                                        Icons.people_outline_rounded,
                                    title:
                                        'Anggota Tidak Ditemukan',
                                    message:
                                        members.isEmpty
                                            ? 'Belum ada anggota aktif.'
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
                                              child:
                                                  _memberCard(
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
            color: adminNavy.withValues(alpha: 0.22),
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
            icon: Icons.groups_2_outlined,
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
                  'Anggota Aktif',
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
                  'Cek data anggota resmi',
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
              borderRadius: BorderRadius.circular(99),
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
    required int male,
    required int female,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap =
            constraints.maxWidth < 350 ? 6.0 : 8.0;

        final width =
            (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _summaryItem(
                label: 'Total',
                value: total,
                icon: Icons.groups_2_outlined,
                color: adminPurple,
                background: softPurple,
              ),
            ),
            SizedBox(
              width: width,
              child: _summaryItem(
                label: 'Laki-laki',
                value: male,
                icon: Icons.male_rounded,
                color: blue,
                background: softBlue,
              ),
            ),
            SizedBox(
              width: width,
              child: _summaryItem(
                label: 'Perempuan',
                value: female,
                icon: Icons.female_rounded,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value > 999 ? '999+' : value.toString(),
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
          hintText: 'Cari nama, NIK, alamat...',
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
          contentPadding: const EdgeInsets.symmetric(
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
        'value': 'laki',
        'label': 'Laki-laki',
      },
      {
        'value': 'perempuan',
        'label': 'Perempuan',
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
            padding: const EdgeInsets.only(right: 6),
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
              visualDensity: const VisualDensity(
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
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Anggota',
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
            borderRadius: BorderRadius.circular(99),
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

  Widget _memberCard(
    Map<String, dynamic> item,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          _showMemberDetail(item);
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: _cardDecoration(radius: 18),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _iconBox(
                icon: Icons.person_outline_rounded,
                color: green,
                background: softGreen,
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
                            _text(item['nama']),
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
                        _activeBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskedNik(item['nik']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 9.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _miniInfo(
                          icon:
                              Icons.phone_outlined,
                          text: _phone(item),
                          color: blue,
                        ),
                        _miniInfo(
                          icon: Icons.wc_outlined,
                          text: _genderText(item),
                          color: adminPurple,
                        ),
                        _miniInfo(
                          icon:
                              Icons.landscape_outlined,
                          text: _landArea(item),
                          color: green,
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

  Widget _activeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: softGreen,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'AKTIF',
        style: TextStyle(
          color: green,
          fontSize: 7.3,
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
        borderRadius: BorderRadius.circular(99),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 10.6,
                    height: 1.35,
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

  Widget _loadingState() {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 98,
          margin: const EdgeInsets.only(bottom: 9),
          decoration: _cardDecoration(radius: 18),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
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
      decoration: _cardDecoration(radius: 20),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.maybePop(context);
        },
        borderRadius: BorderRadius.circular(14),
        child: _iconBox(
          icon: Icons.arrow_back_rounded,
          color: Colors.white,
          background:
              Colors.white.withValues(alpha: 0.14),
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
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: adminNavy.withValues(alpha: 0.045),
          blurRadius: 13,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class _MemberBackground extends StatelessWidget {
  const _MemberBackground();

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