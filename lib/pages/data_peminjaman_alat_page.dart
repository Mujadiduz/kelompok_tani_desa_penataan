import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class DataPeminjamanAlatPage extends StatefulWidget {
  const DataPeminjamanAlatPage({super.key});

  @override
  State<DataPeminjamanAlatPage> createState() => _DataPeminjamanAlatPageState();
}

class _DataPeminjamanAlatPageState extends State<DataPeminjamanAlatPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE6ECE8);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color redStatus = Color(0xffDC2626);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final ValueNotifier<String> _keywordNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _filterNotifier = ValueNotifier<String>('semua');

  final DatabaseReference _peminjamanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('peminjaman_alat');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keywordNotifier.dispose();
    _filterNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _peminjamanRef.get();
  }

  List<Map<String, dynamic>> _ambilData(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries.where((entry) => entry.value is Map).map((entry) {
          final item = Map<String, dynamic>.from(entry.value as Map);
          item['id'] = entry.key.toString();
          return item;
        }).toList();

    list.sort((a, b) => _timeValue(b).compareTo(_timeValue(a)));
    return list;
  }

  int _timeValue(Map<String, dynamic> item) {
    final raw =
        item['created_at'] ??
        item['createdAt'] ??
        item['tanggal_pengajuan'] ??
        item['tanggal_pinjam'] ??
        item['tanggalPinjam'];

    final parsed = DateTime.tryParse((raw ?? '').toString().trim());
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String _text(dynamic value, {String fallback = '-'}) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _statusData(Map<String, dynamic> item) {
    return _text(item['status'], fallback: 'menunggu').toLowerCase().trim();
  }

  String _namaAlat(Map<String, dynamic> item) {
    return _text(item['alat'] ?? item['nama_alat']);
  }

  String _tanggalPinjam(Map<String, dynamic> item) {
    return _formatTanggal(item['tanggal_pinjam'] ?? item['tanggalPinjam']);
  }

  String _tanggalKembali(Map<String, dynamic> item) {
    return _formatTanggal(item['tanggal_kembali'] ?? item['tanggalKembali']);
  }

  String _formatTanggal(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return '-';

    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return raw;
    }
  }

  String _maskNik(dynamic value) {
    final nik = _text(value, fallback: '').replaceAll(RegExp(r'\s+'), '');
    if (nik.isEmpty) return '•••• •••• •••• ----';

    final last4 = nik.length >= 4 ? nik.substring(nik.length - 4) : nik;
    return '•••• •••• •••• $last4';
  }

  int _countStatus(List<Map<String, dynamic>> data, List<String> statuses) {
    return data.where((item) => statuses.contains(_statusData(item))).length;
  }

  Color _statusColor(String status) {
    if (status == 'disetujui') return blueStatus;
    if (status == 'ditolak') return redStatus;
    if (status == 'dipinjam' || status == 'diambil') return orangeStatus;
    if (status == 'selesai' ||
        status == 'dikembalikan' ||
        status == 'sudah_dikembalikan') {
      return primaryGreen;
    }

    return orangeStatus;
  }

  Color _statusBackground(String status) {
    if (status == 'disetujui') return const Color(0xffE3F2FD);
    if (status == 'ditolak') return const Color(0xffFEE2E2);
    if (status == 'dipinjam' || status == 'diambil') {
      return const Color(0xffFFF3E0);
    }
    if (status == 'selesai' ||
        status == 'dikembalikan' ||
        status == 'sudah_dikembalikan') {
      return lightGreen;
    }

    return const Color(0xffFFF3E0);
  }

  String _statusText(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    if (status == 'dipinjam' || status == 'diambil') return 'Dipinjam';
    if (status == 'selesai' ||
        status == 'dikembalikan' ||
        status == 'sudah_dikembalikan') {
      return 'Selesai';
    }

    return 'Menunggu';
  }

  List<Map<String, dynamic>> _filterData({
    required List<Map<String, dynamic>> data,
    required String keyword,
    required String filter,
  }) {
    var result = data;

    if (filter == 'dipinjam') {
      result =
          result.where((item) {
            final status = _statusData(item);
            return status == 'dipinjam' || status == 'diambil';
          }).toList();
    } else if (filter == 'selesai') {
      result =
          result.where((item) {
            final status = _statusData(item);
            return status == 'selesai' ||
                status == 'dikembalikan' ||
                status == 'sudah_dikembalikan';
          }).toList();
    } else if (filter != 'semua') {
      result = result.where((item) => _statusData(item) == filter).toList();
    }

    final q = keyword.toLowerCase().trim();
    if (q.isEmpty) return result;

    return result.where((item) {
      final combined = [
        item['nama'],
        item['nik'],
        item['alat'],
        item['nama_alat'],
        item['status'],
        item['tanggal_pinjam'],
        item['tanggal_kembali'],
        item['tanggalPinjam'],
        item['tanggalKembali'],
        item['catatan'],
      ].map((e) => _text(e, fallback: '').toLowerCase()).join(' ');

      return combined.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: _peminjamanRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                  children: [
                    _header(total: 0),
                    const SizedBox(height: 16),
                    _emptyState(
                      icon: Icons.fact_check_rounded,
                      title: 'Terjadi Kesalahan',
                      message: snapshot.error.toString(),
                    ),
                  ],
                );
              }

              final semuaData = _ambilData(snapshot.data?.snapshot.value);

              final menunggu = _countStatus(semuaData, ['menunggu']);
              final disetujui = _countStatus(semuaData, ['disetujui']);
              final dipinjam = _countStatus(semuaData, ['dipinjam', 'diambil']);
              final selesai = _countStatus(semuaData, [
                'selesai',
                'dikembalikan',
                'sudah_dikembalikan',
              ]);
              final ditolak = _countStatus(semuaData, ['ditolak']);

              return RefreshIndicator(
                color: primaryGreen,
                backgroundColor: Colors.white,
                onRefresh: _refreshData,
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                  children: [
                    _header(total: semuaData.length),
                    const SizedBox(height: 16),
                    _summaryCard(
                      total: semuaData.length,
                      menunggu: menunggu,
                      disetujui: disetujui,
                      dipinjam: dipinjam,
                      selesai: selesai,
                      ditolak: ditolak,
                    ),
                    const SizedBox(height: 14),
                    _searchBox(),
                    const SizedBox(height: 12),
                    _filterChips(),
                    const SizedBox(height: 18),
                    ValueListenableBuilder<String>(
                      valueListenable: _keywordNotifier,
                      builder: (context, keyword, _) {
                        return ValueListenableBuilder<String>(
                          valueListenable: _filterNotifier,
                          builder: (context, filter, _) {
                            final dataFilter = _filterData(
                              data: semuaData,
                              keyword: keyword,
                              filter: filter,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  title: 'Daftar Peminjaman',
                                  subtitle:
                                      '${dataFilter.length} data ditampilkan',
                                ),
                                const SizedBox(height: 12),
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    semuaData.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(28),
                                      child: CircularProgressIndicator(
                                        color: primaryGreen,
                                      ),
                                    ),
                                  )
                                else if (semuaData.isEmpty)
                                  _emptyState(
                                    icon: Icons.assignment_ind_rounded,
                                    title: 'Belum Ada Data',
                                    message:
                                        'Data peminjaman alat akan muncul setelah anggota mengajukan peminjaman.',
                                  )
                                else if (dataFilter.isEmpty)
                                  _emptyState(
                                    icon: Icons.manage_search_rounded,
                                    title: 'Data Tidak Ditemukan',
                                    message:
                                        'Tidak ada data yang sesuai dengan pencarian atau filter.',
                                  )
                                else
                                  ...dataFilter.map(
                                    (item) => _dataCard(item: item),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header({required int total}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  'Data Peminjaman Alat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Riwayat pengajuan peminjaman alat pertanian',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffDDEFE3),
                    fontSize: 11.8,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _headerBadge(total),
        ],
      ),
    );
  }

  Widget _headerBadge(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.precision_manufacturing_rounded,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required int total,
    required int menunggu,
    required int disetujui,
    required int dipinjam,
    required int selesai,
    required int ditolak,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryItem(
                title: 'Total',
                value: total.toString(),
                icon: Icons.dataset_rounded,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _summaryItem(
                title: 'Menunggu',
                value: menunggu.toString(),
                icon: Icons.pending_actions_rounded,
                color: orangeStatus,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _summaryItem(
                title: 'Disetujui',
                value: disetujui.toString(),
                icon: Icons.verified_user_rounded,
                color: blueStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _summaryItem(
                title: 'Dipinjam',
                value: dipinjam.toString(),
                icon: Icons.handyman_rounded,
                color: orangeStatus,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _summaryItem(
                title: 'Selesai',
                value: selesai.toString(),
                icon: Icons.task_alt_rounded,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _summaryItem(
                title: 'Ditolak',
                value: ditolak.toString(),
                icon: Icons.cancel_presentation_rounded,
                color: redStatus,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.022),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 9.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        maxLines: 1,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        onChanged: (value) => _keywordNotifier.value = value,
        decoration: InputDecoration(
          hintText: 'Cari nama, NIK, alat, tanggal, atau status...',
          prefixIcon: const Icon(
            Icons.manage_search_rounded,
            color: primaryGreen,
            size: 19,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 42,
          ),
          suffixIcon: ValueListenableBuilder<String>(
            valueListenable: _keywordNotifier,
            builder: (context, value, _) {
              if (value.isEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: () {
                  _searchController.clear();
                  _keywordNotifier.value = '';
                  _searchFocusNode.requestFocus();
                },
                icon: const Icon(
                  Icons.cancel_rounded,
                  color: textGrey,
                  size: 18,
                ),
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.fromLTRB(0, 16, 14, 14),
          hintStyle: const TextStyle(
            color: textGrey,
            fontWeight: FontWeight.w600,
            fontSize: 12.7,
          ),
        ),
      ),
    );
  }

  Widget _filterChips() {
    final filters = [
      ['semua', 'Semua'],
      ['menunggu', 'Menunggu'],
      ['disetujui', 'Disetujui'],
      ['dipinjam', 'Dipinjam'],
      ['selesai', 'Selesai'],
      ['ditolak', 'Ditolak'],
    ];

    return ValueListenableBuilder<String>(
      valueListenable: _filterNotifier,
      builder: (context, selected, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          child: Row(
            children:
                filters.map((item) {
                  final aktif = selected == item[0];

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: aktif,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 7),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      selectedColor: primaryGreen,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color:
                            aktif
                                ? primaryGreen.withValues(alpha: 0.85)
                                : cardBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      label: Text(item[1]),
                      labelStyle: TextStyle(
                        color: aktif ? Colors.white : textGrey,
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                      onSelected: (_) => _filterNotifier.value = item[0],
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 4,
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
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dataCard({required Map<String, dynamic> item}) {
    final status = _statusData(item);
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.026),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatarBox(status),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _text(item['nama']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(status, color),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.badge_rounded, size: 13, color: textGrey),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _maskNik(item['nik']),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 11.4,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _miniInfo(
                      icon: Icons.precision_manufacturing_rounded,
                      text: _namaAlat(item),
                      color: primaryGreen,
                    ),
                    _miniInfo(
                      icon: Icons.calendar_month_rounded,
                      text: _tanggalPinjam(item),
                      color: blueStatus,
                    ),
                    _miniInfo(
                      icon: Icons.event_available_rounded,
                      text: _tanggalKembali(item),
                      color: orangeStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarBox(String status) {
    final color = _statusColor(status);

    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.11)),
      ),
      child: Icon(Icons.handyman_rounded, color: color, size: 21),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        _statusText(status).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _miniInfo({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    final value = text.trim().isEmpty ? '-' : text.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.026),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 34),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
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

  Widget _backButton() {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 17,
        ),
      ),
    );
  }
}
