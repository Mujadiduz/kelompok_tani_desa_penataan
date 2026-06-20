import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class DataDiriPage extends StatefulWidget {
  final String nik;

  const DataDiriPage({super.key, required this.nik});

  @override
  State<DataDiriPage> createState() => _DataDiriPageState();
}

class _DataDiriPageState extends State<DataDiriPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color blueStatus = Color(0xff1976D2);
  static const Color orangeStatus = Color(0xffFB8C00);

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  Map<String, dynamic>? cariDataDiri(dynamic value) {
    if (value == null || value is! Map) return null;

    final data = Map<dynamic, dynamic>.from(value);
    final nikLogin = widget.nik.replaceAll(RegExp(r'[^0-9]'), '');

    for (final item in data.values) {
      if (item is Map) {
        final anggota = Map<String, dynamic>.from(item);
        final nikData = (anggota['nik'] ?? '').toString().replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

        if (nikData == nikLogin) return anggota;
      }
    }

    return null;
  }

  String ambilLuasSawah(Map<String, dynamic> data) {
    return (data['luas_sawah'] ??
            data['jumlah_petak_sawah'] ??
            data['luasSawah'] ??
            '-')
        .toString();
  }

  String ambilTanggal(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return formatTanggal(value);
    }
    return '-';
  }

  String formatTanggal(String value) {
    try {
      final date = DateTime.parse(value);
      return '${date.day.toString().padLeft(2, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String statusText(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'aktif').toString().toLowerCase().trim();

    if (status == 'aktif' || status == 'disetujui' || status.isEmpty) {
      return 'Anggota Aktif';
    }

    if (status == 'ditolak') return 'Ditolak';

    return status;
  }

  String inisialNama(String nama) {
    final clean = nama.trim();
    if (clean.isEmpty || clean == '-') return 'A';

    final parts = clean.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return clean[0].toUpperCase();
  }

  double parseDouble(dynamic value) {
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  double hitungJatahPupuk(String luasSawah) {
    return parseDouble(luasSawah) / 2;
  }

  String formatAngka(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Future<void> refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FutureBuilder<DataSnapshot>(
          future: anggotaRef.get(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline_rounded,
                title: 'Terjadi Kesalahan',
                message: snapshot.error.toString(),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loadingPage();
            }

            final dataDiri = cariDataDiri(snapshot.data?.value);

            if (dataDiri == null) {
              return _messageState(
                icon: Icons.person_off_rounded,
                title: 'Data Tidak Ditemukan',
                message: 'Data diri anggota tidak ditemukan.',
              );
            }

            final nama = (dataDiri['nama'] ?? '-').toString();
            final luasSawah = ambilLuasSawah(dataDiri);
            final jatahPupuk = hitungJatahPupuk(luasSawah);
            final tanggalDaftar = ambilTanggal(dataDiri, [
              'tanggal_daftar',
              'created_at',
              'tanggal',
            ]);
            final tanggalVerifikasi = ambilTanggal(dataDiri, [
              'tanggal_verifikasi',
              'verified_at',
            ]);

            return RefreshIndicator(
              color: primaryGreen,
              onRefresh: refreshData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _header(
                      context: context,
                      nama: nama,
                      dataDiri: dataDiri,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
                      child: _summaryCard(
                        luasSawah: luasSawah,
                        jatahPupuk: jatahPupuk,
                        status: statusText(dataDiri),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                      child: _sectionTitle(
                        title: 'Informasi Pribadi',
                        icon: Icons.person_rounded,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: _infoCard(
                        children: [
                          _infoItem(
                            icon: Icons.person_rounded,
                            title: 'Nama',
                            value: dataDiri['nama'] ?? '-',
                            color: primaryGreen,
                          ),
                          const Divider(height: 24),
                          _infoItem(
                            icon: Icons.badge_rounded,
                            title: 'NIK',
                            value: dataDiri['nik'] ?? '-',
                            color: blueStatus,
                          ),
                          const Divider(height: 24),
                          _infoItem(
                            icon: Icons.phone_rounded,
                            title: 'Telepon',
                            value: dataDiri['telepon'] ?? '-',
                            color: primaryGreen,
                          ),
                          const Divider(height: 24),
                          _infoItem(
                            icon: Icons.wc_rounded,
                            title: 'Jenis Kelamin',
                            value: dataDiri['jenis_kelamin'] ?? '-',
                            color: orangeStatus,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                      child: _sectionTitle(
                        title: 'Informasi Lahan',
                        icon: Icons.landscape_rounded,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: _infoCard(
                        children: [
                          _infoItem(
                            icon: Icons.home_rounded,
                            title: 'Alamat',
                            value: dataDiri['alamat'] ?? '-',
                            color: blueStatus,
                          ),
                          const Divider(height: 24),
                          _infoItem(
                            icon: Icons.map_rounded,
                            title: 'Keterangan',
                            value:
                                'Data lahan digunakan sebagai dasar pengajuan bantuan pupuk.',
                            color: primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                      child: _sectionTitle(
                        title: 'Informasi Keanggotaan',
                        icon: Icons.verified_user_rounded,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                      child: _infoCard(
                        children: [
                          _infoItem(
                            icon: Icons.calendar_month_rounded,
                            title: 'Tanggal Daftar',
                            value: tanggalDaftar,
                            color: primaryGreen,
                          ),
                          const Divider(height: 24),
                          _infoItem(
                            icon: Icons.event_available_rounded,
                            title: 'Tanggal Verifikasi',
                            value: tanggalVerifikasi,
                            color: blueStatus,
                          ),
                          const Divider(height: 24),
                          _infoItem(
                            icon: Icons.verified_rounded,
                            title: 'Status',
                            value: statusText(dataDiri),
                            color: primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header({
    required BuildContext context,
    required String nama,
    required Map<String, dynamic> dataDiri,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff14532D), Color(0xff2E7D32), Color(0xff66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _backButton(context),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Data Diri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                inisialNama(nama),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _whiteBadge(statusText(dataDiri)),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String luasSawah,
    required double jatahPupuk,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _summaryMini(
              icon: Icons.landscape_rounded,
              title: 'Luas Sawah',
              value: '$luasSawah Ha',
              color: primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryMini(
              icon: Icons.inventory_2_rounded,
              title: 'Jatah Pupuk',
              value: '${formatAngka(jatahPupuk)} Kg',
              color: orangeStatus,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryMini(
              icon: Icons.verified_rounded,
              title: 'Status',
              value: status.replaceAll('Anggota ', ''),
              color: blueStatus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMini({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: textGrey,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _whiteBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _sectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryGreen, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(children: children),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String title,
    required dynamic value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 2,
          child: Text(
            value.toString().isEmpty ? '-' : value.toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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

  Widget _loadingPage() {
    return const Center(child: CircularProgressIndicator(color: primaryGreen));
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 86,
                width: 86,
                decoration: const BoxDecoration(
                  color: lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryGreen, size: 42),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
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
