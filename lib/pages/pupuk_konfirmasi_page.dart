import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class PupukKonfirmasiPage extends StatefulWidget {
  final String namaPupuk;
  final String nama;
  final String nik;
  final String jumlahPetakSawah;
  final String jumlahPupuk;
  final String catatan;
  final String jatahPupuk;
  final String statusJatah;

  const PupukKonfirmasiPage({
    super.key,
    required this.namaPupuk,
    required this.nama,
    required this.nik,
    required this.jumlahPetakSawah,
    required this.jumlahPupuk,
    required this.catatan,
    required this.jatahPupuk,
    required this.statusJatah,
  });

  @override
  State<PupukKonfirmasiPage> createState() => _PupukKonfirmasiPageState();
}

class _PupukKonfirmasiPageState extends State<PupukKonfirmasiPage> {
  bool isLoading = false;

  final DatabaseReference pupukRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("bantuan_pupuk");

  Future<void> kirimPermintaan() async {
    setState(() => isLoading = true);

    try {
      await pupukRef
          .push()
          .set({
            "nama": widget.nama,
            "nik": widget.nik,
            "jenis_pupuk": widget.namaPupuk,
            "jumlah_petak_sawah": widget.jumlahPetakSawah,
            "jatah_pupuk": widget.jatahPupuk,
            "jumlah_pupuk": widget.jumlahPupuk,
            "status_jatah": widget.statusJatah,
            "catatan": widget.catatan,
            "status": "menunggu",
            "tanggal_pengajuan": DateTime.now().toString(),
          })
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permintaan pupuk berhasil dikirim")),
      );

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengirim permintaan: $e")));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Color warnaJatah() {
    if (widget.statusJatah == "melebihi_jatah") return Colors.red;
    return Colors.green;
  }

  String teksJatah() {
    if (widget.statusJatah == "melebihi_jatah") return "Melebihi Jatah";
    return "Sesuai Jatah";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef8ef),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Konfirmasi Pupuk"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            stepIndicator(),
            const SizedBox(height: 22),
            headerCard(),
            const SizedBox(height: 18),
            const Text(
              "Detail Permintaan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            detailItem(Icons.person, "Nama Pemohon", widget.nama),
            detailItem(Icons.badge, "NIK", widget.nik),
            detailItem(Icons.grass, "Jenis Pupuk", widget.namaPupuk),
            detailItem(
              Icons.agriculture,
              "Luas / Petak Sawah",
              widget.jumlahPetakSawah,
            ),
            detailItem(
              Icons.inventory_2,
              "Jatah Pupuk",
              "${widget.jatahPupuk} Kg",
            ),
            detailItem(
              Icons.scale,
              "Jumlah Diajukan",
              "${widget.jumlahPupuk} Kg",
            ),
            detailItem(Icons.note, "Catatan", widget.catatan),
            const SizedBox(height: 16),
            noteBox(),
            const SizedBox(height: 24),
            submitButton(),
          ],
        ),
      ),
    );
  }

  Widget headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffeaffea), Color(0xffffffff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.green.withValues(alpha: 0.18)),
        boxShadow: softShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.grass, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            widget.namaPupuk,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              badge("Menunggu", Colors.orange),
              badge(teksJatah(), warnaJatah()),
            ],
          ),
        ],
      ),
    );
  }

  Widget submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isLoading ? null : kirimPermintaan,
        icon:
            isLoading
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.send, color: Colors.white),
        label: Text(
          isLoading ? "Mengirim..." : "Kirim Permintaan",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget noteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.green, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Permintaan akan masuk ke admin untuk diverifikasi. Status pengajuan dapat dilihat pada halaman riwayat.",
              style: TextStyle(color: Colors.black54, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget detailItem(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: cardStyle(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value.trim().isEmpty ? "-" : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget stepIndicator() {
    return Row(
      children: [
        stepCircle("1", "Pilih", false),
        stepLine(),
        stepCircle("2", "Data", false),
        stepLine(),
        stepCircle("3", "Konfirmasi", true),
      ],
    );
  }

  Widget stepCircle(String number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 17,
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
      boxShadow: softShadow(),
    );
  }

  List<BoxShadow> softShadow() {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ];
  }
}
