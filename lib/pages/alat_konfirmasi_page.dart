import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class AlatKonfirmasiPage extends StatefulWidget {
  final String idAlat;
  final String namaAlat;
  final String nama;
  final String nik;
  final String tanggalPinjam;
  final String tanggalKembali;
  final String catatan;

  const AlatKonfirmasiPage({
    super.key,
    required this.idAlat,
    required this.namaAlat,
    required this.nama,
    required this.nik,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.catatan,
  });

  @override
  State<AlatKonfirmasiPage> createState() =>
      _AlatKonfirmasiPageState();
}

class _AlatKonfirmasiPageState
    extends State<AlatKonfirmasiPage> {
  static const Color primary = Color(0xff2E7D32);
  static const Color dark = Color(0xff14532D);
  static const Color teal = Color(0xff167A6B);
  static const Color deepTeal = Color(0xff0E5F57);
  static const Color blue = Color(0xff326FA3);
  static const Color amber = Color(0xffD98212);
  static const Color red = Color(0xffC83B3B);

  static const Color background = Color(0xffF2F7F5);
  static const Color border = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color softBlue = Color(0xffEAF3FA);
  static const Color softAmber = Color(0xffFFF3DD);

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  bool isLoading = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference peminjamanRef;

  @override
  void initState() {
    super.initState();

    peminjamanRef = db.ref('peminjaman_alat');
  }

  DateTime? _parseDate(String value) {
    final raw = value.trim();

    if (raw.isEmpty || raw == '-') {
      return null;
    }

    final dateOnly = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(raw);

    if (dateOnly != null) {
      return DateTime(
        int.parse(dateOnly.group(1)!),
        int.parse(dateOnly.group(2)!),
        int.parse(dateOnly.group(3)!),
      );
    }

    final reverseDate = RegExp(
      r'^(\d{2})[-/](\d{2})[-/](\d{4})$',
    ).firstMatch(raw);

    if (reverseDate != null) {
      return DateTime(
        int.parse(reverseDate.group(3)!),
        int.parse(reverseDate.group(2)!),
        int.parse(reverseDate.group(1)!),
      );
    }

    final parsed = DateTime.tryParse(raw);

    if (parsed == null) {
      return null;
    }

    final local = parsed.toLocal();

    return DateTime(
      local.year,
      local.month,
      local.day,
    );
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  String _displayDate(String value) {
    final date = _parseDate(value);

    if (date == null) {
      return value.trim().isEmpty ? '-' : value.trim();
    }

    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthNames[date.month - 1]} ${date.year}';
  }

  int _loanDuration() {
    final start = _parseDate(widget.tanggalPinjam);
    final end = _parseDate(widget.tanggalKembali);

    if (start == null || end == null) {
      return 0;
    }

    final difference = _dateOnly(end)
        .difference(_dateOnly(start))
        .inDays;

    return difference < 0 ? 0 : difference + 1;
  }

  bool _dateValid() {
    final start = _parseDate(widget.tanggalPinjam);
    final end = _parseDate(widget.tanggalKembali);

    if (start == null || end == null) {
      return false;
    }

    return !_dateOnly(end).isBefore(
      _dateOnly(start),
    );
  }

  String _normalizedNik(String value) {
    return value
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();
  }

  String _maskedNik(String value) {
    final clean = _normalizedNik(value);

    if (clean.length <= 4) {
      return value;
    }

    return '•••• •••• •••• '
        '${clean.substring(clean.length - 4)}';
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

    return Icons.construction_outlined;
  }

  Color _equipmentColor(String value) {
    final name = value.toLowerCase();

    if (name.contains('sprayer') ||
        name.contains('semprot')) {
      return blue;
    }

    if (name.contains('cangkul')) {
      return amber;
    }

    if (name.contains('traktor')) {
      return primary;
    }

    return teal;
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final width = MediaQuery.sizeOf(dialogContext).width;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: width < 350 ? 16 : 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                18,
                21,
                18,
                17,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: deepTeal.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBox(
                    Icons.send_rounded,
                    teal,
                    softTeal,
                    62,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Kirim Pengajuan?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Peminjaman ${widget.namaAlat} akan dikirim kepada admin untuk diperiksa.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.2,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: softAmber,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: amber.withValues(alpha: 0.10),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: amber,
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Setelah dikirim, jadwal menunggu keputusan admin.',
                            style: TextStyle(
                              color: textGrey,
                              fontSize: 9.3,
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

                      if (compact) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(
                                    false,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textGrey,
                                  side: const BorderSide(
                                    color: border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Periksa Lagi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(
                                    true,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: teal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Kirim Sekarang',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(
                                    false,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textGrey,
                                  side: const BorderSide(
                                    color: border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Periksa Lagi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(
                                    true,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: teal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.send_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Kirim',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitLoan() async {
    if (isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    if (widget.idAlat.trim().isEmpty) {
      _showSnackBar(
        'Data alat tidak valid.',
        red,
      );
      return;
    }

    if (widget.namaAlat.trim().isEmpty) {
      _showSnackBar(
        'Nama alat tidak valid.',
        red,
      );
      return;
    }

    if (widget.nama.trim().isEmpty) {
      _showSnackBar(
        'Data pemohon tidak valid.',
        red,
      );
      return;
    }

    if (_normalizedNik(widget.nik).isEmpty) {
      _showSnackBar(
        'NIK pemohon tidak valid.',
        red,
      );
      return;
    }

    if (!_dateValid()) {
      _showSnackBar(
        'Tanggal peminjaman tidak valid.',
        red,
      );
      return;
    }

    final confirmed =
        await _showConfirmationDialog();

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool notificationSent = true;

    try {
      final now = DateTime.now().toIso8601String();

      final reference = peminjamanRef.push();
      final loanId = reference.key ?? '';

      if (loanId.isEmpty) {
        throw Exception(
          'ID peminjaman tidak dapat dibuat.',
        );
      }

      await reference.set({
        'id_alat': widget.idAlat.trim(),
        'alat': widget.namaAlat.trim(),
        'nama': widget.nama.trim(),
        'nik': _normalizedNik(widget.nik),
        'tanggal_pinjam':
            widget.tanggalPinjam.trim(),
        'tanggal_kembali':
            widget.tanggalKembali.trim(),
        'catatan': widget.catatan.trim(),
        'jumlah': 1,
        'jumlah_alat': 1,
        'status': 'menunggu',
        'tanggal_pengajuan': now,
      }).timeout(
        const Duration(seconds: 15),
      );

      try {
        await NotificationHelper.peminjamanAlatUntukAdmin(
          nik: _normalizedNik(widget.nik),
          nama: widget.nama.trim(),
          namaAlat: widget.namaAlat.trim(),
          jumlah: 1,
          tanggalPinjam: widget.tanggalPinjam.trim(),
          tanggalKembali: widget.tanggalKembali.trim(),
          eventId: loanId,
        );
      } catch (error) {
        notificationSent = false;
        debugPrint(
          'Peminjaman tersimpan, tetapi notifikasi admin gagal: $error',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
      });

      await _showSuccessDialog(
        notificationSent: notificationSent,
      );

      if (!mounted) {
        return;
      }

      _closeLoanFlow();
    } catch (error) {
      debugPrint(
        'Gagal mengirim peminjaman alat: $error',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal mengirim pengajuan. Periksa koneksi internet lalu coba kembali.',
        red,
      );
    } finally {
      if (mounted && isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog({
    required bool notificationSent,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final screenWidth =
            MediaQuery.sizeOf(dialogContext).width;

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
                23,
                19,
                18,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: deepTeal.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBox(
                    Icons.check_circle_rounded,
                    primary,
                    softGreen,
                    66,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pengajuan Berhasil',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Pengajuan peminjaman sudah tersimpan dan menunggu pemeriksaan admin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 11.2,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!notificationSent) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: softAmber,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: amber.withValues(alpha: 0.10),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: amber,
                            size: 17,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pemberitahuan admin belum terkirim, tetapi pengajuan tetap dapat dilihat admin.',
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 9,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 19),
                  SizedBox(
                    width: double.infinity,
                    height: 47,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(
                        Icons.done_rounded,
                        size: 19,
                      ),
                      label: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
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
  }

  void _closeLoanFlow() {
    final navigator = Navigator.of(context);

    for (int index = 0; index < 4; index++) {
      if (!navigator.canPop()) {
        break;
      }

      navigator.pop();
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
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.fixed,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final horizontalPadding = screenWidth < 350
        ? 12.0
        : screenWidth >= 700
            ? 22.0
            : 16.0;

    final duration = _loanDuration();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: background,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _ConfirmationBackground(),
                SafeArea(
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
                          constraints: const BoxConstraints(
                            maxWidth: 760,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              _header(),
                              const SizedBox(height: 12),
                              _stepCard(),
                              const SizedBox(height: 10),
                              _equipmentStatusCard(duration),
                              const SizedBox(height: 10),
                              _detailCard(duration),
                              const SizedBox(height: 10),
                              _informationCard(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading) _loadingOverlay(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _bottomButton(),
    );
  }

  Widget _header() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 370;

        return Container(
          padding: EdgeInsets.all(
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                dark,
                deepTeal,
                teal,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: deepTeal.withValues(alpha: 0.23),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              _backButton(),
              SizedBox(width: compact ? 9 : 11),
              _iconBox(
                Icons.fact_check_outlined,
                Colors.white,
                Colors.white.withValues(alpha: 0.14),
                compact ? 43 : 47,
              ),
              SizedBox(width: compact ? 9 : 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Konfirmasi Peminjaman',
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
                      'Periksa data sebelum dikirim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xffD7EEE7),
                        fontSize: 10.2,
                        fontWeight: FontWeight.w600,
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

  Widget _stepCard() {
    return _card(
      Column(
        children: [
          Row(
            children: [
              _stepCircle('1'),
              _stepLine(),
              _stepCircle('2'),
              _stepLine(),
              _stepCircle('3'),
              _stepLine(),
              _stepCircle('4'),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.verified_outlined,
                color: teal,
                size: 17,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tahap 4 • Periksa dan kirim pengajuan',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 10.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
    );
  }

  Widget _stepCircle(String text) {
    return Container(
      height: 27,
      width: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: teal,
        shape: BoxShape.circle,
        border: Border.all(color: teal),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _stepLine() {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: teal.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _equipmentStatusCard(int duration) {
    final equipmentColor =
        _equipmentColor(widget.namaAlat);

    return _card(
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 330;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.namaAlat,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _badge(
                    icon: Icons.schedule_outlined,
                    label: 'Menunggu Admin',
                    color: amber,
                    badgeBackground: softAmber,
                  ),
                  _badge(
                    icon: Icons.timelapse_outlined,
                    label: duration > 0
                        ? '$duration Hari'
                        : 'Durasi -',
                    color: primary,
                    badgeBackground: softGreen,
                  ),
                  _badge(
                    icon: Icons.inventory_2_outlined,
                    label: '1 Unit',
                    color: blue,
                    badgeBackground: softBlue,
                  ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _iconBox(
                      _equipmentIcon(widget.namaAlat),
                      equipmentColor,
                      equipmentColor.withValues(alpha: 0.09),
                      47,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: content),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _iconBox(
                _equipmentIcon(widget.namaAlat),
                equipmentColor,
                equipmentColor.withValues(alpha: 0.09),
                50,
              ),
              const SizedBox(width: 11),
              Expanded(child: content),
              const SizedBox(width: 8),
              _iconBox(
                Icons.check_circle_outline_rounded,
                primary,
                softGreen,
                38,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailCard(int duration) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Detail Pengajuan',
            subtitle:
                'Pastikan seluruh informasi sudah benar',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xffF8FAF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Nama Pemohon',
                  value: widget.nama,
                ),
                _detailRow(
                  icon: Icons.badge_outlined,
                  label: 'NIK',
                  value: _maskedNik(widget.nik),
                ),
                _detailRow(
                  icon: _equipmentIcon(widget.namaAlat),
                  label: 'Alat',
                  value: widget.namaAlat,
                ),
                _detailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Tanggal Pinjam',
                  value: _displayDate(
                    widget.tanggalPinjam,
                  ),
                ),
                _detailRow(
                  icon: Icons.event_repeat_outlined,
                  label: 'Tanggal Kembali',
                  value: _displayDate(
                    widget.tanggalKembali,
                  ),
                ),
                _detailRow(
                  icon: Icons.timelapse_outlined,
                  label: 'Durasi',
                  value: duration > 0
                      ? '$duration hari'
                      : '-',
                  valueColor: primary,
                ),
                _detailRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Jumlah',
                  value: '1 unit',
                ),
                _detailRow(
                  icon: Icons.notes_outlined,
                  label: 'Catatan',
                  value: widget.catatan.trim().isEmpty
                      ? 'Tidak ada catatan'
                      : widget.catatan.trim(),
                  last: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool last = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 330;

        final iconWidget = Container(
          height: 31,
          width: 31,
          decoration: BoxDecoration(
            color: softTeal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: teal,
            size: 16,
          ),
        );

        final content = compact
            ? Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 9.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value.trim().isEmpty ? '-' : value,
                    style: TextStyle(
                      color: valueColor ?? textDark,
                      fontSize: 10.7,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 9.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value.trim().isEmpty ? '-' : value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: valueColor ?? textDark,
                        fontSize: 10.2,
                        height: 1.35,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              );

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: last
                  ? BorderSide.none
                  : const BorderSide(color: border),
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              iconWidget,
              const SizedBox(width: 9),
              Expanded(child: content),
            ],
          ),
        );
      },
    );
  }

  Widget _informationCard() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: blue.withValues(alpha: 0.10),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: blue,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pengajuan akan masuk ke admin untuk diverifikasi. Alat baru tercatat dipinjam setelah admin menyetujui dan menandai alat sudah diambil.',
              style: TextStyle(
                color: textGrey,
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

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        _iconBox(
          icon,
          teal,
          softTeal,
          38,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 9.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
    required Color badgeBackground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: badgeBackground,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
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
              fontSize: 8.6,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton() {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: deepTeal.withValues(alpha: 0.13),
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
                maxWidth: 760,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 51,
                child: ElevatedButton.icon(
                  onPressed:
                      isLoading ? null : _submitLoan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        teal.withValues(alpha: 0.38),
                    disabledForegroundColor:
                        Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.3,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          size: 19,
                        ),
                  label: Text(
                    isLoading
                        ? 'Mengirim Pengajuan...'
                        : 'Ajukan Peminjaman',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
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

  Widget _loadingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: deepTeal.withValues(alpha: 0.30),
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
                  color: deepTeal.withValues(alpha: 0.18),
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
                    color: teal,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 13),
                Text(
                  'Mengirim Pengajuan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Mohon tunggu dan jangan menutup halaman.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey,
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
        onTap: isLoading
            ? null
            : () {
                FocusScope.of(context).unfocus();
                Navigator.maybePop(context);
              },
        borderRadius: BorderRadius.circular(14),
        child: _iconBox(
          Icons.arrow_back_rounded,
          Colors.white,
          Colors.white.withValues(alpha: 0.14),
          42,
        ),
      ),
    );
  }

  Widget _iconBox(
    IconData icon,
    Color color,
    Color iconBackground,
    double size,
  ) {
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

  Widget _card(
    Widget child, {
    EdgeInsets padding =
        const EdgeInsets.all(13),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: deepTeal.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ConfirmationBackground extends StatelessWidget {
  const _ConfirmationBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base =
                constraints.maxWidth <
                        constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;

            final large = (base * 0.98)
                .clamp(280.0, 470.0)
                .toDouble();

            final medium = (base * 0.67)
                .clamp(190.0, 330.0)
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
                          Color(0xff0E5F57),
                          Color(0xff167A6B),
                          Color(0xffDDEFEA),
                          Color(0xffF2F7F5),
                        ],
                        stops: [
                          0,
                          0.18,
                          0.43,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -large * 0.55,
                    right: -large * 0.30,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(
                        0xff58B89F,
                      ),
                      alpha: 0.20,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.31,
                    left: -medium * 0.58,
                    child: _BackgroundCircle(
                      size: medium,
                      color: const Color(
                        0xffA7DACD,
                      ),
                      alpha: 0.34,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.31,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(
                        0xffDDEFE6,
                      ),
                      alpha: 0.82,
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

class _BackgroundCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _BackgroundCircle({
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