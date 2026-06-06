import 'package:flutter/material.dart';
import 'pupuk_konfirmasi_page.dart';

class PupukFormPage extends StatelessWidget {
  final String namaPupuk;

  const PupukFormPage({
    super.key,
    required this.namaPupuk,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Form Permintaan"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: "Nama Lengkap",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: "Jumlah Petak Sawah",
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              decoration: const InputDecoration(
                labelText: "Jumlah Pupuk (Kg)",
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PupukKonfirmasiPage(
                        namaPupuk: namaPupuk,
                      ),
                    ),
                  );
                },
                child: const Text("Lanjut"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}