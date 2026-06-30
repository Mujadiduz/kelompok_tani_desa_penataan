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
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color redStatus = Color(0xffDC2626);
  static const Color blueStatus = Color(0xff2563EB);

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
    if (stok <= 0) return 'Belum tersedia';
    if (stok <= 10) return 'Terbatas';
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

  String statusLayananText(int tersedia) {
    if (tersedia <= 0) return 'Belum Bisa Diajukan';
    return 'Siap Diajukan';
  }

  String statusLayananDesc(int tersedia) {
    if (tersedia <= 0) {
      return 'Saat ini belum ada pupuk yang tersedia untuk dipilih.';
    }
    return 'Silakan pilih jenis pupuk yang tersedia untuk melanjutkan pengajuan.';
  }

  Color statusLayananColor(int tersedia) {
    if (tersedia <= 0) return orangeStatus;
    return primaryGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: pupukRef.onValue,
            builder: (context, snapshot) {
              final pupukList = ambilPupukList(snapshot.data?.snapshot.value);
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
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                        children: [
                          _userInfoCard(),
                          const SizedBox(height: 12),
                          _summaryGrid(
                            totalJenis: pupukList.length,
                            pupukTersedia: pupukTersedia,
                          ),
                          const SizedBox(height: 12),
                          _infoBox(),
                          const SizedBox(height: 18),
                          _sectionTitle(
                            title: 'Pilih Jenis Pupuk',
                            subtitle: 'Pilih salah satu pupuk untuk diajukan',
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
        message: 'Data pupuk gagal dimuat. Silakan coba lagi.',
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
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
        decoration: BoxDecoration(
          color: darkGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 7),
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
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pilih pupuk yang ingin diajukan',
                    style: TextStyle(
                      color: Color(0xffD1FAE5),
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
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
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primaryGreen,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Pemohon',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.3,
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
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'NIK ${sensorNik(widget.nik)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid({required int totalJenis, required int pupukTersedia}) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryMini(
                title: 'Jenis Pupuk',
                value: totalJenis.toString(),
                icon: Icons.grass_rounded,
                color: primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryMini(
                title: 'Bisa Dipilih',
                value: pupukTersedia.toString(),
                icon: Icons.check_circle_rounded,
                color: blueStatus,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _serviceStatusCard(pupukTersedia),
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
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 11.5,
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

  Widget _serviceStatusCard(int pupukTersedia) {
    final color = statusLayananColor(pupukTersedia);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              pupukTersedia > 0
                  ? Icons.assignment_turned_in_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLayananText(pupukTersedia),
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLayananDesc(pupukTersedia),
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.7,
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
        color: primaryGreen.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Pilih jenis pupuk yang tersedia, lalu lanjutkan pengisian data pengajuan.',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 12.2,
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
          height: 32,
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
                  fontSize: 15.8,
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
      borderRadius: BorderRadius.circular(18),
      child: Opacity(
        opacity: tersedia ? 1 : 0.58,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                selected ? primaryGreen.withValues(alpha: 0.075) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? primaryGreen : borderColor,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 11,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? primaryGreen
                          : primaryGreen.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  iconPupuk(nama),
                  color: selected ? Colors.white : primaryGreen,
                  size: 25,
                ),
              ),
              const SizedBox(width: 11),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    _stokBadge(stok, statusColor),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? primaryGreen : const Color(0xff9CA3AF),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stokBadge(int stok, Color color) {
    final text =
        stok <= 0
            ? teksKeteranganStok(stok)
            : '${teksKeteranganStok(stok)} • $stok Kg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
          height: 52,
          child: ElevatedButton.icon(
            onPressed: aktif ? lanjutPengajuan : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.36),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              aktif ? 'Lanjutkan Pengajuan' : 'Pilih Pupuk Terlebih Dahulu',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
              ),
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: _cardDecoration(radius: 18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              const SizedBox(width: 11),
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
      decoration: _cardDecoration(radius: 18),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 15.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 12.4,
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.032),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
