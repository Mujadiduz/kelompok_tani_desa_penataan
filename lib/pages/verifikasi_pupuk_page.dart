import 'package:flutter/material.dart';

class VerifikasiPupukPage extends StatelessWidget {
  const VerifikasiPupukPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text("Verifikasi Bantuan Pupuk"),
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

            itemPupuk("Budi Santoso", "Urea - 50 Kg", "24/05/2026"),

            itemPupuk("Siti Nurhaliza", "NPK Phonska - 100 Kg", "23/05/2026"),

            itemPupuk("Ahmad Fauzi", "Pupuk Organik - 30 Kg", "22/05/2026"),
          ],
        ),
      ),
    );
  }

  Widget itemPupuk(String nama, String pupuk, String tanggal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xffede9fe),
            child: Icon(Icons.person, color: Colors.deepPurple),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(pupuk),
                Text(tanggal, style: const TextStyle(color: Colors.grey)),
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
