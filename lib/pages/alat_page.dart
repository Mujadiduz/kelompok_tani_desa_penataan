import 'package:flutter/material.dart';
import 'koordinasi_jadwal_page.dart';

class AlatPage extends StatefulWidget {
  const AlatPage({super.key});

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  String? alatDipilih;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Peminjaman Alat"),
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
              "Pilih Alat Pertanian",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Pilih alat desa yang ingin dipinjam.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 22),

            pilihanAlat(
              nama: "Traktor",
              stok: "Stok tersedia 2 Unit",
              icon: Icons.agriculture,
              color: Colors.orange,
            ),

            pilihanAlat(
              nama: "Hand Sprayer",
              stok: "Stok tersedia 5 Unit",
              icon: Icons.water_drop,
              color: Colors.blue,
            ),

            pilihanAlat(
              nama: "Cangkul Mesin",
              stok: "Stok tersedia 3 Unit",
              icon: Icons.build,
              color: Colors.amber,
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
                onPressed:
                    alatDipilih == null
                        ? null
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => KoordinasiJadwalPage(
                                    namaAlat: alatDipilih!,
                                  ),
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
        stepCircle("1", "Pilih", true),
        stepLine(),
        stepCircle("2", "Jadwal", false),
        stepLine(),
        stepCircle("3", "Data", false),
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

  Widget pilihanAlat({
    required String nama,
    required String stok,
    required IconData icon,
    required Color color,
  }) {
    final bool selected = alatDipilih == nama;

    return GestureDetector(
      onTap: () {
        setState(() {
          alatDipilih = nama;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.green : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(stok, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
