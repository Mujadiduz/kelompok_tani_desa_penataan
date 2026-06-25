import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
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
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF57C00);
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

  Future<void> _refreshData() async {
    await peminjamanRef.get();
  }

  int jumlahHariDalamBulan() {
    return DateTime(sekarang.year, sekarang.month + 1, 0).day;
  }

  int hariPertamaBulan() {
    return DateTime(sekarang.year, sekarang.month, 1).weekday;
  }

  String bulanTahun() {
    return '${namaBulan[sekarang.month - 1]} ${sekarang.year}';
  }

  String tanggalLengkap() {
    if (tanggalDipilih == null) return '';
    final bulan = sekarang.month.toString().padLeft(2, '0');
    final tanggal = tanggalDipilih.toString().padLeft(2, '0');
    return '${sekarang.year}-$bulan-$tanggal';
  }

  int ambilTanggal(dynamic tanggalText) {
    final text = tanggalText.toString();
    final angka = RegExp(r'\d+').firstMatch(text);
    if (angka == null) return 0;
    return int.tryParse(angka.group(0)!) ?? 0;
  }

  bool alatSama(Map<String, dynamic> item) {
    final idAlat = (item['id_alat'] ?? '').toString();
    final namaAlat = (item['alat'] ?? item['nama_alat'] ?? '').toString();

    if (idAlat.isNotEmpty) return idAlat == widget.idAlat;

    return namaAlat.toLowerCase().trim() ==
        widget.namaAlat.toLowerCase().trim();
  }

  List<Map<String, dynamic>> ambilDataPeminjaman(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    return data.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
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
    if (tanggal < sekarang.day) return false;
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

    if (status == 'menunggu') {
      return 'Tanggal ini sedang menunggu persetujuan';
    }

    if (status == 'disetujui') {
      return 'Tanggal ini sudah disetujui admin';
    }

    if (status == 'dipinjam') {
      return 'Alat sedang dipinjam pada tanggal ini';
    }

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
      _showSnackBar(
        keteranganTanggal(tanggal, dataPeminjaman),
        tanggal < sekarang.day ? textGrey : orangeStatus,
      );
      return;
    }

    setState(() => tanggalDipilih = tanggal);
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

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pesan,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        child: SafeArea(
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
                          _alatCard(),
                          const SizedBox(height: 14),
                          _summaryGrid(
                            tersedia: tersedia,
                            menunggu: menunggu,
                            dipakai: disetujui + dipinjam,
                          ),
                          const SizedBox(height: 14),
                          _legendStatus(),
                          const SizedBox(height: 18),
                          _sectionTitle(
                            title: 'Kalender Peminjaman',
                            subtitle: 'Pilih tanggal yang masih tersedia',
                          ),
                          const SizedBox(height: 12),
                          _kalenderCard(dataPeminjaman),
                          if (tanggalDipilih != null) ...[
                            const SizedBox(height: 14),
                            _tanggalDipilihCard(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _bottomButton(),
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
                    'Pilih Jadwal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Atur tanggal peminjaman alat pertanian',
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
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
              ),
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
            'Tahap 2 dari 4',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pilih tanggal peminjaman alat yang masih kosong.',
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
              value: 0.50,
              minHeight: 7,
              backgroundColor: primaryGreen.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alatCard() {
    final color = warnaAlat(widget.namaAlat);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(iconAlat(widget.namaAlat), color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alat yang Dipilih',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.namaAlat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
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

  Widget _summaryGrid({
    required int tersedia,
    required int menunggu,
    required int dipakai,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryMini(
            title: 'Tersedia',
            value: tersedia.toString(),
            icon: Icons.event_available_rounded,
            color: primaryGreen,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryMini(
            title: 'Menunggu',
            value: menunggu.toString(),
            icon: Icons.schedule_rounded,
            color: orangeStatus,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryMini(
            title: 'Terpakai',
            value: dipakai.toString(),
            icon: Icons.event_busy_rounded,
            color: redStatus,
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendStatus() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keterangan Warna',
            style: TextStyle(
              color: textDark,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusColor(primaryGreen, 'Tersedia'),
              _statusColor(orangeStatus, 'Menunggu'),
              _statusColor(redStatus, 'Terpakai'),
              _statusColor(const Color(0xffCBD5E1), 'Lewat'),
            ],
          ),
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

  Widget _kalenderCard(List<Map<String, dynamic>> dataPeminjaman) {
    final totalGrid = jumlahHariDalamBulan() + hariPertamaBulan() - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bulanTahun(),
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
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

              if (index < kosongAwal) return const SizedBox();

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
            width: selected ? 1.4 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: blueStatus.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: primaryGreen,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tanggal dipilih: ${tanggalLengkap()}',
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 12.5,
                height: 1.4,
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
            onPressed: aktif ? lanjutKeForm : null,
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
              aktif ? 'Lanjut Isi Data' : 'Pilih Tanggal Terlebih Dahulu',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
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
