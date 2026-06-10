import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class VerifikasiPupukPage extends StatefulWidget {
  const VerifikasiPupukPage({super.key});

  @override
  State<VerifikasiPupukPage> createState() => _VerifikasiPupukPageState();
}

class _VerifikasiPupukPageState extends State<VerifikasiPupukPage> {
  final DatabaseReference pupukRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("bantuan_pupuk");

  Future<void> updateStatus(String id, String status) async {
    await pupukRef.child(id).update({"status": status});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Pengajuan pupuk berhasil $status")));
  }

  Color warnaStatus(String status) {
    if (status == "disetujui") return Colors.green;
    if (status == "ditolak") return Colors.red;
    return Colors.orange;
  }

  Color warnaJatah(String statusJatah) {
    if (statusJatah == "melebihi_jatah") return Colors.red;
    return Colors.green;
  }

  String teksJatah(String statusJatah) {
    if (statusJatah == "melebihi_jatah") {
      return "Melebihi Jatah";
    }
    return "Sesuai Jatah";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Verifikasi Bantuan Pupuk"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: pupukRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text("Belum ada pengajuan bantuan pupuk"),
            );
          }

          final rawData = snapshot.data!.snapshot.value;

          if (rawData is! Map) {
            return const Center(
              child: Text("Format data Firebase tidak sesuai"),
            );
          }

          final data = Map<String, dynamic>.from(rawData);
          final pupukList = data.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: pupukList.length,
            itemBuilder: (context, index) {
              final id = pupukList[index].key.toString();

              final pupuk = Map<String, dynamic>.from(
                pupukList[index].value as Map,
              );

              final status =
                  (pupuk["status"] ?? "menunggu").toString().toLowerCase();

              final statusJatah =
                  (pupuk["status_jatah"] ?? "sesuai_jatah").toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pupuk["nama"] ?? "-",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text("NIK: ${pupuk["nik"] ?? "-"}"),
                      Text("Jenis Pupuk: ${pupuk["jenis_pupuk"] ?? "-"}"),
                      Text(
                        "Jumlah Petak Sawah: ${pupuk["jumlah_petak_sawah"] ?? "-"}",
                      ),
                      Text("Jatah Pupuk: ${pupuk["jatah_pupuk"] ?? "-"} Kg"),
                      Text(
                        "Jumlah Diajukan: ${pupuk["jumlah_pupuk"] ?? "-"} Kg",
                      ),
                      Text("Catatan: ${pupuk["catatan"] ?? "-"}"),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: warnaStatus(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Status: $status",
                              style: TextStyle(
                                color: warnaStatus(status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: warnaJatah(statusJatah).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              teksJatah(statusJatah),
                              style: TextStyle(
                                color: warnaJatah(statusJatah),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

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
                            const SizedBox(width: 10),
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
              );
            },
          );
        },
      ),
    );
  }
}
