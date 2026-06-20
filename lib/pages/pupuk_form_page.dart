import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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
  static const Color darkGreen = Color(0xff1B5E20);
  static const Color lightGreen = Color(0xffE8F5E9);
  static const Color backgroundColor = Color(0xffF6FAF7);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
 
  final jumlahPupukController = TextEditingController();
  final catatanController = TextEditingController();

  String nama = '';
  String luasSawah = '';
  double jatahPupuk = 0;

  bool isLoading = true;
  bool dataDitemukan = false;

  final DatabaseReference anggotaRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref('anggota');

  @override
  void initState() {
    super.initState();
    ambilDataAnggotaLogin();
  }

  Future<void> ambilDataAnggotaLogin() async {
    setState(() {
      isLoading = true;
      dataDitemukan = false;
    });

    try {
      final snapshot = await anggotaRef.get().timeout(
        const Duration(seconds: 10),
      );

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        Map<String, dynamic>? anggotaDitemukan;

        for (final item in data.values) {
          if (item is Map) {
            final anggota = Map<String, dynamic>.from(item);
            final nikData = (anggota['nik'] ?? '').toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );

            final nikLogin = widget.nikUser.replaceAll(RegExp(r'[^0-9]'), '');

            if (nikData == nikLogin) {
              anggotaDitemukan = anggota;
              break;
            }
          }
        }

        if (!mounted) return;

        if (anggotaDitemukan != null) {
          final luasText = (anggotaDitemukan['luas_sawah'] ??
                  anggotaDitemukan['jumlah_petak_sawah'] ??
                  '0')
              .toString()
              .replaceAll(',', '.');

          final luas = double.tryParse(luasText) ?? 0;

          setState(() {
            nama = (anggotaDitemukan!['nama'] ?? widget.namaUser).toString();
            luasSawah = luasText;
            jatahPupuk = luas / 2;
            dataDitemukan = true;
          });
        } else {
          setState(() {
            nama = widget.namaUser;
          });

          _showSnackBar('Data anggota login tidak ditemukan', Colors.red);
        }
      } else {
        if (!mounted) return;
        setState(() {
          nama = widget.namaUser;
        });
        _showSnackBar('Data anggota masih kosong', Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Gagal mengambil data anggota: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  double jumlahDiajukan() {
    return double.tryParse(
          jumlahPupukController.text.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  bool melebihiJatah() {
    return jumlahDiajukan() > jatahPupuk;
  }

  double persentaseJatah() {
    if (jatahPupuk <= 0) return 0;
    final hasil = jumlahDiajukan() / jatahPupuk;
    if (hasil > 1) return 1;
    if (hasil < 0) return 0;
    return hasil;
  }

  String formatAngka(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  void lanjutKonfirmasi() {
    if (!dataDitemukan) {
      _showSnackBar('Data anggota belum ditemukan', Colors.red);
      return;
    }

    if (widget.idPupuk.trim().isEmpty) {
      _showSnackBar('ID pupuk tidak ditemukan', Colors.red);
      return;
    }

    if (jumlahPupukController.text.trim().isEmpty) {
      _showSnackBar('Jumlah pupuk wajib diisi', Colors.red);
      return;
    }

    final jumlah = double.tryParse(
      jumlahPupukController.text.trim().replaceAll(',', '.'),
    );

    if (jumlah == null || jumlah <= 0) {
      _showSnackBar('Jumlah pupuk tidak valid', Colors.red);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PupukKonfirmasiPage(
              idPupuk: widget.idPupuk,
              namaPupuk: widget.namaPupuk,
              nama: nama,
              nik: widget.nikUser.trim(),
              jumlahPetakSawah: luasSawah,
              jumlahPupuk: jumlahPupukController.text.trim(),
              jatahPupuk: jatahPupuk.toStringAsFixed(1),
              statusJatah: melebihiJatah() ? 'melebihi_jatah' : 'sesuai_jatah',
              catatan: catatanController.text.trim(),
            ),
      ),
    );
  }

  void _showSnackBar(String pesan, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    jumlahPupukController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overLimit = dataDitemukan && melebihiJatah();

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
                child: _pupukCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                child:
                    isLoading
                        ? _loadingCard()
                        : dataDitemukan
                        ? _anggotaCard()
                        : _errorCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                child: _formCard(overLimit),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomSubmitBar(),
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
              Icons.grass_rounded,
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
                      'Isi Data Pupuk',
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
                'Form Pengajuan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Lengkapi jumlah pupuk sesuai kebutuhan lahan. Data akan diverifikasi oleh admin.',
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
                        '${widget.namaUser}\nNIK: ${widget.nikUser}',
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _stepCircle('1', 'Pilih', true, completed: true),
          _stepLine(true),
          _stepCircle('2', 'Data', true),
          _stepLine(false),
          _stepCircle('3', 'Kirim', false),
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
          height: 38,
          width: 38,
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
                      size: 22,
                    )
                    : Text(
                      number,
                      style: TextStyle(
                        color: active ? Colors.white : textGrey,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
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

  Widget _pupukCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryGreen, Color(0xff66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jenis Pupuk Dipilih',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 12,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID Pupuk: ${widget.idPupuk}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 11,
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

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _skeletonBox(width: 54, height: 54, radius: 18),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    _skeletonBox(
                      width: double.infinity,
                      height: 14,
                      radius: 20,
                    ),
                    const SizedBox(height: 10),
                    _skeletonBox(
                      width: double.infinity,
                      height: 12,
                      radius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Mengambil data anggota...',
            style: TextStyle(
              color: textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xffE5E7EB),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffFFEBEE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data anggota tidak ditemukan. Pastikan akun sudah terdaftar dan disetujui sebagai anggota.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
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
                  'TERVERIFIKASI',
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
          _infoRow(Icons.person_rounded, 'Nama', nama),
          _infoRow(Icons.badge_rounded, 'NIK', widget.nikUser.trim()),
          _infoRow(Icons.landscape_rounded, 'Luas Sawah', '$luasSawah Ha'),
          _infoRow(
            Icons.inventory_2_rounded,
            'Jatah Pupuk',
            '${jatahPupuk.toStringAsFixed(1)} Kg',
          ),
          const SizedBox(height: 10),
          _jatahProgress(),
          const SizedBox(height: 12),
          _noteBox(
            text:
                'Ketentuan: setiap 2 Ha sawah mendapat jatah 1 Kg pupuk subsidi.',
            color: primaryGreen,
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _jatahProgress() {
    final percent = persentaseJatah();
    final overLimit = melebihiJatah();
    final color = overLimit ? Colors.red : primaryGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pemakaian Jatah',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${formatAngka(jumlahDiajukan())} / ${formatAngka(jatahPupuk)} Kg',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 9,
              backgroundColor: color.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overLimit
                ? 'Jumlah yang diajukan melebihi jatah subsidi.'
                : 'Jumlah pengajuan masih dalam batas jatah.',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard(bool overLimit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Form Pengajuan',
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masukkan jumlah pupuk yang ingin diajukan.',
            style: TextStyle(
              color: textGrey,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: jumlahPupukController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              label: 'Jumlah Pupuk Diajukan (Kg)',
              icon: Icons.scale_rounded,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (overLimit) ...[
            const SizedBox(height: 10),
            _noteBox(
              text:
                  'Jumlah pupuk melebihi jatah subsidi. Admin tetap dapat memverifikasi, tetapi status akan ditandai melebihi jatah.',
              color: Colors.red,
              icon: Icons.warning_amber_rounded,
            ),
          ],
          const SizedBox(height: 13),
          TextField(
            controller: catatanController,
            maxLines: 3,
            decoration: _inputDecoration(
              label: 'Catatan Tambahan',
              icon: Icons.notes_rounded,
            ),
          ),
          const SizedBox(height: 16),
          _ringkasanMini(overLimit),
        ],
      ),
    );
  }

  Widget _ringkasanMini(bool overLimit) {
    final jumlah =
        jumlahPupukController.text.trim().isEmpty
            ? '-'
            : '${jumlahPupukController.text.trim()} Kg';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffE5E7EB)),
      ),
      child: Column(
        children: [
          _summaryRow('Jenis Pupuk', widget.namaPupuk),
          _summaryRow('Jumlah Diajukan', jumlah),
          _summaryRow(
            'Status Jatah',
            overLimit ? 'Melebihi Jatah' : 'Sesuai Jatah',
            valueColor: overLimit ? Colors.red : primaryGreen,
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
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? textDark,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomSubmitBar() {
    final bisaLanjut =
        dataDitemukan &&
        !isLoading &&
        jumlahPupukController.text.trim().isNotEmpty;

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
              bisaLanjut ? 'Lanjut Konfirmasi' : 'Lengkapi Jumlah Pupuk',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteBox({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 17),
          const SizedBox(width: 8),
          SizedBox(
            width: 104,
            child: Text(
              label,
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
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textGrey),
      prefixIcon: Icon(icon, color: primaryGreen),
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
