import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AlatKonfirmasiPage extends StatefulWidget {
  final String namaAlat;
  final String nama;
  final String nik;
  final String tanggalPinjam;
  final String tanggalKembali;
  final String catatan;

  const AlatKonfirmasiPage({
    super.key,
    required this.namaAlat,
    required this.nama,
    required this.nik,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.catatan,
  });

  @override
  State<AlatKonfirmasiPage> createState() => _AlatKonfirmasiPageState();
}

class _AlatKonfirmasiPageState extends State<AlatKonfirmasiPage> {
  bool isLoading = false;

  final DatabaseReference peminjamanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("peminjaman_alat");

  Future<void> ajukanPeminjaman() async {
    setState(() {
      isLoading = true;
    });

    try {
      await peminjamanRef.push().set({
        "nama": widget.nama,
        "nik": widget.nik,
        "alat": widget.namaAlat,
        "tanggal_pinjam": widget.tanggalPinjam,
        "tanggal_kembali": widget.tanggalKembali,
        "catatan": widget.catatan,
        "status": "menunggu",
        "tanggal_pengajuan": DateTime.now().toString(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengajuan peminjaman berhasil dikirim")),
      );

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengirim peminjaman: $e")));
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
        title: const Text("Konfirmasi Peminjaman"),
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
              "Ringkasan Peminjaman",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text(
              "Periksa kembali data sebelum diajukan.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: cardStyle(),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xffffefd6),
                    child: Icon(
                      Icons.agriculture,
                      color: Colors.orange,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.namaAlat,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Status: Menunggu Persetujuan Admin",
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            detailItem("Nama Peminjam", widget.nama),
            detailItem("NIK", widget.nik),
            detailItem("Tanggal Pinjam", widget.tanggalPinjam),
            detailItem("Tanggal Kembali", widget.tanggalKembali),
            detailItem("Catatan", widget.catatan),

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
                onPressed: isLoading ? null : ajukanPeminjaman,
                child: Text(
                  isLoading ? "Mengirim..." : "Ajukan Peminjaman",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
        stepCircle("3", "Data", false),
        stepLine(),
        stepCircle("4", "Konfirmasi", true),
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
