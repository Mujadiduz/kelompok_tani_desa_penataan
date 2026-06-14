import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class StatusKeanggotaanPage extends StatefulWidget {
  const StatusKeanggotaanPage({super.key});

  @override
  State<StatusKeanggotaanPage> createState() => _StatusKeanggotaanPageState();
}

class _StatusKeanggotaanPageState extends State<StatusKeanggotaanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  final nikController = TextEditingController();

  bool isLoading = false;
  Map<String, dynamic>? dataAnggota;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  Future<void> cekStatus() async {
    final nikInput = nikController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (nikInput.isEmpty) {
      _showSnackBar('NIK wajib diisi', Colors.red);
      return;
    }

    if (nikInput.length != 16) {
      _showSnackBar(
        'NIK harus 16 digit. Saat ini terbaca ${nikInput.length} digit.',
        Colors.red,
      );
      return;
    }

    setState(() {
      isLoading = true;
      dataAnggota = null;
    });

    try {
      final calonRef = db.ref('calon_anggota');
      final anggotaRef = db.ref('anggota');

      Map<String, dynamic>? hasil;

      final calonSnapshot = await calonRef.get().timeout(
        const Duration(seconds: 10),
      );

      if (calonSnapshot.exists && calonSnapshot.value != null) {
        hasil = cariDataByNik(calonSnapshot.value, nikInput);
      }

      if (hasil == null) {
        final anggotaSnapshot = await anggotaRef.get().timeout(
          const Duration(seconds: 10),
        );

        if (anggotaSnapshot.exists && anggotaSnapshot.value != null) {
          hasil = cariDataByNik(anggotaSnapshot.value, nikInput);
        }
      }

      if (!mounted) return;

      if (hasil != null) {
        setState(() {
          dataAnggota = hasil;
        });
      } else {
        _showSnackBar('Data anggota tidak ditemukan', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal cek status: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Map<String, dynamic>? cariDataByNik(dynamic value, String nikInput) {
    if (value == null || value is! Map) return null;

    final data = Map<dynamic, dynamic>.from(value);

    for (final item in data.values) {
      if (item is Map) {
        final anggota = Map<String, dynamic>.from(item);
        final nikData = (anggota['nik'] ?? '').toString().replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

        if (nikData == nikInput) {
          return anggota;
        }
      }
    }

    return null;
  }

  void _showSnackBar(String pesan, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color warnaStatus(String status) {
    if (status == 'aktif') return primaryGreen;
    if (status == 'disetujui') return primaryGreen;
    if (status == 'ditolak') return Colors.red;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') return lightGreen;
    if (status == 'ditolak') return const Color(0xffFFEBEE);
    return const Color(0xffFFF3E0);
  }

  IconData iconStatus(String status) {
    if (status == 'aktif' || status == 'disetujui') {
      return Icons.check_circle_rounded;
    }

    if (status == 'ditolak') return Icons.cancel_rounded;

    return Icons.hourglass_top_rounded;
  }

  String teksStatus(String status) {
    if (status == 'aktif') return 'Disetujui / Aktif';
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    return 'Menunggu Verifikasi';
  }

  String ambilLuasSawah() {
    return (dataAnggota?['luas_sawah'] ??
            dataAnggota?['jumlah_petak_sawah'] ??
            '-')
        .toString();
  }

  @override
  void dispose() {
    nikController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status =
        (dataAnggota?['status'] ?? 'menunggu').toString().toLowerCase();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 22),
              _inputCard(),
              const SizedBox(height: 18),
              if (dataAnggota != null) _hasilCard(status),
            ],
          ),
        ),
      ),
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
              Icons.fact_check_rounded,
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
                      'Status Keanggotaan',
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
                'Cek Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Masukkan NIK untuk melihat status pendaftaran anggota kelompok tani.',
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

  Widget _inputCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nomor Induk Kependudukan',
            style: TextStyle(
              color: textDark,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan NIK yang digunakan saat pendaftaran.',
            style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: nikController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              label: 'Masukkan NIK',
              icon: Icons.badge_rounded,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryGreen.withValues(alpha: 0.65),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: isLoading ? null : cekStatus,
              icon:
                  isLoading
                      ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.search_rounded),
              label: Text(
                isLoading ? 'Mengecek...' : 'Cek Status',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hasilCard(String status) {
    final color = warnaStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: backgroundStatus(status),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(iconStatus(status), color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  (dataAnggota!['nama'] ?? '-').toString(),
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoBox(
            children: [
              _infoRow(Icons.badge_rounded, 'NIK', dataAnggota!['nik'] ?? '-'),
              _infoRow(
                Icons.home_rounded,
                'Alamat',
                dataAnggota!['alamat'] ?? '-',
              ),
              _infoRow(
                Icons.wc_rounded,
                'Jenis Kelamin',
                dataAnggota!['jenis_kelamin'] ?? '-',
              ),
              _infoRow(
                Icons.landscape_rounded,
                'Luas Sawah',
                '${ambilLuasSawah()} Ha',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _statusBadge(status),
        ],
      ),
    );
  }

  Widget _infoBox({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString().isEmpty ? '-' : value.toString(),
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = warnaStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(iconStatus(status), color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teksStatus(status),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey),
      prefixIcon: Icon(icon, color: primaryGreen),
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
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
