import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Calon Anggota"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(decoration: input("Nama Lengkap", Icons.person)),
            const SizedBox(height: 12),
            TextField(decoration: input("NIK", Icons.credit_card)),
            const SizedBox(height: 12),
            TextField(decoration: input("No. Telepon", Icons.phone)),
            const SizedBox(height: 12),
            TextField(decoration: input("Alamat", Icons.location_on)),
            const SizedBox(height: 12),
            TextField(decoration: input("Jumlah Petak Sawah", Icons.grass)),
            const SizedBox(height: 12),
            TextField(decoration: input("Email", Icons.email)),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: input("Password", Icons.lock),
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("Daftar"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}