import 'package:flutter/material.dart';
import 'login_page.dart';

class ProfilAdminPage extends StatelessWidget {
  const ProfilAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f2ff),
      appBar: AppBar(
        title: const Text("Profil Admin"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xffede9fe),
              child: Icon(Icons.person, size: 55, color: Colors.deepPurple),
            ),
            const SizedBox(height: 14),
            const Text(
              "Admin Desa",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text("Perangkat Desa Penataan"),

            const SizedBox(height: 28),

            menuItem(Icons.email, "Email", "admin@gmail.com"),
            menuItem(Icons.badge, "Jabatan", "Administrator"),
            menuItem(Icons.phone, "No HP", "08xxxxxxxxxx"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget menuItem(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: whiteCard(),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.grey)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BoxDecoration whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
