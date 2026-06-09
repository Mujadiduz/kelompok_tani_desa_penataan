import 'package:flutter/material.dart';

class VerifikasiPeminjamanPage extends StatelessWidget {
  const VerifikasiPeminjamanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text("Verifikasi Peminjaman Alat"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Pengajuan",
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(child: Center(child: Text("Riwayat"))),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            itemPeminjaman(
              "Budi Santoso",
              "Traktor",
              "14/05/2026 - 17/05/2026",
              Icons.agriculture,
            ),

            itemPeminjaman(
              "Ahmad Fauzi",
              "Hand Sprayer",
              "10/05/2026 - 12/05/2026",
              Icons.water_drop,
            ),

            itemPeminjaman(
              "Siti Nurhaliza",
              "Cangkul Mesin",
              "05/05/2026 - 07/05/2026",
              Icons.build,
            ),
          ],
        ),
      ),
    );
  }

  Widget itemPeminjaman(
    String nama,
    String alat,
    String tanggal,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withValues(alpha: 0.15),
            child: Icon(icon, color: Colors.orange),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(alat),
                Text(
                  tanggal,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Setujui", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Tolak", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
