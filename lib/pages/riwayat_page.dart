import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class RiwayatPage extends StatefulWidget {
  final String nik;

  const RiwayatPage({super.key, required this.nik});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  );

  late final DatabaseReference pupukRef;
  late final DatabaseReference peminjamanRef;

  @override
  void initState() {
    super.initState();
    pupukRef = db.ref("bantuan_pupuk");
    peminjamanRef = db.ref("peminjaman_alat");
  }

  Color warnaStatus(String status) {
    if (status == "disetujui") return Colors.green;
    if (status == "ditolak") return Colors.red;
    return Colors.orange;
  }

  String teksStatus(String status) {
    if (status == "disetujui") return "Disetujui";
    if (status == "ditolak") return "Ditolak";
    return "Menunggu";
  }

  IconData iconAlat(String alat) {
    if (alat.toLowerCase().contains("sprayer")) return Icons.water_drop;
    if (alat.toLowerCase().contains("cangkul")) return Icons.build;
    return Icons.agriculture;
  }

  @override
  Widget build(BuildContext context) {
    final nik = widget.nik.trim();

    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Riwayat Aktivitas"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Riwayat Bantuan Pupuk",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          StreamBuilder<DatabaseEvent>(
            stream: pupukRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Text("Belum ada riwayat bantuan pupuk");
              }

              final rawData = snapshot.data!.snapshot.value;

              if (rawData is! Map) {
                return const Text("Format data pupuk tidak sesuai");
              }

              final data = Map<String, dynamic>.from(rawData);

              final list =
                  data.values
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .where(
                        (item) => (item["nik"] ?? "").toString().trim() == nik,
                      )
                      .toList();

              if (list.isEmpty) {
                return const Text("Belum ada riwayat bantuan pupuk");
              }

              return Column(
                children:
                    list.map((item) {
                      final status =
                          (item["status"] ?? "menunggu")
                              .toString()
                              .toLowerCase();

                      final color = warnaStatus(status);

                      return riwayatCard(
                        icon: Icons.grass,
                        title: item["jenis_pupuk"] ?? "-",
                        subtitle:
                            "Jumlah: ${item["jumlah_pupuk"] ?? "-"} Kg | Jatah: ${item["jatah_pupuk"] ?? "-"} Kg",
                        status: teksStatus(status),
                        color: color,
                      );
                    }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          const Text(
            "Riwayat Peminjaman Alat",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          StreamBuilder<DatabaseEvent>(
            stream: peminjamanRef.onValue,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return const Text("Belum ada riwayat peminjaman alat");
              }

              final rawData = snapshot.data!.snapshot.value;

              if (rawData is! Map) {
                return const Text("Format data peminjaman tidak sesuai");
              }

              final data = Map<String, dynamic>.from(rawData);

              final list =
                  data.values
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .where(
                        (item) => (item["nik"] ?? "").toString().trim() == nik,
                      )
                      .toList();

              if (list.isEmpty) {
                return const Text("Belum ada riwayat peminjaman alat");
              }

              return Column(
                children:
                    list.map((item) {
                      final status =
                          (item["status"] ?? "menunggu")
                              .toString()
                              .toLowerCase();

                      final color = warnaStatus(status);
                      final alat = item["alat"] ?? "-";

                      return riwayatCard(
                        icon: iconAlat(alat),
                        title: alat,
                        subtitle:
                            "Pinjam: ${item["tanggal_pinjam"] ?? "-"} | Kembali: ${item["tanggal_kembali"] ?? "-"}",
                        status: teksStatus(status),
                        color: color,
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget riwayatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
