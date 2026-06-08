import 'package:flutter/material.dart';

class VerifikasiPeminjamanPage extends StatelessWidget {
  const VerifikasiPeminjamanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Peminjaman"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          peminjamanCard("Ahmad Fauzi", "Traktor", "17 Juni - 18 Juni"),
          peminjamanCard("Budi Santoso", "Hand Sprayer", "19 Juni - 20 Juni"),
          peminjamanCard("Joko Susilo", "Cangkul Mesin", "21 Juni - 22 Juni"),
        ],
      ),
    );
  }

  Widget peminjamanCard(String nama, String alat, String tanggal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Alat: $alat"),
            Text("Tanggal: $tanggal"),
            const Text("Status: Menunggu"),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {},
                    child: const Text("Setujui", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {},
                    child: const Text("Tolak", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}