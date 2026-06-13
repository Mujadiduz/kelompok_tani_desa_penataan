import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AlatKonfirmasiPage extends StatefulWidget {
  final String namaAlat;
  final String nama;
  final String nik;
  final String tanggalPinjam;
  final String tanggalKembali;
  final String catatan;

  const AlatKonfirmasiPage({
    super.key,
    required this.namaAlat,
    required this.nama,
    required this.nik,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.catatan,
  });

  @override
  State<AlatKonfirmasiPage> createState() => _AlatKonfirmasiPageState();
}

class _AlatKonfirmasiPageState extends State<AlatKonfirmasiPage> {
  bool isLoading = false;

  final DatabaseReference peminjamanRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("peminjaman_alat");

  Future<void> ajukanPeminjaman() async {
    setState(() => isLoading = true);

    try {
      await peminjamanRef
          .push()
          .set({
            "nama": widget.nama,
            "nik": widget.nik,
            "alat": widget.namaAlat,
            "tanggal_pinjam": widget.tanggalPinjam,
            "tanggal_kembali": widget.tanggalKembali,
            "catatan": widget.catatan,
            "status": "menunggu",
            "tanggal_pengajuan": DateTime.now().toString(),
          })
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pengajuan peminjaman berhasil dikirim")),
      );

      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal mengirim peminjaman: $e")));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4fbf4),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Konfirmasi Peminjaman"),
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
              "Detail Pengajuan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            detailItem(Icons.person, "Nama Peminjam", widget.nama),
            detailItem(Icons.badge, "NIK", widget.nik),
            detailItem(
              Icons.calendar_month,
              "Tanggal Pinjam",
              widget.tanggalPinjam,
            ),
            detailItem(
              Icons.event_available,
              "Tanggal Kembali",
              widget.tanggalKembali,
            ),
            detailItem(Icons.note, "Catatan", widget.catatan),
            const SizedBox(height: 18),
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
          colors: [Color(0xfffff4df), Color(0xffffffff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffffd89b)),
        boxShadow: softShadow(),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.agriculture,
              color: Colors.orange,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.namaAlat,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Menunggu Persetujuan Admin",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
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
        onPressed: isLoading ? null : ajukanPeminjaman,
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
          isLoading ? "Mengirim..." : "Ajukan Peminjaman",
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
              "Setelah diajukan, admin akan memeriksa jadwal dan ketersediaan alat. Status dapat dilihat pada halaman riwayat.",
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

  Widget stepIndicator() {
    return Row(
      children: [
        stepCircle("1", "Pilih", false),
        stepLine(),
        stepCircle("2", "Jadwal", false),
        stepLine(),
        stepCircle("3", "Data", false),
        stepLine(),
        stepCircle("4", "Konfirmasi", true),
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
