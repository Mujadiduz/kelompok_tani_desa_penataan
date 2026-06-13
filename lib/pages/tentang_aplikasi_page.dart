import 'package:flutter/material.dart';

class TentangAplikasiPage extends StatelessWidget {
  const TentangAplikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Tentang Aplikasi"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xffdff3df),
              child: Icon(Icons.eco, size: 60, color: Colors.green),
            ),

            const SizedBox(height: 20),

            const Text(
              "Sistem Informasi Kelompok Tani Desa Penataan",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text("Versi 1.0", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 25),

            cardInfo(
              "Tujuan Aplikasi",
              "Membantu proses administrasi kelompok tani Desa Penataan seperti pendaftaran anggota, bantuan pupuk, peminjaman alat pertanian, dan pengelolaan data anggota.",
            ),

            cardInfo(
              "Fitur Utama",
              "• Pendaftaran Anggota\n"
                  "• Verifikasi Anggota\n"
                  "• Pengajuan Bantuan Pupuk\n"
                  "• Verifikasi Bantuan Pupuk\n"
                  "• Peminjaman Alat Pertanian\n"
                  "• Verifikasi Peminjaman Alat\n"
                  "• Riwayat Pengajuan\n"
                  "• Pengelolaan Data Alat",
            ),

            cardInfo(
              "Teknologi",
              "Flutter sebagai framework aplikasi mobile dan Firebase Realtime Database sebagai media penyimpanan data.",
            ),

            cardInfo(
              "Pengembang",
              "Mujaddiduz Zaman\nProgram Studi Teknik Informatika\nUniversitas Yudharta Pasuruan",
            ),
          ],
        ),
      ),
    );
  }

  Widget cardInfo(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}
