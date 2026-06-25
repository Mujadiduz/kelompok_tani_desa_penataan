import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class AnggotaAktifPage extends StatefulWidget {
  const AnggotaAktifPage({super.key});

  @override
  State<AnggotaAktifPage> createState() => _AnggotaAktifPageState();
}

class _AnggotaAktifPageState extends State<AnggotaAktifPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final ValueNotifier<String> _keywordNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> _filterNotifier = ValueNotifier<String>('semua');

  final DatabaseReference _anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keywordNotifier.dispose();
    _filterNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await _anggotaRef.get();
  }

  List<Map<String, dynamic>> _ambilData(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final item = Map<String, dynamic>.from(entry.value as Map);
              item['id'] = entry.key.toString();
              return item;
            })
            .where((item) {
              final status = _statusData(item);
              return status.isEmpty ||
                  status == 'aktif' ||
                  status == 'anggota' ||
                  status == 'disetujui';
            })
            .toList();

    list.sort((a, b) {
      final namaA = _text(a['nama']).toLowerCase();
      final namaB = _text(b['nama']).toLowerCase();
      return namaA.compareTo(namaB);
    });

    return list;
  }

  String _text(dynamic value, {String fallback = '-'}) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _statusData(Map<String, dynamic> item) {
    return _text(item['status'], fallback: '').toLowerCase().trim();
  }

  String _telepon(Map<String, dynamic> item) {
    return _text(item['telepon'] ?? item['no_hp'] ?? item['nomor_hp']);
  }

  String _genderRaw(Map<String, dynamic> item) {
    return _text(
      item['jenis_kelamin'] ?? item['jenisKelamin'],
      fallback: '',
    ).toLowerCase().trim();
  }

  String _genderText(Map<String, dynamic> item) {
    final gender = _genderRaw(item);

    if (gender == 'laki-laki' || gender == 'laki laki' || gender == 'pria') {
      return 'Laki-laki';
    }

    if (gender == 'perempuan' || gender == 'wanita') {
      return 'Perempuan';
    }

    return '-';
  }

  String _tanggalDaftar(Map<String, dynamic> item) {
    final raw = _text(
      item['tanggal_daftar'] ??
          item['tanggal_verifikasi'] ??
          item['created_at'] ??
          item['tanggal'],
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

  int _countGender(List<Map<String, dynamic>> data, List<String> values) {
    return data.where((item) => values.contains(_genderRaw(item))).length;
  }

  List<Map<String, dynamic>> _filterData({
    required List<Map<String, dynamic>> data,
    required String keyword,
    required String filter,
  }) {
    var result = data;

    if (filter == 'laki') {
      result =
          result.where((item) {
            final gender = _genderRaw(item);
            return gender == 'laki-laki' ||
                gender == 'laki laki' ||
                gender == 'pria';
          }).toList();
    } else if (filter == 'perempuan') {
      result =
          result.where((item) {
            final gender = _genderRaw(item);
            return gender == 'perempuan' || gender == 'wanita';
          }).toList();
    }

    final q = keyword.toLowerCase().trim();
    if (q.isEmpty) return result;

    return result.where((item) {
      final combined = [
        item['nama'],
        item['nik'],
        item['alamat'],
        item['telepon'],
        item['no_hp'],
        item['nomor_hp'],
        item['jenis_kelamin'],
        item['jenisKelamin'],
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
            stream: _anggotaRef.onValue,
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
              final laki = _countGender(semuaData, [
                'laki-laki',
                'laki laki',
                'pria',
              ]);
              final perempuan = _countGender(semuaData, [
                'perempuan',
                'wanita',
              ]);

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
                      laki: laki,
                      perempuan: perempuan,
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
                                    icon: Icons.groups_2_outlined,
                                    title: 'Belum Ada Data',
                                    message:
                                        'Data anggota aktif akan muncul setelah calon anggota disetujui admin.',
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
                  'Anggota Aktif',
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
            icon: Icons.groups_rounded,
            text:
                total == 0
                    ? 'Belum ada data anggota aktif.'
                    : 'Menampilkan data anggota aktif secara ringkas dan mudah dibaca.',
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
    required int laki,
    required int perempuan,
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
            'Pantauan data anggota aktif yang tersimpan di sistem.',
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
                  title: 'Laki-laki',
                  value: laki.toString(),
                  icon: Icons.man_rounded,
                  color: blueStatus,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _summaryItem(
                  title: 'Perempuan',
                  value: perempuan.toString(),
                  icon: Icons.woman_rounded,
                  color: orangeStatus,
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
          hintText: 'Cari nama, NIK, alamat, atau telepon',
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
      ['laki', 'Laki-laki'],
      ['perempuan', 'Perempuan'],
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
                    _miniTag(Icons.phone_rounded, _telepon(item), primaryGreen),
                    _miniTag(Icons.wc_rounded, _genderText(item), blueStatus),
                    _miniTag(
                      Icons.event_rounded,
                      _tanggalDaftar(item),
                      orangeStatus,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(),
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

  Widget _statusBadge() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.14)),
      ),
      child: const Text(
        'AKTIF',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: primaryGreen,
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
