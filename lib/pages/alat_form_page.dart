import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'alat_konfirmasi_page.dart';

class AlatFormPage extends StatefulWidget {
  final String namaAlat;
  final String tanggalDipilih;

  const AlatFormPage({
    super.key,
    required this.namaAlat,
    required this.tanggalDipilih,
  });

  @override
  State<AlatFormPage> createState() => _AlatFormPageState();
}

class _AlatFormPageState extends State<AlatFormPage> {
  final nikController = TextEditingController();
  final tanggalKembaliController = TextEditingController();
  final catatanController = TextEditingController();

  String nama = "";
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
          setState(() {
            nama = anggotaDitemukan!["nama"] ?? "";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Form Peminjaman"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stepIndicator(),
            const SizedBox(height: 25),

            const Text(
              "Isi Data Peminjaman",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text(
              "Masukkan NIK anggota yang sudah disetujui admin.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            infoCard(Icons.agriculture, "Alat Dipilih", widget.namaAlat),
            const SizedBox(height: 12),
            infoCard(
              Icons.calendar_month,
              "Tanggal Pinjam",
              widget.tanggalDipilih,
            ),

            const SizedBox(height: 18),

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

            const SizedBox(height: 16),

            if (dataDitemukan)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: cardStyle(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Data Anggota",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text("Nama: $nama"),
                    Text("NIK: ${nikController.text}"),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            TextField(
              controller: tanggalKembaliController,
              decoration: inputDecoration(
                "Tanggal Kembali",
                Icons.event_available,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: catatanController,
              maxLines: 3,
              decoration: inputDecoration("Catatan / Keperluan", Icons.note),
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
                                  (_) => AlatKonfirmasiPage(
                                    namaAlat: widget.namaAlat,
                                    nama: nama,
                                    nik: nikController.text,
                                    tanggalPinjam: widget.tanggalDipilih,
                                    tanggalKembali:
                                        tanggalKembaliController.text,
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

  Widget stepIndicator() {
    return Row(
      children: [
        stepCircle("1", "Pilih", false),
        stepLine(),
        stepCircle("2", "Jadwal", false),
        stepLine(),
        stepCircle("3", "Data", true),
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

  Widget infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardStyle(),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
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
