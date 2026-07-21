import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'koordinasi_jadwal_page.dart';

class AlatPage extends StatefulWidget {
  final String nama;
  final String nik;

  const AlatPage({
    super.key,
    required this.nama,
    required this.nik,
  });

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  static const Color primary = Color(0xff2E7D32);
  static const Color dark = Color(0xff14532D);
  static const Color teal = Color(0xff167A6B);
  static const Color deepTeal = Color(0xff0E5F57);
  static const Color blue = Color(0xff326FA3);
  static const Color orange = Color(0xffD98212);
  static const Color red = Color(0xffC83B3B);

  static const Color bg = Color(0xffF2F7F5);
  static const Color border = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color softOrange = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);

  String? idAlatDipilih;
  String? namaAlatDipilih;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference alatRef;
  late final DatabaseReference peminjamanRef;

  @override
  void initState() {
    super.initState();

    alatRef = db.ref('alat_pertanian');
    peminjamanRef = db.ref('peminjaman_alat');
  }

  Map<dynamic, dynamic> _map(dynamic value) {
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

  int _int(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<void> _refreshData() async {
    await Future.wait([
      alatRef.get(),
      peminjamanRef.get(),
    ]);
  }

  List<MapEntry<String, dynamic>> _alatList(dynamic value) {
    final result = <MapEntry<String, dynamic>>[];

    for (final entry in _map(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final item = Map<String, dynamic>.from(
        entry.value as Map,
      );

      final status = _text(
        item['status'],
        fallback: 'aktif',
      ).toLowerCase();

      if (status != 'aktif') {
        continue;
      }

      result.add(
        MapEntry(
          entry.key.toString(),
          item,
        ),
      );
    }

    result.sort((a, b) {
      final namaA = _text(
        a.value['nama_alat'],
        fallback: '',
      ).toLowerCase();

      final namaB = _text(
        b.value['nama_alat'],
        fallback: '',
      ).toLowerCase();

      return namaA.compareTo(namaB);
    });

    return result;
  }

  List<Map<String, dynamic>> _peminjamanList(dynamic value) {
    final result = <Map<String, dynamic>>[];

    for (final entry in _map(value).entries) {
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

  int _dipinjam(
    String idAlat,
    String namaAlat,
    List<Map<String, dynamic>> data,
  ) {
    int total = 0;

    for (final item in data) {
      final itemId = _text(
        item['id_alat'] ?? item['alat_id'],
        fallback: '',
      );

      final itemNama = _text(
        item['alat'] ?? item['nama_alat'],
        fallback: '',
      );

      final status = _text(
        item['status'],
        fallback: '',
      ).toLowerCase();

      final alatSama = itemId.isNotEmpty
          ? itemId == idAlat
          : itemNama.toLowerCase().trim() ==
              namaAlat.toLowerCase().trim();

      if (alatSama && status == 'dipinjam') {
        total += _int(
          item['jumlah'] ?? item['jumlah_alat'],
          fallback: 1,
        );
      }
    }

    return total;
  }

  int _totalDipinjam(
    List<MapEntry<String, dynamic>> alat,
    List<Map<String, dynamic>> peminjaman,
  ) {
    int total = 0;

    for (final entry in alat) {
      total += _dipinjam(
        entry.key,
        _text(entry.value['nama_alat']),
        peminjaman,
      );
    }

    return total;
  }

  int _totalTersedia(
    List<MapEntry<String, dynamic>> alat,
    List<Map<String, dynamic>> peminjaman,
  ) {
    int total = 0;

    for (final entry in alat) {
      final jumlahUnit = _int(
        entry.value['jumlah_unit'],
      );

      final sedangDipinjam = _dipinjam(
        entry.key,
        _text(entry.value['nama_alat']),
        peminjaman,
      );

      final tersedia = jumlahUnit - sedangDipinjam;

      total += tersedia < 0 ? 0 : tersedia;
    }

    return total;
  }

  IconData _iconAlat(String nama) {
    final value = nama.toLowerCase();

    if (value.contains('sprayer') ||
        value.contains('semprot')) {
      return Icons.water_drop_outlined;
    }

    if (value.contains('cangkul')) {
      return Icons.handyman_outlined;
    }

    if (value.contains('traktor')) {
      return Icons.agriculture_rounded;
    }

    if (value.contains('pompa')) {
      return Icons.water_outlined;
    }

    if (value.contains('mesin')) {
      return Icons.precision_manufacturing_outlined;
    }

    return Icons.construction_outlined;
  }

  Color _warnaAlat(String nama) {
    final value = nama.toLowerCase();

    if (value.contains('sprayer') ||
        value.contains('semprot')) {
      return blue;
    }

    if (value.contains('cangkul')) {
      return orange;
    }

    if (value.contains('traktor')) {
      return primary;
    }

    return teal;
  }

  Color _warnaStok(int tersedia) {
    if (tersedia <= 0) {
      return red;
    }

    if (tersedia == 1) {
      return orange;
    }

    return primary;
  }

  String _sensorNik(String nik) {
    final clean = nik.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length <= 4) {
      return nik;
    }

    return '•••• •••• •••• ${clean.substring(clean.length - 4)}';
  }

  void _pilihAlat({
    required String id,
    required String nama,
  }) {
    setState(() {
      if (idAlatDipilih == id) {
        idAlatDipilih = null;
        namaAlatDipilih = null;
      } else {
        idAlatDipilih = id;
        namaAlatDipilih = nama;
      }
    });
  }

  void _lanjut() {
    FocusScope.of(context).unfocus();

    if (idAlatDipilih == null ||
        namaAlatDipilih == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KoordinasiJadwalPage(
          idAlat: idAlatDipilih!,
          namaAlat: namaAlatDipilih!,
          nama: widget.nama,
          nik: widget.nik,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final pagePadding = screenWidth < 350
        ? 12.0
        : screenWidth < 600
            ? 16.0
            : screenWidth < 1000
                ? 24.0
                : 32.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: bg,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _AlatBackground(),
                SafeArea(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: alatRef.onValue,
                    builder: (context, alatSnapshot) {
                      return StreamBuilder<DatabaseEvent>(
                        stream: peminjamanRef.onValue,
                        builder: (context, pinjamSnapshot) {
                          final alat = _alatList(
                            alatSnapshot.data?.snapshot.value,
                          );

                          final peminjaman = _peminjamanList(
                            pinjamSnapshot.data?.snapshot.value,
                          );

                          final dipinjam = _totalDipinjam(
                            alat,
                            peminjaman,
                          );

                          final tersedia = _totalTersedia(
                            alat,
                            peminjaman,
                          );

                          final loading =
                              alatSnapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  pinjamSnapshot.connectionState ==
                                      ConnectionState.waiting;

                          final error = alatSnapshot.hasError ||
                              pinjamSnapshot.hasError;

                          return RefreshIndicator(
                            color: teal,
                            backgroundColor: Colors.white,
                            onRefresh: _refreshData,
                            child: ListView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior
                                      .manual,
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                pagePadding,
                                12,
                                pagePadding,
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
                                        _header(),
                                        const SizedBox(height: 12),
                                        _pemohonCard(),
                                        const SizedBox(height: 10),
                                        _stepCard(),
                                        const SizedBox(height: 10),
                                        _summary(
                                          jenis: alat.length,
                                          tersedia: tersedia,
                                          dipinjam: dipinjam,
                                        ),
                                        const SizedBox(height: 10),
                                        _statusCard(tersedia),
                                        const SizedBox(height: 10),
                                        _infoCard(),
                                        const SizedBox(height: 17),
                                        _sectionTitle(),
                                        const SizedBox(height: 10),
                                        _content(
                                          loading: loading,
                                          error: error,
                                          alat: alat,
                                          peminjaman: peminjaman,
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
      bottomNavigationBar: _bottomButton(),
    );
  }

  Widget _content({
    required bool loading,
    required bool error,
    required List<MapEntry<String, dynamic>> alat,
    required List<Map<String, dynamic>> peminjaman,
  }) {
    if (loading) {
      return _loading();
    }

    if (error) {
      return _emptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Data Alat Gagal Dimuat',
        message:
            'Periksa koneksi internet lalu tarik halaman ke bawah.',
        color: red,
        background: softRed,
      );
    }

    if (alat.isEmpty) {
      return _emptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Alat Aktif',
        message:
            'Admin belum menambahkan alat yang dapat dipinjam.',
        color: teal,
        background: softTeal,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 2 : 1;
        const gap = 10.0;

        final itemWidth = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: alat.map((entry) {
            final nama = _text(
              entry.value['nama_alat'],
              fallback: 'Alat pertanian',
            );

            final jumlah = _int(
              entry.value['jumlah_unit'],
            );

            final sedangDipinjam = _dipinjam(
              entry.key,
              nama,
              peminjaman,
            );

            final sisa = jumlah - sedangDipinjam;
            final tersedia = sisa < 0 ? 0 : sisa;

            return SizedBox(
              width: itemWidth,
              child: _alatCard(
                id: entry.key,
                nama: nama,
                jumlah: jumlah,
                dipinjam: sedangDipinjam,
                tersedia: tersedia,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _header() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.maxWidth < 370;

        return Container(
          padding: EdgeInsets.all(
            small ? 12 : 14,
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
            borderRadius: BorderRadius.circular(24),
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
                width: small ? 9 : 11,
              ),
              _icon(
                Icons.agriculture_rounded,
                Colors.white,
                Colors.white.withValues(
                  alpha: 0.14,
                ),
                small ? 43 : 47,
              ),
              SizedBox(
                width: small ? 9 : 11,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peminjaman Alat',
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
                      'Inventaris pertanian Desa Penataan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xffD7EEE7),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
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

  Widget _pemohonCard() {
    return _card(
      Row(
        children: [
          _icon(
            Icons.person_outline_rounded,
            primary,
            softGreen,
            44,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pemohon',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 9.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'NIK ${_sensorNik(widget.nik)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _badge(
            'ANGGOTA',
            primary,
            softGreen,
          ),
        ],
      ),
    );
  }

  Widget _stepCard() {
    return _card(
      Column(
        children: [
          Row(
            children: [
              _step('1', true),
              _line(true),
              _step('2', false),
              _line(false),
              _step('3', false),
              _line(false),
              _step('4', false),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.touch_app_outlined,
                color: teal,
                size: 17,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tahap 1 • Pilih alat yang akan dipinjam',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w900,
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

  Widget _step(
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

  Widget _line(bool active) {
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
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _summary({
    required int jenis,
    required int tersedia,
    required int dipinjam,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 350
            ? 6.0
            : 8.0;

        final itemWidth =
            (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: _summaryItem(
                'Jenis',
                jenis,
                Icons.category_outlined,
                teal,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryItem(
                'Tersedia',
                tersedia,
                Icons.check_circle_outline_rounded,
                primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryItem(
                'Dipinjam',
                dipinjam,
                Icons.outbox_outlined,
                blue,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 9,
      ),
      decoration: _decoration(
        radius: 16,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
          ),
          const SizedBox(height: 5),
          Text(
            value > 999
                ? '999+'
                : value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 15.5,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(int tersedia) {
    final available = tersedia > 0;
    final color = available ? primary : orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: available
            ? softGreen
            : softOrange,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _icon(
            available
                ? Icons.inventory_outlined
                : Icons.hourglass_empty,
            color,
            Colors.white,
            39,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  available
                      ? 'Peminjaman Alat Tersedia'
                      : 'Belum Ada Unit Tersedia',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  available
                      ? 'Pilih alat milik Desa Penataan, lalu tentukan jadwal peminjaman.'
                      : 'Semua unit sedang dipinjam. Periksa kembali setelah alat dikembalikan.',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9.5,
                    height: 1.4,
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

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: softTeal,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: teal.withValues(
            alpha: 0.11,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: teal,
            size: 17,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jumlah tersedia dihitung dari jumlah unit dikurangi alat yang sedang dipinjam.',
              style: TextStyle(
                color: textGrey,
                fontSize: 9.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              borderRadius: BorderRadius.all(
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
                'Alat Pertanian Desa',
                style: TextStyle(
                  color: textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Pilih alat yang masih memiliki unit tersedia.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 9.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _alatCard({
    required String id,
    required String nama,
    required int jumlah,
    required int dipinjam,
    required int tersedia,
  }) {
    final selected = idAlatDipilih == id;
    final enabled = tersedia > 0;
    final equipmentColor = _warnaAlat(nama);
    final stockColor = _warnaStok(tersedia);

    return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: enabled
              ? () {
                  _pilihAlat(
                    id: id,
                    nama: nama,
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: selected
                  ? teal.withValues(alpha: 0.075)
                  : Colors.white.withValues(
                      alpha: enabled ? 0.98 : 0.76,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? teal : border,
                width: selected ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: deepTeal.withValues(
                    alpha: 0.055,
                  ),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 330;

                if (compact) {
                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _icon(
                            _iconAlat(nama),
                            selected
                                ? Colors.white
                                : equipmentColor,
                            selected
                                ? teal
                                : equipmentColor
                                    .withValues(
                                      alpha: 0.10,
                                    ),
                            47,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              nama,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 13.5,
                                height: 1.25,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          _selectionIcon(
                            selected: selected,
                            enabled: enabled,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _alatBadges(
                        jumlah: jumlah,
                        dipinjam: dipinjam,
                        tersedia: tersedia,
                        equipmentColor:
                            equipmentColor,
                        stockColor: stockColor,
                      ),
                      const SizedBox(height: 8),
                      _alatInstruction(enabled),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _icon(
                      _iconAlat(nama),
                      selected
                          ? Colors.white
                          : equipmentColor,
                      selected
                          ? teal
                          : equipmentColor.withValues(
                              alpha: 0.10,
                            ),
                      49,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  nama,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style:
                                      const TextStyle(
                                    color: textDark,
                                    fontSize: 13.5,
                                    height: 1.25,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              _selectionIcon(
                                selected: selected,
                                enabled: enabled,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _alatBadges(
                            jumlah: jumlah,
                            dipinjam: dipinjam,
                            tersedia: tersedia,
                            equipmentColor:
                                equipmentColor,
                            stockColor: stockColor,
                          ),
                          const SizedBox(height: 8),
                          _alatInstruction(enabled),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
  }

  Widget _selectionIcon({
    required bool selected,
    required bool enabled,
  }) {
    return Icon(
      selected
          ? Icons.check_circle_rounded
          : enabled
              ? Icons.radio_button_unchecked_rounded
              : Icons.lock_outline_rounded,
      color: selected
          ? teal
          : enabled
              ? textSoft
              : red,
      size: 21,
    );
  }

  Widget _alatBadges({
    required int jumlah,
    required int dipinjam,
    required int tersedia,
    required Color equipmentColor,
    required Color stockColor,
  }) {
    final enabled = tersedia > 0;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _miniBadge(
          Icons.inventory_2_outlined,
          '$jumlah unit',
          equipmentColor,
        ),
        _miniBadge(
          Icons.outbox_outlined,
          '$dipinjam dipinjam',
          blue,
        ),
        _miniBadge(
          enabled
              ? Icons.check_circle_outline_rounded
              : Icons.block_outlined,
          enabled
              ? '$tersedia tersedia'
              : 'Tidak tersedia',
          stockColor,
        ),
      ],
    );
  }

  Widget _alatInstruction(bool enabled) {
    return Text(
      enabled
          ? 'Ketuk kartu untuk memilih alat.'
          : 'Tunggu sampai unit dikembalikan.',
      style: TextStyle(
        color: enabled ? textGrey : red,
        fontSize: 9.1,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _miniBadge(
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.075,
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 11.5,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8.7,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    final active =
        idAlatDipilih != null &&
            namaAlatDipilih != null;

    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: deepTeal.withValues(
        alpha: 0.13,
      ),
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
                maxWidth: 840,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton.icon(
                  onPressed: active
                      ? _lanjut
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        teal.withValues(
                      alpha: 0.28,
                    ),
                    disabledForegroundColor:
                        Colors.white.withValues(
                      alpha: 0.86,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  icon: Icon(
                    active
                        ? Icons.arrow_forward_rounded
                        : Icons.touch_app_outlined,
                    size: 19,
                  ),
                  label: Text(
                    active
                        ? 'Lanjut Pilih Jadwal'
                        : 'Pilih Alat Terlebih Dahulu',
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

  Widget _loading() {
    return Column(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(
            bottom: 10,
          ),
          padding: const EdgeInsets.all(13),
          decoration: _decoration(
            radius: 20,
          ),
          child: Row(
            children: [
              Container(
                height: 49,
                width: 49,
                decoration: BoxDecoration(
                  color: border,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius:
                            BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius:
                            BorderRadius.circular(99),
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

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required Color background,
  }) {
    return _card(
      Column(
        children: [
          _icon(
            icon,
            color,
            background,
            66,
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.2,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
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
        child: _icon(
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

  Widget _badge(
    String label,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _icon(
    IconData icon,
    Color color,
    Color background,
    double size,
  ) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
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
      decoration: _decoration(
        radius: 20,
      ),
      child: child,
    );
  }

  BoxDecoration _decoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.98,
      ),
      borderRadius:
          BorderRadius.circular(radius),
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
    );
  }
}

class _AlatBackground extends StatelessWidget {
  const _AlatBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final shortestSide = width < height ? width : height;

            final large = (shortestSide * 1.02)
                .clamp(290.0, 520.0)
                .toDouble();
            final medium = (shortestSide * 0.70)
                .clamp(190.0, 360.0)
                .toDouble();
            final iconLarge = (shortestSide * 0.17)
                .clamp(48.0, 92.0)
                .toDouble();
            final iconSmall = (shortestSide * 0.11)
                .clamp(34.0, 62.0)
                .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xff0B4F49),
                          Color(0xff116A60),
                          Color(0xff54A792),
                          Color(0xffDCEFE9),
                          Color(0xffF4F8F6),
                        ],
                        stops: [
                          0,
                          0.17,
                          0.34,
                          0.58,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.56,
                    right: -large * 0.30,
                    child: _Circle(
                      size: large,
                      color: const Color(0xff8BE0C6),
                      alpha: 0.18,
                    ),
                  ),
                  Positioned(
                    top: height * 0.22,
                    left: -medium * 0.62,
                    child: _Circle(
                      size: medium,
                      color: const Color(0xffB9E7D9),
                      alpha: 0.27,
                    ),
                  ),
                  Positioned(
                    top: height * 0.52,
                    right: -medium * 0.46,
                    child: _Circle(
                      size: medium,
                      color: const Color(0xffD7EFE7),
                      alpha: 0.52,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.56,
                    left: -large * 0.32,
                    child: _Circle(
                      size: large,
                      color: const Color(0xffE9F6F1),
                      alpha: 0.88,
                    ),
                  ),
                  Positioned(
                    top: height * 0.07,
                    right: width * 0.08,
                    child: _BackgroundIcon(
                      icon: Icons.agriculture_rounded,
                      size: iconLarge,
                      color: Colors.white,
                      alpha: 0.075,
                    ),
                  ),
                  Positioned(
                    top: height * 0.40,
                    left: width * 0.045,
                    child: _BackgroundIcon(
                      icon: Icons.handyman_outlined,
                      size: iconSmall,
                      color: const Color(0xff0B4F49),
                      alpha: 0.055,
                    ),
                  ),
                  Positioned(
                    bottom: height * 0.14,
                    right: width * 0.06,
                    child: _BackgroundIcon(
                      icon: Icons.precision_manufacturing_outlined,
                      size: iconLarge * 0.88,
                      color: const Color(0xff116A60),
                      alpha: 0.045,
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

class _BackgroundIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double alpha;

  const _BackgroundIcon({
    required this.icon,
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.16,
      child: Icon(
        icon,
        size: size,
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _Circle({
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
