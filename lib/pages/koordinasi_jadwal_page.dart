import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'alat_form_page.dart';

class KoordinasiJadwalPage extends StatefulWidget {
  final String idAlat;
  final String namaAlat;
  final String nama;
  final String nik;

  const KoordinasiJadwalPage({
    super.key,
    required this.idAlat,
    required this.namaAlat,
    required this.nama,
    required this.nik,
  });

  @override
  State<KoordinasiJadwalPage> createState() => _KoordinasiJadwalPageState();
}

class _KoordinasiJadwalPageState extends State<KoordinasiJadwalPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color redStatus = Color(0xffE53935);
  static const Color blueStatus = Color(0xff1976D2);

  int? tanggalDipilih;
  final DateTime sekarang = DateTime.now();

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

  int hariPertamaBulan() {
    final firstDay = DateTime(sekarang.year, sekarang.month, 1);
    return firstDay.weekday;
  }

  String bulanTahun() {
    return '${namaBulan[sekarang.month - 1]} ${sekarang.year}';
  }

  String tanggalLengkap() {
    if (tanggalDipilih == null) return '';

    final tanggal = tanggalDipilih.toString().padLeft(2, '0');
    final bulan = sekarang.month.toString().padLeft(2, '0');

    return '${sekarang.year}-$bulan-$tanggal';
  }

  int ambilTanggal(dynamic tanggalText) {
    final text = tanggalText.toString();
    final angka = RegExp(r'\d+').firstMatch(text);

    if (angka != null) {
      return int.tryParse(angka.group(0)!) ?? 0;
    }

    return 0;
  }

  bool alatSama(Map<String, dynamic> item) {
    final idAlat = (item['id_alat'] ?? '').toString();
    final namaAlat = (item['alat'] ?? item['nama_alat'] ?? '').toString();

    if (idAlat.isNotEmpty) {
      return idAlat == widget.idAlat;
    }

    return namaAlat.toLowerCase().trim() ==
        widget.namaAlat.toLowerCase().trim();
  }

  Map<String, dynamic>? dataPadaTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    for (final item in dataPeminjaman) {
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

  List<Map<String, dynamic>> ambilDataPeminjaman(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    return data.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  int hitungStatus(List<Map<String, dynamic>> data, String statusTarget) {
    int total = 0;

    for (final item in data) {
      if (!alatSama(item)) continue;

      final status = (item['status'] ?? '').toString().toLowerCase();

      if (status == statusTarget) total++;
    }

    return total;
  }

  int hitungTanggalTerpakai(List<Map<String, dynamic>> data) {
    int total = 0;

    for (int i = 1; i <= jumlahHariDalamBulan(); i++) {
      if (dataPadaTanggal(i, data) != null) total++;
    }

    return total;
  }

  bool bisaDipilihTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    final hariIni = sekarang.day;
    if (tanggal < hariIni) return false;

    return dataPadaTanggal(tanggal, dataPeminjaman) == null;
  }

  Color warnaTanggal(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    if (tanggal < sekarang.day) return const Color(0xffCBD5E1);

    final item = dataPadaTanggal(tanggal, dataPeminjaman);

    if (item == null) return primaryGreen;

    final status = (item['status'] ?? '').toString().toLowerCase();

    if (status == 'menunggu') return orangeStatus;
    if (status == 'disetujui' || status == 'dipinjam') return redStatus;

    return primaryGreen;
  }

  String keteranganTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    if (tanggal < sekarang.day) return 'Tanggal sudah lewat';

    final item = dataPadaTanggal(tanggal, dataPeminjaman);

    if (item == null) return 'Tanggal tersedia';

    final status = (item['status'] ?? '').toString().toLowerCase();
    final nama = (item['nama'] ?? '-').toString();

    if (status == 'menunggu') return 'Sedang menunggu persetujuan';
    if (status == 'disetujui') return 'Sudah disetujui untuk $nama';
    if (status == 'dipinjam') return 'Sedang dipinjam oleh $nama';

    return 'Tanggal tersedia';
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

  void pilihTanggal(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    final bisaDipilih = bisaDipilihTanggal(tanggal, dataPeminjaman);

    if (!bisaDipilih) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(keteranganTanggal(tanggal, dataPeminjaman)),
          backgroundColor: tanggal < sekarang.day ? textGrey : orangeStatus,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      tanggalDipilih = tanggal;
    });
  }

  void lanjutKeForm() {
    if (tanggalDipilih == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AlatFormPage(
              idAlat: widget.idAlat,
              namaAlat: widget.namaAlat,
              tanggalDipilih: tanggalLengkap(),
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
          stream: peminjamanRef.onValue,
          builder: (context, snapshot) {
            final dataPeminjaman = ambilDataPeminjaman(
              snapshot.data?.snapshot.value,
            );

            final menunggu = hitungStatus(dataPeminjaman, 'menunggu');
            final disetujui = hitungStatus(dataPeminjaman, 'disetujui');
            final dipinjam = hitungStatus(dataPeminjaman, 'dipinjam');
            final terpakai = hitungTanggalTerpakai(dataPeminjaman);
            final tersedia = jumlahHariDalamBulan() - terpakai;

            return Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _header(context)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                          child: _stepIndicator(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                          child: _alatCard(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                          child: _summaryGrid(
                            tersedia: tersedia,
                            menunggu: menunggu,
                            dipakai: disetujui + dipinjam,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                          child: _legendStatus(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                          child: _sectionTitle('Kalender Peminjaman'),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                          child: _kalenderCard(dataPeminjaman),
                        ),
                      ),
                      if (tanggalDipilih != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                            child: _tanggalDipilihCard(),
                          ),
                        )
                      else
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  ),
                ),
                _bottomButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff14532D), Color(0xff2E7D32), Color(0xff66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
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
              Icons.calendar_month_rounded,
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
                      'Koordinasi Jadwal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Pilih Jadwal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Pilih tanggal peminjaman untuk ${widget.namaAlat}. Tanggal terpakai tidak dapat dipilih.',
                style: const TextStyle(
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
                          fontWeight: FontWeight.w800,
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

  Widget _stepIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stepCircle('1', 'Pilih', true, completed: true),
          _stepLine(true),
          _stepCircle('2', 'Jadwal', true),
          _stepLine(false),
          _stepCircle('3', 'Data', false),
          _stepLine(false),
          _stepCircle('4', 'Kirim', false),
        ],
      ),
    );
  }

  Widget _stepCircle(
    String number,
    String label,
    bool active, {
    bool completed = false,
  }) {
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
            child:
                completed
                    ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                    : Text(
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

  Widget _alatCard() {
    final color = warnaAlat(widget.namaAlat);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(iconAlat(widget.namaAlat), color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alat Dipilih',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.namaAlat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'ID Alat: ${widget.idAlat}',
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
        ],
      ),
    );
  }

  Widget _summaryGrid({
    required int tersedia,
    required int menunggu,
    required int dipakai,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryMini(
            icon: Icons.check_circle_rounded,
            title: 'Tersedia',
            value: tersedia.toString(),
            color: primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryMini(
            icon: Icons.schedule_rounded,
            title: 'Menunggu',
            value: menunggu.toString(),
            color: orangeStatus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryMini(
            icon: Icons.block_rounded,
            title: 'Terpakai',
            value: dipakai.toString(),
            color: redStatus,
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
      height: 104,
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
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

  Widget _legendStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statusColor(primaryGreen, 'Tersedia'),
          _statusColor(orangeStatus, 'Menunggu'),
          _statusColor(redStatus, 'Terpakai'),
          _statusColor(const Color(0xffCBD5E1), 'Lewat'),
        ],
      ),
    );
  }

  Widget _statusColor(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: textGrey,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
            Icons.calendar_month_rounded,
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

  Widget _kalenderCard(List<Map<String, dynamic>> dataPeminjaman) {
    final totalGrid = jumlahHariDalamBulan() + hariPertamaBulan() - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_rounded, color: primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bulanTahun(),
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _namaHari(),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalGrid,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final kosongAwal = hariPertamaBulan() - 1;

              if (index < kosongAwal) {
                return const SizedBox();
              }

              final tanggal = index - kosongAwal + 1;
              return _tanggalBox(tanggal, dataPeminjaman);
            },
          ),
        ],
      ),
    );
  }

  Widget _namaHari() {
    final hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Row(
      children:
          hari.map((item) {
            return Expanded(
              child: Center(
                child: Text(
                  item,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _tanggalBox(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    final warna = warnaTanggal(tanggal, dataPeminjaman);
    final bisaDipilih = bisaDipilihTanggal(tanggal, dataPeminjaman);
    final selected = tanggalDipilih == tanggal;

    return InkWell(
      onTap: () => pilihTanggal(tanggal, dataPeminjaman),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? blueStatus : warna,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? textDark : Colors.transparent,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? blueStatus : warna).withValues(alpha: 0.16),
              blurRadius: selected ? 10 : 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: bisaDipilih ? 1 : 0.72,
          child: Text(
            '$tanggal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tanggalDipilihCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tanggal dipilih: ${tanggalLengkap()}',
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    final aktif = tanggalDipilih != null;

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
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.42),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
            ),
            onPressed: aktif ? lanjutKeForm : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(
              aktif ? 'Lanjut Isi Data' : 'Pilih Tanggal Terlebih Dahulu',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
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
