import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';

class KelolaPengumumanPage extends StatefulWidget {
  const KelolaPengumumanPage({super.key});

  @override
  State<KelolaPengumumanPage> createState() => _KelolaPengumumanPageState();
}

class _KelolaPengumumanPageState extends State<KelolaPengumumanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color cardBorder = Color(0xffE6ECE8);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color redColor = Color(0xffDC2626);
  static const Color orangeColor = Color(0xffF57C00);
  static const Color blueColor = Color(0xff2563EB);
  static const Color purpleColor = Color(0xff7C3AED);

  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference _pengumumanRef;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pengumumanRef = _db.ref('pengumuman');
  }

  List<Map<String, dynamic>> _getAnnouncements(dynamic value) {
    if (value == null || value is! Map) return [];

    final data = Map<dynamic, dynamic>.from(value);

    final list =
        data.entries.where((entry) => entry.value is Map).map((entry) {
          final item = Map<String, dynamic>.from(entry.value as Map);
          item['id'] = entry.key.toString();
          return item;
        }).toList();

    list.sort((a, b) => _timeValue(b).compareTo(_timeValue(a)));
    return list;
  }

  int _timeValue(Map<String, dynamic> item) {
    final raw =
        item['created_at'] ??
        item['createdAt'] ??
        item['tanggal'] ??
        item['tgl'];

    if (raw is int) return raw;
    if (raw is double) return raw.toInt();

    final parsed = DateTime.tryParse((raw ?? '').toString().trim());
    return parsed?.millisecondsSinceEpoch ?? 0;
  }

  String _todayText() {
    final now = DateTime.now();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  int _countStatus(List<Map<String, dynamic>> data, String status) {
    return data.where((item) {
      return (item['status'] ?? '').toString().toLowerCase().trim() == status;
    }).length;
  }

  Future<void> _saveAnnouncement({
    String? id,
    required String title,
    required String body,
    required String status,
    required String category,
  }) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final cleanTitle = title.trim();
      final cleanBody = body.trim();
      final cleanCategory = category.trim();

      if (id == null) {
        await _pengumumanRef
            .push()
            .set({
              'judul': cleanTitle,
              'isi': cleanBody,
              'kategori': cleanCategory,
              'tanggal': _todayText(),
              'status': status,
              'created_at': DateTime.now().millisecondsSinceEpoch,
            })
            .timeout(const Duration(seconds: 10));

        if (status == 'aktif') {
          unawaited(
            NotificationHelper.pengumumanUntukSemuaAnggota(
              judul: cleanTitle,
              isi: cleanBody,
            ),
          );
        }
      } else {
        await _pengumumanRef
            .child(id)
            .update({
              'judul': cleanTitle,
              'isi': cleanBody,
              'kategori': cleanCategory,
              'status': status,
              'tanggal_update': DateTime.now().toIso8601String(),
            })
            .timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;

      _showSnack(
        id == null
            ? 'Pengumuman berhasil ditambahkan.'
            : 'Pengumuman berhasil diperbarui.',
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan pengumuman.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _toggleStatus(String id, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'aktif' ? 'nonaktif' : 'aktif';

      await _pengumumanRef
          .child(id)
          .update({
            'status': newStatus,
            'tanggal_update': DateTime.now().toIso8601String(),
          })
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      _showSnack('Status pengumuman berhasil diperbarui.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal memperbarui status pengumuman.');
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await _pengumumanRef
          .child(id)
          .remove()
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      _showSnack('Pengumuman berhasil dihapus.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menghapus pengumuman.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return 'Info Pupuk';
    if (clean == 'alat') return 'Info Alat';
    if (clean == 'rapat') return 'Rapat';
    if (clean == 'panen') return 'Panen';
    if (clean == 'gotong_royong') return 'Gotong Royong';

    return 'Umum';
  }

  IconData _categoryIcon(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return Icons.inventory_2_rounded;
    if (clean == 'alat') return Icons.precision_manufacturing_rounded;
    if (clean == 'rapat') return Icons.diversity_3_rounded;
    if (clean == 'panen') return Icons.yard_rounded;
    if (clean == 'gotong_royong') return Icons.handshake_rounded;

    return Icons.campaign_rounded;
  }

  Color _categoryColor(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return primaryGreen;
    if (clean == 'alat') return orangeColor;
    if (clean == 'rapat') return blueColor;
    if (clean == 'panen') return darkGreen;
    if (clean == 'gotong_royong') return purpleColor;

    return primaryGreen;
  }

  String _previewSubtitle(int aktif, int total) {
    if (total == 0) {
      return 'Belum ada pengumuman. Tambahkan info agar anggota tertarik membuka halaman pengumuman.';
    }

    if (aktif == 0) {
      return 'Belum ada pengumuman aktif. Aktifkan informasi penting agar tampil di halaman anggota.';
    }

    return '$aktif pengumuman aktif sedang tampil untuk anggota.';
  }

  void _openForm({Map<String, dynamic>? item}) {
    final titleController = TextEditingController(
      text: item?['judul']?.toString() ?? '',
    );
    final bodyController = TextEditingController(
      text: item?['isi']?.toString() ?? '',
    );

    String status = item?['status']?.toString() ?? 'aktif';
    String category = item?['kategori']?.toString() ?? 'umum';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                            item == null
                                ? Icons.add_task_rounded
                                : Icons.edit_note_rounded,
                            primaryGreen,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              item == null
                                  ? 'Tambah Pengumuman'
                                  : 'Edit Pengumuman',
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
                        'Buat informasi yang jelas, singkat, dan menarik agar anggota mau membaca.',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _promoPreview(
                        title:
                            titleController.text.trim().isEmpty
                                ? 'Judul Pengumuman'
                                : titleController.text.trim(),
                        body:
                            bodyController.text.trim().isEmpty
                                ? 'Isi singkat pengumuman akan tampil di sini sebagai pratinjau untuk anggota.'
                                : bodyController.text.trim(),
                        category: category,
                        compact: true,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        controller: titleController,
                        label: 'Judul Pengumuman',
                        hint: 'Contoh: Jadwal Pembagian Pupuk',
                        icon: Icons.title_rounded,
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _inputField(
                        controller: bodyController,
                        label: 'Isi Pengumuman',
                        hint: 'Tulis isi pengumuman yang singkat dan jelas...',
                        icon: Icons.notes_rounded,
                        maxLines: 5,
                        onChanged: (_) => setModalState(() {}),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _categoryOption(
                            value: 'umum',
                            selected: category,
                            onTap: () {
                              setModalState(() => category = 'umum');
                            },
                          ),
                          _categoryOption(
                            value: 'pupuk',
                            selected: category,
                            onTap: () {
                              setModalState(() => category = 'pupuk');
                            },
                          ),
                          _categoryOption(
                            value: 'alat',
                            selected: category,
                            onTap: () {
                              setModalState(() => category = 'alat');
                            },
                          ),
                          _categoryOption(
                            value: 'rapat',
                            selected: category,
                            onTap: () {
                              setModalState(() => category = 'rapat');
                            },
                          ),
                          _categoryOption(
                            value: 'panen',
                            selected: category,
                            onTap: () {
                              setModalState(() => category = 'panen');
                            },
                          ),
                          _categoryOption(
                            value: 'gotong_royong',
                            selected: category,
                            onTap: () {
                              setModalState(() => category = 'gotong_royong');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _statusOption(
                              title: 'Aktif',
                              selected: status == 'aktif',
                              color: primaryGreen,
                              icon: Icons.visibility_rounded,
                              onTap: () {
                                setModalState(() => status = 'aktif');
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _statusOption(
                              title: 'Nonaktif',
                              selected: status == 'nonaktif',
                              color: orangeColor,
                              icon: Icons.visibility_off_rounded,
                              onTap: () {
                                setModalState(() => status = 'nonaktif');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed:
                              _isProcessing
                                  ? null
                                  : () async {
                                    if (titleController.text.trim().isEmpty ||
                                        bodyController.text.trim().isEmpty) {
                                      _showSnack('Judul dan isi wajib diisi.');
                                      return;
                                    }

                                    final navigator = Navigator.of(context);

                                    await _saveAnnouncement(
                                      id: item?['id']?.toString(),
                                      title: titleController.text,
                                      body: bodyController.text,
                                      status: status,
                                      category: category,
                                    );

                                    if (!mounted) return;
                                    navigator.pop();
                                  },
                          icon:
                              _isProcessing
                                  ? const SizedBox(
                                    height: 17,
                                    width: 17,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.save_as_rounded, size: 18),
                          label: Text(
                            _isProcessing
                                ? 'Menyimpan...'
                                : item == null
                                ? 'Simpan Pengumuman'
                                : 'Update Pengumuman',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
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
      titleController.dispose();
      bodyController.dispose();
    });
  }

  Widget _categoryOption({
    required String value,
    required String selected,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selected;
    final color = _categoryColor(value);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.10) : bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.65) : cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_categoryIcon(value), size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              _categoryLabel(value),
              style: TextStyle(
                color: isSelected ? color : textGrey,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryGreen, size: 19),
        filled: true,
        fillColor: const Color(0xffF9FAFB),
        labelStyle: const TextStyle(
          color: textGrey,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: const TextStyle(
          color: textGrey,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.4),
        ),
      ),
    );
  }

  Widget _statusOption({
    required String title,
    required bool selected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.65) : cardBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : textGrey, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: selected ? color : textGrey,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Hapus Pengumuman?',
            style: TextStyle(color: textDark, fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Data pengumuman yang dihapus tidak dapat dikembalikan.',
            style: TextStyle(
              color: textGrey,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteAnnouncement(id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_task_rounded, size: 19),
        label: const Text(
          'Tambah',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: _pengumumanRef.onValue,
          builder: (context, snapshot) {
            final list = _getAnnouncements(snapshot.data?.snapshot.value);
            final aktif = _countStatus(list, 'aktif');
            final nonaktif = _countStatus(list, 'nonaktif');

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 100),
              children: [
                _header(list.length),
                const SizedBox(height: 16),
                _highlightPanel(total: list.length, aktif: aktif),
                const SizedBox(height: 14),
                _summaryGrid(
                  total: list.length,
                  aktif: aktif,
                  nonaktif: nonaktif,
                ),
                const SizedBox(height: 16),
                _infoPanel(aktif: aktif, total: list.length),
                const SizedBox(height: 18),
                _sectionTitle(
                  title: 'Daftar Pengumuman',
                  subtitle: 'Kelola informasi yang dibaca anggota',
                ),
                const SizedBox(height: 12),
                _buildContent(snapshot, list),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    AsyncSnapshot<DatabaseEvent> snapshot,
    List<Map<String, dynamic>> list,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(children: List.generate(3, (_) => _loadingCard()));
    }

    if (snapshot.hasError) {
      return _emptyState(
        title: 'Gagal Memuat Pengumuman',
        message: 'Periksa koneksi internet atau Firebase.',
        icon: Icons.fact_check_rounded,
      );
    }

    if (list.isEmpty) {
      return _emptyState(
        title: 'Belum Ada Pengumuman',
        message:
            'Tambahkan pengumuman agar informasi penting tampil di halaman anggota.',
        icon: Icons.campaign_rounded,
      );
    }

    return Column(
      children: list.map((item) => _announcementCard(item)).toList(),
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
              Icons.campaign_rounded,
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
                  'Kelola Pengumuman',
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
                  'Buat informasi menarik untuk anggota',
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

  Widget _highlightPanel({required int total, required int aktif}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryGreen.withValues(alpha: 0.96),
            darkGreen.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.13),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -30,
            child: Icon(
              Icons.campaign_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengumuman yang menarik membuat anggota lebih cepat membaca informasi.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.2,
                        height: 1.32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _previewSubtitle(aktif, total),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11.7,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
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

  Widget _summaryGrid({
    required int total,
    required int aktif,
    required int nonaktif,
  }) {
    final items = [
      _SummaryItem(
        title: 'Total Info',
        value: total,
        icon: Icons.dataset_rounded,
        color: primaryGreen,
      ),
      _SummaryItem(
        title: 'Aktif',
        value: aktif,
        icon: Icons.visibility_rounded,
        color: blueColor,
      ),
      _SummaryItem(
        title: 'Nonaktif',
        value: nonaktif,
        icon: Icons.visibility_off_rounded,
        color: orangeColor,
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
      decoration: _cardDecoration(radius: 16),
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

  Widget _infoPanel({required int aktif, required int total}) {
    final color = aktif > 0 ? primaryGreen : orangeColor;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          _iconBox(
            aktif > 0 ? Icons.task_alt_rounded : Icons.info_rounded,
            color,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              aktif > 0
                  ? '$aktif dari $total pengumuman sedang aktif dan tampil di halaman anggota.'
                  : 'Belum ada pengumuman aktif. Aktifkan pengumuman agar anggota dapat melihat informasi terbaru.',
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _announcementCard(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final title = (item['judul'] ?? '-').toString();
    final body = (item['isi'] ?? '-').toString();
    final date = (item['tanggal'] ?? '-').toString();
    final status = (item['status'] ?? 'nonaktif').toString().toLowerCase();
    final category = (item['kategori'] ?? 'umum').toString().toLowerCase();
    final active = status == 'aktif';
    final color = _categoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _promoPreview(
            title: title,
            body: body,
            category: category,
            compact: false,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniInfo(
                icon: Icons.calendar_month_rounded,
                text: date,
                color: blueColor,
              ),
              const SizedBox(width: 7),
              _miniInfo(
                icon: _categoryIcon(category),
                text: _categoryLabel(category),
                color: color,
              ),
              const Spacer(),
              _statusBadge(active),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _smallAction(
                icon:
                    active
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                color: active ? orangeColor : primaryGreen,
                onTap: () => _toggleStatus(id, status),
              ),
              const SizedBox(width: 7),
              _smallAction(
                icon: Icons.edit_note_rounded,
                color: blueColor,
                onTap: () => _openForm(item: item),
              ),
              const SizedBox(width: 7),
              _smallAction(
                icon: Icons.delete_forever_rounded,
                color: redColor,
                onTap: () => _confirmDelete(id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _promoPreview({
    required String title,
    required String body,
    required String category,
    required bool compact,
  }) {
    final color = _categoryColor(category);
    final icon = _categoryIcon(category);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.96),
            Color.lerp(color, Colors.black, 0.18) ?? color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: compact ? 0.08 : 0.12),
            blurRadius: compact ? 10 : 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -28,
            child: Icon(
              icon,
              size: compact ? 86 : 110,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      _categoryLabel(category).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 12 : 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 16.5 : 18,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                body,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 12.2,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Flexible(
      child: Container(
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
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 9.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
      decoration: BoxDecoration(
        color: (active ? primaryGreen : orangeColor).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: (active ? primaryGreen : orangeColor).withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        active ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          color: active ? primaryGreen : orangeColor,
          fontSize: 8.8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
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

  Widget _emptyState({
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
          const SizedBox(height: 18),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text(
                'Tambah Pengumuman',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
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
