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

  String? alatDipilih;

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

  int hitungTerpakai(String namaAlat, List<Map<String, dynamic>> data) {
    int total = 0;

    for (final item in data) {
      final alat = (item['alat'] ?? '').toString();
      final status = (item['status'] ?? '').toString().toLowerCase();

      if (alat == namaAlat && (status == 'menunggu' || status == 'disetujui')) {
        total++;
      }
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

    if (alat.contains('sprayer')) return const Color(0xff2563EB);
    if (alat.contains('cangkul')) return const Color(0xffD97706);
    if (alat.contains('traktor')) return orangeStatus;

    return primaryGreen;
  }

  List<Map<String, dynamic>> ambilAlatList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    return data.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((alat) {
          final status = (alat['status'] ?? 'aktif').toString().toLowerCase();
          return status == 'aktif';
        })
        .toList();
  }

  List<Map<String, dynamic>> ambilPeminjamanList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    return data.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int totalUnit(List<Map<String, dynamic>> alatList) {
    int total = 0;

    for (final alat in alatList) {
      total += int.tryParse((alat['jumlah_unit'] ?? 0).toString()) ?? 0;
    }

    return total;
  }

  int totalTersedia(
    List<Map<String, dynamic>> alatList,
    List<Map<String, dynamic>> peminjamanList,
  ) {
    int total = 0;

    for (final alat in alatList) {
      final namaAlat = (alat['nama_alat'] ?? '-').toString();
      final jumlahUnit =
          int.tryParse((alat['jumlah_unit'] ?? 0).toString()) ?? 0;
      final terpakai = hitungTerpakai(namaAlat, peminjamanList);
      final tersedia = jumlahUnit - terpakai;

      total += tersedia < 0 ? 0 : tersedia;
    }

    return total;
  }

  void lanjutPilihJadwal() {
    if (alatDipilih == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => KoordinasiJadwalPage(
              namaAlat: alatDipilih!,
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

                final totalAlat = alatList.length;
                final unitSemua = totalUnit(alatList);
                final unitTersedia = totalTersedia(alatList, peminjamanList);

                return Column(
                  children: [
                    _header(context),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _stepIndicator(),
                            const SizedBox(height: 18),
                            _summaryCard(
                              totalJenis: totalAlat,
                              totalUnit: unitSemua,
                              tersedia: unitTersedia,
                            ),
                            const SizedBox(height: 18),
                            _infoCard(),
                            const SizedBox(height: 22),
                            _sectionTitle('Pilih Alat Pertanian'),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _buildContent(
                                alatSnapshot,
                                alatList,
                                peminjamanList,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _bottomButton(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> alatSnapshot,
    List<Map<String, dynamic>> alatList,
    List<Map<String, dynamic>> peminjamanList,
  ) {
    if (alatSnapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: alatList.length,
      itemBuilder: (context, index) {
        final alat = alatList[index];
        final namaAlat = (alat['nama_alat'] ?? '-').toString();
        final jumlahUnit =
            int.tryParse((alat['jumlah_unit'] ?? 0).toString()) ?? 0;
        final terpakai = hitungTerpakai(namaAlat, peminjamanList);
        final tersedia = jumlahUnit - terpakai;
        final stokTersedia = tersedia < 0 ? 0 : tersedia;

        return _pilihanAlat(
          nama: namaAlat,
          stokTersedia: stokTersedia,
          jumlahUnit: jumlahUnit,
          icon: iconAlat(namaAlat),
          color: warnaAlat(namaAlat),
          tersedia: stokTersedia > 0,
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -36,
            child: Icon(
              Icons.agriculture_rounded,
              size: 145,
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Pilih Alat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih alat pertanian desa yang tersedia untuk digunakan.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
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

  Widget _summaryCard({
    required int totalJenis,
    required int totalUnit,
    required int tersedia,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _summaryItem(
            icon: Icons.handyman_rounded,
            title: 'Jenis',
            value: totalJenis.toString(),
            color: primaryGreen,
          ),
          Container(width: 1, height: 44, color: const Color(0xffE5E7EB)),
          _summaryItem(
            icon: Icons.inventory_2_rounded,
            title: 'Unit',
            value: totalUnit.toString(),
            color: orangeStatus,
          ),
          Container(width: 1, height: 44, color: const Color(0xffE5E7EB)),
          _summaryItem(
            icon: Icons.check_circle_rounded,
            title: 'Tersedia',
            value: tersedia.toString(),
            color: primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pilih salah satu alat yang tersedia. Setelah itu lanjutkan untuk memilih jadwal peminjaman.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
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
    required String nama,
    required int stokTersedia,
    required int jumlahUnit,
    required IconData icon,
    required Color color,
    required bool tersedia,
  }) {
    final selected = alatDipilih == nama;

    return InkWell(
      onTap:
          tersedia
              ? () {
                setState(() {
                  alatDipilih = nama;
                });
              }
              : null,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: tersedia ? 1 : 0.48,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? primaryGreen : const Color(0xffE5E7EB),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: tersedia ? color : textGrey, size: 30),
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
                    const SizedBox(height: 5),
                    Text(
                      tersedia
                          ? 'Tersedia $stokTersedia dari $jumlahUnit unit'
                          : 'Stok alat sedang habis',
                      style: TextStyle(
                        color: tersedia ? textGrey : Colors.red,
                        fontSize: 12,
                        fontWeight:
                            tersedia ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? primaryGreen : textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primaryGreen.withValues(alpha: 0.45),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: alatDipilih == null ? null : lanjutPilihJadwal,
          child: const Text(
            'Lanjut Pilih Jadwal',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
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
          _stepLine(true),
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
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? primaryGreen : const Color(0xffE5E7EB),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : textGrey,
              fontWeight: FontWeight.w900,
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
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: active ? primaryGreen : const Color(0xffE5E7EB),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: const BoxDecoration(
                  color: lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryGreen, size: 36),
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
                ),
              ),
            ],
          ),
        ),
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
