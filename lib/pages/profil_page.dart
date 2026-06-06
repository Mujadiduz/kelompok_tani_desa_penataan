import 'package:flutter/material.dart';

class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f9f6),
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xffd8ead8),
              child: Icon(Icons.person, size: 55, color: Colors.green),
            ),
            const SizedBox(height: 12),
            const Text(
              "Budi Santoso",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Chip(label: Text("Anggota")),
            const SizedBox(height: 25),

            menuItem(Icons.person_outline, "Data Diri"),
            menuItem(Icons.lock_outline, "Ubah Password"),
            menuItem(Icons.info_outline, "Tentang Aplikasi"),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Keluar"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}