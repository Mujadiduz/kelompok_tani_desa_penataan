import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
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
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF3F7F3);
  static const Color softGreen = Color(0xffE8F5E9);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color redStatus = Color(0xffDC2626);
  static const Color blueStatus = Color(0xff1976D2);

  String? pupukDipilih;
  String? idPupukDipilih;

  final DatabaseReference pupukRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('pupuk');

  Future<void> _refreshData() async {
    await pupukRef.get();
  }

  List<Map<String, dynamic>> ambilPupukList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final pupuk = Map<String, dynamic>.from(entry.value as Map);
              pupuk['id_pupuk'] = entry.key.toString();
              return pupuk;
            })
            .where((pupuk) {
              final status =
                  (pupuk['status'] ?? 'aktif').toString().toLowerCase();
              return status == 'aktif';
            })
            .toList();

    list.sort((a, b) {
      final stokA = int.tryParse((a['stok'] ?? 0).toString()) ?? 0;
      final stokB = int.tryParse((b['stok'] ?? 0).toString()) ?? 0;

      if (stokA > 0 && stokB <= 0) return -1;
      if (stokA <= 0 && stokB > 0) return 1;

      final namaA = (a['nama_pupuk'] ?? '').toString();
      final namaB = (b['nama_pupuk'] ?? '').toString();
      return namaA.compareTo(namaB);
    });

    return list;
  }

  int hitungTotalStok(List<Map<String, dynamic>> list) {
    int total = 0;

    for (final pupuk in list) {
      total += int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
    }

    return total;
  }

  int hitungPupukTersedia(List<Map<String, dynamic>> list) {
    return list.where((pupuk) {
      final stok = int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
      return stok > 0;
    }).length;
  }

  void lanjutPengajuan() {
    if (pupukDipilih == null || idPupukDipilih == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PupukFormPage(
              idPupuk: idPupukDipilih!,
              namaPupuk: pupukDipilih!,
              namaUser: widget.nama,
              nikUser: widget.nik,
            ),
      ),
    );
  }

  String teksKeteranganStok(int stok) {
    if (stok <= 0) return 'Stok Habis';
    if (stok <= 10) return 'Stok Terbatas';
    return 'Tersedia';
  }

  Color warnaStok(int stok) {
    if (stok <= 0) return redStatus;
    if (stok <= 10) return orangeStatus;
    return primaryGreen;
  }

  IconData iconPupuk(String nama) {
    final value = nama.toLowerCase();

    if (value.contains('urea')) return Icons.water_drop_rounded;
    if (value.contains('npk')) return Icons.grain_rounded;
    if (value.contains('organik')) return Icons.eco_rounded;
    if (value.contains('kandang')) return Icons.grass_rounded;
    if (value.contains('kompos')) return Icons.local_florist_rounded;
    if (value.contains('za')) return Icons.science_rounded;
    if (value.contains('sp')) return Icons.bubble_chart_rounded;
    if (value.contains('kcl')) return Icons.inventory_2_rounded;
    if (value.contains('dolomit')) return Icons.terrain_rounded;
    if (value.contains('hayati')) return Icons.spa_rounded;

    return Icons.eco_rounded;
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: pupukRef.onValue,
            builder: (context, snapshot) {
              final pupukList = ambilPupukList(snapshot.data?.snapshot.value);
              final totalStok = hitungTotalStok(pupukList);
              final pupukTersedia = hitungPupukTersedia(pupukList);

              return Column(
                children: [
                  _headerPage(),
                  Expanded(
                    child: RefreshIndicator(
                      color: primaryGreen,
                      backgroundColor: Colors.white,
                      onRefresh: _refreshData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          _userInfoCard(),
                          const SizedBox(height: 14),
                          _summaryGrid(
                            totalJenis: pupukList.length,
                            pupukTersedia: pupukTersedia,
                            totalStok: totalStok,
                          ),
                          const SizedBox(height: 14),
                          _infoBox(),
                          const SizedBox(height: 18),
                          _sectionTitle(
                            title: 'Pilih Jenis Pupuk',
                            subtitle: 'Pilih salah satu pupuk yang tersedia',
                          ),
                          const SizedBox(height: 12),
                          _buildContent(snapshot, pupukList),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _bottomButton(),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> snapshot,
    List<Map<String, dynamic>> pupukList,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _loadingState();
    }

    if (snapshot.hasError) {
      return _messageState(
        icon: Icons.error_outline_rounded,
        title: 'Terjadi Kesalahan',
        message: 'Data pupuk gagal dimuat.',
      );
    }

    if (pupukList.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Pupuk Aktif',
        message: 'Data pupuk belum tersedia atau belum diaktifkan admin.',
      );
    }

    return Column(
      children:
          pupukList.map((pupuk) {
            final idPupuk = (pupuk['id_pupuk'] ?? '').toString();
            final namaPupuk = (pupuk['nama_pupuk'] ?? '-').toString();
            final stok = int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
            final tersedia = stok > 0;

            return _pilihanPupuk(
              idPupuk: idPupuk,
              nama: namaPupuk,
              stok: stok,
              tersedia: tersedia,
            );
          }).toList(),
    );
  }

  Widget _headerPage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [darkGreen, primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _backButton(),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bantuan Pupuk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Pilih pupuk untuk melanjutkan pengajuan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Icon(Icons.eco_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userInfoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pemohon',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIK ${sensorNik(widget.nik)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid({
    required int totalJenis,
    required int pupukTersedia,
    required int totalStok,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryMini(
                title: 'Jenis',
                value: totalJenis.toString(),
                icon: Icons.grass_rounded,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryMini(
                title: 'Tersedia',
                value: pupukTersedia.toString(),
                icon: Icons.check_circle_rounded,
                color: blueStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _summaryWide(
          title: 'Total Stok Pupuk Aktif',
          value: '$totalStok Kg',
          description: 'Jumlah stok keseluruhan dari pupuk yang masih aktif.',
          icon: Icons.inventory_2_rounded,
          color: orangeStatus,
        ),
      ],
    );
  }

  Widget _summaryMini({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 86,
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryWide({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Pupuk dengan stok habis tidak dapat dipilih. Setelah memilih pupuk, lanjutkan pengisian data pengajuan.',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 5,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pilihanPupuk({
    required String idPupuk,
    required String nama,
    required int stok,
    required bool tersedia,
  }) {
    final selected = idPupukDipilih == idPupuk;
    final statusColor = warnaStok(stok);

    return InkWell(
      onTap:
          tersedia
              ? () {
                setState(() {
                  idPupukDipilih = idPupuk;
                  pupukDipilih = nama;
                });
              }
              : null,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: tersedia ? 1 : 0.58,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                selected ? primaryGreen.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? primaryGreen : borderColor,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? primaryGreen
                          : primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  iconPupuk(nama),
                  color: selected ? Colors.white : primaryGreen,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _stokBadge(stok, statusColor),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? primaryGreen : textGrey,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stokBadge(int stok, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        '${teksKeteranganStok(stok)} • $stok Kg',
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _bottomButton() {
    final aktif = pupukDipilih != null && idPupukDipilih != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: aktif ? lanjutPengajuan : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.38),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              aktif ? 'Lanjutkan Pengajuan' : 'Pilih Pupuk Terlebih Dahulu',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingState() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 13,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 38),
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
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
        if (!mounted) return;
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
