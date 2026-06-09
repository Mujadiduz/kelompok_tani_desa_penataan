import 'package:flutter/material.dart';

class AlatKonfirmasiPage extends StatelessWidget {
  final String namaAlat;

  const AlatKonfirmasiPage({super.key, required this.namaAlat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Konfirmasi Peminjaman"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
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
                    namaAlat,
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

            detailItem("Nama Peminjam", "Petani Desa Penataan"),
            detailItem("Tanggal Pinjam", "Tanggal terpilih"),
            detailItem("Tanggal Kembali", "Diisi oleh pengguna"),
            detailItem("Catatan", "Keperluan pengolahan lahan"),

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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengajuan peminjaman berhasil dikirim"),
                    ),
                  );
                },
                child: const Text(
                  "Ajukan Peminjaman",
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
