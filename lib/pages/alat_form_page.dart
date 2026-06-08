import 'package:flutter/material.dart';
import 'alat_konfirmasi_page.dart';

class AlatFormPage extends StatelessWidget {
  final String namaAlat;
  final String tanggalDipilih;

  const AlatFormPage({
    super.key,
    required this.namaAlat,
    required this.tanggalDipilih,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Form Peminjaman"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stepIndicator(),
            const SizedBox(height: 25),

            const Text(
              "Isi Data Peminjaman",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Lengkapi data peminjaman alat.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            infoCard(Icons.agriculture, "Alat Dipilih", namaAlat),
            const SizedBox(height: 12),
            infoCard(Icons.calendar_month, "Tanggal Pinjam", tanggalDipilih),

            const SizedBox(height: 18),

            inputField("Nama Peminjam", Icons.person),
            const SizedBox(height: 12),

            inputField("Tanggal Kembali", Icons.event_available),
            const SizedBox(height: 12),

            TextField(
              maxLines: 3,
              decoration: inputDecoration("Catatan / Keperluan", Icons.note),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AlatKonfirmasiPage(namaAlat: namaAlat),
                    ),
                  );
                },
                child: const Text(
                  "Lanjut",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget stepIndicator() {
    return Row(
      children: [
        stepCircle("1", "Pilih", false),
        stepLine(),
        stepCircle("2", "Jadwal", false),
        stepLine(),
        stepCircle("3", "Data", true),
        stepLine(),
        stepCircle("4", "Konfirmasi", false),
      ],
    );
  }

  Widget stepCircle(String number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? Colors.green : Colors.grey.shade300,
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? Colors.green : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget stepLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget infoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardStyle(),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget inputField(String label, IconData icon) {
    return TextField(decoration: inputDecoration(label, icon));
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
