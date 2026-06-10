import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class JadwalAlatAdminPage extends StatefulWidget {
  const JadwalAlatAdminPage({super.key});

  @override
  State<JadwalAlatAdminPage> createState() => _JadwalAlatAdminPageState();
}

class _JadwalAlatAdminPageState extends State<JadwalAlatAdminPage> {
  String alatDipilih = "Traktor";

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

  Color warnaTanggal(int tanggal, List<Map<String, dynamic>> dataPeminjaman) {
    for (final item in dataPeminjaman) {
      final alat = (item["alat"] ?? "").toString();
      final status = (item["status"] ?? "").toString().toLowerCase();
      final tanggalPinjam = (item["tanggal_pinjam"] ?? "").toString();

      if (alat == alatDipilih &&
          tanggalPinjam.contains("$tanggal ${bulanTahun()}")) {
        if (status == "disetujui") return Colors.red;
        if (status == "menunggu") return Colors.orange;
      }
    }

    return Colors.green;
  }

  String keteranganTanggal(
    int tanggal,
    List<Map<String, dynamic>> dataPeminjaman,
  ) {
    for (final item in dataPeminjaman) {
      final alat = (item["alat"] ?? "").toString();
      final status = (item["status"] ?? "").toString().toLowerCase();
      final tanggalPinjam = (item["tanggal_pinjam"] ?? "").toString();
      final nama = (item["nama"] ?? "-").toString();

      if (alat == alatDipilih &&
          tanggalPinjam.contains("$tanggal ${bulanTahun()}")) {
        if (status == "disetujui") return "Dipinjam oleh $nama";
        if (status == "menunggu") return "Menunggu persetujuan";
      }
    }

    return "Tersedia";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f2ff),
      appBar: AppBar(
        title: const Text("Jadwal & Ketersediaan Alat"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: alatDipilih,
              items: const [
                DropdownMenuItem(value: "Traktor", child: Text("Traktor")),
                DropdownMenuItem(
                  value: "Hand Sprayer",
                  child: Text("Hand Sprayer"),
                ),
                DropdownMenuItem(
                  value: "Cangkul Mesin",
                  child: Text("Cangkul Mesin"),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  alatDipilih = value!;
                });
              },
              decoration: InputDecoration(
                labelText: "Pilih Alat",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                statusColor(Colors.green, "Tersedia"),
                const SizedBox(width: 12),
                statusColor(Colors.orange, "Menunggu"),
                const SizedBox(width: 12),
                statusColor(Colors.red, "Dipinjam"),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              bulanTahun(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: peminjamanRef.onValue,
                builder: (context, snapshot) {
                  List<Map<String, dynamic>> dataPeminjaman = [];

                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final rawData = snapshot.data!.snapshot.value;

                    if (rawData is Map) {
                      final data = Map<String, dynamic>.from(rawData);

                      dataPeminjaman =
                          data.values
                              .map((e) => Map<String, dynamic>.from(e as Map))
                              .toList();
                    }
                  }
                  return GridView.builder(
                    itemCount: jumlahHariDalamBulan(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemBuilder: (context, index) {
                      final tanggal = index + 1;
                      final warna = warnaTanggal(tanggal, dataPeminjaman);
                      final keterangan = keteranganTanggal(
                        tanggal,
                        dataPeminjaman,
                      );

                      return GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "$tanggal ${bulanTahun()} - $keterangan",
                              ),
                            ),
                          );
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: warna,
                            borderRadius: BorderRadius.circular(10),
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
                    },
                  );
                },
              ),
            ),
          ],
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
}
