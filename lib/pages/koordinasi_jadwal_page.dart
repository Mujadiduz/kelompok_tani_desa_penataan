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
  static const Color selectedBlue = Color(0xff2563EB);

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

  String bulanTahun() {
    return '${namaBulan[sekarang.month - 1]} ${sekarang.year}';
  }

  String tanggalLengkap() {
    return '$tanggalDipilih ${bulanTahun()}';
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
    final namaAlat = (item['alat'] ?? '').toString();

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

  Color warnaTanggal(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    final item = dataPadaTanggal(tanggal, dataPeminjaman);

    if (item == null) return primaryGreen;

    final status = (item['status'] ?? '').toString().toLowerCase();

    if (status == 'menunggu') return orangeStatus;
    if (status == 'disetujui' || status == 'dipinjam') return redStatus;

    return primaryGreen;
  }

  bool bisaDipilihTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    return dataPadaTanggal(tanggal, dataPeminjaman) == null;
  }

  String keteranganTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    final item = dataPadaTanggal(tanggal, dataPeminjaman);

    if (item == null) return 'Tanggal tersedia';

    final status = (item['status'] ?? '').toString().toLowerCase();
    final nama = (item['nama'] ?? '-').toString();

    if (status == 'menunggu') return 'Sedang menunggu persetujuan';
    if (status == 'disetujui') return 'Sudah disetujui untuk $nama';
    if (status == 'dipinjam') return 'Sedang dipinjam oleh $nama';

    return 'Tanggal tersedia';
  }

  List<Map<String, dynamic>> ambilDataPeminjaman(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    return data.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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

  void pilihTanggal(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    final bisaDipilih = bisaDipilihTanggal(tanggal, dataPeminjaman);

    if (!bisaDipilih) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(keteranganTanggal(tanggal, dataPeminjaman)),
          backgroundColor: orangeStatus,
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
                        _alatCard(),
                        const SizedBox(height: 14),
                        _legendStatus(),
                        const SizedBox(height: 14),
                        Expanded(child: _kalenderCard(dataPeminjaman)),
                        if (tanggalDipilih != null) ...[
                          const SizedBox(height: 14),
                          _tanggalDipilihCard(),
                        ],
                      ],
                    ),
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
                  _backButton(context),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Koordinasi Jadwal',
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
                'Pilih Jadwal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tentukan tanggal peminjaman untuk ${widget.namaAlat}.',
                style: const TextStyle(
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

  Widget _alatCard() {
    final color = warnaAlat(widget.namaAlat);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(iconAlat(widget.namaAlat), color: color, size: 29),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.namaAlat,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
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
        ],
      ),
    );
  }

  Widget _kalenderCard(List<Map<String, dynamic>> dataPeminjaman) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bulanTahun(),
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          _namaHari(),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              itemCount: jumlahHariDalamBulan(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final tanggal = index + 1;
                return _tanggalBox(tanggal, dataPeminjaman);
              },
            ),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedBlue : warna,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? textDark : Colors.transparent,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (selected ? selectedBlue : warna).withValues(alpha: 0.16),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: bisaDipilih ? 1 : 0.75,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, color: primaryGreen),
          const SizedBox(width: 10),
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
          onPressed: tanggalDipilih == null ? null : lanjutKeForm,
          child: const Text(
            'Lanjut Isi Data',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: textGrey,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _stepIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stepCircle('1', 'Pilih', false),
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
