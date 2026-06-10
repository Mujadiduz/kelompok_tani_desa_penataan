import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class VerifikasiAnggotaPage extends StatefulWidget {
  const VerifikasiAnggotaPage({super.key});

  @override
  State<VerifikasiAnggotaPage> createState() => _VerifikasiAnggotaPageState();
}

class _VerifikasiAnggotaPageState extends State<VerifikasiAnggotaPage> {
  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  );

  late final DatabaseReference calonAnggotaRef;
  late final DatabaseReference anggotaRef;

  @override
  void initState() {
    super.initState();
    calonAnggotaRef = db.ref("calon_anggota");
    anggotaRef = db.ref("anggota");
  }

  Future<void> setujuiAnggota(String id, Map anggota) async {
    await anggotaRef.child(id).set({
      "nama": anggota["nama"] ?? "",
      "nik": anggota["nik"] ?? "",
      "telepon": anggota["telepon"] ?? "",
      "alamat": anggota["alamat"] ?? "",
      "jenis_kelamin": anggota["jenis_kelamin"] ?? "",
      "jumlah_petak_sawah": anggota["jumlah_petak_sawah"] ?? "",
      "tanggal_daftar": anggota["tanggal_daftar"] ?? "",
      "password": anggota["password"] ?? "",
      "status": "aktif",
    });

    await calonAnggotaRef.child(id).update({"status": "disetujui"});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Anggota berhasil disetujui")));
  }

  Future<void> tolakAnggota(String id) async {
    try {
      await calonAnggotaRef.child(id).update({"status": "ditolak"});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Anggota ditolak")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menolak anggota: $e")));
    }
  }

  Color warnaStatus(String status) {
    if (status == "disetujui") return Colors.green;
    if (status == "ditolak") return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Verifikasi Anggota"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: calonAnggotaRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Belum ada data calon anggota"));
          }

          final rawData = snapshot.data!.snapshot.value;

          if (rawData is! Map) {
            return const Center(
              child: Text("Format data Firebase tidak sesuai"),
            );
          }

          final data = Map<String, dynamic>.from(rawData);
          final anggotaList = data.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: anggotaList.length,
            itemBuilder: (context, index) {
              final id = anggotaList[index].key.toString();

              final anggota = Map<String, dynamic>.from(
                anggotaList[index].value as Map,
              );

              final status =
                  (anggota["status"] ?? "menunggu").toString().toLowerCase();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anggota["nama"] ?? "-",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text("NIK: ${anggota["nik"] ?? "-"}"),
                      Text("Telepon: ${anggota["telepon"] ?? "-"}"),
                      Text("Alamat: ${anggota["alamat"] ?? "-"}"),
                      Text("Jenis Kelamin: ${anggota["jenis_kelamin"] ?? "-"}"),
                      Text(
                        "Jumlah Petak Sawah: ${anggota["jumlah_petak_sawah"] ?? "-"}",
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: warnaStatus(status),
                        ),
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
                                  setujuiAnggota(id, anggota);
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
                                  tolakAnggota(id);
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
