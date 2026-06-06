import 'package:flutter/material.dart';
import 'profil_page.dart';
import 'riwayat_page.dart';
import 'pupuk_page.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f9f6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 55, 20, 25),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Selamat Datang,",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    "Budi Santoso",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Chip(label: Text("Anggota")),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  cardStatus(),
                  const SizedBox(height: 16),
                GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PupukPage(),
      ),
    );
  },
  child: menuCard(
    icon: Icons.grass,
    title: "Bantuan Pupuk",
    subtitle: "Ajukan & pesan bantuan pupuk",
  ),
),
                  menuCard(
                    icon: Icons.agriculture,
                    title: "Peminjaman Alat",
                    subtitle: "Ajukan peminjaman alat desa",
                  ),
                  menuCard(
                    icon: Icons.history,
                    title: "Riwayat",
                    subtitle: "Riwayat bantuan & peminjaman",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
  currentIndex: 0,
  selectedItemColor: Colors.green,
  onTap: (index) {
    if(index == 1){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiwayatPage(),
      ),
    );
  }

  if(index == 2){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfilPage(),
      ),
    );
  }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfilPage(),
        ),
      );
    }
  },
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Beranda",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: "Riwayat",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: "Profil",
    ),
  ],
),
    );
  }

  Widget cardStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 35),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status Pendaftaran",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Akun Anda telah disetujui"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.green, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
  
}