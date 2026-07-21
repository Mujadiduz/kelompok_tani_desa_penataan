import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_background.dart';

const Color _adminNavy = Color(0xff172554);
const Color _adminIndigo = Color(0xff35469C);
const Color _adminPurple = Color(0xff6946C6);
const Color _adminBlue = Color(0xff326FA3);
const Color _adminTeal = Color(0xff167A6B);
const Color _adminGreen = Color(0xff2E7D32);
const Color _adminAmber = Color(0xffD98212);
const Color _adminRed = Color(0xffC83B3B);

const Color _pageBackground = Color(0xffF4F6FB);
const Color _cardBorder = Color(0xffE1E5EF);
const Color _textDark = Color(0xff18212B);
const Color _textGrey = Color(0xff66727F);
const Color _textSoft = Color(0xff8B96A2);

const Color _softIndigo = Color(0xffECEEFA);
const Color _softPurple = Color(0xffF0EBFC);
const Color _softBlue = Color(0xffEAF3FA);
const Color _softGreen = Color(0xffE9F5EB);
const Color _softAmber = Color(0xffFFF3DD);
const Color _softRed = Color(0xffFBEAEA);

class KelolaAlatPage extends StatefulWidget {
  const KelolaAlatPage({super.key});

  @override
  State<KelolaAlatPage> createState() => _KelolaAlatPageState();
}

class _KelolaAlatPageState extends State<KelolaAlatPage> {
  final TextEditingController _searchController =
      TextEditingController();

  final DatabaseReference _alatRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('alat_pertanian');

  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _stringMap(dynamic value) {
    if (value is! Map) {
      return {};
    }

    final source = Map<dynamic, dynamic>.from(value);

    return source.map(
      (key, item) => MapEntry(
        key.toString(),
        item,
      ),
    );
  }

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    final result = value?.toString().trim() ?? '';

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  int _intValue(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (value is num) {
      try {
        final number = value.toInt();

        return DateTime.fromMillisecondsSinceEpoch(
          number.toString().length >= 13
              ? number
              : number * 1000,
        ).toLocal();
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);

    if (date.millisecondsSinceEpoch == 0) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _normalizedStatus(dynamic value) {
    final status = _text(
      value,
      fallback: 'aktif',
    )
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if ({
      '',
      'active',
      'tersedia',
      'available',
    }.contains(status)) {
      return 'aktif';
    }

    if ({
      'inactive',
      'non_aktif',
      'tidak_aktif',
      'arsip',
    }.contains(status)) {
      return 'nonaktif';
    }

    return status;
  }

  List<MapEntry<String, dynamic>> _toolList(dynamic value) {
    if (value is! Map) {
      return [];
    }

    final result = <MapEntry<String, dynamic>>[];

    for (final entry
        in Map<dynamic, dynamic>.from(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      result.add(
        MapEntry(
          entry.key.toString(),
          _stringMap(entry.value),
        ),
      );
    }

    result.sort((first, second) {
      final firstDate = _parseDate(
        first.value['tanggal_update'] ??
            first.value['tanggal_input'],
      );

      final secondDate = _parseDate(
        second.value['tanggal_update'] ??
            second.value['tanggal_input'],
      );

      final dateComparison =
          secondDate.compareTo(firstDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      final firstName = _text(
        first.value['nama_alat'],
        fallback: '',
      ).toLowerCase();

      final secondName = _text(
        second.value['nama_alat'],
        fallback: '',
      ).toLowerCase();

      return firstName.compareTo(secondName);
    });

    return result;
  }

  List<MapEntry<String, dynamic>> _filteredList(
    List<MapEntry<String, dynamic>> source,
  ) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return source;
    }

    return source.where((entry) {
      final name = _text(
        entry.value['nama_alat'],
        fallback: '',
      ).toLowerCase();

      final status = _normalizedStatus(
        entry.value['status'],
      );

      final unit = _intValue(
        entry.value['jumlah_unit'],
      ).toString();

      return name.contains(query) ||
          status.contains(query) ||
          unit.contains(query);
    }).toList();
  }

  int _totalUnits(
    List<MapEntry<String, dynamic>> data,
  ) {
    int total = 0;

    for (final entry in data) {
      total += _intValue(
        entry.value['jumlah_unit'],
      );
    }

    return total;
  }

  int _activeTools(
    List<MapEntry<String, dynamic>> data,
  ) {
    return data.where((entry) {
      return _normalizedStatus(
            entry.value['status'],
          ) ==
          'aktif';
    }).length;
  }

  IconData _equipmentIcon(String value) {
    final name = value.toLowerCase();

    if (name.contains('sprayer') ||
        name.contains('semprot')) {
      return Icons.water_drop_outlined;
    }

    if (name.contains('cangkul')) {
      return Icons.handyman_outlined;
    }

    if (name.contains('traktor')) {
      return Icons.agriculture_rounded;
    }

    if (name.contains('pompa')) {
      return Icons.water_outlined;
    }

    if (name.contains('mesin')) {
      return Icons.precision_manufacturing_outlined;
    }

    if (name.contains('sabit') ||
        name.contains('parang')) {
      return Icons.content_cut_rounded;
    }

    return Icons.construction_outlined;
  }

  Color _equipmentColor(String value) {
    final name = value.toLowerCase();

    if (name.contains('sprayer') ||
        name.contains('semprot')) {
      return _adminBlue;
    }

    if (name.contains('cangkul')) {
      return _adminAmber;
    }

    if (name.contains('traktor')) {
      return _adminGreen;
    }

    if (name.contains('pompa')) {
      return _adminTeal;
    }

    return _adminPurple;
  }

  Future<void> _refreshData() async {
    await _alatRef.get();
  }

  Future<void> _openToolForm({
    String? id,
    Map<String, dynamic>? data,
  }) async {
    FocusScope.of(context).unfocus();

    final result = await showModalBottomSheet<_ToolFormResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: _adminNavy.withValues(alpha: 0.42),
      builder: (sheetContext) {
        return _ToolFormSheet(
          editing: id != null,
          initialName: _text(
            data?['nama_alat'],
            fallback: '',
          ),
          initialUnit: _intValue(
            data?['jumlah_unit'],
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    await _saveTool(
      id: id,
      result: result,
    );
  }

  Future<void> _saveTool({
    required String? id,
    required _ToolFormResult result,
  }) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      if (id == null) {
        await _alatRef.push().set({
          'nama_alat': result.name,
          'jumlah_unit': result.unit,
          'status': 'aktif',
          'tanggal_input': now,
        }).timeout(
          const Duration(seconds: 12),
        );
      } else {
        await _alatRef.child(id).update({
          'nama_alat': result.name,
          'jumlah_unit': result.unit,
          'tanggal_update': now,
        }).timeout(
          const Duration(seconds: 12),
        );
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        id == null
            ? 'Alat berhasil ditambahkan.'
            : 'Data alat berhasil diperbarui.',
        _adminGreen,
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal menyimpan alat: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      final errorText = error.toString().toLowerCase();
      final message = errorText.contains('permission-denied') ||
              errorText.contains('permission_denied')
          ? 'Akses Firebase ditolak. Periksa Database Rules.'
          : errorText.contains('timeout')
              ? 'Koneksi ke Firebase melewati batas waktu.'
              : 'Gagal menyimpan alat: $error';

      _showSnackBar(
        message,
        _adminRed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _confirmDelete({
    required String id,
    required String name,
  }) async {
    FocusScope.of(context).unfocus();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _DeleteToolDialog(
          toolName: name,
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await _deleteTool(id);
  }

  Future<void> _deleteTool(String id) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await _alatRef.child(id).remove().timeout(
            const Duration(seconds: 12),
          );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Data alat berhasil dihapus.',
        _adminGreen,
      );
    } catch (error, stackTrace) {
      debugPrint('Gagal menghapus alat: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal menghapus alat: $error',
        _adminRed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSnackBar(
    String message,
    Color color,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                color == _adminGreen
                    ? Icons.check_circle_outline_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 350
        ? 12.0
        : screenWidth >= 800
            ? 24.0
            : 16.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _AdminToolBackground(),
                SafeArea(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _alatRef.onValue,
                    builder: (context, snapshot) {
                      final allTools = _toolList(
                        snapshot.data?.snapshot.value,
                      );

                      final filteredTools =
                          _filteredList(allTools);

                      final activeTools =
                          _activeTools(allTools);

                      final totalUnits =
                          _totalUnits(allTools);

                      return RefreshIndicator(
                        color: _adminIndigo,
                        backgroundColor: Colors.white,
                        onRefresh: _refreshData,
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior
                                  .manual,
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            12,
                            horizontalPadding,
                            112,
                          ),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 840,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _header(allTools.length),
                                    const SizedBox(height: 12),
                                    _summarySection(
                                      totalType: allTools.length,
                                      activeType: activeTools,
                                      totalUnits: totalUnits,
                                    ),
                                    const SizedBox(height: 10),
                                    _informationPanel(
                                      totalUnits: totalUnits,
                                      activeTools: activeTools,
                                    ),
                                    const SizedBox(height: 10),
                                    _searchField(),
                                    const SizedBox(height: 17),
                                    _sectionTitle(
                                      resultCount:
                                          filteredTools.length,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildContent(
                                      snapshot: snapshot,
                                      allTools: allTools,
                                      filteredTools:
                                          filteredTools,
                                    ),
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
                if (_isProcessing) _processingOverlay(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomAction(),
    );
  }

  Widget _header(int total) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;

        return Container(
          padding: EdgeInsets.all(
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _adminNavy,
                _adminIndigo,
                _adminPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _adminNavy.withValues(
                  alpha: 0.24,
                ),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _backButton(),
              SizedBox(width: compact ? 9 : 11),
              _iconBox(
                icon:
                    Icons.precision_manufacturing_outlined,
                color: Colors.white,
                iconBackground:
                    Colors.white.withValues(alpha: 0.14),
                size: compact ? 43 : 47,
              ),
              SizedBox(width: compact ? 9 : 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kelola Alat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Inventaris alat pertanian desa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xffE4E7FF),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color:
                        Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      total > 999 ? '999+' : '$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summarySection({
    required int totalType,
    required int activeType,
    required int totalUnits,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 350
            ? 6.0
            : 8.0;

        final itemWidth =
            (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                label: 'Jenis',
                value: totalType,
                icon: Icons.category_outlined,
                color: _adminPurple,
                itemBackground: _softPurple,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                label: 'Aktif',
                value: activeType,
                icon: Icons.verified_outlined,
                color: _adminBlue,
                itemBackground: _softBlue,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                label: 'Total Unit',
                value: totalUnits,
                icon: Icons.inventory_2_outlined,
                color: _adminGreen,
                itemBackground: _softGreen,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
    required Color itemBackground,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 73,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 9,
      ),
      decoration: _cardDecoration(
        radius: 17,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 25,
            width: 25,
            decoration: BoxDecoration(
              color: itemBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value > 999 ? '999+' : '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15.5,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 8.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationPanel({
    required int totalUnits,
    required int activeTools,
  }) {
    final ready = totalUnits > 0 && activeTools > 0;

    final color =
        ready ? _adminIndigo : _adminAmber;

    final panelBackground =
        ready ? _softIndigo : _softAmber;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panelBackground,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.11),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(
            icon: ready
                ? Icons.hub_outlined
                : Icons.info_outline_rounded,
            color: color,
            iconBackground: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  ready
                      ? 'Inventaris desa sudah tersedia'
                      : 'Inventaris desa belum tersedia',
                  style: TextStyle(
                    color: color,
                    fontSize: 11.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ready
                      ? '$totalUnits unit dari $activeTools jenis alat aktif akan ditampilkan kepada anggota.'
                      : 'Tambahkan nama alat dan jumlah unit agar dapat dilihat oleh anggota.',
                  style: const TextStyle(
                    color: _textGrey,
                    fontSize: 9.4,
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

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onTapOutside: (_) {},
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onSubmitted: (_) {
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        hintText: 'Cari nama alat atau jumlah unit',
        hintStyle: const TextStyle(
          color: _textSoft,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _adminIndigo,
          size: 20,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                  });

                  FocusScope.of(context).unfocus();
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: _textGrey,
                  size: 18,
                ),
              ),
        filled: true,
        fillColor: Colors.white.withValues(
          alpha: 0.98,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: _cardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: _adminIndigo,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required int resultCount,
  }) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 31,
          decoration: BoxDecoration(
            color: _adminIndigo,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Alat Desa',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Kelola nama dan jumlah unit alat.',
                style: TextStyle(
                  color: _textGrey,
                  fontSize: 9.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _softIndigo,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$resultCount data',
            style: const TextStyle(
              color: _adminIndigo,
              fontSize: 8.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent({
    required AsyncSnapshot<DatabaseEvent> snapshot,
    required List<MapEntry<String, dynamic>> allTools,
    required List<MapEntry<String, dynamic>>
        filteredTools,
  }) {
    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return _loadingGrid();
    }

    if (snapshot.hasError) {
      return _messageState(
        icon: Icons.cloud_off_outlined,
        title: 'Data Alat Gagal Dimuat',
        message:
            'Periksa koneksi internet lalu tarik halaman ke bawah.',
        color: _adminRed,
        itemBackground: _softRed,
      );
    }

    if (allTools.isEmpty) {
      return _messageState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum Ada Data Alat',
        message:
            'Tekan tombol tambah untuk memasukkan alat pertanian desa.',
        color: _adminPurple,
        itemBackground: _softPurple,
      );
    }

    if (filteredTools.isEmpty) {
      return _messageState(
        icon: Icons.search_off_rounded,
        title: 'Alat Tidak Ditemukan',
        message:
            'Gunakan nama atau jumlah unit lain dalam pencarian.',
        color: _adminAmber,
        itemBackground: _softAmber,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 700 ? 2 : 1;

        const gap = 10.0;

        final itemWidth = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: filteredTools.map((entry) {
            return SizedBox(
              width: itemWidth,
              child: _toolCard(
                id: entry.key,
                tool: entry.value,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _toolCard({
    required String id,
    required Map<String, dynamic> tool,
  }) {
    final name = _text(
      tool['nama_alat'],
      fallback: 'Alat pertanian',
    );

    final unit = _intValue(
      tool['jumlah_unit'],
    );

    final status = _normalizedStatus(
      tool['status'],
    );

    final active = status == 'aktif';

    final equipmentColor =
        _equipmentColor(name);

    final date = _formatDate(
      tool['tanggal_update'] ??
          tool['tanggal_input'],
    );

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _iconBox(
                icon: _equipmentIcon(name),
                color: equipmentColor,
                iconBackground: equipmentColor
                    .withValues(alpha: 0.09),
                size: 47,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date == '-'
                          ? 'Belum ada tanggal pembaruan'
                          : 'Diperbarui $date',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 9.1,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              _statusBadge(active),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _informationChip(
                icon: Icons.inventory_2_outlined,
                label: '$unit unit',
                color: equipmentColor,
              ),
              _informationChip(
                icon: active
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                label: active
                    ? 'Tampil ke anggota'
                    : 'Tidak ditampilkan',
                color: active
                    ? _adminGreen
                    : _adminRed,
              ),
            ],
          ),
          const SizedBox(height: 11),
          const Divider(
            height: 1,
            color: _cardBorder,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 39,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            _openToolForm(
                              id: id,
                              data: tool,
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          _adminIndigo,
                      side: BorderSide(
                        color: _adminIndigo
                            .withValues(alpha: 0.20),
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.edit_note_outlined,
                      size: 17,
                    ),
                    label: const Text(
                      'Edit',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.3,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 39,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            _confirmDelete(
                              id: id,
                              name: name,
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _adminRed,
                      side: BorderSide(
                        color: _adminRed.withValues(
                          alpha: 0.20,
                        ),
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Hapus',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.3,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool active) {
    final color =
        active ? _adminGreen : _adminRed;

    final itemBackground =
        active ? _softGreen : _softRed;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: itemBackground,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        active ? 'AKTIF' : 'NONAKTIF',
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  Widget _informationChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 11.5,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 700 ? 2 : 1;

        const gap = 10.0;

        final itemWidth = columns == 2
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: List.generate(4, (index) {
            return SizedBox(
              width: itemWidth,
              child: _loadingCard(),
            );
          }),
        );
      },
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 154,
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(
        radius: 20,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 47,
                width: 47,
                decoration: BoxDecoration(
                  color: _cardBorder,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: _cardBorder,
                        borderRadius:
                            BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 9,
                      decoration: BoxDecoration(
                        color: _cardBorder,
                        borderRadius:
                            BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 39,
            decoration: BoxDecoration(
              color: _cardBorder,
              borderRadius:
                  BorderRadius.circular(12),
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
    required Color color,
    required Color itemBackground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 30,
      ),
      decoration: _cardDecoration(
        radius: 22,
      ),
      child: Column(
        children: [
          _iconBox(
            icon: icon,
            color: color,
            iconBackground: itemBackground,
            size: 68,
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14.7,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textGrey,
              fontSize: 10,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction() {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor:
          _adminNavy.withValues(alpha: 0.13),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            14,
            9,
            14,
            12,
          ),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 840,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : () {
                          _openToolForm();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _adminIndigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        _adminIndigo.withValues(
                      alpha: 0.38,
                    ),
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 20,
                  ),
                  label: const Text(
                    'Tambah Alat Desa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _processingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: _adminNavy.withValues(alpha: 0.26),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              18,
            ),
            constraints: const BoxConstraints(
              maxWidth: 300,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _adminNavy.withValues(
                    alpha: 0.18,
                  ),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 35,
                  width: 35,
                  child: CircularProgressIndicator(
                    color: _adminIndigo,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 13),
                Text(
                  'Memproses Data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mohon tunggu sampai proses selesai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textGrey,
                    fontSize: 9.4,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _isProcessing
            ? null
            : () {
                FocusScope.of(context).unfocus();
                Navigator.maybePop(context);
              },
        borderRadius: BorderRadius.circular(14),
        child: _iconBox(
          icon: Icons.arrow_back_rounded,
          color: Colors.white,
          iconBackground:
              Colors.white.withValues(alpha: 0.14),
          size: 42,
        ),
      ),
    );
  }

  Widget _iconBox({
    required IconData icon,
    required Color color,
    required Color iconBackground,
    required double size,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: iconBackground,
        borderRadius: BorderRadius.circular(
          size * 0.32,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.5,
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: _cardBorder),
      boxShadow: [
        BoxShadow(
          color: _adminNavy.withValues(alpha: 0.045),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _ToolFormResult {
  final String name;
  final int unit;

  const _ToolFormResult({
    required this.name,
    required this.unit,
  });
}

class _ToolFormSheet extends StatefulWidget {
  final bool editing;
  final String initialName;
  final int initialUnit;

  const _ToolFormSheet({
    required this.editing,
    required this.initialName,
    required this.initialUnit,
  });

  @override
  State<_ToolFormSheet> createState() =>
      _ToolFormSheetState();
}

class _ToolFormSheetState extends State<_ToolFormSheet> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _unitController;

  bool _formAttempted = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialName,
    );

    _unitController = TextEditingController(
      text: widget.initialUnit > 0
          ? widget.initialUnit.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_closing) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _formAttempted = true;
    });

    final valid =
        _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    final unit = int.tryParse(
          _unitController.text.trim(),
        ) ??
        0;

    setState(() {
      _closing = true;
    });

    Navigator.of(context).pop(
      _ToolFormResult(
        name: _nameController.text.trim(),
        unit: unit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: media.viewInsets.bottom,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: media.size.height * 0.88,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _cardBorder),
              boxShadow: [
                BoxShadow(
                  color:
                      _adminNavy.withValues(alpha: 0.20),
                  blurRadius: 30,
                  offset: const Offset(0, 13),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior
                        .manual,
                physics:
                    const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  17,
                  12,
                  17,
                  18,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _formAttempted
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          height: 5,
                          width: 43,
                          decoration: BoxDecoration(
                            color: const Color(0xffD4D8E3),
                            borderRadius:
                                BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _sheetHeader(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization:
                            TextCapitalization.words,
                        textInputAction:
                            TextInputAction.next,
                        onTapOutside: (_) {},
                        validator: (value) {
                          final text =
                              value?.trim() ?? '';

                          if (text.isEmpty) {
                            return 'Nama alat wajib diisi.';
                          }

                          if (text.length < 3) {
                            return 'Nama alat minimal 3 karakter.';
                          }

                          return null;
                        },
                        decoration: _inputDecoration(
                          label: 'Nama Alat',
                          hint:
                              'Contoh: Traktor tangan',
                          icon: Icons
                              .precision_manufacturing_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _unitController,
                        keyboardType:
                            TextInputType.number,
                        textInputAction:
                            TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                          LengthLimitingTextInputFormatter(
                            5,
                          ),
                        ],
                        onTapOutside: (_) {},
                        onFieldSubmitted: (_) {
                          _submit();
                        },
                        validator: (value) {
                          final text =
                              value?.trim() ?? '';

                          if (text.isEmpty) {
                            return 'Jumlah unit wajib diisi.';
                          }

                          final unit =
                              int.tryParse(text) ?? 0;

                          if (unit <= 0) {
                            return 'Jumlah unit harus lebih dari 0.';
                          }

                          return null;
                        },
                        decoration: _inputDecoration(
                          label: 'Jumlah Unit',
                          hint: 'Contoh: 5',
                          icon:
                              Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(height: 13),
                      _sheetInformation(),
                      const SizedBox(height: 18),
                      _sheetActions(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHeader() {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: _softIndigo,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            widget.editing
                ? Icons.edit_note_outlined
                : Icons.add_box_outlined,
            color: _adminIndigo,
            size: 24,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                widget.editing
                    ? 'Edit Data Alat'
                    : 'Tambah Alat Desa',
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.editing
                    ? 'Perbarui nama atau jumlah unit.'
                    : 'Tambahkan inventaris pertanian desa.',
                style: const TextStyle(
                  color: _textGrey,
                  fontSize: 9.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Tutup',
          onPressed: _closing
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
          icon: const Icon(
            Icons.close_rounded,
            color: _textGrey,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _sheetInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _softIndigo,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:
              _adminIndigo.withValues(alpha: 0.10),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _adminIndigo,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jumlah unit menjadi jumlah dasar alat yang dilihat pengguna pada halaman peminjaman.',
              style: TextStyle(
                color: _textGrey,
                fontSize: 9.4,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;

        final cancelButton = SizedBox(
          height: 47,
          child: OutlinedButton(
            onPressed: _closing
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: _textGrey,
              side: const BorderSide(
                color: _cardBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );

        final saveButton = SizedBox(
          height: 47,
          child: ElevatedButton.icon(
            onPressed: _closing ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _adminIndigo,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  _adminIndigo.withValues(alpha: 0.38),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(
              Icons.save_outlined,
              size: 18,
            ),
            label: Text(
              widget.editing
                  ? 'Simpan Perubahan'
                  : 'Simpan Alat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );

        if (compact) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: saveButton,
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: cancelButton,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: 9),
            Expanded(
              flex: 2,
              child: saveButton,
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: _textGrey,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: _textSoft,
        fontSize: 10.2,
      ),
      prefixIcon: Icon(
        icon,
        color: _adminIndigo,
        size: 20,
      ),
      filled: true,
      fillColor: const Color(0xffF8F9FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _cardBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _adminIndigo,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _adminRed,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _adminRed,
          width: 1.4,
        ),
      ),
    );
  }
}

class _DeleteToolDialog extends StatelessWidget {
  final String toolName;

  const _DeleteToolDialog({
    required this.toolName,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 350 ? 16 : 24,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 420,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            19,
            22,
            19,
            18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color:
                    _adminNavy.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  color: _softRed,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _adminRed,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Hapus Data Alat?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textDark,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Data “$toolName” akan dihapus permanen dari inventaris desa.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textGrey,
                  fontSize: 10.7,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _softAmber,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: _adminAmber,
                      size: 17,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tindakan ini tidak dapat dibatalkan.',
                        style: TextStyle(
                          color: _textGrey,
                          fontSize: 9.1,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 19),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth < 300;

                  final cancelButton = SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textGrey,
                        side: const BorderSide(
                          color: _cardBorder,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );

                  final deleteButton = SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _adminRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.delete_forever_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Hapus',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );

                  if (compact) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: deleteButton,
                        ),
                        const SizedBox(height: 9),
                        SizedBox(
                          width: double.infinity,
                          child: cancelButton,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: cancelButton),
                      const SizedBox(width: 9),
                      Expanded(child: deleteButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminToolBackground extends StatelessWidget {
  const _AdminToolBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            final large = (base * 1.04)
                .clamp(300.0, 520.0)
                .toDouble();

            final medium = (base * 0.72)
                .clamp(205.0, 360.0)
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
                          Color(0xff142044),
                          Color(0xff293D83),
                          Color(0xffE7EAF8),
                          Color(0xffF4F6FB),
                        ],
                        stops: [
                          0,
                          0.19,
                          0.44,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.57,
                    right: -large * 0.31,
                    child: _AdminBackgroundCircle(
                      size: large,
                      color: const Color(0xff8B72E0),
                      alpha: 0.24,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.26,
                    left: -medium * 0.58,
                    child: _AdminBackgroundCircle(
                      size: medium,
                      color: const Color(0xff8FA6E6),
                      alpha: 0.26,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.52,
                    right: -medium * 0.64,
                    child: _AdminBackgroundCircle(
                      size: medium * 1.10,
                      color: const Color(0xffE0D9F7),
                      alpha: 0.74,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.54,
                    left: -large * 0.31,
                    child: _AdminBackgroundCircle(
                      size: large,
                      color: const Color(0xffE4E9F7),
                      alpha: 0.88,
                    ),
                  ),
                  const Positioned(
                    top: 76,
                    right: 18,
                    child: _ToolWatermark(
                      icon: Icons.agriculture_rounded,
                      size: 70,
                      color: Colors.white,
                      alpha: 0.065,
                      angle: -0.16,
                    ),
                  ),
                  const Positioned(
                    top: 300,
                    left: 16,
                    child: _ToolWatermark(
                      icon: Icons.construction_rounded,
                      size: 58,
                      color: Color(0xff35469C),
                      alpha: 0.055,
                      angle: 0.20,
                    ),
                  ),
                  const Positioned(
                    bottom: 115,
                    right: 18,
                    child: _ToolWatermark(
                      icon: Icons.precision_manufacturing_outlined,
                      size: 66,
                      color: Color(0xff6946C6),
                      alpha: 0.050,
                      angle: -0.12,
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

class _AdminBackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _AdminBackgroundCircle({
    required this.size,
    required this.color,
    required this.alpha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ToolWatermark extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double alpha;
  final double angle;

  const _ToolWatermark({
    required this.icon,
    required this.size,
    required this.color,
    required this.alpha,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Icon(
        icon,
        size: size,
        color: color.withValues(alpha: alpha),
      ),
    );
  }
}