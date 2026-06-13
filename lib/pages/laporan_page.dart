import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String runningText = "";
  int textIndex = 0;
  Timer? timer;

  final String fullText =
      "Ringkasan data anggota, bantuan pupuk, dan peminjaman alat";

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        "https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app",
  );

  late final DatabaseReference anggotaRef;
  late final DatabaseReference calonAnggotaRef;
  late final DatabaseReference pupukRef;
  late final DatabaseReference peminjamanRef;

  @override
  void initState() {
    super.initState();
    anggotaRef = db.ref("anggota");
    calonAnggotaRef = db.ref("calon_anggota");
    pupukRef = db.ref("bantuan_pupuk");
    peminjamanRef = db.ref("peminjaman_alat");
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

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  int hitungTotal(dynamic value) {
    if (value == null || value is! Map) return 0;
    return value.length;
  }

  int hitungStatus(dynamic value, String statusTarget) {
    if (value == null || value is! Map) return 0;

    int total = 0;
    final data = Map<String, dynamic>.from(value);

    data.forEach((key, value) {
      final item = Map<String, dynamic>.from(value as Map);
      final status = (item["status"] ?? "").toString().toLowerCase();

      if (status == statusTarget) total++;
    });

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f2ff),
      appBar: AppBar(
        elevation: 0,
        title: const Text("Laporan"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          header(),
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: anggotaRef.onValue,
              builder: (context, anggotaSnapshot) {
                return StreamBuilder<DatabaseEvent>(
                  stream: calonAnggotaRef.onValue,
                  builder: (context, calonSnapshot) {
                    return StreamBuilder<DatabaseEvent>(
                      stream: pupukRef.onValue,
                      builder: (context, pupukSnapshot) {
                        return StreamBuilder<DatabaseEvent>(
                          stream: peminjamanRef.onValue,
                          builder: (context, peminjamanSnapshot) {
                            return laporanList(
                              anggotaSnapshot.data?.snapshot.value,
                              calonSnapshot.data?.snapshot.value,
                              pupukSnapshot.data?.snapshot.value,
                              peminjamanSnapshot.data?.snapshot.value,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
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
            child: const Icon(Icons.description, color: Colors.white, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rekap Laporan",
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

  Widget laporanList(
    dynamic anggotaValue,
    dynamic calonValue,
    dynamic pupukValue,
    dynamic peminjamanValue,
  ) {
    final totalAnggota = hitungTotal(anggotaValue);
    final totalCalon = hitungTotal(calonValue);
    final anggotaAktif = hitungStatus(anggotaValue, "aktif");

    final totalPupuk = hitungTotal(pupukValue);
    final pupukMenunggu = hitungStatus(pupukValue, "menunggu");
    final pupukDisetujui = hitungStatus(pupukValue, "disetujui");
    final pupukDitolak = hitungStatus(pupukValue, "ditolak");

    final totalPeminjaman = hitungTotal(peminjamanValue);
    final peminjamanMenunggu = hitungStatus(peminjamanValue, "menunggu");
    final peminjamanDisetujui = hitungStatus(peminjamanValue, "disetujui");
    final peminjamanDitolak = hitungStatus(peminjamanValue, "ditolak");

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        laporanCard("Rekap Anggota", Icons.people, Colors.purple, [
          dataItem("Total Anggota Aktif", "$totalAnggota"),
          dataItem("Calon Anggota", "$totalCalon"),
          dataItem("Status Aktif", "$anggotaAktif"),
        ]),
        const SizedBox(height: 18),
        laporanCard("Laporan Bantuan Pupuk", Icons.grass, Colors.green, [
          dataItem("Total Pengajuan", "$totalPupuk"),
          dataItem("Menunggu", "$pupukMenunggu"),
          dataItem("Disetujui", "$pupukDisetujui"),
          dataItem("Ditolak", "$pupukDitolak"),
        ]),
        const SizedBox(height: 18),
        laporanCard(
          "Laporan Peminjaman Alat",
          Icons.agriculture,
          Colors.orange,
          [
            dataItem("Total Peminjaman", "$totalPeminjaman"),
            dataItem("Menunggu", "$peminjamanMenunggu"),
            dataItem("Disetujui", "$peminjamanDisetujui"),
            dataItem("Ditolak", "$peminjamanDitolak"),
          ],
        ),
      ],
    );
  }

  Widget laporanCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget dataItem(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff8f7ff),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  BoxDecoration whiteCard() {
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
