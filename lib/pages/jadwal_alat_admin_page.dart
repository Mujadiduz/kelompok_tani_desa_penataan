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
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF4F7F4);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color redStatus = Color(0xffDC2626);
  static const Color blueStatus = Color(0xff2563EB);

  String idAlatDipilih = '';
  String namaAlatDipilih = '';

  final DateTime sekarang = DateTime.now();

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _peminjamanRef;
  late final DatabaseReference _alatRef;

  final List<String> _namaBulan = const [
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
    _peminjamanRef = _db.ref('peminjaman_alat');
    _alatRef = _db.ref('alat_pertanian');
  }

  int _jumlahHariDalamBulan() {
    return DateTime(sekarang.year, sekarang.month + 1, 0).day;
  }

  String _bulanTahun() {
    return '${_namaBulan[sekarang.month - 1]} ${sekarang.year}';
  }

  int _ambilTanggal(dynamic tanggalText) {
    final text = (tanggalText ?? '').toString();
    final angka = RegExp(r'\d+').firstMatch(text);
    return angka == null ? 0 : int.tryParse(angka.group(0)!) ?? 0;
  }

  List<MapEntry<String, dynamic>> _ambilAlatList(dynamic value) {
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

  List<MapEntry<String, dynamic>> _ambilPeminjamanList(dynamic value) {
    if (value == null || value is! Map) return [];
    final data = Map<String, dynamic>.from(value);
    return data.entries.toList();
  }

  bool _alatSama(Map<String, dynamic> item) {
    final itemIdAlat = (item['id_alat'] ?? item['alat_id'] ?? '').toString();
    final itemAlat =
        (item['alat'] ?? item['nama_alat'] ?? '').toString().toLowerCase();

    if (itemIdAlat.isNotEmpty && idAlatDipilih.isNotEmpty) {
      return itemIdAlat == idAlatDipilih;
    }

    return itemAlat.trim() == namaAlatDipilih.toLowerCase().trim();
  }

  List<MapEntry<String, dynamic>> _dataUntukAlat(
    List<MapEntry<String, dynamic>> semuaData,
  ) {
    return semuaData.where((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      return _alatSama(item);
    }).toList();
  }

  Map<String, dynamic>? _dataPadaTanggal(
    int tanggal,
    List<MapEntry<String, dynamic>> dataPeminjaman,
  ) {
    for (final entry in dataPeminjaman) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      final status = (item['status'] ?? '').toString().toLowerCase();
      final tanggalPinjam = _ambilTanggal(item['tanggal_pinjam'] ?? '');
      final tanggalKembali = _ambilTanggal(item['tanggal_kembali'] ?? '');

      if (_alatSama(item) &&
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

  Color _warnaTanggal(
    int tanggal,
    List<MapEntry<String, dynamic>> dataPeminjaman,
  ) {
    final item = _dataPadaTanggal(tanggal, dataPeminjaman);
    if (item == null) return primaryGreen;

    final status = (item['status'] ?? '').toString().toLowerCase();

    if (status == 'menunggu') return orangeStatus;
    if (status == 'disetujui') return blueStatus;
    if (status == 'dipinjam') return redStatus;

    return primaryGreen;
  }

  String _keteranganTanggal(
    int tanggal,
    List<MapEntry<String, dynamic>> dataPeminjaman,
  ) {
    final item = _dataPadaTanggal(tanggal, dataPeminjaman);
    if (item == null) return 'Tersedia';

    final status = (item['status'] ?? '').toString().toLowerCase();
    final nama = (item['nama'] ?? '-').toString();

    if (status == 'menunggu') return 'Menunggu verifikasi admin';
    if (status == 'disetujui') return 'Disetujui untuk $nama';
    if (status == 'dipinjam') return 'Sedang dipinjam oleh $nama';

    return 'Tersedia';
  }

  int _hitungStatus(List<MapEntry<String, dynamic>> data, String status) {
    return data.where((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      final itemStatus = (item['status'] ?? '').toString().toLowerCase();
      return itemStatus == status;
    }).length;
  }

  int _hitungSemuaAktif(List<MapEntry<String, dynamic>> data) {
    return data.where((entry) {
      final item = Map<String, dynamic>.from(entry.value as Map);
      final status = (item['status'] ?? '').toString().toLowerCase();

      return status == 'menunggu' ||
          status == 'disetujui' ||
          status == 'dipinjam';
    }).length;
  }

  IconData _iconAlat(String alat) {
    final nama = alat.toLowerCase();

    if (nama.contains('sprayer')) return Icons.water_drop_rounded;
    if (nama.contains('cangkul')) return Icons.construction_rounded;
    if (nama.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  Color _warnaStatus(String status) {
    if (status == 'menunggu') return orangeStatus;
    if (status == 'disetujui') return blueStatus;
    if (status == 'dipinjam') return redStatus;
    if (status == 'dikembalikan') return primaryGreen;
    if (status == 'selesai') return primaryGreen;
    if (status == 'ditolak') return redStatus;

    return textGrey;
  }

  String _teksStatus(String status) {
    if (status == 'menunggu') return 'Menunggu';
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'dipinjam') return 'Dipinjam';
    if (status == 'dikembalikan') return 'Dikembalikan';
    if (status == 'selesai') return 'Selesai';
    if (status == 'ditolak') return 'Ditolak';

    return status.isEmpty ? '-' : status;
  }

  String _formatTanggal(dynamic value) {
    final raw = (value ?? '').toString().trim();
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

  void _tampilkanDetailTanggal(
    int tanggal,
    List<MapEntry<String, dynamic>> dataPeminjaman,
  ) {
    if (!mounted) return;

    final keterangan = _keteranganTanggal(tanggal, dataPeminjaman);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$tanggal ${_bulanTahun()} - $keterangan'),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _pilihAlat(String idAlat, String namaAlat) {
    if (!mounted) return;

    setState(() {
      idAlatDipilih = idAlat;
      namaAlatDipilih = namaAlat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: _alatRef.onValue,
          builder: (context, alatSnapshot) {
            final alatList = _ambilAlatList(alatSnapshot.data?.snapshot.value);

            if (idAlatDipilih.isEmpty && alatList.isNotEmpty) {
              final firstId = alatList.first.key.toString();
              final firstData = Map<String, dynamic>.from(
                alatList.first.value as Map,
              );

              idAlatDipilih = firstId;
              namaAlatDipilih = (firstData['nama_alat'] ?? '-').toString();
            }

            return StreamBuilder<DatabaseEvent>(
              stream: _peminjamanRef.onValue,
              builder: (context, pinjamSnapshot) {
                final dataPeminjaman = _ambilPeminjamanList(
                  pinjamSnapshot.data?.snapshot.value,
                );

                final dataAlat = _dataUntukAlat(dataPeminjaman);
                final totalAktif = _hitungSemuaAktif(dataAlat);
                final menunggu = _hitungStatus(dataAlat, 'menunggu');
                final disetujui = _hitungStatus(dataAlat, 'disetujui');
                final dipinjam = _hitungStatus(dataAlat, 'dipinjam');

                if (alatSnapshot.connectionState == ConnectionState.waiting ||
                    pinjamSnapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: [
                      _headerPage(0),
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(color: primaryGreen),
                        ),
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _headerPage(alatList.length),
                    if (alatList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: _emptySchedule(
                          title: 'Belum Ada Alat',
                          message:
                              'Data alat pertanian aktif belum tersedia. Tambahkan data alat terlebih dahulu.',
                        ),
                      )
                    else ...[
                      const SizedBox(height: 16),
                      _sectionTitle(
                        title: 'Pilih Alat',
                        subtitle: 'Pilih alat untuk melihat jadwal penggunaan',
                        horizontalPadding: 16,
                      ),
                      const SizedBox(height: 12),
                      _pilihAlatList(alatList),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ringkasanAlat(
                          totalAktif: totalAktif,
                          menunggu: menunggu,
                          disetujui: disetujui,
                          dipinjam: dipinjam,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle(
                        title: 'Kalender Ketersediaan',
                        subtitle:
                            'Hijau tersedia, warna lain berarti terjadwal',
                        horizontalPadding: 16,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _kalenderCard(dataPeminjaman),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle(
                        title: 'Urutan Jadwal Peminjam',
                        subtitle: 'Daftar antrean peminjaman alat terpilih',
                        horizontalPadding: 16,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                        child: _daftarJadwal(dataAlat),
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

  Widget _headerPage(int totalAlat) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jadwal Alat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau ketersediaan dan urutan peminjaman alat',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _headerCounter(totalAlat),
        ],
      ),
    );
  }

  Widget _headerCounter(int totalAlat) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            totalAlat.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'alat',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihAlatList(List<MapEntry<String, dynamic>> daftarAlat) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
            onTap: () => _pilihAlat(idAlat, namaAlat),
            borderRadius: BorderRadius.circular(15),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: aktif ? primaryGreen : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: aktif ? primaryGreen : cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: aktif ? 0.07 : 0.03),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _iconAlat(namaAlat),
                    color: aktif ? Colors.white : primaryGreen,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    namaAlat,
                    style: TextStyle(
                      color: aktif ? Colors.white : textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
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
    final tersedia = dipinjam == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _iconAlat(namaAlatDipilih),
              color: primaryGreen,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaAlatDipilih,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalAktif jadwal aktif • $menunggu menunggu • $disetujui disetujui • $dipinjam dipinjam',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusMini(
            label: tersedia ? 'Siap' : 'Terpakai',
            color: tersedia ? primaryGreen : redStatus,
          ),
        ],
      ),
    );
  }

  Widget _kalenderCard(List<MapEntry<String, dynamic>> dataPeminjaman) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _bulanTahun(),
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _legend(primaryGreen, 'Tersedia'),
              _legend(orangeStatus, 'Menunggu'),
              _legend(blueStatus, 'Disetujui'),
              _legend(redStatus, 'Dipinjam'),
            ],
          ),
          const SizedBox(height: 16),
          _namaHari(),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: _jumlahHariDalamBulan(),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final tanggal = index + 1;
              final warna = _warnaTanggal(tanggal, dataPeminjaman);

              return InkWell(
                onTap: () => _tampilkanDetailTanggal(tanggal, dataPeminjaman),
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: warna.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: warna.withValues(alpha: 0.26)),
                  ),
                  child: Text(
                    '$tanggal',
                    style: TextStyle(
                      color: warna,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
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
      final tanggalA = _ambilTanggal(itemA['tanggal_pinjam'] ?? '');
      final tanggalB = _ambilTanggal(itemB['tanggal_pinjam'] ?? '');
      return tanggalA.compareTo(tanggalB);
    });

    if (jadwalAktif.isEmpty) {
      return _emptySchedule(
        title: 'Belum Ada Jadwal',
        message: 'Belum ada data peminjaman aktif untuk alat ini.',
      );
    }

    return Column(
      children: List.generate(jadwalAktif.length, (index) {
        final item = Map<String, dynamic>.from(jadwalAktif[index].value as Map);
        final nomorUrut = index + 1;

        final nama = (item['nama'] ?? '-').toString();
        final nik = (item['nik'] ?? '-').toString();
        final status = (item['status'] ?? 'menunggu').toString().toLowerCase();
        final tanggalPinjam = _formatTanggal(item['tanggal_pinjam']);
        final tanggalKembali = _formatTanggal(item['tanggal_kembali']);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: _warnaStatus(status).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    nomorUrut.toString(),
                    style: TextStyle(
                      color: _warnaStatus(status),
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
                      nama,
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
                      'NIK $nik',
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
                          Icons.event_rounded,
                          tanggalPinjam,
                          blueStatus,
                        ),
                        _miniTag(
                          Icons.event_available_rounded,
                          tanggalKembali,
                          orangeStatus,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusMini(
                label: _teksStatus(status),
                color: _warnaStatus(status),
              ),
            ],
          ),
        );
      }),
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

  Widget _emptySchedule({required String title, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: primaryGreen,
              size: 38,
            ),
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

  Widget _sectionTitle({
    required String title,
    required String subtitle,
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
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
                    fontSize: 16.5,
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
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _statusMini({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
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
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 9,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
