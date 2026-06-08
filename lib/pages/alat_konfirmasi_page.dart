import 'package:flutter/material.dart';

class AlatKonfirmasiPage extends StatelessWidget {
  final String namaAlat;

  const AlatKonfirmasiPage({super.key, required this.namaAlat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Konfirmasi Peminjaman"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ringkasan Peminjaman",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.agriculture, color: Colors.orange),
                title: Text(namaAlat),
                subtitle: const Text("Status: Menunggu persetujuan admin"),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Pengajuan peminjaman alat akan dikirim ke admin untuk dicek jadwal dan ketersediaannya.",
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengajuan peminjaman berhasil dikirim"),
                    ),
                  );
                },
                child: const Text(
                  "Ajukan Peminjaman",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}