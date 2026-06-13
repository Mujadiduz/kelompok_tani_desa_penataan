import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StatusKeanggotaanPage extends StatefulWidget {
  const StatusKeanggotaanPage({super.key});

  @override
  State<StatusKeanggotaanPage> createState() => _StatusKeanggotaanPageState();
}

class _StatusKeanggotaanPageState extends State<StatusKeanggotaanPage> {
  final nikController = TextEditingController();

  bool isLoading = false;
  Map<String, dynamic>? dataAnggota;

  String runningText = "";
  int textIndex = 0;
  Timer? timer;

  final String fullText = "Masukkan NIK untuk melihat status pendaftaran";

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  );

  @override
  void initState() {
    super.initState();
    mulaiEfekKetik();
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

  Future<void> cekStatus() async {
    final nikInput = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (nikInput.isEmpty) {
      tampilPesan("NIK wajib diisi");
      return;
    }

    if (nikInput.length != 16) {
      tampilPesan(
        "NIK harus 16 digit. Saat ini terbaca ${nikInput.length} digit.",
      );
      return;
    }

    setState(() {
      isLoading = true;
      dataAnggota = null;
    });

    try {
      final calonRef = db.ref("calon_anggota");
      final anggotaRef = db.ref("anggota");

      Map<String, dynamic>? hasil;

      final calonSnapshot = await calonRef.get().timeout(
        const Duration(seconds: 10),
      );

      if (calonSnapshot.exists && calonSnapshot.value != null) {
        final data = Map<String, dynamic>.from(calonSnapshot.value as Map);

        data.forEach((key, value) {
          final anggota = Map<String, dynamic>.from(value as Map);
          final nikData = (anggota["nik"] ?? "").toString().replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );

          if (nikData == nikInput) {
            hasil = anggota;
          }
        });
      }

      if (hasil == null) {
        final anggotaSnapshot = await anggotaRef.get().timeout(
          const Duration(seconds: 10),
        );

        if (anggotaSnapshot.exists && anggotaSnapshot.value != null) {
          final data = Map<String, dynamic>.from(anggotaSnapshot.value as Map);

          data.forEach((key, value) {
            final anggota = Map<String, dynamic>.from(value as Map);
            final nikData = (anggota["nik"] ?? "").toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

            if (nikData == nikInput) {
              hasil = anggota;
            }
          });
        }
      }

      if (!mounted) return;

      if (hasil != null) {
        setState(() {
          dataAnggota = hasil;
        });
      } else {
        tampilPesan("Data anggota tidak ditemukan");
      }
    } catch (e) {
      if (!mounted) return;
      tampilPesan("Gagal cek status: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void tampilPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Color warnaStatus(String status) {
    if (status == "aktif") return Colors.green;
    if (status == "disetujui") return Colors.green;
    if (status == "ditolak") return Colors.red;
    return Colors.orange;
  }

  String teksStatus(String status) {
    if (status == "aktif") return "Disetujui / Aktif";
    if (status == "disetujui") return "Disetujui";
    if (status == "ditolak") return "Ditolak";
    return "Menunggu Verifikasi";
  }

  String ambilLuasSawah() {
    return (dataAnggota?["luas_sawah"] ??
            dataAnggota?["jumlah_petak_sawah"] ??
            "-")
        .toString();
  }

  @override
  void dispose() {
    timer?.cancel();
    nikController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status =
        (dataAnggota?["status"] ?? "menunggu").toString().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xffeef8ef),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Status Keanggotaan"),
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
                children: [
                  inputCard(),
                  const SizedBox(height: 18),
                  if (dataAnggota != null) hasilCard(status),
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
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 26),
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
            child: const Icon(Icons.fact_check, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cek Status",
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

  Widget inputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nomor Induk Kependudukan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Masukkan NIK yang digunakan saat pendaftaran.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nikController,
            keyboardType: TextInputType.number,
            decoration: inputDecoration("Masukkan NIK", Icons.badge),
          ),
          const SizedBox(height: 16),
          SizedBox(
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
              onPressed: isLoading ? null : cekStatus,
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
                      : const Icon(Icons.search, color: Colors.white),
              label: Text(
                isLoading ? "Mengecek..." : "Cek Status",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget hasilCard(String status) {
    final color = warnaStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(Icons.person, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dataAnggota!["nama"] ?? "-",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          infoText("NIK", dataAnggota!["nik"] ?? "-"),
          infoText("Alamat", dataAnggota!["alamat"] ?? "-"),
          infoText("Jenis Kelamin", dataAnggota!["jenis_kelamin"] ?? "-"),
          infoText("Luas Sawah", "${ambilLuasSawah()} Ha"),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              teksStatus(status),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(": "),
          Expanded(
            child: Text(
              value.toString(),
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
      borderRadius: BorderRadius.circular(22),
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
