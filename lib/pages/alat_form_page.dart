import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import 'alat_konfirmasi_page.dart';

class AlatFormPage extends StatefulWidget {
  final String idAlat;
  final String namaAlat;
  final String tanggalDipilih;
  final String nama;
  final String nik;

  const AlatFormPage({
    super.key,
    required this.idAlat,
    required this.namaAlat,
    required this.tanggalDipilih,
    required this.nama,
    required this.nik,
  });

  @override
  State<AlatFormPage> createState() => _AlatFormPageState();
}

class _AlatFormPageState extends State<AlatFormPage> {
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
  static const Color textSoft = Color(0xff8B96A2);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softTeal = Color(0xffE6F4F1);
  static const Color softBlue = Color(0xffEAF3FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);

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

  final TextEditingController tanggalKembaliController =
      TextEditingController();

  final TextEditingController catatanController =
      TextEditingController();

  @override
  void dispose() {
    tanggalKembaliController.dispose();
    catatanController.dispose();
    super.dispose();
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

  String _databaseDate(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')} '
        '${_monthNames[value.month - 1]} ${value.year}';
  }

  String _displayDateFromText(String value) {
    final date = _parseDate(value);

    if (date == null) {
      return value.trim().isEmpty ? '-' : value.trim();
    }

    return _displayDate(date);
  }

  String _maskedNik(String value) {
    final clean = value.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (clean.length <= 4) {
      return value;
    }

    return '•••• •••• •••• '
        '${clean.substring(clean.length - 4)}';
  }

  int _loanDuration() {
    final start = _parseDate(widget.tanggalDipilih);

    final end = _parseDate(
      tanggalKembaliController.text,
    );

    if (start == null || end == null) {
      return 0;
    }

    final difference = _dateOnly(end)
        .difference(_dateOnly(start))
        .inDays;

    return difference < 0 ? 0 : difference + 1;
  }

  bool _returnDateValid() {
    final start = _parseDate(widget.tanggalDipilih);

    final end = _parseDate(
      tanggalKembaliController.text,
    );

    if (start == null || end == null) {
      return false;
    }

    return !_dateOnly(end).isBefore(
      _dateOnly(start),
    );
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

  Future<void> _pickReturnDate() async {
    FocusScope.of(context).unfocus();

    final start = _parseDate(
      widget.tanggalDipilih,
    );

    if (start == null) {
      _showSnackBar(
        'Format tanggal pinjam tidak valid.',
        red,
      );
      return;
    }

    final firstDate = _dateOnly(start);

    final currentReturn = _parseDate(
      tanggalKembaliController.text,
    );

    final initialDate = currentReturn != null &&
            !currentReturn.isBefore(firstDate)
        ? _dateOnly(currentReturn)
        : firstDate;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: firstDate.add(
        const Duration(days: 365),
      ),
      helpText: 'Pilih Tanggal Kembali',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (dialogContext, child) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: const ColorScheme.light(
              primary: teal,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textDark,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      tanggalKembaliController.text =
          _databaseDate(selected);
    });
  }

  void _continueToConfirmation() {
    FocusScope.of(context).unfocus();

    if (tanggalKembaliController.text.trim().isEmpty) {
      _showSnackBar(
        'Tanggal kembali wajib dipilih.',
        red,
      );
      return;
    }

    if (!_returnDateValid()) {
      _showSnackBar(
        'Tanggal kembali tidak boleh sebelum tanggal pinjam.',
        red,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlatKonfirmasiPage(
          idAlat: widget.idAlat,
          namaAlat: widget.namaAlat,
          nama: widget.nama,
          nik: widget.nik,
          tanggalPinjam: widget.tanggalDipilih,
          tanggalKembali:
              tanggalKembaliController.text.trim(),
          catatan: catatanController.text.trim(),
        ),
      ),
    );
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
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final keyboardOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0;

    final horizontalPadding = screenWidth < 350
        ? 12.0
        : screenWidth >= 700
            ? 22.0
            : 16.0;

    final validDate = _returnDateValid();
    final duration = _loanDuration();

    final canContinue =
        tanggalKembaliController.text.trim().isNotEmpty &&
            validDate;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: background,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _FormBackground(),
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
                      keyboardOpen ? 24 : 28,
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
                              _identityAndEquipment(),
                              const SizedBox(height: 10),
                              _stepCard(),
                              const SizedBox(height: 10),
                              _loanInformationCard(),
                              const SizedBox(height: 10),
                              _formCard(
                                validDate: validDate,
                                duration: duration,
                              ),
                              const SizedBox(height: 10),
                              _guideCard(),
                              const SizedBox(height: 18),
                              _submitButton(canContinue),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                Icons.edit_note_outlined,
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
                      'Form Peminjaman',
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
                      'Lengkapi tanggal kembali dan catatan',
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

  Widget _identityAndEquipment() {
    final equipmentColor =
        _equipmentColor(widget.namaAlat);

    return _card(
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;

          final applicant = _detailBlock(
            icon: Icons.person_outline_rounded,
            color: primary,
            itemBackground: softGreen,
            label: 'Pemohon',
            title: widget.nama,
            subtitle:
                'NIK ${_maskedNik(widget.nik)}',
          );

          final equipment = _detailBlock(
            icon: _equipmentIcon(widget.namaAlat),
            color: equipmentColor,
            itemBackground:
                equipmentColor.withValues(alpha: 0.09),
            label: 'Alat Dipilih',
            title: widget.namaAlat,
            subtitle: 'Inventaris Desa Penataan',
          );

          if (compact) {
            return Column(
              children: [
                applicant,
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  color: border,
                ),
                const SizedBox(height: 10),
                equipment,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(child: applicant),
              Container(
                width: 1,
                height: 52,
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                color: border,
              ),
              Expanded(child: equipment),
            ],
          );
        },
      ),
    );
  }

  Widget _detailBlock({
    required IconData icon,
    required Color color,
    required Color itemBackground,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBox(
          icon,
          color,
          itemBackground,
          43,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 9.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 8.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepCard() {
    return _card(
      Column(
        children: [
          Row(
            children: [
              _stepCircle('1', true),
              _stepLine(true),
              _stepCircle('2', true),
              _stepLine(true),
              _stepCircle('3', true),
              _stepLine(false),
              _stepCircle('4', false),
            ],
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: teal,
                size: 17,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tahap 3 • Lengkapi detail peminjaman',
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

  Widget _stepCircle(
    String text,
    bool active,
  ) {
    return Container(
      height: 27,
      width: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? teal
            : const Color(0xffEFF3F2),
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? teal : border,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active
              ? Colors.white
              : textSoft,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: active
              ? teal.withValues(alpha: 0.48)
              : const Color(0xffE4EAE8),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _loanInformationCard() {
    final start =
        _parseDate(widget.tanggalDipilih);

    return _card(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.event_available_outlined,
            title: 'Jadwal Pinjam',
            subtitle:
                'Tanggal mulai yang sudah dipilih',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: softTeal,
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color:
                    teal.withValues(alpha: 0.11),
              ),
            ),
            child: Row(
              children: [
                _iconBox(
                  Icons.calendar_today_outlined,
                  teal,
                  Colors.white,
                  42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Pinjam',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 9.4,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        start == null
                            ? widget.tanggalDipilih
                            : _displayDate(start),
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 12.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const _StatusBadge(
                  label: 'TERPILIH',
                  color: teal,
                  background: softTeal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard({
    required bool validDate,
    required int duration,
  }) {
    return _card(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.edit_calendar_outlined,
            title: 'Detail Peminjaman',
            subtitle:
                'Pilih tanggal kembali dan isi catatan',
          ),
          const SizedBox(height: 12),
          _returnDatePicker(
            validDate: validDate,
            duration: duration,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: catatanController,
            minLines: 3,
            maxLines: 5,
            keyboardType:
                TextInputType.multiline,
            textCapitalization:
                TextCapitalization.sentences,
            textInputAction:
                TextInputAction.done,
            scrollPadding:
                const EdgeInsets.only(
              bottom: 120,
            ),
            onTapOutside: (_) {},
            onSubmitted: (_) {
              FocusScope.of(context).unfocus();
            },
            decoration: _inputDecoration(
              label: 'Catatan / Keperluan',
              hint:
                  'Contoh: digunakan untuk mengolah lahan atau penyemprotan.',
              icon: Icons.notes_outlined,
            ),
          ),
          const SizedBox(height: 12),
          _durationInfo(
            validDate: validDate,
            duration: duration,
          ),
        ],
      ),
    );
  }

  Widget _returnDatePicker({
    required bool validDate,
    required int duration,
  }) {
    final raw =
        tanggalKembaliController.text.trim();

    final hasValue = raw.isNotEmpty;

    final color = !hasValue
        ? teal
        : validDate
            ? primary
            : red;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: _pickReturnDate,
        borderRadius:
            BorderRadius.circular(16),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                color.withValues(alpha: 0.075),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  color.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              _iconBox(
                Icons.event_repeat_outlined,
                color,
                Colors.white,
                45,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal Kembali',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 9.5,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasValue
                          ? _displayDateFromText(raw)
                          : 'Pilih tanggal kembali',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasValue
                            ? textDark
                            : color,
                        fontSize: 12.6,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    if (hasValue) ...[
                      const SizedBox(height: 4),
                      Text(
                        validDate
                            ? 'Durasi peminjaman $duration hari'
                            : 'Tanggal kembali tidak valid',
                        style: TextStyle(
                          color: color,
                          fontSize: 8.9,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: color,
                size: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationInfo({
    required bool validDate,
    required int duration,
  }) {
    final hasReturnDate =
        tanggalKembaliController.text
            .trim()
            .isNotEmpty;

    final color = hasReturnDate && validDate
        ? primary
        : hasReturnDate
            ? red
            : amber;

    final itemBackground =
        hasReturnDate && validDate
            ? softGreen
            : hasReturnDate
                ? softRed
                : softAmber;

    final title = hasReturnDate && validDate
        ? 'Jadwal peminjaman siap dikonfirmasi'
        : hasReturnDate
            ? 'Periksa kembali tanggal peminjaman'
            : 'Tanggal kembali belum dipilih';

    final message = hasReturnDate && validDate
        ? 'Alat akan dipinjam selama $duration hari. Catatan bersifat opsional.'
        : hasReturnDate
            ? 'Tanggal kembali harus sama dengan atau setelah tanggal pinjam.'
            : 'Pilih tanggal pengembalian sebelum melanjutkan.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: itemBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            hasReturnDate && validDate
                ? Icons.check_circle_outline_rounded
                : hasReturnDate
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.1,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9.1,
                    height: 1.4,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideCard() {
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: blue,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Setelah halaman konfirmasi dikirim, admin akan memeriksa jadwal dan ketersediaan alat.',
              style: TextStyle(
                color: textGrey,
                fontSize: 9.4,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton(bool enabled) {
    return SizedBox(
      width: double.infinity,
      height: 51,
      child: ElevatedButton.icon(
        onPressed: enabled
            ? _continueToConfirmation
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              teal.withValues(alpha: 0.28),
          disabledForegroundColor:
              Colors.white.withValues(alpha: 0.86),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(
          enabled
              ? Icons.arrow_forward_rounded
              : Icons.event_repeat_outlined,
          size: 19,
        ),
        label: Text(
          enabled
              ? 'Lanjut Konfirmasi'
              : 'Pilih Tanggal Kembali',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12.3,
            fontWeight: FontWeight.w900,
          ),
        ),
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

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      labelStyle: const TextStyle(
        color: textGrey,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: textSoft,
        fontSize: 10.3,
        height: 1.35,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(
          bottom: 56,
        ),
        child: Icon(
          icon,
          color: teal,
          size: 20,
        ),
      ),
      filled: true,
      fillColor: const Color(0xffF8FAF9),
      contentPadding: const EdgeInsets.fromLTRB(
        14,
        17,
        14,
        14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: teal,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
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
        color: Colors.white.withValues(
          alpha: 0.98,
        ),
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

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 7.4,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}

class _FormBackground extends StatelessWidget {
  const _FormBackground();

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
        color: color.withValues(
          alpha: alpha,
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}