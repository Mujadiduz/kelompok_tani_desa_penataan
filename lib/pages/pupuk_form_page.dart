import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'pupuk_konfirmasi_page.dart';

class PupukFormPage extends StatefulWidget {
  final String namaPupuk;
  final String namaUser;
  final String nikUser;

  const PupukFormPage({
    super.key,
    required this.namaPupuk,
    required this.namaUser,
    required this.nikUser,
  });

  @override
  State<PupukFormPage> createState() => _PupukFormPageState();
}

class _PupukFormPageState extends State<PupukFormPage> {
  final jumlahPupukController = TextEditingController();
  final catatanController = TextEditingController();

  String nama = "";
  String luasSawah = "";
  double jatahPupuk = 0;

  bool isLoading = true;
  bool dataDitemukan = false;

  String runningText = "";
  int textIndex = 0;
  Timer? timer;

  final String fullText = "Lengkapi jumlah pupuk yang ingin diajukan";

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  ).ref("anggota");

  @override
  void initState() {
    super.initState();
    mulaiEfekKetik();
    ambilDataAnggotaLogin();
  }

  void mulaiEfekKetik() {
    timer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (textIndex < fullText.length) {
        setState(() {
          runningText += fullText[textIndex];
          textIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> ambilDataAnggotaLogin() async {
    setState(() {
      isLoading = true;
      dataDitemukan = false;
    });

    try {
      final snapshot = await anggotaRef.get().timeout(
        const Duration(seconds: 10),
      );

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        Map<String, dynamic>? anggotaDitemukan;

        data.forEach((key, value) {
          final anggota = Map<String, dynamic>.from(value as Map);
          final nikData = (anggota["nik"] ?? "").toString().replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          final nikLogin = widget.nikUser.replaceAll(RegExp(r'[^0-9]'), '');

          if (nikData == nikLogin) {
            anggotaDitemukan = anggota;
          }
        });

        if (!mounted) return;

        if (anggotaDitemukan != null) {
          final luasText = (anggotaDitemukan!["luas_sawah"] ??
                  anggotaDitemukan!["jumlah_petak_sawah"] ??
                  "0")
              .toString()
              .replaceAll(",", ".");

          final luas = double.tryParse(luasText) ?? 0;

          setState(() {
            nama = anggotaDitemukan!["nama"] ?? widget.namaUser;
            luasSawah = luasText;
            jatahPupuk = luas * 2;
            dataDitemukan = true;
          });
        } else {
          setState(() {
            nama = widget.namaUser;
          });

          tampilPesan("Data anggota login tidak ditemukan");
        }
      }
    } catch (e) {
      if (!mounted) return;
      tampilPesan("Gagal mengambil data anggota: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool melebihiJatah() {
    final jumlahDiajukan =
        double.tryParse(
          jumlahPupukController.text.trim().replaceAll(",", "."),
        ) ??
        0;

    return jumlahDiajukan > jatahPupuk;
  }

  void lanjutKonfirmasi() {
    if (!dataDitemukan) {
      tampilPesan("Data anggota belum ditemukan");
      return;
    }

    if (jumlahPupukController.text.trim().isEmpty) {
      tampilPesan("Jumlah pupuk wajib diisi");
      return;
    }

    final jumlah = double.tryParse(
      jumlahPupukController.text.trim().replaceAll(",", "."),
    );

    if (jumlah == null || jumlah <= 0) {
      tampilPesan("Jumlah pupuk tidak valid");
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PupukKonfirmasiPage(
              namaPupuk: widget.namaPupuk,
              nama: nama,
              nik: widget.nikUser.trim(),
              jumlahPetakSawah: luasSawah,
              jumlahPupuk: jumlahPupukController.text.trim(),
              jatahPupuk: jatahPupuk.toStringAsFixed(1),
              statusJatah: melebihiJatah() ? "melebihi_jatah" : "sesuai_jatah",
              catatan: catatanController.text.trim(),
            ),
      ),
    );
  }

  void tampilPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  @override
  void dispose() {
    timer?.cancel();
    jumlahPupukController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overLimit = dataDitemukan && melebihiJatah();

    return Scaffold(
      backgroundColor: const Color(0xffeef8ef),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Isi Data Pupuk"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            header(),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stepIndicator(),
                  const SizedBox(height: 18),
                  pupukCard(),
                  const SizedBox(height: 14),
                  if (isLoading)
                    loadingCard()
                  else if (dataDitemukan)
                    anggotaCard(),
                  const SizedBox(height: 14),
                  inputJumlah(overLimit),
                  const SizedBox(height: 12),
                  inputCatatan(),
                  const SizedBox(height: 22),
                  tombolLanjut(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.grass, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pengajuan Pupuk",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  runningText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pupukCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardStyle(),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.withValues(alpha: 0.13),
            child: const Icon(Icons.eco, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.namaPupuk,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: cardStyle(),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget anggotaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Data Anggota",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 10),
          infoText("Nama", nama),
          infoText("NIK", widget.nikUser.trim()),
          infoText("Luas Sawah", "$luasSawah Ha"),
          infoText("Jatah Pupuk", "${jatahPupuk.toStringAsFixed(1)} Kg"),
          const SizedBox(height: 8),
          const Text(
            "Ketentuan: 1 Ha sawah mendapat jatah 2 Kg pupuk subsidi.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget inputJumlah(bool overLimit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: jumlahPupukController,
          keyboardType: TextInputType.number,
          decoration: inputDecoration(
            "Jumlah Pupuk Diajukan (Kg)",
            Icons.scale,
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (overLimit) ...[
          const SizedBox(height: 8),
          const Text(
            "Jumlah pupuk melebihi jatah subsidi",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  Widget inputCatatan() {
    return TextField(
      controller: catatanController,
      maxLines: 3,
      decoration: inputDecoration("Catatan", Icons.note),
    );
  }

  Widget tombolLanjut() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: !dataDitemukan ? null : lanjutKonfirmasi,
        child: const Text(
          "Lanjut",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget stepIndicator() {
    return Row(
      children: [
        stepCircle("1", "Pilih", false),
        stepLine(),
        stepCircle("2", "Data", true),
        stepLine(),
        stepCircle("3", "Konfirmasi", false),
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

  Widget infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(": "),
          Expanded(
            child: Text(
              value.isEmpty ? "-" : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      filled: true,
      fillColor: const Color(0xfff8fff8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.green.withValues(alpha: 0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.green, width: 1.4),
      ),
    );
  }

  BoxDecoration cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
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
