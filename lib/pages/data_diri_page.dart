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
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  Map<String, dynamic>? cariDataDiri(dynamic value) {
    if (value == null || value is! Map) return null;

    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final anggota = Map<String, dynamic>.from(item);
        final nikData = (anggota['nik'] ?? '').toString();

        if (nikData == widget.nik) {
          return anggota;
        }
      }
    }

    return null;
  }

  String ambilLuasLahan(Map<String, dynamic> data) {
    return (data['luas_sawah'] ?? data['jumlah_petak_sawah'] ?? '-').toString();
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
              return const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              );
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

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Column(
                children: [
                  _header(context, nama),
                  const SizedBox(height: 22),
                  _sectionTitle('Informasi Pribadi'),
                  const SizedBox(height: 12),
                  _infoCard(
                    children: [
                      _infoItem(
                        icon: Icons.person_rounded,
                        title: 'Nama',
                        value: dataDiri['nama'] ?? '-',
                      ),
                      const Divider(height: 24),
                      _infoItem(
                        icon: Icons.badge_rounded,
                        title: 'NIK',
                        value: dataDiri['nik'] ?? '-',
                      ),
                      const Divider(height: 24),
                      _infoItem(
                        icon: Icons.phone_rounded,
                        title: 'Telepon',
                        value: dataDiri['telepon'] ?? '-',
                      ),
                      const Divider(height: 24),
                      _infoItem(
                        icon: Icons.wc_rounded,
                        title: 'Jenis Kelamin',
                        value: dataDiri['jenis_kelamin'] ?? '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('Informasi Lahan'),
                  const SizedBox(height: 12),
                  _infoCard(
                    children: [
                      _infoItem(
                        icon: Icons.landscape_rounded,
                        title: 'Luas Sawah',
                        value: '${ambilLuasLahan(dataDiri)} Ha',
                      ),
                      const Divider(height: 24),
                      _infoItem(
                        icon: Icons.home_rounded,
                        title: 'Alamat',
                        value: dataDiri['alamat'] ?? '-',
                      ),
                      const Divider(height: 24),
                      _infoItem(
                        icon: Icons.verified_user_rounded,
                        title: 'Status',
                        value: dataDiri['status'] ?? 'aktif',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String nama) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen, Color(0xff43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
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
              Icons.person_rounded,
              size: 145,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                height: 88,
                width: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                nama,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Anggota Aktif',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
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

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: primaryGreen, size: 22),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                fontWeight: FontWeight.w800,
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
              ),
            ),
          ],
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
