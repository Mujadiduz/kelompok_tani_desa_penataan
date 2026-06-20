import 'package:flutter/material.dart';
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
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color orangeStatus = Color(0xffFB8C00);
  static const Color blueStatus = Color(0xff1976D2);

  final tanggalKembaliController = TextEditingController();
  final catatanController = TextEditingController();

  @override
  void dispose() {
    tanggalKembaliController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  void lanjutKonfirmasi() {
    if (tanggalKembaliController.text.trim().isEmpty) {
      _showSnackBar('Tanggal kembali wajib diisi', Colors.red);
      return;
    }

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
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
  final tanggalPinjam = _parseTanggal(widget.tanggalDipilih);

  if (tanggalPinjam == null) {
    _showSnackBar('Format tanggal pinjam tidak valid', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    final validTanggal = tanggalKembaliValid();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: _stepIndicator(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: _alatInfoCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child: _anggotaCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                child: _formCard(validTanggal),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomSubmitBar(validTanggal),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff14532D), Color(0xff2E7D32), Color(0xff66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            bottom: -42,
            child: Icon(
              Icons.assignment_rounded,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _backButton(context),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Form Peminjaman',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Isi Data Peminjaman',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Lengkapi tanggal kembali dan catatan keperluan sebelum dikirim ke admin.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${widget.nama}\nNIK: ${widget.nik}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _stepIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stepCircle('1', 'Pilih', true, completed: true),
          _stepLine(true),
          _stepCircle('2', 'Jadwal', true, completed: true),
          _stepLine(true),
          _stepCircle('3', 'Data', true),
          _stepLine(false),
          _stepCircle('4', 'Kirim', false),
        ],
      ),
    );
  }

  Widget _stepCircle(
    String number,
    String label,
    bool active, {
    bool completed = false,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: active ? primaryGreen : const Color(0xffE5E7EB),
            shape: BoxShape.circle,
            boxShadow:
                active
                    ? [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.24),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ]
                    : [],
          ),
          child: Center(
            child:
                completed
                    ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                    : Text(
                      number,
                      style: TextStyle(
                        color: active ? Colors.white : textGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? primaryGreen : textGrey,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: 3,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: active ? primaryGreen : const Color(0xffE5E7EB),
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _alatInfoCard() {
    final color = warnaAlat(widget.namaAlat);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _infoRow(
            icon: iconAlat(widget.namaAlat),
            iconColor: color,
            title: 'Alat Dipilih',
            value: widget.namaAlat,
          ),
          const Divider(height: 24),
          _infoRow(
            icon: Icons.qr_code_rounded,
            iconColor: primaryGreen,
            title: 'ID Alat',
            value: widget.idAlat,
          ),
          const Divider(height: 24),
          _infoRow(
            icon: Icons.calendar_month_rounded,
            iconColor: primaryGreen,
            title: 'Tanggal Pinjam',
            value: widget.tanggalDipilih,
          ),
        ],
      ),
    );
  }

  Widget _anggotaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Data Anggota',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'AKTIF',
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _smallInfo(Icons.person_rounded, 'Nama', widget.nama),
          _smallInfo(Icons.badge_rounded, 'NIK', widget.nik),
        ],
      ),
    );
  }

  Widget _formCard(bool validTanggal) {
    final durasi = durasiHari();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Peminjaman',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih tanggal kembali dan tulis catatan keperluan peminjaman.',
            style: TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: tanggalKembaliController,
            readOnly: true,
            decoration: _inputDecoration(
              label: 'Tanggal Kembali',
              icon: Icons.event_available_rounded,
              suffixIcon: Icons.calendar_month_rounded,
            ),
            onTap: pilihTanggalKembali,
          ),
          if (tanggalKembaliController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _durationBox(validTanggal, durasi),
          ],
          const SizedBox(height: 13),
          TextField(
            controller: catatanController,
            maxLines: 3,
            decoration: _inputDecoration(
              label: 'Catatan / Keperluan',
              icon: Icons.notes_rounded,
            ),
          ),
          const SizedBox(height: 16),
          _ringkasanMini(validTanggal, durasi),
        ],
      ),
    );
  }

  Widget _durationBox(bool validTanggal, int durasi) {
    final color = validTanggal ? primaryGreen : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            validTanggal ? Icons.timer_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              validTanggal
                  ? 'Durasi peminjaman sekitar $durasi hari.'
                  : 'Tanggal kembali tidak boleh sebelum tanggal pinjam.',
              style: const TextStyle(
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

  Widget _ringkasanMini(bool validTanggal, int durasi) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
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
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
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
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSubmitBar(bool validTanggal) {
    final bisaLanjut =
        tanggalKembaliController.text.trim().isNotEmpty && validTanggal;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: primaryGreen.withValues(alpha: 0.42),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(19),
              ),
            ),
            onPressed: bisaLanjut ? lanjutKonfirmasi : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: Text(
              bisaLanjut ? 'Lanjut Konfirmasi' : 'Pilih Tanggal Kembali',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Icon(icon, color: iconColor, size: 25),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _smallInfo(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 82,
            child: Text(
              title,
              style: const TextStyle(
                color: textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: textDark,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey),
      prefixIcon: Icon(icon, color: primaryGreen),
      suffixIcon:
          suffixIcon == null ? null : Icon(suffixIcon, color: primaryGreen),
      filled: true,
      fillColor: const Color(0xffF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.045),
          blurRadius: 14,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}
