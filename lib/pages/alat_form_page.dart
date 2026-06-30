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
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color redStatus = Color(0xffDC2626);
  static const Color blueStatus = Color(0xff2563EB);

  final TextEditingController tanggalKembaliController =
      TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  @override
  void dispose() {
    tanggalKembaliController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  void lanjutKonfirmasi() {
    FocusScope.of(context).unfocus();

    if (tanggalKembaliController.text.trim().isEmpty) {
      _showSnackBar('Tanggal kembali wajib diisi', redStatus);
      return;
    }

    if (!tanggalKembaliValid()) {
      _showSnackBar(
        'Tanggal kembali tidak boleh sebelum tanggal pinjam',
        redStatus,
      );
      return;
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AlatKonfirmasiPage(
              idAlat: widget.idAlat,
              namaAlat: widget.namaAlat,
              nama: widget.nama,
              nik: widget.nik,
              tanggalPinjam: widget.tanggalDipilih,
              tanggalKembali: tanggalKembaliController.text.trim(),
              catatan: catatanController.text.trim(),
            ),
      ),
    );
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

  IconData iconAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return Icons.water_drop_rounded;
    if (alat.contains('cangkul')) return Icons.construction_rounded;
    if (alat.contains('traktor')) return Icons.agriculture_rounded;

    return Icons.handyman_rounded;
  }

  Color warnaAlat(String nama) {
    final alat = nama.toLowerCase();

    if (alat.contains('sprayer')) return blueStatus;
    if (alat.contains('cangkul')) return const Color(0xffD97706);
    if (alat.contains('traktor')) return orangeStatus;

    return primaryGreen;
  }

  Future<void> pilihTanggalKembali() async {
    FocusScope.of(context).unfocus();

    final tanggalPinjam = _parseTanggal(widget.tanggalDipilih);

    if (tanggalPinjam == null) {
      _showSnackBar('Format tanggal pinjam tidak valid', redStatus);
      return;
    }

    final awalPinjam = DateTime(
      tanggalPinjam.year,
      tanggalPinjam.month,
      tanggalPinjam.day,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: awalPinjam,
      firstDate: awalPinjam,
      lastDate: awalPinjam.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Kembali',
      confirmText: 'Pilih',
      cancelText: 'Batal',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        tanggalKembaliController.text = _formatTanggal(picked);
      });
    }
  }

  DateTime? _parseTanggal(String value) {
    try {
      final clean = value.trim();

      if (clean.contains('-')) {
        final parts = clean.split('-');

        if (parts.length != 3) return null;

        if (parts[0].length == 4) {
          return DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length != 3) return null;

        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  String _formatTanggal(DateTime date) {
    return '${date.year}-${_duaDigit(date.month)}-${_duaDigit(date.day)}';
  }

  String _duaDigit(int value) {
    return value.toString().padLeft(2, '0');
  }

  int durasiHari() {
    final pinjam = _parseTanggal(widget.tanggalDipilih);
    final kembali = _parseTanggal(tanggalKembaliController.text.trim());

    if (pinjam == null || kembali == null) return 0;

    final awal = DateTime(pinjam.year, pinjam.month, pinjam.day);
    final akhir = DateTime(kembali.year, kembali.month, kembali.day);

    final selisih = akhir.difference(awal).inDays;
    return selisih < 0 ? 0 : selisih + 1;
  }

  bool tanggalKembaliValid() {
    if (tanggalKembaliController.text.trim().isEmpty) return false;

    final pinjam = _parseTanggal(widget.tanggalDipilih);
    final kembali = _parseTanggal(tanggalKembaliController.text.trim());

    if (pinjam == null || kembali == null) return false;

    final awal = DateTime(pinjam.year, pinjam.month, pinjam.day);
    final akhir = DateTime(kembali.year, kembali.month, kembali.day);

    return !akhir.isBefore(awal);
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final validTanggal = tanggalKembaliValid();
    final durasi = durasiHari();

    final bisaLanjut =
        tanggalKembaliController.text.trim().isNotEmpty && validTanggal;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 24),
              children: [
                _headerPage(),
                const SizedBox(height: 14),
                _userInfoCard(),
                const SizedBox(height: 12),
                _stepCard(),
                const SizedBox(height: 12),
                _alatInfoCard(),
                const SizedBox(height: 12),
                _formCard(validTanggal, durasi),
                const SizedBox(height: 12),
                _guideCard(),
                const SizedBox(height: 18),
                _submitButton(bisaLanjut),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerPage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _backButton(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Form Peminjaman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lengkapi jadwal kembali',
                  style: TextStyle(
                    color: Color(0xffD1FAE5),
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _userInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: primaryGreen,
              size: 25,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Pemohon',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'NIK ${sensorNik(widget.nik)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: primaryGreen,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepDot('1', true),
              _stepLine(true),
              _stepDot('2', true),
              _stepLine(true),
              _stepDot('3', true),
              _stepLine(false),
              _stepDot('4', false),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tahap 3 dari 4',
            style: TextStyle(
              color: primaryGreen,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tentukan tanggal kembali dan isi catatan jika diperlukan.',
            style: TextStyle(
              color: textGrey,
              fontSize: 11.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(String text, bool active) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: active ? primaryGreen : const Color(0xffEEF2F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? primaryGreen : borderColor),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : textGrey,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color:
              active
                  ? primaryGreen.withValues(alpha: 0.55)
                  : const Color(0xffE5E7EB),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _alatInfoCard() {
    final color = warnaAlat(widget.namaAlat);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.agriculture_rounded,
            title: 'Data Alat',
            subtitle: 'Alat dan tanggal pinjam yang dipilih',
          ),
          const SizedBox(height: 13),
          _infoArea(
            children: [
              _infoRow(
                iconAlat(widget.namaAlat),
                'Alat',
                widget.namaAlat,
                iconColor: color,
              ),
              _infoRow(
                Icons.calendar_month_rounded,
                'Tanggal Pinjam',
                widget.tanggalDipilih,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formCard(bool validTanggal, int durasi) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.assignment_rounded,
            title: 'Detail Peminjaman',
            subtitle: 'Lengkapi tanggal kembali',
          ),
          const SizedBox(height: 13),
          _tanggalKembaliCard(validTanggal, durasi),
          const SizedBox(height: 12),
          TextField(
            controller: catatanController,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(
              label: 'Catatan / Keperluan',
              icon: Icons.notes_rounded,
            ),
          ),
          const SizedBox(height: 14),
          _ringkasanMini(validTanggal, durasi),
        ],
      ),
    );
  }

  Widget _tanggalKembaliCard(bool validTanggal, int durasi) {
    final hasValue = tanggalKembaliController.text.trim().isNotEmpty;
    final color =
        !hasValue
            ? primaryGreen
            : validTanggal
            ? primaryGreen
            : redStatus;

    return InkWell(
      onTap: pilihTanggalKembali,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.event_available_rounded,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Kembali',
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasValue
                        ? tanggalKembaliController.text.trim()
                        : 'Pilih tanggal kembali',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue ? textDark : color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (hasValue) ...[
                    const SizedBox(height: 6),
                    Text(
                      validTanggal
                          ? 'Durasi peminjaman $durasi hari'
                          : 'Tanggal tidak valid',
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.calendar_month_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _ringkasanMini(bool validTanggal, int durasi) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _summaryRow('Alat', widget.namaAlat),
          _summaryRow('Tanggal Pinjam', widget.tanggalDipilih),
          _summaryRow(
            'Tanggal Kembali',
            tanggalKembaliController.text.trim().isEmpty
                ? '-'
                : tanggalKembaliController.text.trim(),
          ),
          _summaryRow(
            'Durasi',
            validTanggal && durasi > 0 ? '$durasi hari' : '-',
            valueColor: validTanggal ? primaryGreen : textDark,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _guideCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.075),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.16)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primaryGreen, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Pastikan tanggal kembali sudah sesuai sebelum melanjutkan ke halaman konfirmasi.',
              style: TextStyle(
                color: primaryGreen,
                fontSize: 12.2,
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
      height: 52,
      child: ElevatedButton.icon(
        onPressed: enabled ? lanjutKonfirmasi : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryGreen.withValues(alpha: 0.36),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
        label: Text(
          enabled ? 'Lanjut Konfirmasi' : 'Pilih Tanggal Kembali',
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
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
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: primaryGreen, size: 21),
        ),
        const SizedBox(width: 10),
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
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoArea({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 3),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: textDark,
                fontSize: 11.8,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              isLast ? BorderSide.none : const BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? textDark,
                fontSize: 11.8,
                fontWeight: FontWeight.w900,
              ),
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
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
      labelStyle: const TextStyle(
        color: textGrey,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: primaryGreen, size: 21),
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryGreen, width: 1.4),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 18}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.032),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
