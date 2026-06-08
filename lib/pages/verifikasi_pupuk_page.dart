import 'package:flutter/material.dart';

class VerifikasiPupukPage extends StatelessWidget {
  const VerifikasiPupukPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Pupuk"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          pupukCard("Ahmad Fauzi", "Pupuk Urea", "50 Kg"),
          pupukCard("Budi Santoso", "NPK Phonska", "100 Kg"),
          pupukCard("Joko Susilo", "Pupuk Urea", "25 Kg"),
        ],
      ),
    );
  }

  Widget pupukCard(String nama, String jenisPupuk, String jumlah) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Jenis Pupuk: $jenisPupuk"),
            Text("Jumlah: $jumlah"),
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