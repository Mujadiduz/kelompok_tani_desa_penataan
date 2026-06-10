import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PupukKonfirmasiPage extends StatefulWidget {
  final String namaPupuk;
  final String nama;
  final String nik;
  final String jumlahPetakSawah;
  final String jumlahPupuk;
  final String catatan;
  final String jatahPupuk;
  final String statusJatah;

  const PupukKonfirmasiPage({
    super.key,
    required this.namaPupuk,
    required this.nama,
    required this.nik,
    required this.jumlahPetakSawah,
    required this.jumlahPupuk,
    required this.catatan,
    required this.jatahPupuk,
    required this.statusJatah,
  });

  @override
  State<PupukKonfirmasiPage> createState() => _PupukKonfirmasiPageState();
}

class _PupukKonfirmasiPageState extends State<PupukKonfirmasiPage> {
  bool isLoading = false;

  final DatabaseReference pupukRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("bantuan_pupuk");

  Future<void> kirimPermintaan() async {
    setState(() {
      isLoading = true;
    });

    await pupukRef.push().set({
      "nama": widget.nama,
      "nik": widget.nik,
      "jenis_pupuk": widget.namaPupuk,
      "jumlah_petak_sawah": widget.jumlahPetakSawah,

      "jatah_pupuk": widget.jatahPupuk,
      "jumlah_pupuk": widget.jumlahPupuk,
      "status_jatah": widget.statusJatah,

      "catatan": widget.catatan,
      "status": "menunggu",
      "tanggal_pengajuan": DateTime.now().toString(),
    });

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Permintaan pupuk berhasil dikirim")),
    );

    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Konfirmasi Pupuk"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Konfirmasi Permintaan",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            detailItem("Nama Pemohon", widget.nama),
            detailItem("NIK", widget.nik),
            detailItem("Jenis Pupuk", widget.namaPupuk),
            detailItem("Jumlah Petak Sawah", widget.jumlahPetakSawah),
            detailItem("Jumlah Pupuk", "${widget.jumlahPupuk} Kg"),
            detailItem("Catatan", widget.catatan),

            const Spacer(),

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
                onPressed: isLoading ? null : kirimPermintaan,
                child: Text(
                  isLoading ? "Mengirim..." : "Kirim Permintaan",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailItem(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: cardStyle(),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.grey)),
          ),
          Text(
            value.isEmpty ? "-" : value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
