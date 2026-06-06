import 'package:flutter/material.dart';

class PupukKonfirmasiPage extends StatelessWidget {
  final String namaPupuk;

  const PupukKonfirmasiPage({
    super.key,
    required this.namaPupuk,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konfirmasi"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Ringkasan Permintaan",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.grass,
                  color: Colors.green,
                ),
                title: Text(namaPupuk),
                subtitle: const Text(
                  "Menunggu Persetujuan Admin",
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Permintaan pupuk akan dikirim ke admin kelompok tani untuk diverifikasi terlebih dahulu.",
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Permintaan berhasil dikirim",
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Kirim Permintaan",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}