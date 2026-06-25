import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class KelolaPupukPage extends StatefulWidget {
  const KelolaPupukPage({super.key});

  @override
  State<KelolaPupukPage> createState() => _KelolaPupukPageState();
}

class _KelolaPupukPageState extends State<KelolaPupukPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF4F7F4);
  static const Color softGreen = Color(0xffE8F5E9);
  static const Color cardBorder = Color(0xffE5E7EB);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffF57C00);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color redStatus = Color(0xffDC2626);

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();

  final DatabaseReference _pupukRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('pupuk');

  bool _isSaving = false;

  @override
  void dispose() {
    _namaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  IconData _iconPupuk(String nama) {
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

  Color _warnaPupuk(String nama) {
    final value = nama.toLowerCase();

    if (value.contains('urea')) return blueStatus;
    if (value.contains('npk')) return orangeStatus;
    if (value.contains('organik')) return primaryGreen;
    if (value.contains('kompos')) return primaryGreen;

    return primaryGreen;
  }

  Color _warnaStok(int stok) {
    if (stok <= 0) return redStatus;
    if (stok <= 10) return orangeStatus;
    return primaryGreen;
  }

  Future<void> _refreshData() async {
    await _pupukRef.get();
  }

  Future<void> _simpanPupuk(String? id) async {
    if (_isSaving) return;

    final nama = _namaController.text.trim();
    final stok = int.tryParse(_stokController.text.trim()) ?? 0;

    if (nama.isEmpty) {
      _showSnackBar('Nama pupuk wajib diisi', redStatus);
      return;
    }

    if (stok < 0) {
      _showSnackBar('Stok pupuk tidak boleh kurang dari 0', redStatus);
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (id == null) {
        await _pupukRef
            .push()
            .set({
              'nama_pupuk': nama,
              'stok': stok,
              'status': 'aktif',
              'tanggal_input': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 10));
      } else {
        await _pupukRef
            .child(id)
            .update({
              'nama_pupuk': nama,
              'stok': stok,
              'tanggal_update': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;

      _namaController.clear();
      _stokController.clear();
      Navigator.pop(context);

      _showSnackBar(
        id == null ? 'Pupuk berhasil ditambahkan' : 'Pupuk berhasil diperbarui',
        primaryGreen,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menyimpan pupuk: $e', redStatus);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _hapusPupuk(String id) async {
    try {
      await _pupukRef.child(id).remove().timeout(const Duration(seconds: 10));

      if (!mounted) return;
      _showSnackBar('Data pupuk berhasil dihapus', primaryGreen);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal menghapus pupuk: $e', redStatus);
    }
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pesan,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  List<MapEntry<String, dynamic>> _ambilPupukList(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<String, dynamic>.from(value);
    final list = data.entries.toList();

    list.sort((a, b) {
      final pupukA = Map<String, dynamic>.from(a.value as Map);
      final pupukB = Map<String, dynamic>.from(b.value as Map);

      final dateA = _parseDate(
        pupukA['tanggal_input'] ?? pupukA['tanggal_update'],
      );
      final dateB = _parseDate(
        pupukB['tanggal_input'] ?? pupukB['tanggal_update'],
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

  int _hitungTotalStok(List<MapEntry<String, dynamic>> list) {
    int total = 0;

    for (final entry in list) {
      final pupuk = Map<String, dynamic>.from(entry.value as Map);
      total += int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
    }

    return total;
  }

  int _hitungAktif(List<MapEntry<String, dynamic>> list) {
    return list.where((entry) {
      final pupuk = Map<String, dynamic>.from(entry.value as Map);
      final status = (pupuk['status'] ?? 'aktif').toString().toLowerCase();
      return status == 'aktif';
    }).length;
  }

  int _hitungStokRendah(List<MapEntry<String, dynamic>> list) {
    return list.where((entry) {
      final pupuk = Map<String, dynamic>.from(entry.value as Map);
      final stok = int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
      return stok > 0 && stok <= 10;
    }).length;
  }

  int _hitungStokKosong(List<MapEntry<String, dynamic>> list) {
    return list.where((entry) {
      final pupuk = Map<String, dynamic>.from(entry.value as Map);
      final stok = int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
      return stok <= 0;
    }).length;
  }

  void _formPupuk({String? id, Map<String, dynamic>? data}) {
    _namaController.text = (data?['nama_pupuk'] ?? '').toString();
    _stokController.text = (data?['stok'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
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
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: primaryGreen.withValues(alpha: 0.11),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: primaryGreen,
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              id == null ? 'Tambah Pupuk' : 'Edit Pupuk',
                              style: const TextStyle(
                                color: textDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lengkapi data pupuk yang digunakan untuk pengajuan bantuan anggota.',
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
                          label: 'Nama Pupuk',
                          icon: Icons.grass_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _stokController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Stok Pupuk (Kg)',
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed:
                                  _isSaving
                                      ? null
                                      : () {
                                        _namaController.clear();
                                        _stokController.clear();
                                        Navigator.pop(sheetContext);
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
                                disabledBackgroundColor: primaryGreen
                                    .withValues(alpha: 0.45),
                                disabledForegroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed:
                                  _isSaving
                                      ? null
                                      : () async {
                                        setSheetState(() {});
                                        await _simpanPupuk(id);
                                      },
                              icon:
                                  _isSaving
                                      ? const SizedBox(
                                        height: 17,
                                        width: 17,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.save_rounded,
                                        size: 18,
                                      ),
                              label: Text(
                                _isSaving ? 'Menyimpan' : 'Simpan',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (!mounted) return;
      if (!_isSaving) {
        _namaController.clear();
        _stokController.clear();
      }
    });
  }

  Widget _bottomSheetInfo() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 21),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Stok pupuk akan otomatis berkurang ketika admin menandai bantuan sebagai sudah diambil.',
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

  Future<void> _konfirmasiHapus(String id, String namaPupuk) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: redStatus.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: redStatus,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hapus Pupuk?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Data pupuk $namaPupuk akan dihapus dari Firebase. Tindakan ini tidak dapat dibatalkan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, false),
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
                          backgroundColor: redStatus,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: const Icon(Icons.delete_rounded, size: 18),
                        label: const Text(
                          'Hapus',
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

    if (!mounted) return;

    if (hasil == true) {
      await _hapusPupuk(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => _formPupuk(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Pupuk',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: _pupukRef.onValue,
            builder: (context, snapshot) {
              final pupukList = _ambilPupukList(snapshot.data?.snapshot.value);
              final totalStok = _hitungTotalStok(pupukList);
              final pupukAktif = _hitungAktif(pupukList);
              final stokRendah = _hitungStokRendah(pupukList);
              final stokKosong = _hitungStokKosong(pupukList);

              return RefreshIndicator(
                color: primaryGreen,
                backgroundColor: Colors.white,
                onRefresh: _refreshData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: [
                    _header(pupukList.length),
                    const SizedBox(height: 16),
                    _sectionTitle(
                      title: 'Ringkasan Pupuk',
                      subtitle: 'Pantauan stok dan jenis pupuk yang tersedia',
                      horizontalPadding: 16,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _summaryGrid(
                        totalJenis: pupukList.length,
                        pupukAktif: pupukAktif,
                        totalStok: totalStok,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _infoPanel(
                        stokRendah: stokRendah,
                        stokKosong: stokKosong,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle(
                      title: 'Daftar Pupuk',
                      subtitle: 'Kelola nama pupuk dan jumlah stok',
                      horizontalPadding: 16,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: _buildContent(snapshot, pupukList),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> snapshot,
    List<MapEntry<String, dynamic>> pupukList,
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

    if (pupukList.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Data Pupuk',
        message: 'Tekan tombol tambah untuk memasukkan data pupuk.',
      );
    }

    return Column(
      children:
          pupukList.map((entry) {
            final id = entry.key.toString();
            final pupuk = Map<String, dynamic>.from(entry.value as Map);

            return _pupukCard(id, pupuk);
          }).toList(),
    );
  }

  Widget _header(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [darkGreen, primaryGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: darkGreen.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
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
                    'Kelola Pupuk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Atur data stok pupuk untuk bantuan anggota',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
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
      ),
    );
  }

  Widget _headerCounter(int total) {
    return Container(
      constraints: const BoxConstraints(minWidth: 54, minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
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
            'pupuk',
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
    required int pupukAktif,
    required int totalStok,
  }) {
    final items = [
      _SummaryItem(
        title: 'Jenis Pupuk',
        value: totalJenis.toString(),
        icon: Icons.grass_rounded,
        color: primaryGreen,
      ),
      _SummaryItem(
        title: 'Pupuk Aktif',
        value: pupukAktif.toString(),
        icon: Icons.check_circle_rounded,
        color: blueStatus,
      ),
      _SummaryItem(
        title: 'Total Stok',
        value: '$totalStok Kg',
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
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: item.color, size: 23),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _infoPanel({required int stokRendah, required int stokKosong}) {
    final hasWarning = stokRendah > 0 || stokKosong > 0;

    String message;
    if (stokKosong > 0) {
      message =
          '$stokKosong jenis pupuk stoknya kosong. Segera lakukan pembaruan stok agar data bantuan tetap akurat.';
    } else if (stokRendah > 0) {
      message =
          '$stokRendah jenis pupuk memiliki stok terbatas. Segera lakukan pengecekan stok.';
    } else {
      message =
          'Stok pupuk akan otomatis berkurang saat admin menandai bantuan sebagai sudah diambil.';
    }

    final color = hasWarning ? orangeStatus : primaryGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasWarning
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
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

  Widget _pupukCard(String id, Map<String, dynamic> pupuk) {
    final namaPupuk = (pupuk['nama_pupuk'] ?? '-').toString();
    final stok = int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
    final status = (pupuk['status'] ?? 'aktif').toString();
    final color = _warnaPupuk(namaPupuk);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconPupuk(namaPupuk), color: color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  namaPupuk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15.5,
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
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _detailMini(
                    icon: Icons.inventory_2_rounded,
                    label: 'Stok',
                    value: '$stok Kg',
                    color: _warnaStok(stok),
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
                  onTap: () => _formPupuk(id: id, data: pupuk),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  icon: Icons.delete_rounded,
                  label: 'Hapus',
                  color: redStatus,
                  onTap: () => _konfirmasiHapus(id, namaPupuk),
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
          textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (aktif ? primaryGreen : redStatus).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (aktif ? primaryGreen : redStatus).withValues(alpha: 0.16),
        ),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(16),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              color: softGreen,
              shape: BoxShape.circle,
              border: Border.all(color: primaryGreen.withValues(alpha: 0.12)),
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cardBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.035),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
