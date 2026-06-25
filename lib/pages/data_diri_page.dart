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
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color backgroundColor = Color(0xffF7FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color blueStatus = Color(0xff2563EB);

  final DatabaseReference _anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  Map<String, dynamic>? _findMember(dynamic value) {
    if (value == null || value is! Map) return null;

    final data = Map<dynamic, dynamic>.from(value);
    final loginNik = widget.nik.replaceAll(RegExp(r'[^0-9]'), '');

    for (final item in data.values) {
      if (item is! Map) continue;

      final member = Map<String, dynamic>.from(item);
      final dataNik = (member['nik'] ?? '').toString().replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (dataNik == loginNik) return member;
    }

    return null;
  }

  String _text(dynamic value, {String fallback = '-'}) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _landSize(Map<String, dynamic> data) {
    return _text(
      data['luas_sawah'] ?? data['jumlah_petak_sawah'] ?? data['luasSawah'],
    );
  }

  String _dateFrom(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return _formatDate(value);
    }
    return '-';
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();

    return '$day-$month-$year';
  }

  String _statusText(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'aktif').toString().toLowerCase().trim();

    if (status.isEmpty || status == 'aktif' || status == 'disetujui') {
      return 'Anggota Aktif';
    }

    if (status == 'ditolak') return 'Ditolak';

    return status;
  }

  String _initialName(String name) {
    final clean = name.trim();
    if (clean.isEmpty || clean == '-') return 'A';

    final parts = clean.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return clean[0].toUpperCase();
  }

  double _parseDouble(dynamic value) {
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  double _fertilizerQuota(String landSize) {
    return _parseDouble(landSize) / 2;
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FutureBuilder<DataSnapshot>(
          future: _anggotaRef.get().timeout(const Duration(seconds: 10)),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _messageState(
                icon: Icons.error_outline_rounded,
                title: 'Terjadi Kesalahan',
                message: 'Data diri gagal dimuat.',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loadingState();
            }

            final member = _findMember(snapshot.data?.value);

            if (member == null) {
              return _messageState(
                icon: Icons.person_off_rounded,
                title: 'Data Tidak Ditemukan',
                message: 'Data diri anggota tidak ditemukan.',
              );
            }

            return RefreshIndicator(
              color: primaryGreen,
              onRefresh: _refreshData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  _topBar(),
                  const SizedBox(height: 16),
                  _profileHeader(member),
                  const SizedBox(height: 16),
                  _summaryCard(member),
                  const SizedBox(height: 22),
                  _sectionTitle('Data Anggota'),
                  const SizedBox(height: 12),
                  _dataCard(member),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _topButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            if (mounted) Navigator.pop(context);
          },
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Data Diri',
            style: TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileHeader(Map<String, dynamic> data) {
    final name = _text(data['nama']);
    final status = _statusText(data);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -30,
            child: Icon(
              Icons.person_rounded,
              size: 135,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 68,
                    width: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initialName(name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'NIK ${_text(data['nik'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status keanggotaan terdaftar sebagai $status.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status.replaceAll('Anggota ', '').toUpperCase(),
                        style: const TextStyle(
                          color: primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(Map<String, dynamic> data) {
    final landSize = _landSize(data);
    final quota = _fertilizerQuota(landSize);
    final status = _statusText(data).replaceAll('Anggota ', '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _summaryMini(
              icon: Icons.landscape_rounded,
              title: 'Luas Sawah',
              value: '$landSize Ha',
              color: primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryMini(
              icon: Icons.inventory_2_rounded,
              title: 'Jatah Pupuk',
              value: '${_formatNumber(quota)} Kg',
              color: orangeStatus,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _summaryMini(
              icon: Icons.verified_rounded,
              title: 'Status',
              value: status,
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
            color: color.withValues(alpha: 0.11),
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

  Widget _dataCard(Map<String, dynamic> data) {
    final dateRegistered = _dateFrom(data, [
      'tanggal_daftar',
      'created_at',
      'tanggal',
    ]);

    final dateVerified = _dateFrom(data, ['tanggal_verifikasi', 'verified_at']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _dataItem(
            icon: Icons.person_rounded,
            title: 'Nama',
            value: _text(data['nama']),
            color: primaryGreen,
          ),
          const Divider(height: 24),
          _dataItem(
            icon: Icons.badge_rounded,
            title: 'NIK',
            value: _text(data['nik']),
            color: blueStatus,
          ),
          const Divider(height: 24),
          _dataItem(
            icon: Icons.phone_rounded,
            title: 'Telepon',
            value: _text(data['telepon']),
            color: primaryGreen,
          ),
          const Divider(height: 24),
          _dataItem(
            icon: Icons.wc_rounded,
            title: 'Jenis Kelamin',
            value: _text(data['jenis_kelamin']),
            color: orangeStatus,
          ),
          const Divider(height: 24),
          _dataItem(
            icon: Icons.home_rounded,
            title: 'Alamat',
            value: _text(data['alamat']),
            color: blueStatus,
            multiline: true,
          ),
          const Divider(height: 24),
          _dataItem(
            icon: Icons.landscape_rounded,
            title: 'Luas Sawah',
            value: '${_landSize(data)} Ha',
            color: primaryGreen,
          ),
          const Divider(height: 24),
          _dataItem(
            icon: Icons.calendar_month_rounded,
            title: 'Tanggal Daftar',
            value: dateRegistered,
            color: primaryGreen,
          ),
          const Divider(height: 24),
          _dataItem(
            icon: Icons.event_available_rounded,
            title: 'Tanggal Verifikasi',
            value: dateVerified,
            color: blueStatus,
          ),
        ],
      ),
    );
  }

  Widget _dataItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool multiline = false,
  }) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
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
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            maxLines: multiline ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
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

  Widget _topButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cardBorder),
        ),
        child: Icon(icon, color: textDark),
      ),
    );
  }

  Widget _loadingState() {
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
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: _cardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 86,
                width: 86,
                decoration: BoxDecoration(
                  color: softGreen,
                  borderRadius: BorderRadius.circular(30),
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
                  height: 1.45,
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
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
