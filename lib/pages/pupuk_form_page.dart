import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'pupuk_konfirmasi_page.dart';

class PupukFormPage extends StatefulWidget {
  final String namaPupuk;

  const PupukFormPage({super.key, required this.namaPupuk});

  @override
  State<PupukFormPage> createState() => _PupukFormPageState();
}

class _PupukFormPageState extends State<PupukFormPage> {
  final nikController = TextEditingController();
  final jumlahPupukController = TextEditingController();
  final catatanController = TextEditingController();

  String nama = "";
  String jumlahPetakSawah = "";
  double jatahPupuk = 0;

  bool isLoading = false;
  bool dataDitemukan = false;

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("anggota");

  Future<void> cekDataAnggota() async {
    setState(() {
      isLoading = true;
      dataDitemukan = false;
    });

    try {
      final snapshot = await anggotaRef.get().timeout(
        const Duration(seconds: 10),
      );

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        Map<String, dynamic>? anggotaDitemukan;

        data.forEach((key, value) {
          final anggota = Map<String, dynamic>.from(value as Map);

          if ((anggota["nik"] ?? "").toString().trim() ==
              nikController.text.trim()) {
            anggotaDitemukan = anggota;
          }
        });

        if (anggotaDitemukan != null) {
          final petak =
              int.tryParse(
                (anggotaDitemukan!["jumlah_petak_sawah"] ?? "0").toString(),
              ) ??
              0;

          setState(() {
            nama = anggotaDitemukan!["nama"] ?? "";
            jumlahPetakSawah = petak.toString();
            jatahPupuk = petak / 2;
            dataDitemukan = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data anggota ditemukan")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("NIK tidak ditemukan di data anggota"),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data anggota masih kosong")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengecek data: $e")));
    }

    setState(() {
      isLoading = false;
    });
  }

  bool melebihiJatah() {
    final jumlahDiajukan = double.tryParse(jumlahPupukController.text) ?? 0;

    return jumlahDiajukan > jatahPupuk;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Isi Data Pupuk"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Isi Data Permintaan",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "VERSI BARU CEK NIK",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              "Jenis Pupuk: ${widget.namaPupuk}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: nikController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration("Masukkan NIK", Icons.badge),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : cekDataAnggota,
                child: Text(
                  isLoading ? "Mengecek..." : "Cek Data Anggota",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 18),

            if (dataDitemukan)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: cardStyle(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("NIK: ${nikController.text}"),
                    Text("Jumlah Petak Sawah: $jumlahPetakSawah"),
                    Text("Jatah Pupuk Subsidi: $jatahPupuk Kg"),
                    const SizedBox(height: 8),
                    const Text(
                      "Ketentuan: 2 petak sawah = 1 Kg pupuk subsidi",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 18),

            TextField(
              controller: jumlahPupukController,
              keyboardType: TextInputType.number,
              decoration: inputDecoration(
                "Jumlah Pupuk Diajukan (Kg)",
                Icons.scale,
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 8),

            if (dataDitemukan && melebihiJatah())
              const Text(
                "Jumlah pupuk melebihi jatah subsidi",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 12),

            TextField(
              controller: catatanController,
              maxLines: 3,
              decoration: inputDecoration("Catatan", Icons.note),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed:
                    !dataDitemukan
                        ? null
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => PupukKonfirmasiPage(
                                    namaPupuk: widget.namaPupuk,
                                    nama: nama,
                                    nik: nikController.text,
                                    jumlahPetakSawah: jumlahPetakSawah,
                                    jumlahPupuk: jumlahPupukController.text,
                                    jatahPupuk: jatahPupuk.toString(),
                                    statusJatah:
                                        melebihiJatah()
                                            ? "melebihi_jatah"
                                            : "sesuai_jatah",
                                    catatan: catatanController.text,
                                  ),
                            ),
                          );
                        },
                child: const Text(
                  "Lanjut",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  BoxDecoration cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
