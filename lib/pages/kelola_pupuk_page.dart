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
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color cardBorder = Color(0xffE6ECE8);
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

    if (value.contains('urea')) return Icons.water_drop_outlined;
    if (value.contains('npk')) return Icons.scatter_plot_rounded;
    if (value.contains('organik')) return Icons.nature_rounded;
    if (value.contains('kandang')) return Icons.yard_rounded;
    if (value.contains('kompos')) return Icons.compost_rounded;
    if (value.contains('za')) return Icons.science_rounded;
    if (value.contains('sp')) return Icons.bubble_chart_rounded;
    if (value.contains('kcl')) return Icons.inventory_2_rounded;
    if (value.contains('dolomit')) return Icons.terrain_rounded;
    if (value.contains('hayati')) return Icons.spa_rounded;

    return Icons.inventory_2_rounded;
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
                child: SingleChildScrollView(
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
                              id == null ? 'Tambah Pupuk' : 'Edit Pupuk',
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
                        'Lengkapi data pupuk untuk kebutuhan bantuan anggota.',
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
                          label: 'Nama Pupuk',
                          icon: Icons.inventory_2_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _stokController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Stok Pupuk (Kg)',
                          icon: Icons.dataset_rounded,
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
                                        Icons.save_as_rounded,
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
              'Stok pupuk otomatis berkurang saat bantuan ditandai sudah diambil.',
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

  Future<void> _konfirmasiHapus(String id, String namaPupuk) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
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
                        icon: const Icon(
                          Icons.delete_forever_rounded,
                          size: 18,
                        ),
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
        elevation: 2,
        onPressed: () => _formPupuk(),
        icon: const Icon(Icons.add_task_rounded, size: 19),
        label: const Text(
          'Tambah',
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
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
                  children: [
                    _header(pupukList.length),
                    const SizedBox(height: 16),
                    _summaryGrid(
                      totalJenis: pupukList.length,
                      pupukAktif: pupukAktif,
                      totalStok: totalStok,
                    ),
                    const SizedBox(height: 16),
                    _stockPanel(
                      totalStok: totalStok,
                      pupukAktif: pupukAktif,
                      stokRendah: stokRendah,
                      stokKosong: stokKosong,
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle(
                      title: 'Daftar Pupuk',
                      subtitle: 'Kelola nama pupuk dan jumlah stok',
                    ),
                    const SizedBox(height: 12),
                    _buildContent(snapshot, pupukList),
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
        icon: Icons.fact_check_rounded,
        title: 'Terjadi Kesalahan',
        message: snapshot.error.toString(),
      );
    }

    if (pupukList.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_rounded,
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
              Icons.inventory_2_rounded,
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
                  'Kelola Pupuk',
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
                  'Data stok pupuk untuk bantuan anggota',
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
    required int pupukAktif,
    required int totalStok,
  }) {
    final items = [
      _SummaryItem(
        title: 'Jenis Pupuk',
        value: totalJenis.toString(),
        icon: Icons.category_rounded,
        color: primaryGreen,
      ),
      _SummaryItem(
        title: 'Aktif',
        value: pupukAktif.toString(),
        icon: Icons.verified_user_rounded,
        color: blueStatus,
      ),
      _SummaryItem(
        title: 'Stok Tersedia',
        value: totalStok.toString(),
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
            item.value,
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

  Widget _stockPanel({
    required int totalStok,
    required int pupukAktif,
    required int stokRendah,
    required int stokKosong,
  }) {
    final hasWarning = stokRendah > 0 || stokKosong > 0;
    final aman = totalStok > 0 && pupukAktif > 0 && !hasWarning;
    final color = hasWarning ? orangeStatus : primaryGreen;

    String title;
    String message;

    if (stokKosong > 0) {
      title = 'Stok pupuk perlu diperbarui';
      message =
          '$stokKosong jenis pupuk kosong. Segera perbarui stok agar data bantuan tetap akurat.';
    } else if (stokRendah > 0) {
      title = 'Stok pupuk mulai terbatas';
      message =
          '$stokRendah jenis pupuk memiliki stok rendah. Lakukan pengecekan sebelum bantuan disetujui.';
    } else if (aman) {
      title = 'Stok pupuk siap digunakan';
      message =
          '$totalStok kg dari $pupukAktif jenis pupuk aktif tersedia untuk bantuan anggota.';
    } else {
      title = 'Stok pupuk belum siap';
      message =
          'Tambahkan data pupuk aktif agar pengajuan bantuan bisa diproses.';
    }

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          _iconBox(
            hasWarning
                ? Icons.warning_amber_rounded
                : aman
                ? Icons.task_alt_rounded
                : Icons.info_rounded,
            color,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
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

  Widget _pupukCard(String id, Map<String, dynamic> pupuk) {
    final namaPupuk = (pupuk['nama_pupuk'] ?? '-').toString();
    final stok = int.tryParse((pupuk['stok'] ?? 0).toString()) ?? 0;
    final status = (pupuk['status'] ?? 'aktif').toString();
    final color = _warnaPupuk(namaPupuk);
    final tanggal = _formatTanggal(
      pupuk['tanggal_update'] ?? pupuk['tanggal_input'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        children: [
          Row(
            children: [
              _pupukIconBox(_iconPupuk(namaPupuk), color),
              const SizedBox(width: 11),
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
                text: '$stok kg',
                color: _warnaStok(stok),
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
                onTap: () => _formPupuk(id: id, data: pupuk),
              ),
              const SizedBox(width: 7),
              _smallAction(
                icon: Icons.delete_forever_rounded,
                color: redStatus,
                onTap: () => _konfirmasiHapus(id, namaPupuk),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pupukIconBox(IconData icon, Color color) {
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
