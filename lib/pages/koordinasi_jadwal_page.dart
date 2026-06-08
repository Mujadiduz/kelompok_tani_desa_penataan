import 'package:flutter/material.dart';
import 'alat_form_page.dart';

class KoordinasiJadwalPage extends StatefulWidget {
  final String namaAlat;

  const KoordinasiJadwalPage({super.key, required this.namaAlat});

  @override
  State<KoordinasiJadwalPage> createState() => _KoordinasiJadwalPageState();
}

class _KoordinasiJadwalPageState extends State<KoordinasiJadwalPage> {
  int? tanggalDipilih;

  final List<int> tanggalDipinjam = [5, 6, 14, 15, 21];
  final List<int> tanggalMenunggu = [10, 18, 24];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        title: const Text("Koordinasi Jadwal"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stepIndicator(),
            const SizedBox(height: 22),
            const Text(
              "Koordinasi Jadwal",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Pilih tanggal tersedia untuk meminjam ${widget.namaAlat}.",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            alatCard(),
            const SizedBox(height: 18),
            Row(
              children: [
                statusColor(Colors.green, "Tersedia"),
                const SizedBox(width: 12),
                statusColor(Colors.red, "Dipinjam"),
                const SizedBox(width: 12),
                statusColor(Colors.orange, "Menunggu"),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: cardStyle(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Juni 2026",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Sen"),
                        Text("Sel"),
                        Text("Rab"),
                        Text("Kam"),
                        Text("Jum"),
                        Text("Sab"),
                        Text("Min"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        itemCount: 35,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemBuilder: (context, index) {
                          final tanggal = index + 1;
                          return tanggalBox(tanggal);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (tanggalDipilih != null)
              Center(
                child: Text(
                  "Tanggal dipilih: $tanggalDipilih Juni 2026",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 12),
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
                    tanggalDipilih == null
                        ? null
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => AlatFormPage(
                                    namaAlat: widget.namaAlat,
                                    tanggalDipilih: "$tanggalDipilih Juni 2026",
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

  Widget tanggalBox(int tanggal) {
    Color warna = Colors.green;
    bool bisaDipilih = true;

    if (tanggalDipinjam.contains(tanggal)) {
      warna = Colors.red;
      bisaDipilih = false;
    } else if (tanggalMenunggu.contains(tanggal)) {
      warna = Colors.orange;
      bisaDipilih = false;
    }

    final bool selected = tanggalDipilih == tanggal;

    return GestureDetector(
      onTap:
          bisaDipilih
              ? () {
                setState(() {
                  tanggalDipilih = tanggal;
                });
              }
              : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.blue : warna.withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          border:
              selected
                  ? Border.all(color: Colors.black, width: 2)
                  : Border.all(color: Colors.transparent),
        ),
        child: Text(
          "$tanggal",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget alatCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardStyle(),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.orange,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.namaAlat,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget statusColor(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget stepIndicator() {
    return Row(
      children: [
        stepCircle("1", "Pilih", false),
        stepLine(),
        stepCircle("2", "Jadwal", true),
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
