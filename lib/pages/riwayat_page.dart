import 'package:flutter/material.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Riwayat Aktivitas"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Riwayat Bantuan Pupuk",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          riwayatCard(
            icon: Icons.grass,
            title: "Pupuk Urea",
            subtitle: "Jumlah: 50 Kg",
            status: "Menunggu",
            color: Colors.orange,
          ),

          riwayatCard(
            icon: Icons.eco,
            title: "NPK Phonska",
            subtitle: "Jumlah: 100 Kg",
            status: "Disetujui",
            color: Colors.green,
          ),

          const SizedBox(height: 24),

          const Text(
            "Riwayat Peminjaman Alat",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          riwayatCard(
            icon: Icons.agriculture,
            title: "Traktor",
            subtitle: "Tanggal: 17 Juni 2026",
            status: "Menunggu",
            color: Colors.orange,
          ),

          riwayatCard(
            icon: Icons.water_drop,
            title: "Hand Sprayer",
            subtitle: "Tanggal: 10 Juni 2026",
            status: "Disetujui",
            color: Colors.green,
          ),

          riwayatCard(
            icon: Icons.build,
            title: "Cangkul Mesin",
            subtitle: "Tanggal: 5 Juni 2026",
            status: "Ditolak",
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget riwayatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}