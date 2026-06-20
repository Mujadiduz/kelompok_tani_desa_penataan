import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class JadwalAlatAdminPage extends StatefulWidget {
  const JadwalAlatAdminPage({super.key});

  @override
  State<JadwalAlatAdminPage> createState() => _JadwalAlatAdminPageState();
}

class _JadwalAlatAdminPageState extends State<JadwalAlatAdminPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color redStatus = Color(0xffE53935);
  static const Color blueStatus = Color(0xff1976D2);

  String idAlatDipilih = '';
  String namaAlatDipilih = '';

  final DateTime sekarang = DateTime.now();

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference peminjamanRef;
  late final DatabaseReference alatRef;

  final List<String> namaBulan = const [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    peminjamanRef = db.ref('peminjaman_alat');
    alatRef = db.ref('alat_pertanian');
  }

  int jumlahHariDalamBulan() {
    return DateTime(sekarang.year, sekarang.month + 1, 0).day;
  }

  String bulanTahun() {
    return '${namaBulan[sekarang.month - 1]} ${sekarang.year}';
  }

  int ambilTanggal(dynamic tanggalText) {
    final text = tanggalText.toString();
    final angka = RegExp(r'\d+').firstMatch(text);
    return angka == null ? 0 : int.tryParse(angka.group(0)!) ?? 0;
  }

  List<MapEntry<String, dynamic>> ambilAlatList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);

    final list =
        data.entries.where((entry) {
          final alat = Map<String, dynamic>.from(entry.value as Map);
          final status = (alat['status'] ?? 'aktif').toString().toLowerCase();
          return status == 'aktif';
        }).toList();

    list.sort((a, b) {
      final alatA = Map<String, dynamic>.from(a.value as Map);
      final alatB = Map<String, dynamic>.from(b.value as Map);
      final namaA = (alatA['nama_alat'] ?? '').toString().toLowerCase();
      final namaB = (alatB['nama_alat'] ?? '').toString().toLowerCase();
      return namaA.compareTo(namaB);
    });

    return list;
  }

  List<MapEntry<String, dynamic>> ambilPeminjamanList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);
    return data.entries.toList();
  }

  bool alatSama(Map<String, dynamic> item) {
    final itemIdAlat = (item['id_alat'] ?? '').toString();
    final itemAlat = (item['alat'] ?? '').toString().toLowerCase().trim();

    if (itemIdAlat.isNotEmpty && idAlatDipilih.isNotEmpty) {
      return itemIdAlat == idAlatDipilih;
    }

    return itemAlat == namaAlatDipilih.toLowerCase().trim();
  }

  List<MapEntry<String, dynamic>> dataUntukAlat(
    List<MapEntry<String, dynamic>> semuaData,
  ) {
    return semuaData.where((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      return alatSama(item);
    }).toList();
  }

  Map<String, dynamic>? dataPadaTanggal(
    int tanggal,
    List<MapEntry<String, dynamic>> dataPeminjaman,
  ) {
    for (final entry in dataPeminjaman) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      final status = (item['status'] ?? '').toString().toLowerCase();
      final tanggalPinjam = ambilTanggal(item['tanggal_pinjam'] ?? '');
      final tanggalKembali = ambilTanggal(item['tanggal_kembali'] ?? '');

      if (alatSama(item) &&
          tanggal >= tanggalPinjam &&
          tanggal <= tanggalKembali &&
          (status == 'menunggu' ||
              status == 'disetujui' ||
              status == 'dipinjam')) {
        return item;
      }
    }

    return null;
  }

  Color warnaTanggal(
    int tanggal,
    List<MapEntry<String, dynamic>> dataPeminjaman,
  ) {
    final item = dataPadaTanggal(tanggal, dataPeminjaman);

    if (item == null) return primaryGreen;

    final status = (item['status'] ?? '').toString().toLowerCase();

    if (status == 'menunggu') return orangeStatus;
    if (status == 'disetujui') return blueStatus;
    if (status == 'dipinjam') return redStatus;

    return primaryGreen;
  }

  String keteranganTanggal(
    int tanggal,
    List<MapEntry<String, dynamic>> dataPeminjaman,
  ) {
    final item = dataPadaTanggal(tanggal, dataPeminjaman);

    if (item == null) return 'Tersedia';

    final status = (item['status'] ?? '').toString().toLowerCase();
    final nama = (item['nama'] ?? '-').toString();

    if (status == 'menunggu') return 'Menunggu verifikasi admin';
    if (status == 'disetujui') return 'Disetujui untuk $nama';
    if (status == 'dipinjam') return 'Sedang dipinjam oleh $nama';

    return 'Tersedia';
  }

  int hitungStatus(List<MapEntry<String, dynamic>> data, String status) {
    return data.where((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      final itemStatus = (item['status'] ?? '').toString().toLowerCase();
      return itemStatus == status;
    }).length;
  }

  int hitungSemuaAktif(List<MapEntry<String, dynamic>> data) {
    return data.where((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      final status = (item['status'] ?? '').toString().toLowerCase();
      return status == 'menunggu' ||
          status == 'disetujui' ||
          status == 'dipinjam';
    }).length;
  }

  IconData iconAlat(String alat) {
    final nama = alat.toLowerCase();

    if (nama.contains('sprayer')) return Icons.water_drop_rounded;
    if (nama.contains('cangkul')) return Icons.construction_rounded;
    if (nama.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  Color warnaStatus(String status) {
    if (status == 'menunggu') return orangeStatus;
    if (status == 'disetujui') return blueStatus;
    if (status == 'dipinjam') return redStatus;
    if (status == 'dikembalikan') return primaryGreen;
    if (status == 'ditolak') return Colors.red;
    return textGrey;
  }

  String teksStatus(String status) {
    if (status == 'menunggu') return 'Menunggu';
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'dipinjam') return 'Dipinjam';
    if (status == 'dikembalikan') return 'Dikembalikan';
    if (status == 'ditolak') return 'Ditolak';
    return status;
  }

  void tampilkanDetailTanggal(
    int tanggal,
    List<MapEntry<String, dynamic>> dataPeminjaman,
  ) {
    final keterangan = keteranganTanggal(tanggal, dataPeminjaman);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$tanggal ${bulanTahun()} - $keterangan'),
        backgroundColor: primaryGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void pilihAlat(String idAlat, String namaAlat) {
    setState(() {
      idAlatDipilih = idAlat;
      namaAlatDipilih = namaAlat;
    });
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

            if (idAlatDipilih.isEmpty && alatList.isNotEmpty) {
              final firstId = alatList.first.key.toString();
              final firstData = Map<String, dynamic>.from(
                alatList.first.value as Map,
              );
              idAlatDipilih = firstId;
              namaAlatDipilih = (firstData['nama_alat'] ?? '-').toString();
            }

            return StreamBuilder<DatabaseEvent>(
              stream: peminjamanRef.onValue,
              builder: (context, pinjamSnapshot) {
                final dataPeminjaman = ambilPeminjamanList(
                  pinjamSnapshot.data?.snapshot.value,
                );

                final dataAlat = dataUntukAlat(dataPeminjaman);
                final totalAktif = hitungSemuaAktif(dataAlat);
                final menunggu = hitungStatus(dataAlat, 'menunggu');
                final disetujui = hitungStatus(dataAlat, 'disetujui');
                final dipinjam = hitungStatus(dataAlat, 'dipinjam');

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _headerPage()),
                    if (alatList.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: _emptySchedule(),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(child: _pilihAlat(alatList)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                          child: _ringkasanAlat(
                            totalAktif: totalAktif,
                            menunggu: menunggu,
                            disetujui: disetujui,
                            dipinjam: dipinjam,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                          child: _sectionTitle('Kalender Ketersediaan'),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                          child: _kalenderCard(dataPeminjaman),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                          child: _sectionTitle('Urutan Jadwal Peminjam'),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                          child: _daftarJadwal(dataAlat),
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _headerPage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
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
            right: -20,
            bottom: -40,
            child: Icon(
              Icons.calendar_month_rounded,
              size: 145,
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
                      'Jadwal Alat Pertanian',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Pantau ketersediaan dan urutan peminjam alat berdasarkan data peminjaman.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
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

  Widget _pilihAlat(List<MapEntry<String, dynamic>> daftarAlat) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: daftarAlat.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final idAlat = daftarAlat[index].key.toString();
          final alat = Map<String, dynamic>.from(
            daftarAlat[index].value as Map,
          );
          final namaAlat = (alat['nama_alat'] ?? '-').toString();
          final aktif = idAlatDipilih == idAlat;

          return InkWell(
            onTap: () => pilihAlat(idAlat, namaAlat),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: aktif ? primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: aktif ? primaryGreen : const Color(0xffE5E7EB),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: aktif ? 0.08 : 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    iconAlat(namaAlat),
                    color: aktif ? Colors.white : primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    namaAlat,
                    style: TextStyle(
                      color: aktif ? Colors.white : textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _ringkasanAlat({
    required int totalAktif,
    required int menunggu,
    required int disetujui,
    required int dipinjam,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              iconAlat(namaAlatDipilih),
              color: primaryGreen,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaAlatDipilih,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalAktif jadwal aktif • $menunggu menunggu • $disetujui disetujui • $dipinjam dipinjam',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          _statusMini(
            label: dipinjam > 0 ? 'Terpakai' : 'Siap',
            color: dipinjam > 0 ? redStatus : primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _kalenderCard(List<MapEntry<String, dynamic>> dataPeminjaman) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bulanTahun(),
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _statusColor(primaryGreen, 'Tersedia'),
              const SizedBox(width: 10),
              _statusColor(orangeStatus, 'Menunggu'),
              const SizedBox(width: 10),
              _statusColor(blueStatus, 'Disetujui'),
              const SizedBox(width: 10),
              _statusColor(redStatus, 'Dipinjam'),
            ],
          ),
          const SizedBox(height: 16),
          _namaHari(),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: jumlahHariDalamBulan(),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final tanggal = index + 1;
              final warna = warnaTanggal(tanggal, dataPeminjaman);

              return InkWell(
                onTap: () => tampilkanDetailTanggal(tanggal, dataPeminjaman),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: warna,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: warna.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '$tanggal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _namaHari() {
    final hari = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];

    return Row(
      children:
          hari.map((item) {
            return Expanded(
              child: Center(
                child: Text(
                  item,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _daftarJadwal(List<MapEntry<String, dynamic>> dataAlat) {
    final jadwalAktif =
        dataAlat.where((entry) {
          final item = Map<String, dynamic>.from(entry.value as Map);
          final status = (item['status'] ?? '').toString().toLowerCase();
          return status == 'menunggu' ||
              status == 'disetujui' ||
              status == 'dipinjam';
        }).toList();

    jadwalAktif.sort((a, b) {
      final itemA = Map<String, dynamic>.from(a.value as Map);
      final itemB = Map<String, dynamic>.from(b.value as Map);
      final tanggalA = ambilTanggal(itemA['tanggal_pinjam'] ?? '');
      final tanggalB = ambilTanggal(itemB['tanggal_pinjam'] ?? '');
      return tanggalA.compareTo(tanggalB);
    });

    if (jadwalAktif.isEmpty) {
      return _emptySchedule();
    }

    return Column(
      children: List.generate(jadwalAktif.length, (index) {
        final item = Map<String, dynamic>.from(jadwalAktif[index].value as Map);
        final nomorUrut = index + 1;

        final nama = (item['nama'] ?? '-').toString();
        final nik = (item['nik'] ?? '-').toString();
        final status = (item['status'] ?? 'menunggu').toString().toLowerCase();
        final tanggalPinjam = (item['tanggal_pinjam'] ?? '-').toString();
        final tanggalKembali = (item['tanggal_kembali'] ?? '-').toString();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: warnaStatus(status).withValues(alpha: 0.12),
                child: Text(
                  '$nomorUrut',
                  style: TextStyle(
                    color: warnaStatus(status),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NIK: $nik',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$tanggalPinjam - $tanggalKembali',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _statusMini(
                label: teksStatus(status),
                color: warnaStatus(status),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _emptySchedule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: const BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: primaryGreen,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Jadwal',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Belum ada data peminjaman aktif untuk alat ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textGrey, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _statusColor(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: textGrey,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _statusMini({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
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
