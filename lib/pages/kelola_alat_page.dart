import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class KelolaAlatPage extends StatefulWidget {
  const KelolaAlatPage({super.key});

  @override
  State<KelolaAlatPage> createState() => _KelolaAlatPageState();
}

class _KelolaAlatPageState extends State<KelolaAlatPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color cardBorder = Color(0xffE6ECE8);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color redStatus = Color(0xffDC2626);

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController();

  final DatabaseReference _alatRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('alat_pertanian');

  @override
  void dispose() {
    _namaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _simpanAlat(String? id) async {
    final namaAlat = _namaController.text.trim();
    final jumlahUnit = int.tryParse(_jumlahController.text.trim()) ?? 0;

    if (namaAlat.isEmpty) {
      _showSnackBar('Nama alat wajib diisi', redStatus);
      return;
    }

    if (jumlahUnit <= 0) {
      _showSnackBar('Jumlah unit harus lebih dari 0', redStatus);
      return;
    }

    try {
      if (id == null) {
        await _alatRef
            .push()
            .set({
              'nama_alat': namaAlat,
              'jumlah_unit': jumlahUnit,
              'status': 'aktif',
              'tanggal_input': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 10));
      } else {
        await _alatRef
            .child(id)
            .update({
              'nama_alat': namaAlat,
              'jumlah_unit': jumlahUnit,
              'tanggal_update': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;

      _namaController.clear();
      _jumlahController.clear();
      Navigator.pop(context);

      _showSnackBar(
        id == null ? 'Alat berhasil ditambahkan' : 'Alat berhasil diperbarui',
        primaryGreen,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menyimpan alat: $e', redStatus);
    }
  }

  Future<void> _hapusAlat(String id) async {
    try {
      await _alatRef.child(id).remove().timeout(const Duration(seconds: 10));

      if (!mounted) return;
      _showSnackBar('Alat berhasil dihapus', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menghapus alat: $e', redStatus);
    }
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<MapEntry<String, dynamic>> _ambilAlatList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);
    final list = data.entries.toList();

    list.sort((a, b) {
      final alatA = Map<String, dynamic>.from(a.value as Map);
      final alatB = Map<String, dynamic>.from(b.value as Map);

      final dateA = _parseDate(
        alatA['tanggal_input'] ?? alatA['tanggal_update'],
      );
      final dateB = _parseDate(
        alatB['tanggal_input'] ?? alatB['tanggal_update'],
      );

      return dateB.compareTo(dateA);
    });

    return list;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    try {
      return DateTime.parse(value.toString().trim());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  int _hitungTotalUnit(List<MapEntry<String, dynamic>> list) {
    int total = 0;

    for (final entry in list) {
      final alat = Map<String, dynamic>.from(entry.value as Map);
      total += int.tryParse((alat['jumlah_unit'] ?? 0).toString()) ?? 0;
    }

    return total;
  }

  int _hitungAktif(List<MapEntry<String, dynamic>> list) {
    return list.where((entry) {
      final alat = Map<String, dynamic>.from(entry.value as Map);
      final status = (alat['status'] ?? 'aktif').toString().toLowerCase();
      return status == 'aktif';
    }).length;
  }

  IconData _iconAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return Icons.water_drop_outlined;
    if (alat.contains('cangkul')) return Icons.handyman_rounded;
    if (alat.contains('traktor')) return Icons.precision_manufacturing_rounded;

    return Icons.construction_rounded;
  }

  Color _warnaAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return blueStatus;
    if (alat.contains('cangkul')) return orangeStatus;
    if (alat.contains('traktor')) return primaryGreen;

    return primaryGreen;
  }

  String _formatTanggal(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return '-';

    try {
      final date = DateTime.parse(raw);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return raw;
    }
  }

  void _formAlat({String? id, Map<String, dynamic>? data}) {
    _namaController.text = (data?['nama_alat'] ?? '').toString();
    _jumlahController.text = (data?['jumlah_unit'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 14,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xffD1D5DB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _iconBox(
                      id == null
                          ? Icons.add_task_rounded
                          : Icons.edit_note_rounded,
                      primaryGreen,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        id == null ? 'Tambah Alat' : 'Edit Alat',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Lengkapi data alat pertanian yang digunakan untuk peminjaman anggota.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _namaController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Nama Alat',
                    icon: Icons.precision_manufacturing_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'Jumlah Unit',
                    icon: Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(height: 14),
                _bottomSheetInfo(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textGrey,
                          side: const BorderSide(color: cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          _namaController.clear();
                          _jumlahController.clear();
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
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _simpanAlat(id),
                        icon: const Icon(Icons.save_as_rounded, size: 18),
                        label: const Text(
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

  void _konfirmasiHapus(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hapus Alat?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Data alat ini akan dihapus dari Firebase. Tindakan ini tidak dapat dibatalkan.',
            style: TextStyle(
              color: textGrey,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: redStatus,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _hapusAlat(id);
              },
              icon: const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text(
                'Hapus',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bottomSheetInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.065),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, color: primaryGreen, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Jumlah unit digunakan sebagai stok dasar untuk proses peminjaman alat.',
              style: TextStyle(
                color: textGrey,
                fontSize: 11.6,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _formAlat(),
        icon: const Icon(Icons.add_task_rounded, size: 19),
        label: const Text(
          'Tambah',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: _alatRef.onValue,
          builder: (context, snapshot) {
            final alatList = _ambilAlatList(snapshot.data?.snapshot.value);
            final totalUnit = _hitungTotalUnit(alatList);
            final alatAktif = _hitungAktif(alatList);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
              children: [
                _header(alatList.length),
                const SizedBox(height: 16),
                _summaryGrid(
                  totalJenis: alatList.length,
                  alatAktif: alatAktif,
                  totalUnit: totalUnit,
                ),
                const SizedBox(height: 16),
                _stockPanel(totalUnit: totalUnit, alatAktif: alatAktif),
                const SizedBox(height: 18),
                _sectionTitle(
                  title: 'Daftar Alat',
                  subtitle: 'Kelola nama alat dan jumlah unit',
                ),
                const SizedBox(height: 12),
                _buildContent(snapshot, alatList),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> snapshot,
    List<MapEntry<String, dynamic>> alatList,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(children: List.generate(3, (_) => _loadingCard()));
    }

    if (snapshot.hasError) {
      return _messageState(
        icon: Icons.fact_check_rounded,
        title: 'Terjadi Kesalahan',
        message: snapshot.error.toString(),
      );
    }

    if (alatList.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_rounded,
        title: 'Belum Ada Data Alat',
        message: 'Tekan tombol tambah untuk memasukkan data alat pertanian.',
      );
    }

    return Column(
      children:
          alatList.map((entry) {
            final id = entry.key.toString();
            final alat = Map<String, dynamic>.from(entry.value as Map);

            return _alatCard(id, alat);
          }).toList(),
    );
  }

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [darkGreen, primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.precision_manufacturing_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kelola Alat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Data alat untuk peminjaman anggota',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xffDDEFE3),
                    fontSize: 11.8,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _headerCounter(total),
        ],
      ),
    );
  }

  Widget _headerCounter(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fact_check_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryGrid({
    required int totalJenis,
    required int alatAktif,
    required int totalUnit,
  }) {
    final items = [
      _SummaryItem(
        title: 'Jenis Alat',
        value: totalJenis,
        icon: Icons.category_rounded,
        color: primaryGreen,
      ),
      _SummaryItem(
        title: 'Aktif',
        value: alatAktif,
        icon: Icons.verified_user_rounded,
        color: blueStatus,
      ),
      _SummaryItem(
        title: 'Unit Tersedia',
        value: totalUnit,
        icon: Icons.inventory_2_rounded,
        color: orangeStatus,
      ),
    ];

    return Row(
      children: [
        Expanded(child: _summaryCard(items[0])),
        const SizedBox(width: 9),
        Expanded(child: _summaryCard(items[1])),
        const SizedBox(width: 9),
        Expanded(child: _summaryCard(items[2])),
      ],
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.022),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 15, color: item.color),
          const Spacer(),
          Text(
            item.value.toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: item.color,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textGrey,
              fontSize: 9.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockPanel({required int totalUnit, required int alatAktif}) {
    final aman = totalUnit > 0 && alatAktif > 0;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          _iconBox(
            aman ? Icons.task_alt_rounded : Icons.info_rounded,
            aman ? primaryGreen : orangeStatus,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aman ? 'Stok alat siap digunakan' : 'Stok alat belum siap',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  aman
                      ? '$totalUnit unit dari $alatAktif jenis alat aktif tersedia untuk peminjaman.'
                      : 'Tambahkan alat aktif agar anggota dapat mengajukan peminjaman.',
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

  Widget _alatCard(String id, Map<String, dynamic> alat) {
    final namaAlat = (alat['nama_alat'] ?? '-').toString();
    final jumlahUnit = int.tryParse((alat['jumlah_unit'] ?? 0).toString()) ?? 0;
    final status = (alat['status'] ?? 'aktif').toString();
    final icon = _iconAlat(namaAlat);
    final color = _warnaAlat(namaAlat);
    final tanggal = _formatTanggal(
      alat['tanggal_update'] ?? alat['tanggal_input'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        children: [
          Row(
            children: [
              _alatIconBox(icon, color),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaAlat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Diperbarui: $tanggal',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniInfo(
                icon: Icons.inventory_2_rounded,
                text: '$jumlahUnit unit',
                color: color,
              ),
              const SizedBox(width: 7),
              _miniInfo(
                icon: Icons.verified_user_rounded,
                text: status.toLowerCase() == 'aktif' ? 'Aktif' : 'Nonaktif',
                color:
                    status.toLowerCase() == 'aktif' ? primaryGreen : redStatus,
              ),
              const Spacer(),
              _smallAction(
                icon: Icons.edit_note_rounded,
                color: orangeStatus,
                onTap: () => _formAlat(id: id, data: alat),
              ),
              const SizedBox(width: 7),
              _smallAction(
                icon: Icons.delete_forever_rounded,
                color: redStatus,
                onTap: () => _konfirmasiHapus(id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _alatIconBox(IconData icon, Color color) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.11)),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }

  Widget _miniInfo({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 31,
        width: 31,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.11)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final aktif = status.toLowerCase() == 'aktif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: (aktif ? primaryGreen : redStatus).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (aktif ? primaryGreen : redStatus).withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        aktif ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          color: aktif ? primaryGreen : redStatus,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 20),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  height: 11,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: primaryGreen, size: 34),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
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

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          height: 30,
          width: 4,
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
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 17,
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey, fontSize: 12.5),
      prefixIcon: Icon(icon, color: primaryGreen, size: 19),
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryGreen, width: 1.4),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.026),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
