import 'package:flutter/material.dart';
import 'verifikasi_anggota_page.dart';
import 'verifikasi_peminjaman_page.dart';
import 'verifikasi_pupuk_page.dart';
import 'jadwal_alat_admin_page.dart';
import 'laporan_page.dart';
import 'profil_admin_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f2ff),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 35),
            headerAdmin(),
            const SizedBox(height: 20),

            const Text(
              "Ringkasan Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: summaryCard(
                    "128",
                    "Anggota",
                    Icons.people,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: summaryCard(
                    "24",
                    "Pengajuan",
                    Icons.person_add,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: summaryCard(
                    "18",
                    "Bantuan",
                    Icons.grass,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: summaryCard(
                    "12",
                    "Alat",
                    Icons.agriculture,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Menu Admin",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
              children: [
                menuBox(
                  context,
                  "Anggota",
                  Icons.person,
                  const VerifikasiAnggotaPage(),
                ),
                menuBox(
                  context,
                  "Bantuan\nPupuk",
                  Icons.grass,
                  const VerifikasiPupukPage(),
                ),
                menuBox(
                  context,
                  "Peminjaman\nAlat",
                  Icons.agriculture,
                  const VerifikasiPeminjamanPage(),
                ),
                menuBox(
                  context,
                  "Jadwal\nAlat",
                  Icons.calendar_month,
                  const JadwalAlatAdminPage(),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LaporanPage()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilAdminPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: "Laporan",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget headerAdmin() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff6a35d6), Color(0xff8b5cf6)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.purple, size: 40),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Datang,",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "Admin Desa",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("Administrator", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Icon(Icons.notifications, color: Colors.white),
        ],
      ),
    );
  }

  Widget summaryCard(String total, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: whiteCard(),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            total,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget menuBox(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        decoration: whiteCard(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.purple, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration whiteCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
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
