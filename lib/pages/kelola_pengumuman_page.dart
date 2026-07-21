import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class KelolaPengumumanPage extends StatefulWidget {
  const KelolaPengumumanPage({super.key});

  @override
  State<KelolaPengumumanPage> createState() => _KelolaPengumumanPageState();
}

class _KelolaPengumumanPageState extends State<KelolaPengumumanPage> {
  static const Color primaryGreen = Color(0xff2E7D32);

  static const Color adminNavy = Color(0xff172A46);
  static const Color adminNavyLight = Color(0xff294762);
  static const Color adminPurple = Color(0xff6256A4);

  static const Color softGreen = Color(0xffE9F5EB);

  static const Color bgColor = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  static const Color redColor = Color(0xffC83B3B);
  static const Color orangeColor = Color(0xffD98212);
  static const Color blueColor = Color(0xff326CA3);

  static const Color categoryGeneral = Color(0xff6A5CAD);
  static const Color categoryPupuk = Color(0xff2C8A73);
  static const Color categoryAlat = Color(0xffD0852A);
  static const Color categoryRapat = Color(0xff3E78AE);
  static const Color categoryPanen = Color(0xffA56A2C);
  static const Color categoryGotong = Color(0xffB05B78);

  static const Color categoryGeneralSoft = Color(0xffEEEAF8);
  static const Color categoryPupukSoft = Color(0xffE4F3EE);
  static const Color categoryAlatSoft = Color(0xffFFF2DE);
  static const Color categoryRapatSoft = Color(0xffE8F1FA);
  static const Color categoryPanenSoft = Color(0xffF6EBDD);
  static const Color categoryGotongSoft = Color(0xffF8E8EF);

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
        backgroundColor: adminNavy,
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

    if (clean == 'pupuk') return categoryPupuk;
    if (clean == 'alat') return categoryAlat;
    if (clean == 'rapat') return categoryRapat;
    if (clean == 'panen') return categoryPanen;
    if (clean == 'gotong_royong') return categoryGotong;

    return categoryGeneral;
  }

  Color _categoryBackground(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') return categoryPupukSoft;
    if (clean == 'alat') return categoryAlatSoft;
    if (clean == 'rapat') return categoryRapatSoft;
    if (clean == 'panen') return categoryPanenSoft;
    if (clean == 'gotong_royong') return categoryGotongSoft;

    return categoryGeneralSoft;
  }

  List<Color> _categoryGradient(String category) {
    final clean = category.toLowerCase().trim();

    if (clean == 'pupuk') {
      return const [
        Color(0xff2C8A73),
        Color(0xff176150),
      ];
    }

    if (clean == 'alat') {
      return const [
        Color(0xffD0852A),
        Color(0xff9E5B18),
      ];
    }

    if (clean == 'rapat') {
      return const [
        Color(0xff3E78AE),
        Color(0xff244F7B),
      ];
    }

    if (clean == 'panen') {
      return const [
        Color(0xffA56A2C),
        Color(0xff74451C),
      ];
    }

    if (clean == 'gotong_royong') {
      return const [
        Color(0xffB05B78),
        Color(0xff75384F),
      ];
    }

    return const [
      Color(0xff6A5CAD),
      Color(0xff433A76),
    ];
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

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final titleController = TextEditingController(
      text: item?['judul']?.toString() ?? '',
    );
    final bodyController = TextEditingController(
      text: item?['isi']?.toString() ?? '',
    );

    String status = item?['status']?.toString() ?? 'aktif';
    String category = item?['kategori']?.toString() ?? 'umum';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final screenHeight = MediaQuery.sizeOf(context).height;
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

            return Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                top: 10,
                bottom: keyboardInset + 14,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight - keyboardInset - 34,
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
                            adminPurple,
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
                          const SizedBox(width: 8),
                          Material(
                            color: const Color(0xffF1F3F7),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _isProcessing
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();

                                      await Future<void>.delayed(
                                        const Duration(milliseconds: 90),
                                      );

                                      if (!context.mounted) return;
                                      Navigator.of(context).pop();
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: const SizedBox(
                                height: 38,
                                width: 38,
                                child: Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: textGrey,
                                    size: 20,
                                  ),
                                ),
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

                                    FocusScope.of(context).unfocus();

                                    await _saveAnnouncement(
                                      id: item?['id']?.toString(),
                                      title: titleController.text,
                                      body: bodyController.text,
                                      status: status,
                                      category: category,
                                    );

                                    await Future<void>.delayed(
                                      const Duration(milliseconds: 90),
                                    );

                                    if (!mounted || !context.mounted) {
                                      return;
                                    }

                                    Navigator.of(context).pop();
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
            ),
            );
          },
        );
      },
    );

    /*
     * Tunggu animasi penutupan bottom sheet selesai sebelum controller
     * dibuang. Ini mencegah TextField masih menjadi dependent ketika
     * elemen modal sedang dilepas dari widget tree.
     */
    await Future<void>.delayed(
      const Duration(milliseconds: 280),
    );

    titleController.dispose();
    bodyController.dispose();
  }

  Widget _categoryOption({
    required String value,
    required String selected,
    required VoidCallback onTap,
  }) {
    final isSelected = value == selected;
    final color = _categoryColor(value);
    final backgroundColor = _categoryBackground(value);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? backgroundColor
                : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.55)
                  : cardBorder,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: Center(
                  child: Icon(
                    _categoryIcon(value),
                    size: 14,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _categoryLabel(value),
                style: TextStyle(
                  color: isSelected ? color : textGrey,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
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
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 340 ? 13.0 : 17.0;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: adminPurple,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => _openForm(),
        icon: const Icon(
          Icons.add_task_rounded,
          size: 19,
        ),
        label: const Text(
          'Tambah',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _AdminDashboardBackground(),
              SafeArea(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _pengumumanRef.onValue,
                  builder: (context, snapshot) {
                    final list = _getAnnouncements(
                      snapshot.data?.snapshot.value,
                    );
                    final aktif = _countStatus(list, 'aktif');
                    final nonaktif = _countStatus(list, 'nonaktif');

                    return RefreshIndicator(
                      color: adminPurple,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await _pengumumanRef.get();
                      },
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          100,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 760,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _header(list.length),
                                  const SizedBox(height: 15),
                                  _highlightPanel(
                                    total: list.length,
                                    aktif: aktif,
                                  ),
                                  const SizedBox(height: 14),
                                  _summaryGrid(
                                    total: list.length,
                                    aktif: aktif,
                                    nonaktif: nonaktif,
                                  ),
                                  const SizedBox(height: 14),
                                  _infoPanel(
                                    aktif: aktif,
                                    total: list.length,
                                  ),
                                  const SizedBox(height: 18),
                                  _sectionTitle(
                                    title: 'Daftar Pengumuman',
                                    subtitle:
                                        'Kelola informasi yang dibaca anggota',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildContent(snapshot, list),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            adminNavy,
            adminNavyLight,
            adminPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.23),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -58,
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 42,
              bottom: -62,
              child: Container(
                height: 105,
                width: 105,
                decoration: BoxDecoration(
                  color: const Color(0xffB9ACFF)
                      .withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                _adminHeaderButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () {
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                Container(
                  height: 45,
                  width: 45,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: adminNavy,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
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
                          fontSize: 17.4,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Buat dan atur informasi untuk anggota',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xffDFE6F1),
                          fontSize: 9.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 40,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.19),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.fact_check_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        total > 99 ? '99+' : total.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 45,
          width: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.19),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _highlightPanel({
    required int total,
    required int aktif,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            adminNavy,
            adminNavyLight,
            adminPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _safeIconBox(
            icon: Icons.auto_awesome_rounded,
            color: adminPurple,
            backgroundColor: Colors.white,
            size: 48,
            iconSize: 23,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Publikasikan informasi yang jelas dan mudah dibaca.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.8,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _previewSubtitle(aktif, total),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.79),
                    fontSize: 10.8,
                    height: 1.4,
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

  Widget _summaryGrid({
    required int total,
    required int aktif,
    required int nonaktif,
  }) {
    final items = [
      _SummaryItem(
        title: 'Total',
        value: total,
        icon: Icons.dataset_outlined,
        color: adminPurple,
      ),
      _SummaryItem(
        title: 'Aktif',
        value: aktif,
        icon: Icons.visibility_outlined,
        color: categoryPupuk,
      ),
      _SummaryItem(
        title: 'Nonaktif',
        value: nonaktif,
        icon: Icons.visibility_off_outlined,
        color: orangeColor,
      ),
    ];

    return Row(
      children: [
        Expanded(
          child: _summaryCard(items[0]),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryCard(items[1]),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _summaryCard(items[2]),
        ),
      ],
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.color.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.045),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 29,
            width: 29,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.value > 99
                      ? '99+'
                      : item.value.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 15,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 8.5,
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

  Widget _infoPanel({required int aktif, required int total}) {
    final color = aktif > 0 ? categoryPupuk : orangeColor;

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
    final backgroundColor = _categoryBackground(category);
    final gradient = _categoryGradient(category);
    final icon = _categoryIcon(category);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        compact ? 13 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            Colors.white.withValues(alpha: 0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: compact ? 9 : 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: compact ? 92 : 104,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _safeIconBox(
                      icon: icon,
                      color: color,
                      backgroundColor: Colors.white,
                      size: compact ? 39 : 42,
                      iconSize: compact ? 19 : 20,
                      borderColor: color.withValues(alpha: 0.10),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _categoryLabel(category).toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 8.7,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 11),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textDark,
                    fontSize: compact ? 15.3 : 16.3,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.8,
                    height: 1.42,
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 34,
          width: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.11),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 17,
              ),
            ),
          ),
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

  Widget _iconBox(IconData icon, Color color) {
    return _safeIconBox(
      icon: icon,
      color: color,
      backgroundColor: color.withValues(alpha: 0.10),
      size: 42,
      iconSize: 21,
      borderColor: color.withValues(alpha: 0.07),
    );
  }

  Widget _safeIconBox({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required double size,
    required double iconSize,
    Color? borderColor,
  }) {
    return SizedBox(
      height: size,
      width: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(size * 0.31),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor),
        ),
        child: Center(
          child: SizedBox(
            height: iconSize + 4,
            width: iconSize + 4,
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: iconSize,
              ),
            ),
          ),
        ),
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
          color: adminNavy.withValues(alpha: 0.06),
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

class _AdminDashboardBackground
    extends StatelessWidget {
  const _AdminDashboardBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final baseSize =
                width < height ? width : height;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(280.0, 470.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.67)
                    .clamp(190.0, 330.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.40)
                    .clamp(120.0, 200.0)
                    .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xff172A46),
                          Color(0xff263E61),
                          Color(0xffE8EAF2),
                          Color(0xffF2F4F8),
                        ],
                        stops: [
                          0,
                          0.22,
                          0.49,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -largeCircle * 0.55,
                    right: -largeCircle * 0.30,
                    child: _AdminBackgroundCircle(
                      size: largeCircle,
                      color:
                          const Color(0xff6256A4),
                      alpha: 0.22,
                      borderColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.13,
                    left: -smallCircle * 0.22,
                    child: _AdminBackgroundRing(
                      size: smallCircle,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: height * 0.26,
                    left: -mediumCircle * 0.56,
                    child: _AdminBackgroundCircle(
                      size: mediumCircle,
                      color:
                          const Color(0xff54779A),
                      alpha: 0.21,
                      borderColor:
                          const Color(0xff54779A),
                    ),
                  ),
                  Positioned(
                    top: height * 0.47,
                    right:
                        -mediumCircle * 0.62,
                    child: _AdminBackgroundCircle(
                      size: mediumCircle * 1.08,
                      color:
                          const Color(0xffE8E1F7),
                      alpha: 0.76,
                      borderColor:
                          const Color(0xff725BB4),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -largeCircle * 0.52,
                    left: -largeCircle * 0.31,
                    child: _AdminBackgroundCircle(
                      size: largeCircle,
                      color:
                          const Color(0xffDCEDE8),
                      alpha: 0.76,
                      borderColor:
                          const Color(0xff28766F),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -mediumCircle * 0.36,
                    right:
                        -mediumCircle * 0.42,
                    child: _AdminBackgroundCircle(
                      size: mediumCircle,
                      color:
                          const Color(0xffE7EDF6),
                      alpha: 0.86,
                      borderColor:
                          const Color(0xff326CA3),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AdminBackgroundCircle
    extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  final Color borderColor;

  const _AdminBackgroundCircle({
    required this.size,
    required this.color,
    required this.alpha,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor.withValues(
            alpha: 0.08,
          ),
          width: 2,
        ),
      ),
    );
  }
}

class _AdminBackgroundRing
    extends StatelessWidget {
  final double size;
  final Color color;

  const _AdminBackgroundRing({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }
}
