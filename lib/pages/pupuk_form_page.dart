import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_background.dart';
import 'pupuk_konfirmasi_page.dart';

class PupukFormPage extends StatefulWidget {
  final String idPupuk;
  final String namaPupuk;
  final String namaUser;
  final String nikUser;

  const PupukFormPage({
    super.key,
    required this.idPupuk,
    required this.namaPupuk,
    required this.namaUser,
    required this.nikUser,
  });

  @override
  State<PupukFormPage> createState() => _PupukFormPageState();
}

class _PupukFormPageState extends State<PupukFormPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color bgColor = Color(0xffF6FAF7);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color redStatus = Color(0xffDC2626);

  final TextEditingController jumlahPupukController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  @override
  void dispose() {
    jumlahPupukController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  double jumlahDiajukan() {
    return double.tryParse(
          jumlahPupukController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  void lanjutKonfirmasi() {
    FocusScope.of(context).unfocus();

    if (widget.idPupuk.trim().isEmpty) {
      _showSnackBar('Data pupuk tidak valid.', redStatus);
      return;
    }

    final jumlahText = jumlahPupukController.text.trim();

    if (jumlahText.isEmpty) {
      _showSnackBar('Jumlah pupuk wajib diisi.', redStatus);
      return;
    }

    final jumlah = double.tryParse(jumlahText.replaceAll(',', '.'));

    if (jumlah == null || jumlah <= 0) {
      _showSnackBar('Jumlah pupuk tidak valid.', redStatus);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PupukKonfirmasiPage(
              idPupuk: widget.idPupuk,
              namaPupuk: widget.namaPupuk,
              nama: widget.namaUser,
              nik: widget.nikUser.trim(),
              jumlahPupuk: jumlahText,
              catatan: catatanController.text.trim(),
            ),
      ),
    );
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bisaLanjut = jumlahPupukController.text.trim().isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      body: AppBackground(
        showPattern: false,
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            padding: EdgeInsets.fromLTRB(16, 14, 16, bottomInset + 24),
            children: [
              _headerPage(),
              const SizedBox(height: 14),
              _pupukCard(),
              const SizedBox(height: 12),
              _anggotaCard(),
              const SizedBox(height: 12),
              _formCard(),
              const SizedBox(height: 14),
              _infoBox(),
              const SizedBox(height: 18),
              _submitButton(bisaLanjut),
            ],
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
                  'Pengajuan Pupuk',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Lengkapi data pengajuan',
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

  Widget _pupukCard() {
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
              Icons.inventory_2_rounded,
              color: primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jenis Pupuk Dipilih',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 11.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.namaPupuk,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: primaryGreen,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _anggotaCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.person_rounded,
            title: 'Data Pemohon',
            subtitle: 'Data anggota yang mengajukan',
          ),
          const SizedBox(height: 13),
          _infoArea(
            children: [
              _infoRow(Icons.person_outline_rounded, 'Nama', widget.namaUser),
              _infoRow(Icons.badge_outlined, 'NIK', sensorNik(widget.nikUser)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.edit_note_rounded,
            title: 'Form Pengajuan',
            subtitle: 'Masukkan jumlah pupuk yang dibutuhkan',
          ),
          const SizedBox(height: 13),
          TextField(
            controller: jumlahPupukController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: _inputDecoration(
              label: 'Jumlah Pupuk (Kg)',
              icon: Icons.scale_rounded,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: catatanController,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(
              label: 'Catatan Tambahan',
              icon: Icons.notes_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox() {
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
              'Jumlah pupuk yang diajukan akan diperiksa dan diverifikasi oleh admin kelompok tani. Pengajuan ini tidak dihitung otomatis berdasarkan luas lahan.',
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
          enabled ? 'Lanjut Konfirmasi' : 'Lengkapi Jumlah Pupuk',
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
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
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
              value.isEmpty ? '-' : value,
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
