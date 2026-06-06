import 'package:flutter/material.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          riwayatCard(
            "Bantuan Pupuk Urea",
            "50 Kg",
            "Disetujui",
            Colors.green,
          ),

          riwayatCard(
            "Peminjaman Traktor",
            "24/05/2026",
            "Menunggu",
            Colors.orange,
          ),

          riwayatCard(
            "Pupuk NPK Phonska",
            "100 Kg",
            "Disetujui",
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget riwayatCard(
      String judul,
      String detail,
      String status,
      Color warna,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(judul),
        subtitle: Text(detail),
        trailing: Chip(
          label: Text(
            status,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: warna,
        ),
      ),
    );
  }
}