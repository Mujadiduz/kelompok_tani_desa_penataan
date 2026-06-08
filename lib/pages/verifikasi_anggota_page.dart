import 'package:flutter/material.dart';

class VerifikasiAnggotaPage extends StatelessWidget {
  const VerifikasiAnggotaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Anggota"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          anggotaCard(
            "Ahmad Fauzi",
            "2 Petak Sawah",
          ),

          anggotaCard(
            "Budi Santoso",
            "3 Petak Sawah",
          ),

          anggotaCard(
            "Joko Susilo",
            "1 Petak Sawah",
          ),
        ],
      ),
    );
  }

  Widget anggotaCard(
      String nama,
      String sawah,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(sawah),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Setujui",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {},
                    child: const Text(
                      "Tolak",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
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