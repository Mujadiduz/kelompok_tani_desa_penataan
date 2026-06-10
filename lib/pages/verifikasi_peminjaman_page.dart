import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class VerifikasiPeminjamanPage extends StatefulWidget {
  const VerifikasiPeminjamanPage({super.key});

  @override
  State<VerifikasiPeminjamanPage> createState() =>
      _VerifikasiPeminjamanPageState();
}

class _VerifikasiPeminjamanPageState extends State<VerifikasiPeminjamanPage> {
  final DatabaseReference peminjamanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("peminjaman_alat");

  Future<void> updateStatus(String id, String status) async {
    await peminjamanRef.child(id).update({"status": status});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Peminjaman berhasil $status")));
  }

  Color warnaStatus(String status) {
    if (status == "disetujui") return Colors.green;
    if (status == "ditolak") return Colors.red;
    return Colors.orange;
  }

  IconData iconAlat(String alat) {
    if (alat.toLowerCase().contains("sprayer")) return Icons.water_drop;
    if (alat.toLowerCase().contains("cangkul")) return Icons.build;
    return Icons.agriculture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Verifikasi Peminjaman Alat"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: peminjamanRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text("Belum ada pengajuan peminjaman alat"),
            );
          }

          final rawData = snapshot.data!.snapshot.value;

          if (rawData is! Map) {
            return const Center(
              child: Text("Format data Firebase tidak sesuai"),
            );
          }

          final data = Map<String, dynamic>.from(rawData);
          final peminjamanList = data.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: peminjamanList.length,
            itemBuilder: (context, index) {
              final id = peminjamanList[index].key.toString();

              final item = Map<String, dynamic>.from(
                peminjamanList[index].value as Map,
              );

              final status =
                  (item["status"] ?? "menunggu").toString().toLowerCase();

              final alat = item["alat"] ?? "-";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.15),
                        child: Icon(iconAlat(alat), color: Colors.orange),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["nama"] ?? "-",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("NIK: ${item["nik"] ?? "-"}"),
                            Text("Alat: $alat"),
                            Text("Pinjam: ${item["tanggal_pinjam"] ?? "-"}"),
                            Text("Kembali: ${item["tanggal_kembali"] ?? "-"}"),
                            Text("Catatan: ${item["catatan"] ?? "-"}"),

                            const SizedBox(height: 8),

                            Text(
                              "Status: $status",
                              style: TextStyle(
                                color: warnaStatus(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            if (status == "menunggu")
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () {
                                        updateStatus(id, "disetujui");
                                      },
                                      child: const Text(
                                        "Setujui",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () {
                                        updateStatus(id, "ditolak");
                                      },
                                      child: const Text(
                                        "Tolak",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
