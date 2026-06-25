import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class DataBantuanPupukPage extends StatefulWidget {
  const DataBantuanPupukPage({super.key});

  @override
  State<DataBantuanPupukPage> createState() => _DataBantuanPupukPageState();
}

class _DataBantuanPupukPageState extends State<DataBantuanPupukPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color redStatus = Color(0xffDC2626);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final ValueNotifier<String> _keywordNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _filterNotifier = ValueNotifier<String>('semua');

  final DatabaseReference _bantuanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('bantuan_pupuk');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keywordNotifier.dispose();
    _filterNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _bantuanRef.get();
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
        item['tanggal_pengajuan'] ??
        item['tanggal'] ??
        item['created_at'] ??
        item['waktu_pengajuan'];

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

  String _jenisPupuk(Map<String, dynamic> item) {
    return _text(item['jenis_pupuk'] ?? item['nama_pupuk']);
  }

  String _jumlahPupuk(Map<String, dynamic> item) {
    final jumlah = _text(
      item['jumlah_pupuk'] ?? item['jumlah_kg'] ?? item['jumlah'],
    );

    if (jumlah == '-') return '-';
    return '$jumlah Kg';
  }

  String _tanggalPengajuan(Map<String, dynamic> item) {
    final raw = _text(
      item['tanggal_pengajuan'] ??
          item['tanggal'] ??
          item['created_at'] ??
          item['waktu_pengajuan'],
      fallback: '',
    );

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

  int _countStatus(List<Map<String, dynamic>> data, String status) {
    return data.where((item) => _statusData(item) == status).length;
  }

  Color _statusColor(String status) {
    if (status == 'disetujui') return blueStatus;
    if (status == 'ditolak') return redStatus;
    if (status == 'sudah_diambil') return primaryGreen;
    return orangeStatus;
  }

  Color _statusBackground(String status) {
    if (status == 'disetujui') return const Color(0xffE3F2FD);
    if (status == 'ditolak') return const Color(0xffFEE2E2);
    if (status == 'sudah_diambil') return lightGreen;
    return const Color(0xffFFF3E0);
  }

  String _statusText(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    if (status == 'sudah_diambil') return 'Diambil';
    return 'Menunggu';
  }

  List<Map<String, dynamic>> _filterData({
    required List<Map<String, dynamic>> data,
    required String keyword,
    required String filter,
  }) {
    var result = data;

    if (filter != 'semua') {
      result = result.where((item) => _statusData(item) == filter).toList();
    }

    final q = keyword.toLowerCase().trim();
    if (q.isEmpty) return result;

    return result.where((item) {
      final combined = [
        item['nama'],
        item['nik'],
        item['jenis_pupuk'],
        item['nama_pupuk'],
        item['status'],
        item['tanggal_pengajuan'],
        item['tanggal'],
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
            stream: _bantuanRef.onValue,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                  children: [
                    _header(total: 0),
                    const SizedBox(height: 16),
                    _emptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Terjadi Kesalahan',
                      message: snapshot.error.toString(),
                    ),
                  ],
                );
              }

              final semuaData = _ambilData(snapshot.data?.snapshot.value);
              final menunggu = _countStatus(semuaData, 'menunggu');
              final disetujui = _countStatus(semuaData, 'disetujui');
              final diambil = _countStatus(semuaData, 'sudah_diambil');
              final ditolak = _countStatus(semuaData, 'ditolak');

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
                      diambil: diambil,
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
                                  title: 'Daftar Data',
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
                                    icon: Icons.inbox_outlined,
                                    title: 'Belum Ada Data',
                                    message:
                                        'Data bantuan pupuk akan muncul setelah anggota mengajukan bantuan.',
                                  )
                                else if (dataFilter.isEmpty)
                                  _emptyState(
                                    icon: Icons.search_off_rounded,
                                    title: 'Data Tidak Ditemukan',
                                    message:
                                        'Tidak ada data yang sesuai dengan pencarian atau filter.',
                                  )
                                else
                                  ...dataFilter.asMap().entries.map(
                                    (entry) => _dataCard(
                                      nomor: entry.key + 1,
                                      item: entry.value,
                                    ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _backButton(),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Data Bantuan Pupuk',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _headerBadge('$total Data'),
            ],
          ),
          const SizedBox(height: 14),
          _headerInfo(
            icon: Icons.eco_rounded,
            text:
                total == 0
                    ? 'Belum ada data bantuan pupuk.'
                    : 'Menampilkan data bantuan pupuk secara ringkas dan mudah dibaca.',
          ),
        ],
      ),
    );
  }

  Widget _headerBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _headerInfo({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.90),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
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
    required int diambil,
    required int ditolak,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Data',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pantauan status data bantuan pupuk yang tersimpan di sistem.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12.2,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
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
                  icon: Icons.schedule_rounded,
                  color: orangeStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  title: 'Disetujui',
                  value: disetujui.toString(),
                  icon: Icons.check_circle_rounded,
                  color: blueStatus,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _summaryItem(
                  title: 'Diambil',
                  value: diambil.toString(),
                  icon: Icons.inventory_rounded,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _summaryItem(
                  title: 'Ditolak',
                  value: ditolak.toString(),
                  icon: Icons.cancel_rounded,
                  color: redStatus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 19,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.5,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      decoration: _cardDecoration(),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        maxLines: 1,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        onChanged: (value) => _keywordNotifier.value = value,
        decoration: InputDecoration(
          hintText: 'Cari nama, NIK, jenis pupuk, atau status',
          prefixIcon: const Icon(Icons.search_rounded, color: primaryGreen),
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
                icon: const Icon(Icons.close_rounded, color: textGrey),
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          hintStyle: const TextStyle(
            color: textGrey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
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
      ['sudah_diambil', 'Diambil'],
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
                      label: Text(item[1]),
                      selectedColor: primaryGreen,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: aktif ? primaryGreen : cardBorder,
                      ),
                      labelStyle: TextStyle(
                        color: aktif ? Colors.white : textGrey,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
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
          height: 34,
          width: 5,
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
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dataCard({required int nomor, required Map<String, dynamic> item}) {
    final status = _statusData(item);
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _numberBox(nomor),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(item['nama']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIK ${_text(item['nik'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _miniTag(
                      Icons.eco_rounded,
                      _jenisPupuk(item),
                      primaryGreen,
                    ),
                    _miniTag(
                      Icons.inventory_2_rounded,
                      _jumlahPupuk(item),
                      orangeStatus,
                    ),
                    _miniTag(
                      Icons.event_rounded,
                      _tanggalPengajuan(item),
                      blueStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(status, color),
        ],
      ),
    );
  }

  Widget _numberBox(int nomor) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          nomor.toString(),
          style: const TextStyle(
            color: primaryGreen,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        _statusText(status).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _miniTag(IconData icon, String text, Color color) {
    final value = text.trim().isEmpty ? '-' : text.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
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
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 84,
            width: 84,
            decoration: BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.5,
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
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 13,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
