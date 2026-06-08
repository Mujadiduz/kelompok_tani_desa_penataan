import 'package:flutter/material.dart';
import 'verifikasi_anggota_page.dart';
import 'verifikasi_pupuk_page.dart';
import 'verifikasi_peminjaman_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f9f6),
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            adminCard(
              context,
              "Verifikasi Anggota",
              "Setujui calon anggota baru",
              Icons.people,
              const VerifikasiAnggotaPage(),
            ),
            adminCard(
              context,
              "Verifikasi Pupuk",
              "Cek permintaan bantuan pupuk",
              Icons.grass,
              const VerifikasiPupukPage(),
            ),
            adminCard(
              context,
              "Verifikasi Peminjaman",
              "Cek pengajuan alat pertanian",
              Icons.agriculture,
              const VerifikasiPeminjamanPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget adminCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget page,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}