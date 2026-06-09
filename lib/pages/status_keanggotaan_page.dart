import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StatusKeanggotaanPage extends StatefulWidget {
  const StatusKeanggotaanPage({super.key});

  @override
  State<StatusKeanggotaanPage> createState() => _StatusKeanggotaanPageState();
}

class _StatusKeanggotaanPageState extends State<StatusKeanggotaanPage> {
  final nikController = TextEditingController();

  bool isLoading = false;
  Map<String, dynamic>? dataAnggota;

  final DatabaseReference calonAnggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("calon_anggota");

  Future<void> cekStatus() async {
    setState(() {
      isLoading = true;
      dataAnggota = null;
    });

    final snapshot =
        await calonAnggotaRef
            .orderByChild("nik")
            .equalTo(nikController.text)
            .get();

    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final anggota = Map<String, dynamic>.from(data.values.first as Map);

      setState(() {
        dataAnggota = anggota;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data anggota tidak ditemukan")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  Color warnaStatus(String status) {
    if (status == "disetujui") return Colors.green;
    if (status == "ditolak") return Colors.red;
    return Colors.orange;
  }

  String teksStatus(String status) {
    if (status == "disetujui") return "Disetujui";
    if (status == "ditolak") return "Ditolak";
    return "Menunggu Verifikasi";
  }

  @override
  Widget build(BuildContext context) {
    final status =
        (dataAnggota?["status"] ?? "menunggu").toString().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Status Keanggotaan"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nikController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Masukkan NIK",
                prefixIcon: const Icon(Icons.badge),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : cekStatus,
                child: Text(
                  isLoading ? "Mengecek..." : "Cek Status",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (dataAnggota != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dataAnggota!["nama"] ?? "-",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text("NIK: ${dataAnggota!["nik"] ?? "-"}"),
                    Text("Alamat: ${dataAnggota!["alamat"] ?? "-"}"),
                    Text(
                      "Jumlah Petak Sawah: ${dataAnggota!["jumlah_petak_sawah"] ?? "-"}",
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: warnaStatus(status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        teksStatus(status),
                        style: TextStyle(
                          color: warnaStatus(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
