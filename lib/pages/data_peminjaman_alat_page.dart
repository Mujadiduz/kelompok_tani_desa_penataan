import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DataPeminjamanAlatPage extends StatefulWidget {
  const DataPeminjamanAlatPage({super.key});

  @override
  State<DataPeminjamanAlatPage> createState() => _DataPeminjamanAlatPageState();
}

class _DataPeminjamanAlatPageState extends State<DataPeminjamanAlatPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color redStatus = Color(0xffE53935);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  final ValueNotifier<String> keywordNotifier = ValueNotifier<String>('');
  final ValueNotifier<String> filterNotifier = ValueNotifier<String>('semua');

  final DatabaseReference peminjamanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('peminjaman_alat');

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    keywordNotifier.dispose();
    filterNotifier.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> ambilData(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries.map((entry) {
          final item = Map<String, dynamic>.from(entry.value as Map);
          item['id'] = entry.key.toString();
          return item;
        }).toList();

    return list.reversed.toList();
  }

  String statusData(Map<String, dynamic> item) {
    return (item['status'] ?? 'menunggu').toString().toLowerCase().trim();
  }

  List<Map<String, dynamic>> filterData({
    required List<Map<String, dynamic>> data,
    required String keyword,
    required String filter,
  }) {
    var result = data;

    if (filter != 'semua') {
      result = result.where((item) => statusData(item) == filter).toList();
    }

    final q = keyword.toLowerCase().trim();

    if (q.isNotEmpty) {
      result =
          result.where((item) {
            final gabungan = [
              item['nama'],
              item['nik'],
              item['alat'],
              item['nama_alat'],
              item['status'],
              item['tanggal_pinjam'],
              item['tanggal_kembali'],
              item['catatan'],
            ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

            return gabungan.contains(q);
          }).toList();
    }

    return result;
  }

  int hitungStatus(List<Map<String, dynamic>> data, String status) {
    return data.where((item) => statusData(item) == status).length;
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') return blueStatus;
    if (status == 'ditolak') return redStatus;
    if (status == 'dipinjam') return orangeStatus;
    if (status == 'selesai' || status == 'dikembalikan') return primaryGreen;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return const Color(0xffE3F2FD);
    if (status == 'ditolak') return const Color(0xffFFEBEE);
    if (status == 'dipinjam') return const Color(0xffFFF3E0);
    if (status == 'selesai' || status == 'dikembalikan') return lightGreen;
    return const Color(0xffFFF3E0);
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    if (status == 'dipinjam') return 'Dipinjam';
    if (status == 'selesai') return 'Selesai';
    if (status == 'dikembalikan') return 'Dikembalikan';
    return 'Menunggu';
  }

  String formatTanggal(dynamic value) {
    final raw = (value ?? '').toString();
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

  String namaAlat(Map<String, dynamic> item) {
    return (item['alat'] ?? item['nama_alat'] ?? '-').toString();
  }

  String tanggalPinjam(Map<String, dynamic> item) {
    return formatTanggal(item['tanggal_pinjam'] ?? item['tanggalPinjam']);
  }

  String tanggalKembali(Map<String, dynamic> item) {
    return formatTanggal(item['tanggal_kembali'] ?? item['tanggalKembali']);
  }

  int hitungSelesai(List<Map<String, dynamic>> data) {
    return data.where((item) {
      final status = statusData(item);
      return status == 'selesai' || status == 'dikembalikan';
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: peminjamanRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  _header(0),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  _header(0),
                  Expanded(
                    child: _emptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Terjadi Kesalahan',
                      message: snapshot.error.toString(),
                    ),
                  ),
                ],
              );
            }

            final semuaData = ambilData(snapshot.data?.snapshot.value);

            final menunggu = hitungStatus(semuaData, 'menunggu');
            final disetujui = hitungStatus(semuaData, 'disetujui');
            final dipinjam = hitungStatus(semuaData, 'dipinjam');
            final selesai = hitungSelesai(semuaData);
            final ditolak = hitungStatus(semuaData, 'ditolak');

            return Column(
              children: [
                _header(semuaData.length),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      _dashboardSummary(
                        total: semuaData.length,
                        menunggu: menunggu,
                        disetujui: disetujui,
                        dipinjam: dipinjam,
                        selesai: selesai,
                        ditolak: ditolak,
                      ),
                      const SizedBox(height: 16),
                      _searchBox(),
                      const SizedBox(height: 12),
                      _filterChips(),
                      const SizedBox(height: 18),
                      ValueListenableBuilder<String>(
                        valueListenable: keywordNotifier,
                        builder: (context, keyword, _) {
                          return ValueListenableBuilder<String>(
                            valueListenable: filterNotifier,
                            builder: (context, filter, _) {
                              final dataFilter = filterData(
                                data: semuaData,
                                keyword: keyword,
                                filter: filter,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionHeader(dataFilter.length),
                                  const SizedBox(height: 12),
                                  if (semuaData.isEmpty)
                                    _emptyState(
                                      icon: Icons.inbox_outlined,
                                      title: 'Belum Ada Data',
                                      message:
                                          'Data peminjaman alat akan muncul setelah anggota mengajukan peminjaman.',
                                    )
                                  else if (dataFilter.isEmpty)
                                    _emptyState(
                                      icon: Icons.search_off_rounded,
                                      title: 'Data Tidak Ditemukan',
                                      message:
                                          'Tidak ada data peminjaman alat yang sesuai dengan pencarian atau filter.',
                                    )
                                  else
                                    ...dataFilter.asMap().entries.map((entry) {
                                      return _dataRowCard(
                                        entry.key + 1,
                                        entry.value,
                                      );
                                    }),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff14532D), Color(0xff2E7D32), Color(0xff66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            bottom: -42,
            child: Icon(
              Icons.agriculture_rounded,
              size: 155,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Data Peminjaman Alat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text(
                      'Rekap Peminjaman Alat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _headerCounter(total),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Halaman ini digunakan untuk melihat rekap seluruh peminjaman alat tanpa proses verifikasi.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCounter(int total) {
    return Container(
      constraints: const BoxConstraints(minWidth: 58, minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'rekap',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardSummary({
    required int total,
    required int menunggu,
    required int disetujui,
    required int dipinjam,
    required int selesai,
    required int ditolak,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  title: 'Total',
                  value: total.toString(),
                  icon: Icons.dataset_rounded,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  title: 'Menunggu',
                  value: menunggu.toString(),
                  icon: Icons.schedule_rounded,
                  color: orangeStatus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryBox(
                  title: 'Disetujui',
                  value: disetujui.toString(),
                  icon: Icons.check_circle_rounded,
                  color: blueStatus,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  title: 'Dipinjam',
                  value: dipinjam.toString(),
                  icon: Icons.agriculture_rounded,
                  color: orangeStatus,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryBox(
                  title: 'Selesai',
                  value: selesai.toString(),
                  icon: Icons.task_alt_rounded,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _summaryBox(
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

  Widget _summaryBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 7),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.5,
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
        controller: searchController,
        focusNode: searchFocusNode,
        maxLines: 1,
        textInputAction: TextInputAction.search,
        keyboardType: TextInputType.text,
        onChanged: (value) {
          keywordNotifier.value = value;
        },
        decoration: InputDecoration(
          hintText: 'Cari nama, NIK, alat, tanggal, atau status',
          prefixIcon: const Icon(Icons.search_rounded, color: primaryGreen),
          suffixIcon: ValueListenableBuilder<String>(
            valueListenable: keywordNotifier,
            builder: (context, value, _) {
              if (value.isEmpty) return const SizedBox.shrink();

              return IconButton(
                onPressed: () {
                  searchController.clear();
                  keywordNotifier.value = '';
                  searchFocusNode.requestFocus();
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
      ['dipinjam', 'Dipinjam'],
      ['selesai', 'Selesai'],
      ['ditolak', 'Ditolak'],
    ];

    return ValueListenableBuilder<String>(
      valueListenable: filterNotifier,
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
                        color: aktif ? primaryGreen : const Color(0xffE5E7EB),
                      ),
                      labelStyle: TextStyle(
                        color: aktif ? Colors.white : textGrey,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        filterNotifier.value = item[0];
                      },
                    ),
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(int totalTampil) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Daftar Rekap',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$totalTampil data',
            style: const TextStyle(
              color: primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataRowCard(int nomor, Map<String, dynamic> item) {
    final status = statusData(item);
    final color = warnaStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 13),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
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
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (item['nama'] ?? '-').toString(),
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
                    'NIK ${item['nik'] ?? '-'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _miniTag(
                        Icons.agriculture_rounded,
                        namaAlat(item),
                        primaryGreen,
                      ),
                      _miniTag(
                        Icons.event_rounded,
                        tanggalPinjam(item),
                        blueStatus,
                      ),
                      _miniTag(
                        Icons.event_available_rounded,
                        tanggalKembali(item),
                        orangeStatus,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundStatus(status),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                teksStatus(status).toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniTag(IconData icon, String text, Color color) {
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
            text,
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

  Widget _backButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 22),
      child: Column(
        children: [
          Container(
            height: 88,
            width: 88,
            decoration: const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryGreen, size: 42),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
