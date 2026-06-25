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
  static const Color bgColor = Color(0xffF4F7F4);
  static const Color cardBorder = Color(0xffE5E7EB);
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

    if (alat.contains('sprayer')) return Icons.water_drop_rounded;
    if (alat.contains('cangkul')) return Icons.construction_rounded;
    if (alat.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  Color _warnaAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return blueStatus;
    if (alat.contains('cangkul')) return orangeStatus;
    if (alat.contains('traktor')) return primaryGreen;

    return primaryGreen;
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
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
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
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xffD1D5DB),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: primaryGreen.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.agriculture_rounded,
                        color: primaryGreen,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        id == null ? 'Tambah Alat' : 'Edit Alat',
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lengkapi data alat pertanian yang digunakan untuk peminjaman anggota.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _namaController,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    label: 'Nama Alat',
                    icon: Icons.agriculture_rounded,
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textGrey,
                          side: const BorderSide(color: cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
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
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        onPressed: () => _simpanAlat(id),
                        icon: const Icon(Icons.save_rounded, size: 18),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
              child: const Text('Batal'),
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
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Widget _bottomSheetInfo() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 21),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Jumlah unit menjadi stok dasar. Ketersediaan alat akan digunakan pada fitur peminjaman.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12,
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
        elevation: 3,
        onPressed: () => _formAlat(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Alat',
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
              padding: EdgeInsets.zero,
              children: [
                _header(alatList.length),
                const SizedBox(height: 16),
                _sectionTitle(
                  title: 'Ringkasan Alat',
                  subtitle: 'Pantauan data alat pertanian yang tersedia',
                  horizontalPadding: 16,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _summaryGrid(
                    totalJenis: alatList.length,
                    alatAktif: alatAktif,
                    totalUnit: totalUnit,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _infoPanel(),
                ),
                const SizedBox(height: 18),
                _sectionTitle(
                  title: 'Daftar Alat',
                  subtitle: 'Kelola nama alat dan jumlah unit',
                  horizontalPadding: 16,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: _buildContent(snapshot, alatList),
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
    List<MapEntry<String, dynamic>> alatList,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(children: List.generate(3, (_) => _loadingCard()));
    }

    if (snapshot.hasError) {
      return _messageState(
        icon: Icons.error_outline_rounded,
        title: 'Terjadi Kesalahan',
        message: snapshot.error.toString(),
      );
    }

    if (alatList.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola Alat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Atur data alat pertanian untuk peminjaman',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _headerCounter(total),
        ],
      ),
    );
  }

  Widget _headerCounter(int total) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52, minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'alat',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
        icon: Icons.handyman_rounded,
        color: primaryGreen,
      ),
      _SummaryItem(
        title: 'Alat Aktif',
        value: alatAktif,
        icon: Icons.check_circle_rounded,
        color: blueStatus,
      ),
      _SummaryItem(
        title: 'Total Unit',
        value: totalUnit,
        icon: Icons.inventory_2_rounded,
        color: orangeStatus,
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard(items[0])),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard(items[1])),
          ],
        ),
        const SizedBox(height: 10),
        _summaryCard(items[2]),
      ],
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    return Container(
      height: 92,
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value.toString(),
                  style: TextStyle(
                    color: item.color,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
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

  Widget _infoPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data alat ini terhubung ke halaman peminjaman dan jadwal alat. Jumlah unit menjadi stok dasar alat.',
              style: TextStyle(
                color: textGrey,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  namaAlat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffF9FAFB),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _detailMini(
                    icon: Icons.inventory_2_rounded,
                    label: 'Jumlah Unit',
                    value: jumlahUnit.toString(),
                    color: color,
                  ),
                ),
                Container(width: 1, height: 40, color: cardBorder),
                Expanded(
                  child: _detailMini(
                    icon: Icons.verified_rounded,
                    label: 'Status',
                    value:
                        status.toLowerCase() == 'aktif' ? 'Aktif' : 'Nonaktif',
                    color:
                        status.toLowerCase() == 'aktif'
                            ? primaryGreen
                            : redStatus,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit',
                  color: orangeStatus,
                  onTap: () => _formAlat(id: id, data: alat),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  icon: Icons.delete_rounded,
                  label: 'Hapus',
                  color: redStatus,
                  onTap: () => _konfirmasiHapus(id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailMini({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: textGrey,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final aktif = status.toLowerCase() == 'aktif';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: (aktif ? primaryGreen : redStatus).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        aktif ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          color: aktif ? primaryGreen : redStatus,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.13)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              shape: BoxShape.circle,
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
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String subtitle,
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
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
                    fontSize: 16.5,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 9,
          offset: const Offset(0, 3),
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
