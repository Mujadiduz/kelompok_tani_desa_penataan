import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class VerifikasiPupukPage extends StatefulWidget {
  const VerifikasiPupukPage({super.key});

  @override
  State<VerifikasiPupukPage> createState() => _VerifikasiPupukPageState();
}

class _VerifikasiPupukPageState extends State<VerifikasiPupukPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);

  String selectedFilter = 'semua';

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference bantuanPupukRef;
  late final DatabaseReference stokPupukRef;

  @override
  void initState() {
    super.initState();
    bantuanPupukRef = db.ref('bantuan_pupuk');
    stokPupukRef = db.ref('pupuk');
  }

  Future<void> updateStatus(
    String id,
    String status,
    Map<String, dynamic> dataPupuk,
  ) async {
    try {
      if (status == 'disetujui') {
        final jenisPupuk = (dataPupuk['jenis_pupuk'] ?? '').toString();
        final jumlahDiajukan =
            int.tryParse((dataPupuk['jumlah_pupuk'] ?? '0').toString()) ?? 0;

        final snapshot = await stokPupukRef.get().timeout(
          const Duration(seconds: 10),
        );

        if (snapshot.exists && snapshot.value != null) {
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
          bool pupukDitemukan = false;

          for (final entry in data.entries) {
            final idPupuk = entry.key.toString();
            final pupuk = Map<dynamic, dynamic>.from(entry.value as Map);

            final namaPupuk = (pupuk['nama_pupuk'] ?? '').toString();
            final stokSekarang =
                int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;

            if (namaPupuk.toLowerCase().trim() ==
                jenisPupuk.toLowerCase().trim()) {
              pupukDitemukan = true;

              if (stokSekarang < jumlahDiajukan) {
                if (!mounted) return;
                _showSnackBar('Stok pupuk tidak mencukupi', Colors.red);
                return;
              }

              final stokBaru = stokSekarang - jumlahDiajukan;
              await stokPupukRef.child(idPupuk).update({'stok': stokBaru});
              break;
            }
          }

          if (!pupukDitemukan) {
            if (!mounted) return;
            _showSnackBar(
              'Jenis pupuk tidak ditemukan di data stok',
              Colors.red,
            );
            return;
          }
        }
      }

      await bantuanPupukRef.child(id).update({'status': status});

      if (!mounted) return;

      _showSnackBar(
        'Pengajuan pupuk berhasil $status',
        status == 'disetujui' ? primaryGreen : Colors.red,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengubah status: $e', Colors.red);
    }
  }

  Future<void> tampilkanKonfirmasi({
    required String id,
    required String status,
    required Map<String, dynamic> pupuk,
  }) async {
    final nama = (pupuk['nama'] ?? '-').toString();
    final isSetuju = status == 'disetujui';

    final hasil = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            isSetuju ? 'Setujui Bantuan Pupuk?' : 'Tolak Bantuan Pupuk?',
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            isSetuju
                ? 'Pengajuan pupuk dari $nama akan disetujui dan stok pupuk akan dikurangi.'
                : 'Pengajuan pupuk dari $nama akan ditolak.',
            style: const TextStyle(color: textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSetuju ? primaryGreen : Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(isSetuju ? 'Setujui' : 'Tolak'),
            ),
          ],
        );
      },
    );

    if (hasil == true) {
      await updateStatus(id, status, pupuk);
    }
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') return primaryGreen;
    if (status == 'ditolak') return Colors.red;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') return lightGreen;
    if (status == 'ditolak') return const Color(0xffFFEBEE);
    return const Color(0xffFFF3E0);
  }

  String teksStatus(String status) {
    if (status == 'disetujui') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    return 'Menunggu';
  }

  Color warnaJatah(String statusJatah) {
    if (statusJatah == 'melebihi_jatah') return Colors.red;
    return primaryGreen;
  }

  String teksJatah(String statusJatah) {
    if (statusJatah == 'melebihi_jatah') return 'Melebihi Jatah';
    return 'Sesuai Jatah';
  }

  String ambilLahan(Map<String, dynamic> pupuk) {
    return (pupuk['luas_sawah'] ?? pupuk['jumlah_petak_sawah'] ?? '-')
        .toString();
  }

  List<MapEntry<String, dynamic>> filterData(
    List<MapEntry<String, dynamic>> data,
  ) {
    if (selectedFilter == 'semua') return data;

    return data.where((entry) {
      final item = Map<dynamic, dynamic>.from(entry.value as Map);
      final status = (item['status'] ?? 'menunggu').toString().toLowerCase();
      return status == selectedFilter;
    }).toList();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _filterStatus(),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: bantuanPupukRef.onValue,
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

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return _messageState(
                      icon: Icons.inbox_outlined,
                      title: 'Belum Ada Pengajuan',
                      message: 'Belum ada pengajuan bantuan pupuk.',
                    );
                  }

                  final rawData = snapshot.data!.snapshot.value;

                  if (rawData is! Map) {
                    return _messageState(
                      icon: Icons.warning_amber_rounded,
                      title: 'Format Data Salah',
                      message: 'Struktur data Firebase tidak sesuai.',
                    );
                  }

                  final data = Map<String, dynamic>.from(rawData);
                  final semuaData = data.entries.toList().reversed.toList();
                  final pupukList = filterData(semuaData);

                  if (pupukList.isEmpty) {
                    return _messageState(
                      icon: Icons.search_off_rounded,
                      title: 'Data Tidak Ditemukan',
                      message: 'Tidak ada pengajuan pupuk dengan status ini.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    itemCount: pupukList.length,
                    itemBuilder: (context, index) {
                      final id = pupukList[index].key.toString();
                      final pupuk = Map<String, dynamic>.from(
                        pupukList[index].value as Map,
                      );

                      return _pupukCard(id, pupuk);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
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
            right: -22,
            bottom: -38,
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
                  _backButton(),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Verifikasi Pupuk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Periksa dan setujui pengajuan bantuan pupuk dari anggota kelompok tani.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _backButton() {
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

  Widget _filterStatus() {
    final filters = [
      _FilterItem(label: 'Semua', value: 'semua'),
      _FilterItem(label: 'Menunggu', value: 'menunggu'),
      _FilterItem(label: 'Disetujui', value: 'disetujui'),
      _FilterItem(label: 'Ditolak', value: 'ditolak'),
    ];

    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final aktif = selectedFilter == item.value;

          return ChoiceChip(
            label: Text(item.label),
            selected: aktif,
            showCheckmark: false,
            backgroundColor: Colors.white,
            selectedColor: primaryGreen,
            labelStyle: TextStyle(
              color: aktif ? Colors.white : textGrey,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            side: BorderSide(
              color: aktif ? primaryGreen : const Color(0xffE5E7EB),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            onSelected: (_) {
              setState(() {
                selectedFilter = item.value;
              });
            },
          );
        },
      ),
    );
  }

  Widget _pupukCard(String id, Map<String, dynamic> pupuk) {
    final status = (pupuk['status'] ?? 'menunggu').toString().toLowerCase();
    final statusJatah = (pupuk['status_jatah'] ?? 'sesuai_jatah').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(pupuk, status),
          const SizedBox(height: 16),
          _infoBox(
            children: [
              _infoRow(Icons.badge_outlined, 'NIK', pupuk['nik'] ?? '-'),
              _infoRow(
                Icons.grass_rounded,
                'Jenis Pupuk',
                pupuk['jenis_pupuk'] ?? '-',
              ),
              _infoRow(
                Icons.landscape_rounded,
                'Luas Sawah',
                '${ambilLahan(pupuk)} Ha',
              ),
              _infoRow(
                Icons.scale_rounded,
                'Jatah Pupuk',
                '${pupuk['jatah_pupuk'] ?? '-'} Kg',
              ),
              _infoRow(
                Icons.inventory_2_rounded,
                'Diajukan',
                '${pupuk['jumlah_pupuk'] ?? '-'} Kg',
              ),
              _infoRow(Icons.notes_rounded, 'Catatan', pupuk['catatan'] ?? '-'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(
                teksStatus(status),
                warnaStatus(status),
                backgroundStatus(status),
              ),
              _badge(
                teksJatah(statusJatah),
                warnaJatah(statusJatah),
                warnaJatah(statusJatah).withValues(alpha: 0.12),
              ),
            ],
          ),
          if (status == 'menunggu') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    title: 'Tolak',
                    icon: Icons.close_rounded,
                    color: Colors.red,
                    onPressed: () {
                      tampilkanKonfirmasi(
                        id: id,
                        status: 'ditolak',
                        pupuk: pupuk,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    title: 'Setujui',
                    icon: Icons.check_rounded,
                    color: primaryGreen,
                    onPressed: () {
                      tampilkanKonfirmasi(
                        id: id,
                        status: 'disetujui',
                        pupuk: pupuk,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cardTop(Map<String, dynamic> pupuk, String status) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: primaryGreen,
            size: 28,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            (pupuk['nama'] ?? '-').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _badge(
          teksStatus(status),
          warnaStatus(status),
          backgroundStatus(status),
        ),
      ],
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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

class _FilterItem {
  final String label;
  final String value;

  const _FilterItem({required this.label, required this.value});
}
