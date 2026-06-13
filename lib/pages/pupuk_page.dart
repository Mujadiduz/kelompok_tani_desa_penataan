import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'pupuk_form_page.dart';

class PupukPage extends StatefulWidget {
  final String nama;
  final String nik;

  const PupukPage({super.key, required this.nama, required this.nik});

  @override
  State<PupukPage> createState() => _PupukPageState();
}

class _PupukPageState extends State<PupukPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  String? pupukDipilih;

  final DatabaseReference pupukRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('pupuk');

  List<Map<String, dynamic>> ambilPupukList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    return data.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((pupuk) {
          final status = (pupuk['status'] ?? 'aktif').toString().toLowerCase();
          return status == 'aktif';
        })
        .toList();
  }

  int hitungTotalStok(List<Map<String, dynamic>> list) {
    int total = 0;

    for (final pupuk in list) {
      total += int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
    }

    return total;
  }

  void lanjutPengajuan() {
    if (pupukDipilih == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PupukFormPage(
              namaPupuk: pupukDipilih!,
              namaUser: widget.nama,
              nikUser: widget.nik,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: pupukRef.onValue,
          builder: (context, snapshot) {
            final pupukList = ambilPupukList(snapshot.data?.snapshot.value);
            final totalStok = hitungTotalStok(pupukList);
            final pupukTersedia =
                pupukList.where((pupuk) {
                  final stok =
                      int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
                  return stok > 0;
                }).length;

            return Column(
              children: [
                _header(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepIndicator(),
                        const SizedBox(height: 18),
                        _summaryCard(
                          totalJenis: pupukList.length,
                          pupukTersedia: pupukTersedia,
                          totalStok: totalStok,
                        ),
                        const SizedBox(height: 22),
                        _sectionTitle('Pilih Jenis Pupuk'),
                        const SizedBox(height: 12),
                        Expanded(child: _buildContent(snapshot, pupukList)),
                      ],
                    ),
                  ),
                ),
                _bottomButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> snapshot,
    List<Map<String, dynamic>> pupukList,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: primaryGreen),
      );
    }

    if (snapshot.hasError) {
      return _messageState(
        icon: Icons.error_outline_rounded,
        title: 'Terjadi Kesalahan',
        message: snapshot.error.toString(),
      );
    }

    if (pupukList.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Pupuk Aktif',
        message: 'Admin perlu menambahkan data pupuk terlebih dahulu.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 18),
      itemCount: pupukList.length,
      itemBuilder: (context, index) {
        final pupuk = pupukList[index];
        final namaPupuk = (pupuk['nama_pupuk'] ?? '-').toString();
        final stok = int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
        final tersedia = stok > 0;

        return _pilihanPupuk(nama: namaPupuk, stok: stok, tersedia: tersedia);
      },
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -36,
            child: Icon(
              Icons.grass_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(context),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Bantuan Pupuk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Pilih Pupuk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pilih jenis pupuk yang tersedia untuk diajukan kepada admin.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _summaryCard({
    required int totalJenis,
    required int pupukTersedia,
    required int totalStok,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _summaryItem(
            icon: Icons.eco_rounded,
            title: 'Jenis',
            value: totalJenis.toString(),
            color: primaryGreen,
          ),
          Container(width: 1, height: 44, color: const Color(0xffE5E7EB)),
          _summaryItem(
            icon: Icons.check_circle_rounded,
            title: 'Tersedia',
            value: pupukTersedia.toString(),
            color: primaryGreen,
          ),
          Container(width: 1, height: 44, color: const Color(0xffE5E7EB)),
          _summaryItem(
            icon: Icons.inventory_2_rounded,
            title: 'Stok',
            value: '$totalStok Kg',
            color: orangeStatus,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pilihanPupuk({
    required String nama,
    required int stok,
    required bool tersedia,
  }) {
    final selected = pupukDipilih == nama;

    return InkWell(
      onTap:
          tersedia
              ? () {
                setState(() {
                  pupukDipilih = nama;
                });
              }
              : null,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: tersedia ? 1 : 0.48,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? primaryGreen : const Color(0xffE5E7EB),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? primaryGreen.withValues(alpha: 0.14)
                          : lightGreen,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.eco_rounded,
                  color: tersedia ? primaryGreen : textGrey,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      tersedia ? 'Stok tersedia $stok Kg' : 'Stok pupuk habis',
                      style: TextStyle(
                        color: tersedia ? textGrey : Colors.red,
                        fontSize: 12,
                        fontWeight:
                            tersedia ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? primaryGreen : textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: primaryGreen.withValues(alpha: 0.45),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: pupukDipilih == null ? null : lanjutPengajuan,
          child: const Text(
            'Lanjut Pengajuan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stepCircle('1', 'Pilih', true),
          _stepLine(true),
          _stepCircle('2', 'Data', false),
          _stepLine(false),
          _stepCircle('3', 'Kirim', false),
        ],
      ),
    );
  }

  Widget _stepCircle(String number, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: active ? primaryGreen : const Color(0xffE5E7EB),
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : textGrey,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? primaryGreen : textGrey,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: active ? primaryGreen : const Color(0xffE5E7EB),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: const BoxDecoration(
                  color: lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryGreen, size: 36),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
