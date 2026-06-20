import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'koordinasi_jadwal_page.dart';

class AlatPage extends StatefulWidget {
  final String nama;
  final String nik;

  const AlatPage({super.key, required this.nama, required this.nik});

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);

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

  List<MapEntry<String, dynamic>> ambilAlatList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);

    return data.entries.where((entry) {
      final alat = Map<String, dynamic>.from(entry.value as Map);
      final status = (alat['status'] ?? 'aktif').toString().toLowerCase();
      return status == 'aktif';
    }).toList();
  }

  List<Map<String, dynamic>> ambilPeminjamanList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    return data.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int hitungDipinjam(
    String idAlat,
    String namaAlat,
    List<Map<String, dynamic>> data,
  ) {
    int total = 0;

    for (final item in data) {
      final itemIdAlat = (item['id_alat'] ?? '').toString();
      final itemAlat = (item['alat'] ?? '').toString();
      final status = (item['status'] ?? '').toString().toLowerCase();

      final alatSama =
          itemIdAlat.isNotEmpty
              ? itemIdAlat == idAlat
              : itemAlat.toLowerCase().trim() == namaAlat.toLowerCase().trim();

      if (alatSama && status == 'dipinjam') {
        total +=
            int.tryParse(
              (item['jumlah'] ?? item['jumlah_alat'] ?? 1).toString(),
            ) ??
            1;
      }
    }

    return total;
  }

  int totalUnit(List<MapEntry<String, dynamic>> alatList) {
    int total = 0;

    for (final entry in alatList) {
      final alat = Map<String, dynamic>.from(entry.value as Map);
      total += int.tryParse((alat['jumlah_unit'] ?? 0).toString()) ?? 0;
    }

    return total;
  }

  int totalTersedia(
    List<MapEntry<String, dynamic>> alatList,
    List<Map<String, dynamic>> peminjamanList,
  ) {
    int total = 0;

    for (final entry in alatList) {
      final idAlat = entry.key.toString();
      final alat = Map<String, dynamic>.from(entry.value as Map);
      final namaAlat = (alat['nama_alat'] ?? '-').toString();
      final jumlahUnit =
          int.tryParse((alat['jumlah_unit'] ?? 0).toString()) ?? 0;
      final dipinjam = hitungDipinjam(idAlat, namaAlat, peminjamanList);
      final tersedia = jumlahUnit - dipinjam;

      total += tersedia < 0 ? 0 : tersedia;
    }

    return total;
  }

  IconData iconAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return Icons.water_drop_rounded;
    if (alat.contains('cangkul')) return Icons.construction_rounded;
    if (alat.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  Color warnaAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return blueStatus;
    if (alat.contains('cangkul')) return const Color(0xffD97706);
    if (alat.contains('traktor')) return orangeStatus;

    return primaryGreen;
  }

  String teksStatusStok(int tersedia) {
    if (tersedia <= 0) return 'Tidak tersedia';
    if (tersedia <= 1) return 'Terbatas';
    return 'Tersedia';
  }

  Color warnaStatusStok(int tersedia) {
    if (tersedia <= 0) return Colors.red;
    if (tersedia <= 1) return orangeStatus;
    return primaryGreen;
  }

  Color backgroundStatusStok(int tersedia) {
    if (tersedia <= 0) return const Color(0xffFFEBEE);
    if (tersedia <= 1) return const Color(0xffFFF3E0);
    return lightGreen;
  }

  void lanjutPilihJadwal() {
    if (idAlatDipilih == null || namaAlatDipilih == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => KoordinasiJadwalPage(
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
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: alatRef.onValue,
          builder: (context, alatSnapshot) {
            final alatList = ambilAlatList(alatSnapshot.data?.snapshot.value);

            return StreamBuilder<DatabaseEvent>(
              stream: peminjamanRef.onValue,
              builder: (context, pinjamSnapshot) {
                final peminjamanList = ambilPeminjamanList(
                  pinjamSnapshot.data?.snapshot.value,
                );

                final totalJenis = alatList.length;
                final unitSemua = totalUnit(alatList);
                final unitTersedia = totalTersedia(alatList, peminjamanList);

                return Column(
                  children: [
                    _header(context),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                        children: [
                          _stepIndicator(),
                          const SizedBox(height: 16),
                          _premiumSummary(
                            totalJenis: totalJenis,
                            totalUnit: unitSemua,
                            tersedia: unitTersedia,
                          ),
                          const SizedBox(height: 18),
                          _infoCard(),
                          const SizedBox(height: 22),
                          _sectionTitle('Daftar Alat Pertanian'),
                          const SizedBox(height: 12),
                          _buildContent(alatSnapshot, alatList, peminjamanList),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _bottomButton(),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> alatSnapshot,
    List<MapEntry<String, dynamic>> alatList,
    List<Map<String, dynamic>> peminjamanList,
  ) {
    if (alatSnapshot.connectionState == ConnectionState.waiting) {
      return _loadingState();
    }

    if (alatSnapshot.hasError) {
      return _messageState(
        icon: Icons.error_outline_rounded,
        title: 'Terjadi Kesalahan',
        message: alatSnapshot.error.toString(),
      );
    }

    if (alatList.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Alat Aktif',
        message: 'Admin perlu menambahkan data alat terlebih dahulu.',
      );
    }

    return Column(
      children:
          alatList.map((entry) {
            final idAlat = entry.key.toString();
            final alat = Map<String, dynamic>.from(entry.value as Map);
            final namaAlat = (alat['nama_alat'] ?? '-').toString();
            final jumlahUnit =
                int.tryParse((alat['jumlah_unit'] ?? 0).toString()) ?? 0;
            final dipinjam = hitungDipinjam(idAlat, namaAlat, peminjamanList);
            final tersedia = jumlahUnit - dipinjam;
            final stokTersedia = tersedia < 0 ? 0 : tersedia;

            return _pilihanAlat(
              idAlat: idAlat,
              nama: namaAlat,
              stokTersedia: stokTersedia,
              jumlahUnit: jumlahUnit,
              icon: iconAlat(namaAlat),
              color: warnaAlat(namaAlat),
              tersedia: stokTersedia > 0,
            );
          }).toList(),
    );
  }

  Widget _header(BuildContext context) {
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
            color: darkGreen.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            bottom: -42,
            child: Icon(
              Icons.agriculture_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(context),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Peminjaman Alat',
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
              const Text(
                'Pilih Alat Pertanian',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Pilih alat pertanian desa yang tersedia, lalu lanjutkan ke pemilihan jadwal peminjaman.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
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
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.nama}\nNIK: ${widget.nik}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _premiumSummary({
    required int totalJenis,
    required int totalUnit,
    required int tersedia,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryMini(
            icon: Icons.handyman_rounded,
            title: 'Jenis',
            value: totalJenis.toString(),
            color: primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryMini(
            icon: Icons.inventory_2_rounded,
            title: 'Total Unit',
            value: totalUnit.toString(),
            color: orangeStatus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryMini(
            icon: Icons.check_circle_rounded,
            title: 'Tersedia',
            value: tersedia.toString(),
            color: blueStatus,
          ),
        ),
      ],
    );
  }

  Widget _summaryMini({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xffECFDF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ketersediaan alat dihitung otomatis dari total unit dikurangi alat yang sedang dipinjam. Stok berkurang saat admin menandai alat dipinjam.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihanAlat({
    required String idAlat,
    required String nama,
    required int stokTersedia,
    required int jumlahUnit,
    required IconData icon,
    required Color color,
    required bool tersedia,
  }) {
    final selected = idAlatDipilih == idAlat;
    final statusColor = warnaStatusStok(stokTersedia);

    return InkWell(
      onTap:
          tersedia
              ? () {
                setState(() {
                  idAlatDipilih = idAlat;
                  namaAlatDipilih = nama;
                });
              }
              : null,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: tersedia ? 1 : 0.56,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xffF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected ? primaryGreen : const Color(0xffE5E7EB),
              width: selected ? 1.7 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.07 : 0.045),
                blurRadius: selected ? 18 : 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient:
                      selected
                          ? LinearGradient(
                            colors: [color, color.withValues(alpha: 0.70)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  color: selected ? null : color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  icon,
                  color:
                      selected
                          ? Colors.white
                          : tersedia
                          ? color
                          : textGrey,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundStatusStok(stokTersedia),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            teksStatusStok(stokTersedia),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '$stokTersedia dari $jumlahUnit unit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'ID Alat: $idAlat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? primaryGreen : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? primaryGreen : const Color(0xffD1D5DB),
                    width: 1.5,
                  ),
                ),
                child:
                    selected
                        ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 19,
                        )
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomButton() {
    final aktif = idAlatDipilih != null && namaAlatDipilih != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.42),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
            ),
            onPressed: aktif ? lanjutPilihJadwal : null,
            child: Text(
              aktif ? 'Lanjut Pilih Jadwal' : 'Pilih Alat Terlebih Dahulu',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stepCircle('1', 'Pilih', true),
          _stepLine(false),
          _stepCircle('2', 'Jadwal', false),
          _stepLine(false),
          _stepCircle('3', 'Data', false),
          _stepLine(false),
          _stepCircle('4', 'Kirim', false),
        ],
      ),
    );
  }

  Widget _stepCircle(String number, String label, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: active ? primaryGreen : const Color(0xffE5E7EB),
            shape: BoxShape.circle,
            boxShadow:
                active
                    ? [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                    : [],
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: active ? Colors.white : textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? primaryGreen : textGrey,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 3,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: active ? primaryGreen : const Color(0xffE5E7EB),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.agriculture_rounded,
            color: primaryGreen,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xffE5E7EB),
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xffE5E7EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xffE5E7EB),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryGreen, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12,
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
