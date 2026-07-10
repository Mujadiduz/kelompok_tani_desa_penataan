import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class DataDiriPage extends StatefulWidget {
  final String nik;

  const DataDiriPage({super.key, required this.nik});

  @override
  State<DataDiriPage> createState() => _DataDiriPageState();
}

class _DataDiriPageState extends State<DataDiriPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

  final DatabaseReference _anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  String get cleanNik => widget.nik.replaceAll(RegExp(r'[^0-9]'), '');

  String _text(dynamic value, {String fallback = '-'}) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _initial(String name) {
    final clean = name.trim();
    if (clean.isEmpty || clean == '-') return 'A';
    return clean[0].toUpperCase();
  }

  String _landSize(Map<String, dynamic> data) {
    final value = _text(data['luas_lahan'] ?? data['luas_sawah'], fallback: '');
    if (value.isEmpty) return '-';
    return '$value ha';
  }

  String _formatDate(dynamic value) {
    final text = _text(value, fallback: '');
    if (text.isEmpty) return '-';

    final date = DateTime.tryParse(text);
    if (date == null) return text;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
          child: FutureBuilder<DataSnapshot>(
            future: _anggotaRef
                .child(cleanNik)
                .get()
                .timeout(const Duration(seconds: 10)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryGreen),
                );
              }

              if (snapshot.hasError ||
                  snapshot.data?.value == null ||
                  snapshot.data?.value is! Map) {
                return _emptyState();
              }

              final data = Map<String, dynamic>.from(
                snapshot.data!.value as Map,
              );

              return RefreshIndicator(
                color: primaryGreen,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    _header(),
                    const SizedBox(height: 14),
                    _profileCard(data),
                    const SizedBox(height: 14),
                    _infoCard(data),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textDark,
              size: 17,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Data Diri',
          style: TextStyle(
            color: textDark,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _profileCard(Map<String, dynamic> data) {
    final nama = _text(data['nama']);
    final nik = _text(data['nik'] ?? cleanNik);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(24),
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
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Center(
              child: Text(
                _initial(nama),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
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
                const Text(
                  'Anggota Aktif',
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nama,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'NIK $nik',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _item(Icons.phone_rounded, 'Telepon', _text(data['telepon'])),
          _divider(),
          _item(Icons.wc_rounded, 'Kelamin', _text(data['jenis_kelamin'])),
          _divider(),
          _item(Icons.home_rounded, 'Alamat', _text(data['alamat'])),
          _divider(),
          _item(Icons.landscape_rounded, 'Luas Lahan', _landSize(data)),
          _divider(),
          _item(
            Icons.calendar_month_rounded,
            'Terdaftar',
            _formatDate(data['tanggal_daftar']),
          ),
          _divider(),
          _item(
            Icons.verified_rounded,
            'Verifikasi',
            _formatDate(data['tanggal_verifikasi']),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen, size: 21),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: textDark,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 16, color: cardBorder.withValues(alpha: 0.85));
  }

  Widget _emptyState() {
    return AppBackground(
      showPattern: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_off_rounded, color: primaryGreen, size: 46),
                SizedBox(height: 14),
                Text(
                  'Data Tidak Ditemukan',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Data anggota tidak tersedia untuk akun ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}