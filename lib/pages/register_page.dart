import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Daftar Calon Anggota"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Isi data diri dengan benar",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            inputField("Nama Lengkap", Icons.person),

            const SizedBox(height: 12),

            inputField("NIK", Icons.badge),

            const SizedBox(height: 12),

            inputField("No Telepon", Icons.phone),

            const SizedBox(height: 12),

            inputField("Alamat", Icons.location_on),

            const SizedBox(height: 12),

            inputField("Jenis Kelamin", Icons.people),

            const SizedBox(height: 12),

            inputField("Pekerjaan", Icons.work),

            const SizedBox(height: 12),

            inputField("Jumlah Petak Sawah", Icons.agriculture),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pendaftaran berhasil dikirim"),
                    ),
                  );
                },
                child: const Text(
                  "Daftar",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Sudah punya akun? "),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Masuk di sini"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField(String label, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
