import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AnggotaAktifPage extends StatefulWidget {
  const AnggotaAktifPage({super.key});

  @override
  State<AnggotaAktifPage> createState() => _AnggotaAktifPageState();
}

class _AnggotaAktifPageState extends State<AnggotaAktifPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ValueNotifier<String> keywordNotifier = ValueNotifier<String>('');

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    keywordNotifier.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> ambilAnggota(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.values
            .whereType<Map>()
            .map((item) {
              return Map<String, dynamic>.from(item);
            })
            .where((anggota) {
              final status =
                  (anggota['status'] ?? '').toString().toLowerCase().trim();
              return status == 'aktif' || status.isEmpty;
            })
            .toList();

    list.sort((a, b) {
      final namaA = (a['nama'] ?? '').toString().toLowerCase();
      final namaB = (b['nama'] ?? '').toString().toLowerCase();
      return namaA.compareTo(namaB);
    });

    return list;
  }

  List<Map<String, dynamic>> filterAnggota(
    List<Map<String, dynamic>> data,
    String keyword,
  ) {
    final q = keyword.toLowerCase().trim();

    if (q.isEmpty) return data;

    return data.where((item) {
      final gabungan = [
        item['nama'],
        item['nik'],
        item['alamat'],
        item['telepon'],
        item['no_hp'],
        item['nomor_hp'],
        item['jenis_kelamin'],
      ].map((e) => (e ?? '').toString().toLowerCase()).join(' ');

      return gabungan.contains(q);
    }).toList();
  }

  String ambilLuasSawah(Map<String, dynamic> item) {
    return (item['luas_sawah'] ??
            item['jumlah_petak_sawah'] ??
            item['luasSawah'] ??
            '-')
        .toString();
  }

  String ambilTelepon(Map<String, dynamic> item) {
    return (item['telepon'] ?? item['no_hp'] ?? item['nomor_hp'] ?? '-')
        .toString();
  }

  String ambilAlamat(Map<String, dynamic> item) {
    return (item['alamat'] ?? '-').toString();
  }

  String ambilJenisKelamin(Map<String, dynamic> item) {
    return (item['jenis_kelamin'] ?? item['jenisKelamin'] ?? '-').toString();
  }

  String ambilTanggalDaftar(Map<String, dynamic> item) {
    final raw =
        (item['tanggal_daftar'] ??
                item['tanggal_verifikasi'] ??
                item['created_at'] ??
                '')
            .toString();

    if (raw.isEmpty) return '-';

    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: anggotaRef.onValue,
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

            final semuaAnggota = ambilAnggota(snapshot.data?.snapshot.value);

            return Column(
              children: [
                _header(semuaAnggota.length),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.manual,
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    children: [
                      _searchBox(),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<String>(
                        valueListenable: keywordNotifier,
                        builder: (context, keyword, _) {
                          final hasilFilter = filterAnggota(
                            semuaAnggota,
                            keyword,
                          );

                          return Column(
                            children: [
                              _summaryCard(
                                semuaAnggota.length,
                                hasilFilter.length,
                                keyword,
                              ),
                              const SizedBox(height: 16),
                              if (semuaAnggota.isEmpty)
                                _emptyState(
                                  icon: Icons.groups_2_outlined,
                                  title: 'Belum Ada Anggota Aktif',
                                  message:
                                      'Data anggota yang sudah disetujui admin akan muncul di halaman ini.',
                                )
                              else if (hasilFilter.isEmpty)
                                _emptyState(
                                  icon: Icons.search_off_rounded,
                                  title: 'Data Tidak Ditemukan',
                                  message:
                                      'Tidak ada anggota yang sesuai dengan pencarian.',
                                )
                              else
                                ...hasilFilter.map(
                                  (item) => _anggotaCard(item),
                                ),
                            ],
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

  Widget _header(int totalAnggota) {
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
              Icons.groups_rounded,
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
                      'Anggota Aktif',
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
                      'Data Anggota Resmi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 58,
                      minHeight: 58,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          totalAnggota.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'aktif',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Menampilkan anggota kelompok tani yang sudah disetujui dan berstatus aktif.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
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
          hintText: 'Cari nama lengkap, NIK, alamat, atau telepon',
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(int total, int tampil, String keyword) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.verified_user_rounded, color: primaryGreen),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              keyword.trim().isEmpty
                  ? 'Terdapat $total anggota aktif yang terdaftar dalam sistem.'
                  : 'Menampilkan $tampil dari $total anggota aktif sesuai pencarian.',
              style: const TextStyle(
                color: textDark,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _anggotaCard(Map<String, dynamic> item) {
    final nama = (item['nama'] ?? '-').toString();
    final nik = (item['nik'] ?? '-').toString();
    final telepon = ambilTelepon(item);
    final alamat = ambilAlamat(item);
    final jenisKelamin = ambilJenisKelamin(item);
    final luasSawah = ambilLuasSawah(item);
    final tanggalDaftar = ambilTanggalDaftar(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(nama),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nik,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(),
            ],
          ),
          const SizedBox(height: 15),
          _infoBox(
            children: [
              _infoRow(Icons.phone_rounded, 'Telepon', telepon),
              _infoRow(Icons.wc_rounded, 'Jenis Kelamin', jenisKelamin),
              _infoRow(Icons.location_on_rounded, 'Alamat', alamat),
              _infoRow(Icons.landscape_rounded, 'Luas Sawah', '$luasSawah Ha'),
              _infoRow(
                Icons.event_available_rounded,
                'Terdaftar',
                tanggalDaftar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(String nama) {
    final initial = nama.trim().isEmpty ? 'A' : nama.trim()[0].toUpperCase();

    return Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: primaryGreen,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'AKTIF',
        style: TextStyle(
          color: primaryGreen,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoBox({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString().trim().isEmpty ? '-' : value.toString(),
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
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
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
