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
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color redStatus = Color(0xffDC2626);
  static const Color blueStatus = Color(0xff2563EB);

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
    if (tersedia <= 0) return 'Belum tersedia';
    if (tersedia <= 1) return 'Terbatas';
    return 'Tersedia';
  }

  Color warnaStatusStok(int tersedia) {
    if (tersedia <= 0) return redStatus;
    if (tersedia <= 1) return orangeStatus;
    return primaryGreen;
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  String statusLayananText(int tersedia) {
    if (tersedia <= 0) return 'Belum Bisa Dipinjam';
    return 'Siap Dipinjam';
  }

  String statusLayananDesc(int tersedia) {
    if (tersedia <= 0) {
      return 'Saat ini belum ada alat yang tersedia untuk dipilih.';
    }
    return 'Silakan pilih alat yang tersedia, lalu lanjutkan ke pemilihan jadwal.';
  }

  Color statusLayananColor(int tersedia) {
    if (tersedia <= 0) return orangeStatus;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
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
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                            children: [
                              _userInfoCard(),
                              const SizedBox(height: 12),
                              _stepCard(),
                              const SizedBox(height: 12),
                              _summaryGrid(
                                totalJenis: totalJenis,
                                tersedia: unitTersedia,
                                dipinjam: unitDipinjam,
                              ),
                              const SizedBox(height: 12),
                              _serviceStatusCard(unitTersedia),
                              const SizedBox(height: 12),
                              _guideCard(),
                              const SizedBox(height: 18),
                              _sectionTitle(
                                title: 'Pilih Alat Pertanian',
                                subtitle:
                                    'Pilih alat yang tersedia untuk dipinjam',
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
        message: 'Data alat gagal dimuat. Silakan coba lagi.',
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
        decoration: BoxDecoration(
          color: darkGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 7),
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
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih alat yang ingin dipinjam',
                    style: TextStyle(
                      color: Color(0xffD1FAE5),
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primaryGreen,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Pemohon',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.3,
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
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'NIK ${sensorNik(widget.nik)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepDot('1', true),
              _stepLine(true),
              _stepDot('2', false),
              _stepLine(false),
              _stepDot('3', false),
              _stepLine(false),
              _stepDot('4', false),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tahap 1 dari 4',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih alat pertanian terlebih dahulu sebelum menentukan jadwal.',
            style: TextStyle(
              color: textGrey,
              fontSize: 11.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(String text, bool active) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: active ? primaryGreen : const Color(0xffEEF2F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? primaryGreen : borderColor),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : textGrey,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color:
              active
                  ? primaryGreen.withValues(alpha: 0.55)
                  : const Color(0xffE5E7EB),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _summaryGrid({
    required int totalJenis,
    required int tersedia,
    required int dipinjam,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryMini(
            title: 'Pilihan Alat',
            value: totalJenis.toString(),
            icon: Icons.handyman_rounded,
            color: primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryMini(
            title: 'Siap Dipinjam',
            value: tersedia.toString(),
            icon: Icons.check_circle_rounded,
            color: blueStatus,
          ),
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
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
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
                    fontSize: 11.5,
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

  Widget _serviceStatusCard(int tersedia) {
    final color = statusLayananColor(tersedia);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tersedia > 0
                  ? Icons.assignment_turned_in_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLayananText(tersedia),
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLayananDesc(tersedia),
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.7,
                    height: 1.35,
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

  Widget _guideCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Alat yang tersedia dapat dipilih. Setelah itu, lanjutkan ke tahap pemilihan jadwal peminjaman.',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 12.2,
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
          height: 32,
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
                  fontSize: 15.8,
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
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: tersedia ? 1 : 0.58,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                selected ? primaryGreen.withValues(alpha: 0.075) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? primaryGreen : borderColor,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 11,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? primaryGreen
                          : primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  iconAlat(nama),
                  color: selected ? Colors.white : primaryGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 11),
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
                        fontSize: 15,
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
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? primaryGreen : const Color(0xff9CA3AF),
                size: 24,
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
    final text =
        tersedia <= 0
            ? teksStatusStok(tersedia)
            : '${teksStatusStok(tersedia)} • $tersedia unit';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
          height: 52,
          child: ElevatedButton.icon(
            onPressed: aktif ? lanjutPilihJadwal : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.36),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              aktif ? 'Lanjut Pilih Jadwal' : 'Pilih Alat Terlebih Dahulu',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: _cardDecoration(radius: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              const SizedBox(width: 11),
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
      decoration: _cardDecoration(radius: 18),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 15.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.032),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
