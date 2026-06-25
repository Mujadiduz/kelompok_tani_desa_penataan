import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
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
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color softGreen = Color(0xffE8F5E9);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color redStatus = Color(0xffDC2626);
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

  Future<void> _refreshData() async {
    await Future.wait([alatRef.get(), peminjamanRef.get()]);
  }

  List<MapEntry<String, dynamic>> ambilAlatList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);

    final list =
        data.entries.where((entry) {
          if (entry.value is! Map) return false;
          final alat = Map<String, dynamic>.from(entry.value as Map);
          final status = (alat['status'] ?? 'aktif').toString().toLowerCase();
          return status == 'aktif';
        }).toList();

    list.sort((a, b) {
      final alatA = Map<String, dynamic>.from(a.value as Map);
      final alatB = Map<String, dynamic>.from(b.value as Map);

      final namaA = (alatA['nama_alat'] ?? '').toString();
      final namaB = (alatB['nama_alat'] ?? '').toString();

      return namaA.compareTo(namaB);
    });

    return list;
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

  int totalDipinjam(
    List<MapEntry<String, dynamic>> alatList,
    List<Map<String, dynamic>> peminjamanList,
  ) {
    int total = 0;

    for (final entry in alatList) {
      final idAlat = entry.key.toString();
      final alat = Map<String, dynamic>.from(entry.value as Map);
      final namaAlat = (alat['nama_alat'] ?? '-').toString();

      total += hitungDipinjam(idAlat, namaAlat, peminjamanList);
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

  String teksStatusStok(int tersedia) {
    if (tersedia <= 0) return 'Tidak Tersedia';
    if (tersedia <= 1) return 'Terbatas';
    return 'Tersedia';
  }

  Color warnaStatusStok(int tersedia) {
    if (tersedia <= 0) return redStatus;
    if (tersedia <= 1) return orangeStatus;
    return primaryGreen;
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

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        child: SafeArea(
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
                  final unitDipinjam = totalDipinjam(alatList, peminjamanList);
                  final unitTersedia = totalTersedia(alatList, peminjamanList);

                  return Column(
                    children: [
                      _headerPage(),
                      Expanded(
                        child: RefreshIndicator(
                          color: primaryGreen,
                          backgroundColor: Colors.white,
                          onRefresh: _refreshData,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                            children: [
                              _userInfoCard(),
                              const SizedBox(height: 14),
                              _stepCard(),
                              const SizedBox(height: 14),
                              _summaryGrid(
                                totalJenis: totalJenis,
                                totalUnit: unitSemua,
                                tersedia: unitTersedia,
                                dipinjam: unitDipinjam,
                              ),
                              const SizedBox(height: 14),
                              _guideCard(),
                              const SizedBox(height: 18),
                              _sectionTitle(
                                title: 'Pilih Alat Pertanian',
                                subtitle:
                                    'Pilih alat yang masih tersedia untuk dipinjam',
                              ),
                              const SizedBox(height: 12),
                              _buildContent(
                                alatSnapshot,
                                alatList,
                                peminjamanList,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
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
        message: 'Data alat gagal dimuat.',
      );
    }

    if (alatList.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Alat Aktif',
        message: 'Data alat pertanian belum tersedia atau belum diaktifkan.',
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
              tersedia: stokTersedia > 0,
            );
          }).toList(),
    );
  }

  Widget _headerPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [darkGreen, primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.20),
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
                    'Peminjaman Alat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Pilih alat untuk melanjutkan jadwal peminjaman',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(Icons.agriculture_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pemohon',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIK ${sensorNik(widget.nik)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tahap 1 dari 4',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pilih alat pertanian yang ingin dipinjam.',
            style: TextStyle(
              color: textGrey,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0.25,
              minHeight: 7,
              backgroundColor: primaryGreen.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid({
    required int totalJenis,
    required int totalUnit,
    required int tersedia,
    required int dipinjam,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryMini(
                title: 'Jenis',
                value: totalJenis.toString(),
                icon: Icons.handyman_rounded,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryMini(
                title: 'Tersedia',
                value: tersedia.toString(),
                icon: Icons.check_circle_rounded,
                color: blueStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryMini(
                title: 'Dipinjam',
                value: dipinjam.toString(),
                icon: Icons.output_rounded,
                color: orangeStatus,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryMini(
                title: 'Total Unit',
                value: totalUnit.toString(),
                icon: Icons.inventory_2_rounded,
                color: primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryMini({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
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

  Widget _guideCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Alat yang sedang dipinjam anggota lain akan mengurangi jumlah tersedia. Setelah memilih alat, lanjutkan ke pilihan jadwal.',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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

  Widget _pilihanAlat({
    required String idAlat,
    required String nama,
    required int stokTersedia,
    required int jumlahUnit,
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
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: tersedia ? 1 : 0.58,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                selected ? primaryGreen.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? primaryGreen : borderColor,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? primaryGreen
                          : primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  iconAlat(nama),
                  color: selected ? Colors.white : primaryGreen,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _stokBadge(
                      tersedia: stokTersedia,
                      jumlahUnit: jumlahUnit,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? primaryGreen : textGrey,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stokBadge({
    required int tersedia,
    required int jumlahUnit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        '${teksStatusStok(tersedia)} • $tersedia dari $jumlahUnit unit',
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _bottomButton() {
    final aktif = idAlatDipilih != null && namaAlatDipilih != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: aktif ? lanjutPilihJadwal : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.38),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              aktif ? 'Lanjut Pilih Jadwal' : 'Pilih Alat Terlebih Dahulu',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 13,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      decoration: BoxDecoration(
                        color: borderColor,
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
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
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
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
