import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class VerifikasiAnggotaPage extends StatefulWidget {
  const VerifikasiAnggotaPage({super.key});

  @override
  State<VerifikasiAnggotaPage> createState() => _VerifikasiAnggotaPageState();
}

class _VerifikasiAnggotaPageState extends State<VerifikasiAnggotaPage> {
  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color softGreen = Color(0xffEAF7EC);
  static const Color textDark = Color(0xff1F2937);
  static const Color textGrey = Color(0xff6B7280);
  static const Color borderColor = Color(0xffE5E7EB);
  static const Color orangeStatus = Color(0xffF59E0B);
  static const Color redStatus = Color(0xffDC2626);
  static const Color blueStatus = Color(0xff2563EB);
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminNavyLight = Color(0xff294762);
  static const Color adminPurple = Color(0xff6256A4);
  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color textSoft = Color(0xff8B96A2);

  String selectedFilter = 'semua';
  bool isProcessing = false;

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference calonAnggotaRef;
  late final DatabaseReference anggotaRef;

  @override
  void initState() {
    super.initState();
    calonAnggotaRef = db.ref('calon_anggota');
    anggotaRef = db.ref('anggota');
  }

  String _text(dynamic value) {
    if (value == null) return '-';
    final result = value.toString().trim();
    return result.isEmpty ? '-' : result;
  }

  double _number(dynamic value) {
    if (value == null) return 0;
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  String ambilNik(Map<String, dynamic> item) {
    return _text(item['nik'] ?? item['nik_anggota'] ?? item['nik_user']);
  }

  String ambilNama(Map<String, dynamic> item) {
    return _text(item['nama'] ?? item['nama_anggota'] ?? item['nama_user']);
  }

  String ambilTelepon(Map<String, dynamic> item) {
    return _text(
      item['telepon'] ??
          item['no_hp'] ??
          item['nomor_hp'] ??
          item['nomor_telepon'],
    );
  }

  String ambilPassword(Map<String, dynamic> item) {
    final password = item['password']?.toString().trim() ?? '';
    return password;
  }

  String normalStatus(Map<String, dynamic> item) {
    final status = _text(item['status']).toLowerCase();
    return status == '-' ? 'menunggu' : status;
  }

  String luasLahanText(Map<String, dynamic> item) {
    final luasBaru = item['luas_lahan'];
    final luasLama = item['luas_sawah'];

    if (luasBaru != null && _text(luasBaru) != '-') {
      final angka = _number(luasBaru);
      if (angka > 0) return '${angka.toStringAsFixed(3)} ha';
      return '${_text(luasBaru)} ha';
    }

    if (luasLama != null && _text(luasLama) != '-') {
      return '${_text(luasLama)} ha';
    }

    return '-';
  }

  String keteranganLahanText(Map<String, dynamic> item) {
    final ket = _text(item['keterangan_luas_lahan']);
    if (ket != '-') return ket;

    final mode = _text(item['mode_lahan']);
    if (mode != '-') return 'Input menggunakan satuan $mode';

    return '-';
  }

  String formatNomorTujuan(String nomor) {
    var clean = nomor.replaceAll(RegExp(r'[^0-9]'), '');

    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    } else if (clean.startsWith('8')) {
      clean = '62$clean';
    }

    return clean;
  }

  String buatPesanVerifikasi({
    required String nama,
    required String nik,
    required String password,
  }) {
    return 'Yth. Bapak/Ibu $nama,\n\n'
        'Kami informasikan bahwa pengajuan Anda sebagai Anggota Kelompok Tani Desa Penataan telah disetujui.\n\n'
        'Silakan login ke aplikasi TaniGo menggunakan data berikut:\n\n'
        'NIK      : $nik\n'
        'Password : $password\n\n'
        'Demi keamanan akun, kami menyarankan Anda untuk segera mengganti password setelah berhasil login.\n\n'
        'Terima kasih.\n\n'
        'Salam,\n'
        'Admin TaniGo\n'
        'Kelompok Tani Desa Penataan';
  }

  Future<void> bukaWhatsAppAnggota({
    required String nama,
    required String nik,
    required String password,
    required String telepon,
  }) async {
    final nomor = formatNomorTujuan(telepon);

    if (nomor.length < 10) {
      _showSnackBar('Nomor WhatsApp anggota tidak valid.', redStatus);
      return;
    }

    final pesan = Uri.encodeComponent(
      buatPesanVerifikasi(nama: nama, nik: nik, password: password),
    );

    final uri = Uri.parse('https://wa.me/$nomor?text=$pesan');
    final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!berhasil && mounted) {
      _showSnackBar('WhatsApp tidak dapat dibuka.', redStatus);
    }
  }

  Future<void> bukaSmsAnggota({
    required String nama,
    required String nik,
    required String password,
    required String telepon,
  }) async {
    final nomor = telepon.replaceAll(RegExp(r'[^0-9+]'), '');

    if (nomor.length < 10) {
      _showSnackBar('Nomor SMS anggota tidak valid.', redStatus);
      return;
    }

    final pesan = Uri.encodeComponent(
      buatPesanVerifikasi(nama: nama, nik: nik, password: password),
    );

    final uri = Uri.parse('sms:$nomor?body=$pesan');
    final berhasil = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!berhasil && mounted) {
      _showSnackBar('Aplikasi SMS tidak dapat dibuka.', redStatus);
    }
  }

  Future<void> tampilkanDialogKirimPesan({
    required String nama,
    required String nik,
    required String password,
    required String telepon,
  }) async {
    final hasil = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogIcon(Icons.verified_user_rounded, primaryGreen),
                const SizedBox(height: 15),
                const Text(
                  'Anggota Berhasil Diverifikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Pilih media pemberitahuan untuk mengirim informasi login kepada $nama.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12.7,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _dialogActionButton(
                  title: 'Kirim WhatsApp',
                  subtitle: 'Buka WhatsApp admin ke nomor anggota',
                  icon: Icons.chat_rounded,
                  color: primaryGreen,
                  onTap: () => Navigator.pop(dialogContext, 'wa'),
                ),
                const SizedBox(height: 10),
                _dialogActionButton(
                  title: 'Kirim SMS',
                  subtitle: 'Gunakan jika nomor tidak memiliki WhatsApp',
                  icon: Icons.sms_rounded,
                  color: blueStatus,
                  onTap: () => Navigator.pop(dialogContext, 'sms'),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textDark,
                      side: const BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(dialogContext, 'lewati'),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    if (hasil == 'wa') {
      await bukaWhatsAppAnggota(
        nama: nama,
        nik: nik,
        password: password,
        telepon: telepon,
      );
    } else if (hasil == 'sms') {
      await bukaSmsAnggota(
        nama: nama,
        nik: nik,
        password: password,
        telepon: telepon,
      );
    }
  }

  Widget _dialogActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.075),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 13.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.4,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 15),
          ],
        ),
      ),
    );
  }

  Future<void> setujuiAnggota(String id, Map<String, dynamic> anggota) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    String nik = '';
    String nama = '-';
    String password = '';
    String telepon = '-';
    bool berhasil = false;

    try {
      nik = ambilNik(anggota).replaceAll(RegExp(r'[^0-9]'), '');
      nama = ambilNama(anggota);
      password = ambilPassword(anggota);
      telepon = ambilTelepon(anggota);

      if (nik.length != 16) {
        _showSnackBar('NIK calon anggota tidak valid.', redStatus);
        return;
      }

      if (password.isEmpty) {
        _showSnackBar('Password calon anggota belum tersimpan.', redStatus);
        return;
      }

      await anggotaRef.child(nik).set({
        'nama': nama,
        'nik': nik,
        'telepon': telepon,
        'alamat': _text(anggota['alamat']),
        'jenis_kelamin': _text(anggota['jenis_kelamin']),

        'luas_lahan': anggota['luas_lahan'] ?? anggota['luas_sawah'] ?? 0,

        'satuan_lahan': anggota['satuan_lahan'] ?? 'ha',

        'mode_lahan': anggota['mode_lahan'] ?? '-',

        'jumlah_petak': anggota['jumlah_petak'] ?? 0,

        'luas_per_petak_m2': anggota['luas_per_petak_m2'] ?? 0,

        'luas_meter_m2': anggota['luas_meter_m2'] ?? 0,

        'keterangan_luas_lahan':
            anggota['keterangan_luas_lahan'] ?? keteranganLahanText(anggota),

        'foto_ktp_base64': _text(anggota['foto_ktp_base64']),

        'tanggal_daftar': _text(anggota['tanggal_daftar']),

        'tanggal_verifikasi': DateTime.now().toIso8601String(),

        'password': password,
        'status': 'aktif',
      });

      await calonAnggotaRef.child(id).remove();

      unawaited(NotificationHelper.anggotaDisetujui(nik: nik, nama: nama));

      berhasil = true;
    } catch (_) {
      if (!mounted) return;

      _showSnackBar('Gagal menyetujui anggota.', redStatus);
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }

    if (!mounted) return;

    if (berhasil) {
      await tampilkanDialogKirimPesan(
        nama: nama,
        nik: nik,
        password: password,
        telepon: telepon,
      );
    }
  }

  Future<void> tolakAnggota(String id, Map<String, dynamic> anggota) async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final nik = ambilNik(anggota);
      final nama = ambilNama(anggota);

      await calonAnggotaRef.child(id).update({
        'status': 'ditolak',
        'tanggal_verifikasi': DateTime.now().toIso8601String(),
      });

      unawaited(NotificationHelper.anggotaDitolak(nik: nik, nama: nama));

      if (!mounted) return;
      _showSnackBar('Anggota berhasil ditolak.', redStatus);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Gagal menolak anggota.', redStatus);
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
  }

  Future<void> tampilkanKonfirmasi({
    required String id,
    required Map<String, dynamic> anggota,
    required String status,
  }) async {
    final nama = ambilNama(anggota);
    final isSetuju = status == 'disetujui';
    final color = isSetuju ? primaryGreen : redStatus;

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogIcon(
                  isSetuju ? Icons.verified_rounded : Icons.block_rounded,
                  color,
                ),
                const SizedBox(height: 15),
                Text(
                  isSetuju ? 'Setujui Anggota?' : 'Tolak Anggota?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  isSetuju
                      ? 'Data $nama akan dipindahkan menjadi anggota aktif.'
                      : 'Pengajuan anggota dari $nama akan ditolak.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12.7,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext, true),
                        icon: Icon(
                          isSetuju ? Icons.check_rounded : Icons.close_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isSetuju ? 'Setujui' : 'Tolak',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (hasil != true) return;

    if (isSetuju) {
      await setujuiAnggota(id, anggota);
    } else {
      await tolakAnggota(id, anggota);
    }
  }

  Uint8List? decodeFoto(String base64Text) {
    try {
      if (base64Text.isEmpty || base64Text == '-') return null;
      return base64Decode(base64Text);
    } catch (_) {
      return null;
    }
  }

  void lihatFotoKtp(String base64Text) {
    final fotoBytes = decodeFoto(base64Text);

    if (fotoBytes == null) {
      _showSnackBar('Foto KTP tidak tersedia.', redStatus);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  color: darkGreen,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.badge_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Foto KTP Calon Anggota',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(dialogContext),
                        borderRadius: BorderRadius.circular(99),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.memory(fotoBytes, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int countStatus(List<MapEntry<String, dynamic>> data, String status) {
    if (status == 'semua') return data.length;

    return data.where((entry) {
      if (entry.value is! Map) return false;
      final item = Map<String, dynamic>.from(entry.value as Map);
      return normalStatus(item) == status;
    }).length;
  }

  List<MapEntry<String, dynamic>> filterData(
    List<MapEntry<String, dynamic>> data,
  ) {
    if (selectedFilter == 'semua') return data;

    return data.where((entry) {
      if (entry.value is! Map) return false;
      final item = Map<String, dynamic>.from(entry.value as Map);
      return normalStatus(item) == selectedFilter;
    }).toList();
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui' || status == 'aktif') return primaryGreen;
    if (status == 'ditolak') return redStatus;
    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui' || status == 'aktif') return softGreen;
    if (status == 'ditolak') return const Color(0xffFEE2E2);
    return const Color(0xffFFF7ED);
  }

  String teksStatus(String status) {
    if (status == 'disetujui' || status == 'aktif') return 'Disetujui';
    if (status == 'ditolak') return 'Ditolak';
    return 'Menunggu';
  }

  String formatTanggal(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty || text == '-') return '-';

    try {
      final date = DateTime.parse(text).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      return '$day-$month-$year';
    } catch (_) {
      return text;
    }
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNik.length <= 4) return nik;
    return '•••• •••• •••• ${cleanNik.substring(cleanNik.length - 4)}';
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 340 ? 13.0 : 17.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _AdminMemberBackground(),
              SafeArea(
                child: StreamBuilder<DatabaseEvent>(
                  stream: calonAnggotaRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _statePage(
                        horizontalPadding,
                        error: snapshot.error.toString(),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _statePage(
                        horizontalPadding,
                        loading: true,
                      );
                    }

                    final rawData = snapshot.data?.snapshot.value;
                    final semuaData = <MapEntry<String, dynamic>>[];

                    if (rawData is Map) {
                      for (final entry in Map<dynamic, dynamic>.from(rawData).entries) {
                        if (entry.value is! Map) {
                          continue;
                        }

                        semuaData.add(
                          MapEntry(
                            entry.key.toString(),
                            Map<String, dynamic>.from(entry.value as Map),
                          ),
                        );
                      }
                    }

                    semuaData.sort((a, b) {
                      final dateA = DateTime.tryParse(
                            _text(a.value['tanggal_daftar']),
                          ) ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      final dateB = DateTime.tryParse(
                            _text(b.value['tanggal_daftar']),
                          ) ??
                          DateTime.fromMillisecondsSinceEpoch(0);
                      return dateB.compareTo(dateA);
                    });

                    final totalSemua = countStatus(semuaData, 'semua');
                    final totalMenunggu = countStatus(semuaData, 'menunggu');
                    final totalDisetujui = countStatus(semuaData, 'disetujui');
                    final totalDitolak = countStatus(semuaData, 'ditolak');
                    final anggotaList = filterData(semuaData);

                    return RefreshIndicator(
                      color: adminPurple,
                      backgroundColor: Colors.white,
                      onRefresh: () async {
                        await calonAnggotaRef.get();
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          28,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _header(totalMenunggu),
                                  const SizedBox(height: 13),
                                  _filterPanel(
                                    totalSemua: totalSemua,
                                    totalMenunggu: totalMenunggu,
                                    totalDisetujui: totalDisetujui,
                                    totalDitolak: totalDitolak,
                                  ),
                                  const SizedBox(height: 12),
                                  _infoBox(totalMenunggu),
                                  const SizedBox(height: 16),
                                  _sectionTitle(
                                    count: anggotaList.length,
                                  ),
                                  const SizedBox(height: 10),
                                  if (semuaData.isEmpty)
                                    _messageState(
                                      icon: Icons.person_add_alt_1_outlined,
                                      title: 'Belum Ada Calon Anggota',
                                      message:
                                          'Data pendaftaran anggota baru belum tersedia.',
                                    )
                                  else if (anggotaList.isEmpty)
                                    _messageState(
                                      icon: Icons.search_off_rounded,
                                      title: 'Data Tidak Ditemukan',
                                      message:
                                          'Tidak ada calon anggota dengan status yang dipilih.',
                                    )
                                  else
                                    ...anggotaList.map((entry) {
                                      return _anggotaCard(
                                        entry.key,
                                        entry.value,
                                      );
                                    }),
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
              if (isProcessing) _processingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statePage(
    double horizontalPadding, {
    bool loading = false,
    String? error,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        28,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                _header(0),
                const SizedBox(height: 90),
                if (loading)
                  const CircularProgressIndicator(
                    color: adminPurple,
                    strokeWidth: 2.8,
                  )
                else
                  _messageState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Data Tidak Dapat Dimuat',
                    message: error == null || error.isEmpty
                        ? 'Periksa koneksi internet lalu buka kembali halaman.'
                        : error,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(int totalMenunggu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 13, 14, 13),
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
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(alpha: 0.24),
            blurRadius: 23,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -45,
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
            Row(
              children: [
                _backButton(),
                const SizedBox(width: 10),
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.19),
                    ),
                  ),
                  child: const Icon(
                    Icons.how_to_reg_outlined,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifikasi Anggota',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Pemeriksaan calon anggota baru',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xffDFE5F0),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                _headerCounter(totalMenunggu),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCounter(int total) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 40,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.19),
        ),
      ),
      child: Column(
        children: [
          Text(
            total > 99 ? '99+' : total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'baru',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.77),
              fontSize: 8.6,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterPanel({
    required int totalSemua,
    required int totalMenunggu,
    required int totalDisetujui,
    required int totalDitolak,
  }) {
    final filters = [
      _FilterItem(
        label: 'Menunggu',
        value: 'menunggu',
        total: totalMenunggu,
        icon: Icons.pending_actions_outlined,
        color: orangeStatus,
      ),
      _FilterItem(
        label: 'Disetujui',
        value: 'disetujui',
        total: totalDisetujui,
        icon: Icons.verified_outlined,
        color: primaryGreen,
      ),
      _FilterItem(
        label: 'Ditolak',
        value: 'ditolak',
        total: totalDitolak,
        icon: Icons.block_outlined,
        color: redStatus,
      ),
      _FilterItem(
        label: 'Semua',
        value: 'semua',
        total: totalSemua,
        icon: Icons.grid_view_rounded,
        color: adminPurple,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: _cardDecoration(radius: 19),
      child: SizedBox(
        height: 39,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final filter = filters[index];
            final active = selectedFilter == filter.value;

            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedFilter = filter.value;
                  });
                },
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? filter.color
                        : filter.color.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? filter.color
                          : filter.color.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        color: active ? Colors.white : filter.color,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        filter.label,
                        style: TextStyle(
                          color: active ? Colors.white : textDark,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 19,
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          filter.total > 99
                              ? '99+'
                              : filter.total.toString(),
                          style: TextStyle(
                            color: active ? Colors.white : filter.color,
                            fontSize: 8,
                            height: 1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _infoBox(int totalMenunggu) {
    final clear = totalMenunggu == 0;
    final color = clear ? primaryGreen : orangeStatus;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: clear ? softGreen : const Color(0xffFFF3DD),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 37,
            width: 37,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              clear
                  ? Icons.task_alt_rounded
                  : Icons.info_outline_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              clear
                  ? 'Semua pendaftaran anggota sudah diproses.'
                  : '$totalMenunggu calon anggota masih memerlukan pemeriksaan data dan KTP.',
              style: const TextStyle(
                color: textGrey,
                fontSize: 10.3,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({
    required int count,
  }) {
    return Row(
      children: [
        Container(
          height: 31,
          width: 5,
          decoration: BoxDecoration(
            color: adminPurple,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar Calon Anggota',
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Periksa data lalu tentukan hasil verifikasi.',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 10.4,
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
            color: adminPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count data',
            style: const TextStyle(
              color: adminPurple,
              fontSize: 8.6,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _anggotaCard(
    String id,
    Map<String, dynamic> anggota,
  ) {
    final status = normalStatus(anggota);
    final fotoKtpBase64 = _text(anggota['foto_ktp_base64']);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTop(anggota, status),
          const SizedBox(height: 10),
          _activityStrip(
            status: status,
            date: formatTanggal(anggota['tanggal_daftar']),
          ),
          const SizedBox(height: 10),
          _dataCalonBox(anggota),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 330;

              final ktpButton = _ktpButton(fotoKtpBase64);

              if (status != 'menunggu') {
                return ktpButton;
              }

              final approveButton = _actionButton(
                title: 'Setujui',
                icon: Icons.check_rounded,
                color: primaryGreen,
                onPressed: () {
                  tampilkanKonfirmasi(
                    id: id,
                    anggota: anggota,
                    status: 'disetujui',
                  );
                },
              );

              final rejectButton = _actionButton(
                title: 'Tolak',
                icon: Icons.close_rounded,
                color: redStatus,
                outlined: true,
                onPressed: () {
                  tampilkanKonfirmasi(
                    id: id,
                    anggota: anggota,
                    status: 'ditolak',
                  );
                },
              );

              if (compact) {
                return Column(
                  children: [
                    ktpButton,
                    const SizedBox(height: 8),
                    approveButton,
                    const SizedBox(height: 8),
                    rejectButton,
                  ],
                );
              }

              return Column(
                children: [
                  ktpButton,
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Expanded(child: rejectButton),
                      const SizedBox(width: 8),
                      Expanded(child: approveButton),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _cardTop(
    Map<String, dynamic> anggota,
    String status,
  ) {
    return Row(
      children: [
        Container(
          height: 45,
          width: 45,
          decoration: BoxDecoration(
            color: adminPurple.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.person_search_outlined,
            color: adminPurple,
            size: 23,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ambilNama(anggota),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 13.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'NIK ${sensorNik(ambilNik(anggota))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        _statusBadge(status),
      ],
    );
  }

  Widget _activityStrip({
    required String status,
    required String date,
  }) {
    final approved = status == 'disetujui' || status == 'aktif';
    final rejected = status == 'ditolak';
    final endColor = approved
        ? primaryGreen
        : rejected
            ? redStatus
            : orangeStatus;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _activityNode(
            icon: Icons.app_registration_outlined,
            label: 'Daftar',
            color: adminPurple,
            active: true,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: endColor.withValues(alpha: 0.35),
            ),
          ),
          _activityNode(
            icon: approved
                ? Icons.verified_outlined
                : rejected
                    ? Icons.block_outlined
                    : Icons.schedule_outlined,
            label: approved
                ? 'Disetujui'
                : rejected
                    ? 'Ditolak'
                    : 'Menunggu',
            color: endColor,
            active: true,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: textSoft,
                fontSize: 8.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityNode({
    required IconData icon,
    required String label,
    required Color color,
    required bool active,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: active ? color : borderColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 13,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8.7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _dataCalonBox(Map<String, dynamic> anggota) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 2),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.phone_outlined,
            'Telepon',
            ambilTelepon(anggota),
          ),
          _infoRow(
            Icons.home_outlined,
            'Alamat',
            anggota['alamat'],
          ),
          _infoRow(
            Icons.landscape_outlined,
            'Luas Lahan',
            luasLahanText(anggota),
            valueColor: primaryGreen,
          ),
          if (keteranganLahanText(anggota) != '-')
            _infoRow(
              Icons.info_outline_rounded,
              'Keterangan',
              keteranganLahanText(anggota),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    dynamic value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: adminPurple,
            size: 15,
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 9.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _text(value),
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
      ),
    );
  }

  Widget _ktpButton(String fotoKtpBase64) {
    final available =
        fotoKtpBase64.isNotEmpty && fotoKtpBase64 != '-';

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: OutlinedButton.icon(
        onPressed: available
            ? () {
                lihatFotoKtp(fotoKtpBase64);
              }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: adminPurple,
          disabledForegroundColor: textSoft,
          side: BorderSide(
            color: available
                ? adminPurple.withValues(alpha: 0.24)
                : borderColor,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        icon: const Icon(
          Icons.badge_outlined,
          size: 17,
        ),
        label: Text(
          available ? 'Lihat Foto KTP' : 'Foto KTP Tidak Tersedia',
          style: const TextStyle(
            fontSize: 9.8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 86),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: warnaStatus(status).withValues(alpha: 0.13),
        ),
      ),
      child: Text(
        teksStatus(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: warnaStatus(status),
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: isProcessing ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(
                  color: color.withValues(alpha: 0.22),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: Icon(icon, size: 16),
              label: Text(
                title,
                style: const TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: isProcessing ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    color.withValues(alpha: 0.30),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: Icon(icon, size: 16),
              label: Text(
                title,
                style: const TextStyle(
                  fontSize: 9.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 28,
      ),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: adminPurple.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: adminPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _processingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: adminNavy.withValues(alpha: 0.28),
          alignment: Alignment.center,
          child: Container(
            height: 74,
            width: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: adminPurple,
              strokeWidth: 2.8,
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
        onTap: isProcessing
            ? null
            : () {
                FocusScope.of(context).unfocus();
                Navigator.maybePop(context);
              },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _dialogIcon(
    IconData icon,
    Color color,
  ) {
    return Container(
      height: 62,
      width: 62,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 32,
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: [
        BoxShadow(
          color: adminNavy.withValues(alpha: 0.05),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _FilterItem {
  final String label;
  final String value;
  final int total;
  final IconData icon;
  final Color color;

  const _FilterItem({
    required this.label,
    required this.value,
    required this.total,
    required this.icon,
    required this.color,
  });
}

class _AdminMemberBackground extends StatelessWidget {
  const _AdminMemberBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final base = constraints.maxWidth < constraints.maxHeight
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
                          Color(0xff172A46),
                          Color(0xff294762),
                          Color(0xffE8EBF2),
                          Color(0xffF2F4F8),
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
                      color: const Color(0xff7367B5),
                      alpha: 0.20,
                    ),
                  ),
                  Positioned(
                    top: constraints.maxHeight * 0.31,
                    left: -medium * 0.58,
                    child: _BackgroundCircle(
                      size: medium,
                      color: const Color(0xffB9B1DD),
                      alpha: 0.30,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.31,
                    child: _BackgroundCircle(
                      size: large,
                      color: const Color(0xffE6E3F2),
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
