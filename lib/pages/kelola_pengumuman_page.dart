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
  static const Color bgColor = Color(0xffF4F7F4);
  static const Color cardBorder = Color(0xffE5E7EB);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        content: Text(message),
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

    if (clean == 'pupuk') return Icons.eco_rounded;
    if (clean == 'alat') return Icons.agriculture_rounded;
    if (clean == 'rapat') return Icons.groups_rounded;
    if (clean == 'panen') return Icons.grass_rounded;
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
                child: SingleChildScrollView(
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
                              Icons.campaign_rounded,
                              color: primaryGreen,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item == null
                                  ? 'Tambah Pengumuman'
                                  : 'Edit Pengumuman',
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
                        'Buat informasi yang akan tampil pada halaman anggota.',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 12.5,
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
                                ? 'Isi singkat pengumuman akan tampil di sini.'
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
                        hint: 'Tulis isi pengumuman...',
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
                              onTap: () {
                                setModalState(() => status = 'nonaktif');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
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
                          child: Text(
                            _isProcessing
                                ? 'Menyimpan...'
                                : item == null
                                ? 'Simpan Pengumuman'
                                : 'Update Pengumuman',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? color : cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_categoryIcon(value), size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              _categoryLabel(value),
              style: TextStyle(
                color: isSelected ? color : textGrey,
                fontSize: 12,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryGreen),
            filled: true,
            fillColor: const Color(0xffF9FAFB),
            hintStyle: const TextStyle(color: textGrey, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusOption({
    required String title,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : bgColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? color : cardBorder),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: selected ? color : textGrey,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
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
            borderRadius: BorderRadius.circular(18),
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
              child: const Text('Batal'),
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
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: const Text('Hapus'),
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
        elevation: 3,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
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
              padding: EdgeInsets.zero,
              children: [
                _header(list.length),
                const SizedBox(height: 16),
                _sectionTitle(
                  title: 'Ringkasan Pengumuman',
                  subtitle: 'Pantauan informasi yang tampil untuk anggota',
                  horizontalPadding: 16,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _summaryGrid(
                    total: list.length,
                    aktif: aktif,
                    nonaktif: nonaktif,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _infoPanel(),
                ),
                const SizedBox(height: 18),
                _sectionTitle(
                  title: 'Daftar Pengumuman',
                  subtitle: 'Kelola informasi yang dibaca anggota',
                  horizontalPadding: 16,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: _buildContent(snapshot, list),
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
    List<Map<String, dynamic>> list,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Column(children: List.generate(3, (_) => _loadingCard()));
    }

    if (snapshot.hasError) {
      return _emptyState(
        title: 'Gagal Memuat Pengumuman',
        message: 'Periksa koneksi internet atau Firebase.',
        icon: Icons.error_outline_rounded,
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
      children:
          list.map((item) {
            return _announcementCard(item);
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
                  'Kelola Pengumuman',
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
                  'Atur informasi yang tampil di halaman anggota',
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
            'info',
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
    required int total,
    required int aktif,
    required int nonaktif,
  }) {
    final items = [
      _SummaryItem(
        title: 'Total Info',
        value: total,
        icon: Icons.campaign_rounded,
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
              'Pengumuman aktif akan tampil di halaman anggota. Saat membuat pengumuman aktif, anggota akan mendapatkan notifikasi.',
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

  Widget _announcementCard(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final title = (item['judul'] ?? '-').toString();
    final body = (item['isi'] ?? '-').toString();
    final date = (item['tanggal'] ?? '-').toString();
    final status = (item['status'] ?? 'nonaktif').toString().toLowerCase();
    final category = (item['kategori'] ?? 'umum').toString().toLowerCase();
    final active = status == 'aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _promoPreview(
            title: title,
            body: body,
            category: category,
            compact: false,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: textGrey.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusBadge(active),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  title: active ? 'Nonaktif' : 'Aktifkan',
                  icon:
                      active
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                  color: active ? orangeColor : primaryGreen,
                  onTap: () => _toggleStatus(id, status),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  title: 'Edit',
                  icon: Icons.edit_rounded,
                  color: blueColor,
                  onTap: () => _openForm(item: item),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  title: 'Hapus',
                  icon: Icons.delete_rounded,
                  color: redColor,
                  onTap: () => _confirmDelete(id),
                ),
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -26,
            child: Icon(
              _categoryIcon(category),
              size: compact ? 90 : 112,
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
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _categoryIcon(category),
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _categoryLabel(category).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
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
                  fontSize: compact ? 17 : 18,
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
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 12.5,
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

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: (active ? primaryGreen : orangeColor).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          color: active ? primaryGreen : orangeColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
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
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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
          const SizedBox(height: 18),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
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
