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

  String alatDipilih = 'Traktor';
  final DateTime sekarang = DateTime.now();

  final List<String> daftarAlat = const [
    'Traktor',
    'Hand Sprayer',
    'Cangkul Mesin',
  ];

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

  final DatabaseReference peminjamanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('peminjaman_alat');

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

  bool alatSama(String alatFirebase) {
    return alatFirebase.toLowerCase().trim() ==
        alatDipilih.toLowerCase().trim();
  }

  List<Map<String, dynamic>> dataUntukAlat(
    List<Map<String, dynamic>> semuaData,
  ) {
    return semuaData.where((item) {
      final alat = (item['alat'] ?? '').toString();
      return alatSama(alat);
    }).toList();
  }

  Map<String, dynamic>? dataPadaTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    for (final item in dataPeminjaman) {
      final alat = (item['alat'] ?? '').toString();
      final status = (item['status'] ?? '').toString().toLowerCase();
      final tanggalPinjam = ambilTanggal(item['tanggal_pinjam'] ?? '');
      final tanggalKembali = ambilTanggal(item['tanggal_kembali'] ?? '');

      if (alatSama(alat) &&
          tanggal >= tanggalPinjam &&
          tanggal <= tanggalKembali &&
          (status == 'disetujui' || status == 'menunggu')) {
        return item;
      }
    }

    return null;
  }

  Color warnaTanggal(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    final item = dataPadaTanggal(tanggal, dataPeminjaman);

    if (item == null) return primaryGreen;

    final status = (item['status'] ?? '').toString().toLowerCase();

    if (status == 'disetujui') return redStatus;
    if (status == 'menunggu') return orangeStatus;

    return primaryGreen;
  }

  String keteranganTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    final item = dataPadaTanggal(tanggal, dataPeminjaman);

    if (item == null) return 'Tersedia';

    final status = (item['status'] ?? '').toString().toLowerCase();
    final nama = (item['nama'] ?? '-').toString();

    if (status == 'disetujui') return 'Sedang dipinjam oleh $nama';
    if (status == 'menunggu') return 'Menunggu persetujuan';

    return 'Tersedia';
  }

  IconData iconAlat(String alat) {
    final nama = alat.toLowerCase();

    if (nama.contains('sprayer')) return Icons.water_drop_rounded;
    if (nama.contains('cangkul')) return Icons.construction_rounded;
    if (nama.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  int hitungStatus(List<Map<String, dynamic>> data, String status) {
    return data.where((item) {
      final itemStatus = (item['status'] ?? '').toString().toLowerCase();
      return itemStatus == status;
    }).length;
  }

  void tampilkanDetailTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: peminjamanRef.onValue,
          builder: (context, snapshot) {
            final dataPeminjaman = _ambilDataPeminjaman(snapshot);
            final dataAlat = dataUntukAlat(dataPeminjaman);
            final disetujui = hitungStatus(dataAlat, 'disetujui');
            final menunggu = hitungStatus(dataAlat, 'menunggu');

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _headerPage()),
                SliverToBoxAdapter(child: _pilihAlat()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                    child: _ringkasanAlat(
                      totalDipinjam: disetujui,
                      totalMenunggu: menunggu,
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
                    child: _sectionTitle('Daftar Jadwal Alat'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                    child: _daftarJadwal(dataAlat),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _ambilDataPeminjaman(
    AsyncSnapshot<DatabaseEvent> snapshot,
  ) {
    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
      return [];
    }

    final rawData = snapshot.data!.snapshot.value;

    if (rawData is! Map) return [];

    final data = Map<dynamic, dynamic>.from(rawData);

    return data.values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
        .reversed
        .toList();
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
                'Pantau ketersediaan alat berdasarkan jadwal peminjaman anggota.',
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

  Widget _pilihAlat() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: daftarAlat.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final alat = daftarAlat[index];
          final aktif = alatDipilih == alat;

          return InkWell(
            onTap: () {
              setState(() {
                alatDipilih = alat;
              });
            },
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
                    iconAlat(alat),
                    color: aktif ? Colors.white : primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    alat,
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
    required int totalDipinjam,
    required int totalMenunggu,
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
            child: Icon(iconAlat(alatDipilih), color: primaryGreen, size: 31),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alatDipilih,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalDipinjam disetujui • $totalMenunggu menunggu',
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
            label: totalDipinjam > 0 ? 'Terpakai' : 'Siap',
            color: totalDipinjam > 0 ? redStatus : primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _kalenderCard(List<Map<String, dynamic>> dataPeminjaman) {
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

  Widget _daftarJadwal(List<Map<String, dynamic>> dataAlat) {
    final jadwalAktif =
        dataAlat.where((item) {
          final status = (item['status'] ?? '').toString().toLowerCase();
          return status == 'disetujui' || status == 'menunggu';
        }).toList();

    if (jadwalAktif.isEmpty) {
      return _emptySchedule();
    }

    return Column(
      children:
          jadwalAktif.map((item) {
            final nama = (item['nama'] ?? '-').toString();
            final status =
                (item['status'] ?? 'menunggu').toString().toLowerCase();
            final tanggalPinjam = (item['tanggal_pinjam'] ?? '-').toString();
            final tanggalKembali = (item['tanggal_kembali'] ?? '-').toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(15),
              decoration: _cardDecoration(),
              child: Row(
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: backgroundStatus(status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      status == 'disetujui'
                          ? Icons.event_busy_rounded
                          : Icons.pending_actions_rounded,
                      color: warnaStatus(status),
                      size: 25,
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                  _statusMini(label: status, color: warnaStatus(status)),
                ],
              ),
            );
          }).toList(),
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
            'Alat ini belum memiliki jadwal peminjaman aktif.',
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

  Color warnaStatus(String status) {
    if (status == 'disetujui') return redStatus;
    if (status == 'menunggu') return orangeStatus;
    return primaryGreen;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return const Color(0xffFFEBEE);
    if (status == 'menunggu') return const Color(0xffFFF3E0);
    return lightGreen;
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
