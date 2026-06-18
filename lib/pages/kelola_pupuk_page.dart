import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class KelolaPupukPage extends StatefulWidget {
  const KelolaPupukPage({super.key});

  @override
  State<KelolaPupukPage> createState() => _KelolaPupukPageState();
}

class _KelolaPupukPageState extends State<KelolaPupukPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  final namaController = TextEditingController();
  final stokController = TextEditingController();

  final DatabaseReference pupukRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('pupuk');

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

  Future<void> simpanPupuk(String? id) async {
    final nama = namaController.text.trim();
    final stok = int.tryParse(stokController.text.trim()) ?? 0;

    if (nama.isEmpty) {
      _showSnackBar('Nama pupuk wajib diisi', Colors.red);
      return;
    }

    if (stok < 0) {
      _showSnackBar('Stok pupuk tidak boleh kurang dari 0', Colors.red);
      return;
    }

    try {
      if (id == null) {
        await pupukRef
            .push()
            .set({
              'nama_pupuk': nama,
              'stok': stok,
              'status': 'aktif',
              'tanggal_input': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 10));
      } else {
        await pupukRef
            .child(id)
            .update({'nama_pupuk': nama, 'stok': stok})
            .timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;

      namaController.clear();
      stokController.clear();
      Navigator.pop(context);

      _showSnackBar(
        id == null ? 'Pupuk berhasil ditambahkan' : 'Pupuk berhasil diperbarui',
        primaryGreen,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menyimpan pupuk: $e', Colors.red);
    }
  }

  Future<void> hapusPupuk(String id) async {
    try {
      await pupukRef.child(id).remove().timeout(const Duration(seconds: 10));

      if (!mounted) return;

      _showSnackBar('Data pupuk berhasil dihapus', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menghapus pupuk: $e', Colors.red);
    }
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

  List<MapEntry<String, dynamic>> ambilPupukList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);

    return data.entries.toList().reversed.toList();
  }

  int hitungTotalStok(List<MapEntry<String, dynamic>> list) {
    int total = 0;

    for (final entry in list) {
      final pupuk = Map<String, dynamic>.from(entry.value as Map);
      total += int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
    }

    return total;
  }

  int hitungAktif(List<MapEntry<String, dynamic>> list) {
    return list.where((entry) {
      final pupuk = Map<String, dynamic>.from(entry.value as Map);
      final status = (pupuk['status'] ?? 'aktif').toString().toLowerCase();
      return status == 'aktif';
    }).length;
  }

  void formPupuk({String? id, Map<String, dynamic>? data}) {
    namaController.text = (data?['nama_pupuk'] ?? '').toString();
    stokController.text = (data?['stok'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xffD1D5DB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  id == null ? 'Tambah Pupuk' : 'Edit Pupuk',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masukkan nama pupuk dan jumlah stok tersedia.',
                  style: TextStyle(color: textGrey, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: namaController,
                  decoration: _inputDecoration(
                    label: 'Nama Pupuk',
                    icon: Icons.grass_rounded,
                  ),
                ),
                const SizedBox(height: 13),
                TextField(
                  controller: stokController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'Stok Pupuk (Kg)',
                    icon: Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textGrey,
                          side: const BorderSide(color: Color(0xffE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          namaController.clear();
                          stokController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => simpanPupuk(id),
                        child: const Text(
                          'Simpan',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Hapus Pupuk?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Data pupuk ini akan dihapus dari Firebase.',
            style: TextStyle(color: textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                hapusPupuk(id);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    namaController.dispose();
    stokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => formPupuk(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: pupukRef.onValue,
          builder: (context, snapshot) {
            final pupukList = ambilPupukList(snapshot.data?.snapshot.value);
            final totalStok = hitungTotalStok(pupukList);
            final pupukAktif = hitungAktif(pupukList);

            return Column(
              children: [
                _header(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: Column(
                      children: [
                        _summaryCard(
                          totalJenis: pupukList.length,
                          pupukAktif: pupukAktif,
                          totalStok: totalStok,
                        ),
                        const SizedBox(height: 18),
                        Expanded(child: _buildContent(snapshot, pupukList)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> snapshot,
    List<MapEntry<String, dynamic>> pupukList,
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
        title: 'Belum Ada Data Pupuk',
        message: 'Tekan tombol tambah untuk memasukkan data pupuk.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: pupukList.length,
      itemBuilder: (context, index) {
        final id = pupukList[index].key.toString();
        final pupuk = Map<String, dynamic>.from(pupukList[index].value as Map);

        return _pupukCard(id, pupuk);
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
              Icons.eco_rounded,
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
                      'Kelola Pupuk',
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
                'Data Pupuk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kelola stok pupuk yang tersedia untuk anggota kelompok tani.',
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
    required int pupukAktif,
    required int totalStok,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _summaryItem(
            icon: Icons.grass_rounded,
            title: 'Jenis',
            value: totalJenis.toString(),
            color: primaryGreen,
          ),
          Container(width: 1, height: 44, color: const Color(0xffE5E7EB)),
          _summaryItem(
            icon: Icons.check_circle_rounded,
            title: 'Aktif',
            value: pupukAktif.toString(),
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

  Widget _pupukCard(String id, Map<String, dynamic> pupuk) {
    final namaPupuk = (pupuk['nama_pupuk'] ?? '-').toString();
    final stok = int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
    final status = (pupuk['status'] ?? 'aktif').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(iconPupuk(namaPupuk), color: primaryGreen, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaPupuk,
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
                  'Stok tersedia: $stok Kg',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'ID: $id',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _statusBadge(status),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _circleAction(
            icon: Icons.edit_rounded,
            color: orangeStatus,
            onTap: () => formPupuk(id: id, data: pupuk),
          ),
          const SizedBox(width: 8),
          _circleAction(
            icon: Icons.delete_rounded,
            color: Colors.red,
            onTap: () => konfirmasiHapus(id),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final aktif = status.toLowerCase() == 'aktif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: aktif ? lightGreen : const Color(0xffFFEBEE),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        aktif ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          color: aktif ? primaryGreen : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 20),
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
