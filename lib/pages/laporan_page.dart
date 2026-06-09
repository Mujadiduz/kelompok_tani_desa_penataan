import 'package:flutter/material.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f2ff),
      appBar: AppBar(
        title: const Text("Laporan"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          laporanCard("Laporan Bantuan Pupuk", Icons.grass, Colors.green, [
            dataItem("Total Pengajuan", "35"),
            dataItem("Disetujui", "28"),
            dataItem("Ditolak", "7"),
          ]),
          const SizedBox(height: 18),
          laporanCard(
            "Laporan Peminjaman Alat",
            Icons.agriculture,
            Colors.orange,
            [
              dataItem("Total Peminjaman", "18"),
              dataItem("Sedang Dipinjam", "4"),
              dataItem("Selesai", "14"),
            ],
          ),
          const SizedBox(height: 18),
          laporanCard("Rekap Anggota", Icons.people, Colors.purple, [
            dataItem("Total Anggota", "128"),
            dataItem("Calon Anggota", "24"),
            dataItem("Anggota Aktif", "104"),
          ]),
        ],
      ),
    );
  }

  Widget laporanCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget dataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  BoxDecoration whiteCard() {
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
