import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'alat_form_page.dart';

class KoordinasiJadwalPage extends StatefulWidget {
  final String namaAlat;
  final String nama;
  final String nik;

  const KoordinasiJadwalPage({
    super.key,
    required this.namaAlat,
    required this.nama,
    required this.nik,
  });

  @override
  State<KoordinasiJadwalPage> createState() => _KoordinasiJadwalPageState();
}

class _KoordinasiJadwalPageState extends State<KoordinasiJadwalPage> {
  int? tanggalDipilih;
  final DateTime sekarang = DateTime.now();

  final List<String> namaBulan = [
    "Januari",
    "Februari",
    "Maret",
    "April",
    "Mei",
    "Juni",
    "Juli",
    "Agustus",
    "September",
    "Oktober",
    "November",
    "Desember",
  ];

  final DatabaseReference peminjamanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("peminjaman_alat");

  int jumlahHariDalamBulan() {
    return DateTime(sekarang.year, sekarang.month + 1, 0).day;
  }

  String bulanTahun() {
    return "${namaBulan[sekarang.month - 1]} ${sekarang.year}";
  }

  String tanggalLengkap() {
    return "$tanggalDipilih ${bulanTahun()}";
  }

  int ambilTanggal(dynamic tanggalText) {
    final text = tanggalText.toString();
    final angka = RegExp(r'\d+').firstMatch(text);
    if (angka != null) return int.tryParse(angka.group(0)!) ?? 0;
    return 0;
  }

  Color warnaTanggal(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    for (final item in dataPeminjaman) {
      final alat = (item["alat"] ?? "").toString();
      final status = (item["status"] ?? "").toString().toLowerCase();
      final tanggalPinjam = ambilTanggal(item["tanggal_pinjam"] ?? "");
      final tanggalKembali = ambilTanggal(item["tanggal_kembali"] ?? "");

      if (alat == widget.namaAlat &&
          tanggal >= tanggalPinjam &&
          tanggal <= tanggalKembali) {
        if (status == "disetujui") return Colors.red;
        if (status == "menunggu") return Colors.orange;
      }
    }

    return Colors.green;
  }

  bool bisaDipilihTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    for (final item in dataPeminjaman) {
      final alat = (item["alat"] ?? "").toString();
      final status = (item["status"] ?? "").toString().toLowerCase();
      final tanggalPinjam = ambilTanggal(item["tanggal_pinjam"] ?? "");
      final tanggalKembali = ambilTanggal(item["tanggal_kembali"] ?? "");

      if (alat == widget.namaAlat &&
          tanggal >= tanggalPinjam &&
          tanggal <= tanggalKembali &&
          (status == "disetujui" || status == "menunggu")) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef8ef),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Koordinasi Jadwal"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: peminjamanRef.onValue,
        builder: (context, snapshot) {
          final dataPeminjaman = ambilDataPeminjaman(
            snapshot.data?.snapshot.value,
          );

          return Column(
            children: [
              header(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stepIndicator(),
                      const SizedBox(height: 18),
                      alatCard(),
                      const SizedBox(height: 14),
                      legendStatus(),
                      const SizedBox(height: 14),
                      Expanded(child: kalenderCard(dataPeminjaman)),
                      const SizedBox(height: 14),
                      if (tanggalDipilih != null) tanggalDipilihCard(),
                      const SizedBox(height: 12),
                      tombolLanjut(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> ambilDataPeminjaman(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);

    return data.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Widget header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pilih Jadwal",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Tentukan tanggal peminjaman untuk ${widget.namaAlat}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget alatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardStyle(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.orange,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.namaAlat,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget legendStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardStyle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          statusColor(Colors.green, "Tersedia"),
          statusColor(Colors.orange, "Menunggu"),
          statusColor(Colors.red, "Dipinjam"),
        ],
      ),
    );
  }

  Widget kalenderCard(List<Map<String, dynamic>> dataPeminjaman) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bulanTahun(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sen"),
              Text("Sel"),
              Text("Rab"),
              Text("Kam"),
              Text("Jum"),
              Text("Sab"),
              Text("Min"),
            ],
          ),
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
                return tanggalBox(tanggal, dataPeminjaman);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget tanggalBox(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    final warna = warnaTanggal(tanggal, dataPeminjaman);
    final bisaDipilih = bisaDipilihTanggal(tanggal, dataPeminjaman);
    final selected = tanggalDipilih == tanggal;

    return GestureDetector(
      onTap:
          bisaDipilih
              ? () {
                setState(() {
                  tanggalDipilih = tanggal;
                });
              }
              : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.blue : warna.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(10),
          border:
              selected
                  ? Border.all(color: Colors.black, width: 2)
                  : Border.all(color: Colors.transparent),
        ),
        child: Text(
          "$tanggal",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget tanggalDipilihCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.18)),
      ),
      child: Text(
        "Tanggal dipilih: ${tanggalLengkap()}",
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget tombolLanjut() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed:
            tanggalDipilih == null
                ? null
                : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AlatFormPage(
                            namaAlat: widget.namaAlat,
                            tanggalDipilih: tanggalLengkap(),
                            nama: widget.nama,
                            nik: widget.nik,
                          ),
                    ),
                  );
                },
        child: const Text(
          "Lanjut",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget statusColor(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget stepIndicator() {
    return Row(
      children: [
        stepCircle("1", "Pilih", false),
        stepLine(),
        stepCircle("2", "Jadwal", true),
        stepLine(),
        stepCircle("3", "Data", false),
        stepLine(),
        stepCircle("4", "Konfirmasi", false),
      ],
    );
  }

  Widget stepCircle(String number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? Colors.green : Colors.grey.shade300,
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? Colors.green : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget stepLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: Colors.grey.shade300,
      ),
    );
  }

  BoxDecoration cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
