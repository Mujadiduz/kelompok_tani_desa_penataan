import 'package:flutter/material.dart';
import 'alat_page.dart';
import 'profil_page.dart';
import 'pupuk_page.dart';
import 'riwayat_page.dart';

class UserHomePage extends StatelessWidget {
  final String nama;
  final String nik;

  const UserHomePage({super.key, required this.nama, required this.nik});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 55, 20, 28),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat Datang,",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Sistem Informasi Kelompok Tani",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  statusCard(),

                  const SizedBox(height: 22),

                  const Text(
                    "Menu Utama",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PupukPage()),
                      );
                    },
                    child: menuCard(
                      Icons.grass,
                      "Bantuan Pupuk",
                      "Ajukan bantuan pupuk subsidi",
                      Colors.green,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlatPage()),
                      );
                    },
                    child: menuCard(
                      Icons.agriculture,
                      "Peminjaman Alat",
                      "Ajukan peminjaman alat pertanian desa",
                      Colors.orange,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiwayatPage(nik: nik),
                        ),
                      );
                    },
                    child: menuCard(
                      Icons.history,
                      "Riwayat",
                      "Lihat riwayat bantuan dan peminjaman",
                      Colors.blue,
                    ),
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
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RiwayatPage(nik: nik)),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilPage(nama: nama, nik: nik),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget statusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardStyle(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xffdff3df),
            child: Icon(Icons.verified, color: Colors.green, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Status Keanggotaan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "Aktif sebagai anggota kelompok tani\nNIK: $nik",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget menuCard(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardStyle(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  BoxDecoration cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
