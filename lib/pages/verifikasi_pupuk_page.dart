import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class VerifikasiPupukPage extends StatefulWidget {
  const VerifikasiPupukPage({super.key});

  @override
  State<VerifikasiPupukPage> createState() =>
      _VerifikasiPupukPageState();
}

class _VerifikasiPupukPageState
    extends State<VerifikasiPupukPage> {
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminNavyLight = Color(0xff294762);
  static const Color adminPurple = Color(0xff6256A4);
  static const Color adminIndigo = Color(0xff435987);

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color orangeStatus = Color(0xffD98212);
  static const Color blueStatus = Color(0xff326CA3);
  static const Color redStatus = Color(0xffC83B3B);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softBlue = Color(0xffE9F2FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);
  static const Color softPurple = Color(0xffF0ECFA);

  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  late final DatabaseReference rootRef;
  late final DatabaseReference bantuanPupukRef;

  String selectedFilter = 'menunggu_verifikasi';
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();

    rootRef = db.ref();
    bantuanPupukRef = db.ref('bantuan_pupuk');
  }

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value == null || value is! Map) {
      return {};
    }

    return Map<dynamic, dynamic>.from(value);
  }

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    if (result.isEmpty ||
        result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  dynamic _firstValue(
    Map<dynamic, dynamic> item,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = item[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty &&
          text != '-' &&
          text.toLowerCase() != 'null') {
        return value;
      }
    }

    return null;
  }

  double _number(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().replaceAll(',', '.'),
        ) ??
        0;
  }

  String _cleanStatus(dynamic value) {
    return (value ?? 'menunggu')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');
  }

  bool _isPendingStatus(dynamic value) {
    final status = _cleanStatus(value);

    const pendingStatuses = {
      '',
      'menunggu',
      'pending',
      'diajukan',
      'pengajuan',
      'proses',
      'diproses',
      'sedang_diproses',
      'sedang diproses',
      'verifikasi',
      'diverifikasi',
      'menunggu_verifikasi',
      'menunggu verifikasi',
      'belum_diproses',
      'belum diproses',
    };

    return pendingStatuses.contains(status);
  }

  String normalStatus(
    Map<dynamic, dynamic> item,
  ) {
    final status = _cleanStatus(item['status']);

    if (_isPendingStatus(status)) {
      return 'menunggu_verifikasi';
    }

    if (status == 'approved' ||
        status == 'siap_diambil' ||
        status == 'siap diambil') {
      return 'disetujui';
    }

    if (status == 'rejected') {
      return 'ditolak';
    }

    if (status == 'diambil' ||
        status == 'selesai' ||
        status == 'completed') {
      return 'sudah_diambil';
    }

    return status;
  }

  String ambilNik(
    Map<dynamic, dynamic> item,
  ) {
    return _text(
      item['nik'] ??
          item['nik_anggota'] ??
          item['nik_user'] ??
          item['nikUser'] ??
          item['no_nik'],
      fallback: '',
    ).replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
  }

  String ambilNama(
    Map<dynamic, dynamic> item,
  ) {
    return _text(
      item['nama'] ??
          item['nama_anggota'] ??
          item['nama_user'] ??
          item['namaUser'],
      fallback: 'Anggota',
    );
  }

  String ambilNamaProgram(
    Map<dynamic, dynamic> item,
  ) {
    return _text(
      item['nama_program'] ??
          item['program_bantuan'] ??
          item['judul_program'],
      fallback: 'Program Bantuan Pupuk',
    );
  }

  String ambilPeriode(
    Map<dynamic, dynamic> item,
  ) {
    return _text(
      item['periode'] ??
          item['periode_bantuan'] ??
          item['bulan_program'],
      fallback: 'Belum ditentukan',
    );
  }

  String ambilJenisPupuk(
    Map<dynamic, dynamic> item,
  ) {
    return _text(
      item['jenis_pupuk'] ??
          item['nama_pupuk'] ??
          item['pupuk'] ??
          item['jenis'],
      fallback: 'Pupuk bantuan',
    );
  }

  double ambilJumlahDiajukan(
    Map<dynamic, dynamic> item,
  ) {
    return _number(
      item['jumlah_diajukan'] ??
          item['jumlah_paket_kg'] ??
          item['jumlah_kg'] ??
          item['jumlah_pupuk'] ??
          item['jumlah'] ??
          item['total_pupuk'],
    );
  }

  double ambilJumlahFinal(
    Map<dynamic, dynamic> item,
  ) {
    final finalAmount = _number(
      item['jumlah_disetujui'] ??
          item['jumlah_final_kg'] ??
          item['jumlah_ditetapkan'],
    );

    if (finalAmount > 0) {
      return finalAmount;
    }

    return ambilJumlahDiajukan(item);
  }

  String ambilLokasiPengambilan(
    Map<dynamic, dynamic> item,
  ) {
    return _text(
      item['lokasi_pengambilan'] ??
          item['tempat_pengambilan'],
      fallback: '-',
    );
  }

  String ambilCatatanUser(
    Map<dynamic, dynamic> item,
  ) {
    return _text(
      item['catatan_user'] ??
          item['catatan'] ??
          item['keterangan'],
      fallback: '-',
    );
  }

  String ambilCatatanAdmin(
    Map<dynamic, dynamic> item,
  ) {
    return _text(
      item['catatan_admin'] ??
          item['pesan_admin'] ??
          item['alasan_penolakan'],
      fallback: '-',
    );
  }

  String _normalizeNik(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll(
          RegExp(r'[^0-9]'),
          '',
        )
        .trim();
  }

  Map<dynamic, dynamic>? _findMember(
    dynamic anggotaValue,
    String nik,
  ) {
    final cleanNik = _normalizeNik(nik);

    if (cleanNik.isEmpty) {
      return null;
    }

    final data = _asMap(anggotaValue);

    for (final entry in data.entries) {
      if (entry.value is! Map) {
        continue;
      }

      final member = Map<dynamic, dynamic>.from(
        entry.value as Map,
      );

      final nikData = _normalizeNik(
        member['nik'] ?? entry.key,
      );

      if (nikData == cleanNik) {
        return member;
      }
    }

    return null;
  }

  bool _isActiveMember(
    Map<dynamic, dynamic>? member,
  ) {
    if (member == null) {
      return false;
    }

    final status = _cleanStatus(
      member['status'],
    );

    return status.isEmpty ||
        status == 'aktif' ||
        status == 'anggota' ||
        status == 'disetujui';
  }

  String _memberStatusText(
    Map<dynamic, dynamic>? member,
  ) {
    if (member == null) {
      return 'Tidak ditemukan';
    }

    if (_isActiveMember(member)) {
      return 'Anggota aktif';
    }

    final status = _text(
      member['status'],
      fallback: 'Tidak aktif',
    );

    return status;
  }

  String _formatLandArea(
    Map<dynamic, dynamic>? member,
  ) {
    if (member == null) {
      return '-';
    }

    final explanation = _text(
      member['keterangan_luas_lahan'],
    );

    if (explanation != '-') {
      return explanation;
    }

    final directArea = _text(
      member['luas_lahan'],
    );

    if (directArea != '-') {
      final lower = directArea.toLowerCase();

      if (lower.contains('ha') ||
          lower.contains('m²') ||
          lower.contains('m2') ||
          lower.contains('meter')) {
        return directArea;
      }

      final unit = _text(
        member['satuan_lahan'],
        fallback: 'Ha',
      );

      return '$directArea $unit';
    }

    final squareMeters = _text(
      member['luas_meter_m2'],
    );

    if (squareMeters != '-') {
      return '$squareMeters m²';
    }

    final perPlot = _text(
      member['luas_per_petak_m2'],
    );

    final plots = _text(
      member['jumlah_petak'],
    );

    if (perPlot != '-' && plots != '-') {
      return '$plots petak • $perPlot m²/petak';
    }

    return '-';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int || value is double) {
      final number = value is int
          ? value
          : (value as double).toInt();

      try {
        final milliseconds =
            number.toString().length >= 13
                ? number
                : number * 1000;

        return DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
        ).toLocal();
      } catch (_) {
        return null;
      }
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == '-') {
      return null;
    }

    final numeric = int.tryParse(text);

    if (numeric != null) {
      try {
        final milliseconds =
            text.length >= 13
                ? numeric
                : numeric * 1000;

        return DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
        ).toLocal();
      } catch (_) {
        return null;
      }
    }

    final parsed = DateTime.tryParse(text);

    if (parsed != null) {
      return parsed.toLocal();
    }

    final slashParts = text.split('/');

    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);

      if (day != null &&
          month != null &&
          year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  DateTime _readDate(
    Map<dynamic, dynamic> item,
  ) {
    final raw = _firstValue(
      item,
      [
        'tanggal_pengajuan',
        'tanggalPengajuan',
        'created_at',
        'createdAt',
        'tanggal',
        'waktu',
        'timestamp',
      ],
    );

    return _parseDate(raw) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _monthName(int month) {
    const months = [
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

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String formatTanggal(
    dynamic value, {
    bool includeTime = false,
  }) {
    final date = _parseDate(value);

    if (date == null) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');

    final dateText =
        '$day ${_monthName(date.month)} ${date.year}';

    if (!includeTime) {
      return dateText;
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$dateText • $hour:$minute';
  }

  String _inputDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String sensorNik(String nik) {
    final cleanNik = nik.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cleanNik.length <= 4) {
      return nik;
    }

    return '•••• •••• •••• '
        '${cleanNik.substring(cleanNik.length - 4)}';
  }

  String formatKg(double value) {
    if (value <= 0) {
      return '-';
    }

    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }

  String teksStatus(String status) {
    if (status == 'menunggu_verifikasi') {
      return 'Menunggu';
    }

    if (status == 'disetujui') {
      return 'Disetujui';
    }

    if (status == 'ditolak') {
      return 'Ditolak';
    }

    if (status == 'sudah_diambil') {
      return 'Sudah Diambil';
    }

    return 'Menunggu';
  }

  String teksStatusPanjang(String status) {
    if (status == 'menunggu_verifikasi') {
      return 'Menunggu penetapan bantuan oleh admin';
    }

    if (status == 'disetujui') {
      return 'Bantuan telah ditetapkan dan siap diambil';
    }

    if (status == 'ditolak') {
      return 'Pengajuan bantuan tidak disetujui';
    }

    if (status == 'sudah_diambil') {
      return 'Bantuan pupuk telah diserahkan';
    }

    return 'Menunggu proses admin';
  }

  Color warnaStatus(String status) {
    if (status == 'disetujui') {
      return blueStatus;
    }

    if (status == 'ditolak') {
      return redStatus;
    }

    if (status == 'sudah_diambil') {
      return primaryGreen;
    }

    return orangeStatus;
  }

  Color backgroundStatus(String status) {
    if (status == 'disetujui') {
      return softBlue;
    }

    if (status == 'ditolak') {
      return softRed;
    }

    if (status == 'sudah_diambil') {
      return softGreen;
    }

    return softAmber;
  }

  IconData iconPupuk(String pupuk) {
    final name = pupuk.toLowerCase();

    if (name.contains('urea')) {
      return Icons.water_drop_outlined;
    }

    if (name.contains('npk')) {
      return Icons.grain_rounded;
    }

    if (name.contains('organik')) {
      return Icons.energy_savings_leaf_rounded;
    }

    if (name.contains('kompos')) {
      return Icons.local_florist_rounded;
    }

    if (name.contains('za')) {
      return Icons.science_outlined;
    }

    return Icons.inventory_2_outlined;
  }

  List<MapEntry<String, dynamic>> _readApplications(
    dynamic value,
  ) {
    final data = _asMap(value);
    final result = <MapEntry<String, dynamic>>[];

    for (final entry in data.entries) {
      if (entry.value is! Map) {
        continue;
      }

      result.add(
        MapEntry<String, dynamic>(
          entry.key.toString(),
          entry.value,
        ),
      );
    }

    result.sort(
      (a, b) {
        final itemA = Map<dynamic, dynamic>.from(
          a.value as Map,
        );

        final itemB = Map<dynamic, dynamic>.from(
          b.value as Map,
        );

        return _readDate(itemB).compareTo(
          _readDate(itemA),
        );
      },
    );

    return result;
  }

  Map<String, int> hitungStatus(
    List<MapEntry<String, dynamic>> data,
  ) {
    int menunggu = 0;
    int disetujui = 0;
    int ditolak = 0;
    int sudahDiambil = 0;

    for (final entry in data) {
      if (entry.value is! Map) {
        continue;
      }

      final item = Map<dynamic, dynamic>.from(
        entry.value as Map,
      );

      final status = normalStatus(item);

      if (status == 'menunggu_verifikasi') {
        menunggu++;
      } else if (status == 'disetujui') {
        disetujui++;
      } else if (status == 'ditolak') {
        ditolak++;
      } else if (status == 'sudah_diambil') {
        sudahDiambil++;
      }
    }

    return {
      'semua': data.length,
      'menunggu_verifikasi': menunggu,
      'disetujui': disetujui,
      'ditolak': ditolak,
      'sudah_diambil': sudahDiambil,
    };
  }

  List<MapEntry<String, dynamic>> filterData(
    List<MapEntry<String, dynamic>> data,
  ) {
    if (selectedFilter == 'semua') {
      return data;
    }

    return data.where(
      (entry) {
        if (entry.value is! Map) {
          return false;
        }

        final item = Map<dynamic, dynamic>.from(
          entry.value as Map,
        );

        return normalStatus(item) ==
            selectedFilter;
      },
    ).toList();
  }

  Future<void> refreshData() async {
    await rootRef.get();
  }

  Future<void> _openApprovalSheet({
    required String id,
    required Map<dynamic, dynamic> item,
  }) async {
    final currentAmount = ambilJumlahFinal(item);

    final amountController = TextEditingController(
      text: currentAmount > 0
          ? formatKg(currentAmount)
          : '',
    );

    final existingDate = _parseDate(
      item['tanggal_pengambilan'],
    );

    DateTime? selectedDate = existingDate;

    final dateController = TextEditingController(
      text: selectedDate == null
          ? ''
          : _inputDate(selectedDate),
    );

    final locationController = TextEditingController(
      text: ambilLokasiPengambilan(item) == '-'
          ? ''
          : ambilLokasiPengambilan(item),
    );

    final noteController = TextEditingController(
      text: ambilCatatanAdmin(item) == '-'
          ? ''
          : ambilCatatanAdmin(item),
    );

    String errorText = '';

    final result =
        await showModalBottomSheet<_ApprovalData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:
          adminNavy.withValues(alpha: 0.52),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            final bottomInset =
                MediaQuery.viewInsetsOf(context).bottom;

            return AnimatedPadding(
              duration:
                  const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: bottomInset,
              ),
              child: FractionallySizedBox(
                heightFactor: 0.92,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _sheetHeader(
                            context: sheetContext,
                            icon:
                                Icons.fact_check_outlined,
                            title: 'Tetapkan Bantuan',
                            subtitle:
                                'Tentukan jumlah dan jadwal pengambilan',
                            color: primaryGreen,
                          ),
                          Expanded(
                            child: ListView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior
                                      .manual,
                              padding:
                                  const EdgeInsets.fromLTRB(
                                17,
                                15,
                                17,
                                25,
                              ),
                              children: [
                                _approvalSummary(item),
                                const SizedBox(height: 14),
                                _sheetSectionTitle(
                                  icon:
                                      Icons.tune_outlined,
                                  title:
                                      'Penetapan Admin',
                                  subtitle:
                                      'Data ini akan dilihat oleh anggota.',
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller:
                                      amountController,
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal: true,
                                  ),
                                  textInputAction:
                                      TextInputAction.next,
                                  onTapOutside: (_) {},
                                  decoration:
                                      _inputDecoration(
                                    label:
                                        'Jumlah Disetujui (Kg)',
                                    icon:
                                        Icons.scale_outlined,
                                  ),
                                ),
                                const SizedBox(height: 11),
                                TextField(
                                  controller:
                                      dateController,
                                  readOnly: true,
                                  onTapOutside: (_) {},
                                  onTap: () async {
                                    final picked =
                                        await showDatePicker(
                                      context:
                                          sheetContext,
                                      initialDate:
                                          selectedDate ??
                                              DateTime.now()
                                                  .add(
                                                const Duration(
                                                  days: 1,
                                                ),
                                              ),
                                      firstDate:
                                          DateTime(2020),
                                      lastDate:
                                          DateTime(2100),
                                      helpText:
                                          'Pilih tanggal pengambilan',
                                      cancelText: 'Batal',
                                      confirmText: 'Pilih',
                                    );

                                    if (picked == null) {
                                      return;
                                    }

                                    setSheetState(() {
                                      selectedDate = picked;
                                      dateController.text =
                                          _inputDate(
                                        picked,
                                      );
                                    });
                                  },
                                  decoration:
                                      _inputDecoration(
                                    label:
                                        'Tanggal Pengambilan',
                                    icon: Icons
                                        .calendar_month_outlined,
                                    suffixIcon: Icons
                                        .arrow_drop_down_rounded,
                                  ),
                                ),
                                const SizedBox(height: 11),
                                TextField(
                                  controller:
                                      locationController,
                                  textInputAction:
                                      TextInputAction.next,
                                  textCapitalization:
                                      TextCapitalization
                                          .sentences,
                                  onTapOutside: (_) {},
                                  decoration:
                                      _inputDecoration(
                                    label:
                                        'Lokasi Pengambilan',
                                    icon: Icons
                                        .location_on_outlined,
                                  ),
                                ),
                                const SizedBox(height: 11),
                                TextField(
                                  controller:
                                      noteController,
                                  maxLines: 3,
                                  keyboardType:
                                      TextInputType.multiline,
                                  textInputAction:
                                      TextInputAction.done,
                                  textCapitalization:
                                      TextCapitalization
                                          .sentences,
                                  onTapOutside: (_) {},
                                  onSubmitted: (_) {
                                    FocusScope.of(
                                      sheetContext,
                                    ).unfocus();
                                  },
                                  decoration:
                                      _inputDecoration(
                                    label:
                                        'Catatan Admin',
                                    icon:
                                        Icons.notes_outlined,
                                  ),
                                ),
                                if (errorText.isNotEmpty) ...[
                                  const SizedBox(height: 11),
                                  _sheetError(errorText),
                                ],
                                const SizedBox(height: 18),
                                SizedBox(
                                  height: 51,
                                  child:
                                      ElevatedButton.icon(
                                    onPressed: () {
                                      FocusScope.of(
                                        sheetContext,
                                      ).unfocus();

                                      final amount =
                                          double.tryParse(
                                        amountController
                                            .text
                                            .trim()
                                            .replaceAll(
                                              ',',
                                              '.',
                                            ),
                                      );

                                      final location =
                                          locationController
                                              .text
                                              .trim();

                                      if (amount == null ||
                                          amount <= 0) {
                                        setSheetState(() {
                                          errorText =
                                              'Jumlah bantuan harus lebih dari 0 Kg.';
                                        });
                                        return;
                                      }

                                      if (selectedDate ==
                                          null) {
                                        setSheetState(() {
                                          errorText =
                                              'Tanggal pengambilan wajib dipilih.';
                                        });
                                        return;
                                      }

                                      if (location.isEmpty) {
                                        setSheetState(() {
                                          errorText =
                                              'Lokasi pengambilan wajib diisi.';
                                        });
                                        return;
                                      }

                                      Navigator.pop(
                                        sheetContext,
                                        _ApprovalData(
                                          amount: amount,
                                          pickupDate:
                                              selectedDate!,
                                          location:
                                              location,
                                          adminNote:
                                              noteController
                                                  .text
                                                  .trim(),
                                        ),
                                      );
                                    },
                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          primaryGreen,
                                      foregroundColor:
                                          Colors.white,
                                      elevation: 0,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          15,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons
                                          .check_circle_outline_rounded,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Simpan dan Setujui',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight:
                                            FontWeight.w900,
                                      ),
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
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    dateController.dispose();
    locationController.dispose();
    noteController.dispose();

    if (result == null || !mounted) {
      return;
    }

    await _approveApplication(
      id: id,
      item: item,
      approval: result,
    );
  }

  Future<void> _approveApplication({
    required String id,
    required Map<dynamic, dynamic> item,
    required _ApprovalData approval,
  }) async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      final existingApprovalDate = _text(
        item['tanggal_disetujui'],
      );

      final previousStatus = normalStatus(item);

      await bantuanPupukRef.child(id).update({
        'status': 'disetujui',
        'status_penyaluran': 'siap_diambil',
        'jumlah_disetujui': approval.amount,
        'jumlah_final_kg': approval.amount,
        'tanggal_verifikasi': now,
        'tanggal_disetujui':
            existingApprovalDate == '-'
                ? now
                : existingApprovalDate,
        'tanggal_pengambilan':
            _inputDate(approval.pickupDate),
        'lokasi_pengambilan': approval.location,
        'catatan_admin': approval.adminNote,
      });

      final nik = ambilNik(item);
      final jenisPupuk = ambilJenisPupuk(item);

      if (previousStatus ==
              'menunggu_verifikasi' &&
          nik.isNotEmpty) {
        try {
          await NotificationHelper.pupukDisetujui(
            nik: nik,
            jenisPupuk: jenisPupuk,
            eventId: '${id}_disetujui',
          );
        } catch (error) {
          debugPrint(
            'Bantuan pupuk disetujui, tetapi notifikasi user gagal: $error',
          );
        }
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        previousStatus == 'disetujui'
            ? 'Penetapan bantuan berhasil diperbarui.'
            : 'Pengajuan berhasil disetujui dan dijadwalkan.',
        primaryGreen,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal menyimpan penetapan bantuan.',
        redStatus,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _openRejectionSheet({
    required String id,
    required Map<dynamic, dynamic> item,
  }) async {
    final reasonController = TextEditingController(
      text: ambilCatatanAdmin(item) == '-'
          ? ''
          : ambilCatatanAdmin(item),
    );

    String errorText = '';

    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:
          adminNavy.withValues(alpha: 0.52),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            final bottomInset =
                MediaQuery.viewInsetsOf(context).bottom;

            return AnimatedPadding(
              duration:
                  const Duration(milliseconds: 180),
              padding: EdgeInsets.only(
                bottom: bottomInset,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                  ),
                  child: Material(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          17,
                          10,
                          17,
                          22,
                        ),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Container(
                              height: 5,
                              width: 43,
                              decoration: BoxDecoration(
                                color: cardBorder,
                                borderRadius:
                                    BorderRadius.circular(
                                  999,
                                ),
                              ),
                            ),
                            const SizedBox(height: 17),
                            Container(
                              height: 58,
                              width: 58,
                              decoration: BoxDecoration(
                                color:
                                    redStatus.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  19,
                                ),
                              ),
                              child: const Icon(
                                Icons.block_rounded,
                                color: redStatus,
                                size: 29,
                              ),
                            ),
                            const SizedBox(height: 13),
                            const Text(
                              'Tolak Pengajuan?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textDark,
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tuliskan alasan penolakan untuk ${ambilNama(item)}.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: textGrey,
                                fontSize: 11,
                                height: 1.4,
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 17),
                            TextField(
                              controller:
                                  reasonController,
                              maxLines: 4,
                              keyboardType:
                                  TextInputType.multiline,
                              textInputAction:
                                  TextInputAction.done,
                              textCapitalization:
                                  TextCapitalization
                                      .sentences,
                              onTapOutside: (_) {},
                              onSubmitted: (_) {
                                FocusScope.of(
                                  sheetContext,
                                ).unfocus();
                              },
                              decoration:
                                  _inputDecoration(
                                label:
                                    'Alasan Penolakan',
                                icon: Icons
                                    .notes_outlined,
                              ),
                            ),
                            if (errorText.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _sheetError(errorText),
                            ],
                            const SizedBox(height: 17),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      Navigator.pop(
                                        sheetContext,
                                      );
                                    },
                                    style: OutlinedButton
                                        .styleFrom(
                                      foregroundColor:
                                          textDark,
                                      side: const BorderSide(
                                        color: cardBorder,
                                      ),
                                      minimumSize:
                                          const Size(
                                        0,
                                        48,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Batal',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child:
                                      ElevatedButton.icon(
                                    onPressed: () {
                                      FocusScope.of(
                                        sheetContext,
                                      ).unfocus();

                                      final value =
                                          reasonController
                                              .text
                                              .trim();

                                      if (value.isEmpty) {
                                        setSheetState(() {
                                          errorText =
                                              'Alasan penolakan wajib diisi.';
                                        });
                                        return;
                                      }

                                      Navigator.pop(
                                        sheetContext,
                                        value,
                                      );
                                    },
                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          redStatus,
                                      foregroundColor:
                                          Colors.white,
                                      elevation: 0,
                                      minimumSize:
                                          const Size(
                                        0,
                                        48,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Tolak',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    reasonController.dispose();

    if (reason == null ||
        reason.trim().isEmpty ||
        !mounted) {
      return;
    }

    await _rejectApplication(
      id: id,
      item: item,
      reason: reason,
    );
  }

  Future<void> _rejectApplication({
    required String id,
    required Map<dynamic, dynamic> item,
    required String reason,
  }) async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      await bantuanPupukRef.child(id).update({
        'status': 'ditolak',
        'status_penyaluran': 'ditolak',
        'alasan_penolakan': reason.trim(),
        'catatan_admin': reason.trim(),
        'tanggal_verifikasi': now,
        'tanggal_diproses': now,
      });

      final nik = ambilNik(item);
      final jenisPupuk = ambilJenisPupuk(item);

      if (nik.isNotEmpty) {
        try {
          await NotificationHelper.pupukDitolak(
            nik: nik,
            jenisPupuk: jenisPupuk,
            eventId: '${id}_ditolak',
          );
        } catch (error) {
          debugPrint(
            'Bantuan pupuk ditolak, tetapi notifikasi user gagal: $error',
          );
        }
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Pengajuan bantuan pupuk berhasil ditolak.',
        redStatus,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Gagal menolak pengajuan.',
        redStatus,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> konfirmasiSudahDiambil({
    required String id,
    required Map<dynamic, dynamic> item,
  }) async {
    final nama = ambilNama(item);
    final pupuk = ambilJenisPupuk(item);
    final jumlah = formatKg(
      ambilJumlahFinal(item),
    );

    final result = await _showConfirmDialog(
      icon: Icons.inventory_rounded,
      iconColor: primaryGreen,
      title: 'Bantuan Sudah Diambil?',
      message:
          'Pastikan $nama telah menerima $pupuk sebanyak '
          '$jumlah Kg. Tindakan ini tidak mengurangi stok '
          'pupuk karena merupakan pencatatan penyaluran bantuan pemerintah.',
      confirmText: 'Ya, Sudah Diambil',
      confirmColor: primaryGreen,
    );

    if (!mounted || result != true) {
      return;
    }

    await tandaiSudahDiambil(
      id,
      item,
    );
  }

  Future<void> tandaiSudahDiambil(
    String id,
    Map<dynamic, dynamic> item,
  ) async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final status = normalStatus(item);

      if (status != 'disetujui') {
        throw Exception(
          'Hanya bantuan yang telah disetujui '
          'yang dapat ditandai sudah diambil.',
        );
      }

      final amount = ambilJumlahFinal(item);

      if (amount <= 0) {
        throw Exception(
          'Jumlah bantuan belum ditetapkan.',
        );
      }

      final now = DateTime.now().toIso8601String();

      await bantuanPupukRef.child(id).update({
        'status': 'sudah_diambil',
        'status_penyaluran': 'sudah_diambil',
        'tanggal_diambil': now,
        'waktu_pengambilan': now,
        'tanggal_selesai': now,
      });

      final nik = ambilNik(item);
      final jenisPupuk = ambilJenisPupuk(item);

      if (nik.isNotEmpty) {
        try {
          await NotificationHelper.pupukSudahDiambil(
            nik: nik,
            jenisPupuk: jenisPupuk,
            jumlahKg: formatKg(amount),
            eventId: '${id}_sudah_diambil',
          );
        } catch (error) {
          debugPrint(
            'Bantuan pupuk sudah diambil, tetapi notifikasi user gagal: $error',
          );
        }
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Bantuan berhasil ditandai sudah diambil.',
        primaryGreen,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        error
            .toString()
            .replaceAll('Exception: ', ''),
        redStatus,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              22,
              20,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 62,
                  width: 62,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: iconColor.withValues(
                        alpha: 0.16,
                      ),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 21),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          side: const BorderSide(
                            color: cardBorder,
                          ),
                          minimumSize:
                              const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                            true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize:
                              const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
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
  }

  void _showSnackBar(
    String message,
    Color color,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
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
          17,
          0,
          17,
          17,
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

    final horizontalPadding =
        screenWidth < 340 ? 13.0 : 17.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _AdminPupukBackground(),
                SafeArea(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: rootRef.onValue,
                    builder: (
                      context,
                      snapshot,
                    ) {
                      if (snapshot.hasError) {
                        return _errorContent(
                          horizontalPadding,
                          snapshot.error.toString(),
                        );
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _loadingContent(
                          horizontalPadding,
                        );
                      }

                      final root = _asMap(
                        snapshot
                            .data?.snapshot.value,
                      );

                      final semuaData =
                          _readApplications(
                        root['bantuan_pupuk'],
                      );

                      final anggotaValue =
                          root['anggota'];

                      final counts =
                          hitungStatus(semuaData);

                      final filteredData =
                          filterData(semuaData);

                      return RefreshIndicator(
                        color: adminPurple,
                        backgroundColor:
                            Colors.white,
                        onRefresh: refreshData,
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
                            28,
                          ),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(
                                  maxWidth: 760,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .stretch,
                                  children: [
                                    _headerPage(
                                      counts[
                                              'menunggu_verifikasi'] ??
                                          0,
                                    ),
                                    const SizedBox(
                                      height: 13,
                                    ),
                                    _filterPanel(
                                      totalSemua:
                                          counts['semua'] ??
                                              0,
                                      totalMenunggu:
                                          counts[
                                                  'menunggu_verifikasi'] ??
                                              0,
                                      totalDisetujui:
                                          counts[
                                                  'disetujui'] ??
                                              0,
                                      totalDiambil:
                                          counts[
                                                  'sudah_diambil'] ??
                                              0,
                                      totalDitolak:
                                          counts[
                                                  'ditolak'] ??
                                              0,
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    _infoStatus(
                                      counts[
                                              'menunggu_verifikasi'] ??
                                          0,
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),
                                    _sectionTitle(
                                      title:
                                          'Daftar Pengajuan',
                                      subtitle:
                                          selectedFilter ==
                                                  'semua'
                                              ? 'Seluruh bantuan pupuk pemerintah'
                                              : 'Filter: ${teksStatus(selectedFilter)}',
                                    ),
                                    const SizedBox(
                                      height: 11,
                                    ),
                                    if (semuaData.isEmpty)
                                      _messageState(
                                        icon: Icons
                                            .inventory_2_outlined,
                                        title:
                                            'Belum Ada Pengajuan',
                                        message:
                                            'Pengajuan bantuan pupuk pemerintah belum tersedia.',
                                      )
                                    else if (filteredData
                                        .isEmpty)
                                      _messageState(
                                        icon: Icons
                                            .search_off_rounded,
                                        title:
                                            'Data Tidak Ditemukan',
                                        message:
                                            'Tidak ada pengajuan dengan status ini.',
                                      )
                                    else
                                      ...filteredData.map(
                                        (entry) {
                                          final item = Map<
                                              dynamic,
                                              dynamic>.from(
                                            entry.value
                                                as Map,
                                          );

                                          return _pupukCard(
                                            id: entry.key,
                                            item: item,
                                            anggotaValue:
                                                anggotaValue,
                                          );
                                        },
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
                if (isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: adminNavy.withValues(
                        alpha: 0.28,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        height: 74,
                        width: 74,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child:
                            const CircularProgressIndicator(
                          color: adminPurple,
                          strokeWidth: 2.8,
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
  }

  Widget _headerPage(int totalMenunggu) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        13,
        13,
        14,
        13,
      ),
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
            color: adminNavy.withValues(
              alpha: 0.25,
            ),
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
                  color: Colors.white.withValues(
                    alpha: 0.07,
                  ),
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
                    color: Colors.white.withValues(
                      alpha: 0.14,
                    ),
                    borderRadius:
                        BorderRadius.circular(15),
                    border: Border.all(
                      color:
                          Colors.white.withValues(
                        alpha: 0.19,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.fact_check_outlined,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verifikasi Bantuan Pupuk',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.2,
                          fontWeight:
                              FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Penetapan bantuan pemerintah',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xffDFE5F0),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w600,
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
        color: Colors.white.withValues(
          alpha: 0.13,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.19,
          ),
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
              color: Colors.white.withValues(
                alpha: 0.77,
              ),
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
    required int totalDiambil,
    required int totalDitolak,
  }) {
    final filters = [
      _FilterItem(
        label: 'Menunggu',
        value: 'menunggu_verifikasi',
        total: totalMenunggu,
        icon: Icons.pending_actions_outlined,
        color: orangeStatus,
      ),
      _FilterItem(
        label: 'Disetujui',
        value: 'disetujui',
        total: totalDisetujui,
        icon: Icons.verified_outlined,
        color: blueStatus,
      ),
      _FilterItem(
        label: 'Diambil',
        value: 'sudah_diambil',
        total: totalDiambil,
        icon: Icons.inventory_outlined,
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
      decoration: _cardDecoration(
        radius: 19,
      ),
      child: SizedBox(
        height: 39,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: filters.length,
          separatorBuilder: (
            context,
            index,
          ) {
            return const SizedBox(width: 7);
          },
          itemBuilder: (
            context,
            index,
          ) {
            final filter = filters[index];
            final active =
                selectedFilter == filter.value;

            return Material(
              color: Colors.transparent,
              borderRadius:
                  BorderRadius.circular(999),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedFilter =
                        filter.value;
                  });
                },
                borderRadius:
                    BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? filter.color
                        : filter.color.withValues(
                            alpha: 0.07,
                          ),
                    borderRadius:
                        BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? filter.color
                          : filter.color.withValues(
                              alpha: 0.12,
                            ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        color: active
                            ? Colors.white
                            : filter.color,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        filter.label,
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : textDark,
                          fontSize: 9.8,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        constraints:
                            const BoxConstraints(
                          minWidth: 20,
                          minHeight: 19,
                        ),
                        alignment: Alignment.center,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white.withValues(
                                  alpha: 0.18,
                                )
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            999,
                          ),
                        ),
                        child: Text(
                          filter.total > 99
                              ? '99+'
                              : filter.total
                                  .toString(),
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : filter.color,
                            fontSize: 8,
                            height: 1,
                            fontWeight:
                                FontWeight.w900,
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

  Widget _infoStatus(int totalMenunggu) {
    final clear = totalMenunggu == 0;
    final color =
        clear ? primaryGreen : orangeStatus;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: clear ? softGreen : softAmber,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
                  ? 'Semua pengajuan bantuan telah diproses.'
                  : '$totalMenunggu pengajuan memerlukan penetapan jumlah, jadwal, dan lokasi pengambilan.',
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
    required String title,
    required String subtitle,
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
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pupukCard({
    required String id,
    required Map<dynamic, dynamic> item,
    required dynamic anggotaValue,
  }) {
    final name = ambilNama(item);
    final nik = ambilNik(item);
    final program = ambilNamaProgram(item);
    final period = ambilPeriode(item);
    final fertilizer = ambilJenisPupuk(item);
    final requestedAmount =
        ambilJumlahDiajukan(item);
    final finalAmount = ambilJumlahFinal(item);
    final status = normalStatus(item);

    final member = _findMember(
      anggotaValue,
      nik,
    );

    final eligible = _isActiveMember(member);

    final submissionDate = formatTanggal(
      _firstValue(
        item,
        [
          'tanggal_pengajuan',
          'tanggalPengajuan',
          'created_at',
          'createdAt',
          'tanggal',
        ],
      ),
      includeTime: true,
    );

    final pickupDate = formatTanggal(
      item['tanggal_pengambilan'],
    );

    final pickupLocation =
        ambilLokasiPengambilan(item);

    final userNote = ambilCatatanUser(item);
    final adminNote = ambilCatatanAdmin(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 47,
                width: 47,
                decoration: BoxDecoration(
                  color:
                      primaryGreen.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: Icon(
                  iconPupuk(fertilizer),
                  color: primaryGreen,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      program,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 13.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$name • ${sensorNik(nik)}',
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      period,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textSoft,
                        fontSize: 9.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 11),
          _eligibilityBanner(
            eligible: eligible,
            member: member,
          ),
          const SizedBox(height: 11),
          _dataBox(
            children: [
              _infoRow(
                Icons.badge_outlined,
                'NIK',
                sensorNik(nik),
              ),
              _infoRow(
                Icons.verified_user_outlined,
                'Keanggotaan',
                _memberStatusText(member),
                valueColor: eligible
                    ? primaryGreen
                    : redStatus,
              ),
              _infoRow(
                Icons.landscape_outlined,
                'Luas Lahan',
                _formatLandArea(member),
              ),
              _infoRow(
                Icons.inventory_2_outlined,
                'Jenis Pupuk',
                fertilizer,
              ),
              _infoRow(
                Icons.scale_outlined,
                'Paket/Diajukan',
                requestedAmount > 0
                    ? '${formatKg(requestedAmount)} Kg'
                    : 'Belum ditentukan',
              ),
              if (status !=
                  'menunggu_verifikasi')
                _infoRow(
                  Icons.fact_check_outlined,
                  'Jumlah Final',
                  finalAmount > 0
                      ? '${formatKg(finalAmount)} Kg'
                      : '-',
                  valueColor: finalAmount > 0
                      ? primaryGreen
                      : redStatus,
                ),
              _infoRow(
                Icons.schedule_outlined,
                'Diajukan',
                submissionDate,
              ),
              if (status == 'disetujui' ||
                  status == 'sudah_diambil') ...[
                _infoRow(
                  Icons.calendar_month_outlined,
                  'Pengambilan',
                  pickupDate,
                  valueColor: blueStatus,
                ),
                _infoRow(
                  Icons.location_on_outlined,
                  'Lokasi',
                  pickupLocation,
                ),
              ],
              if (status == 'sudah_diambil')
                _infoRow(
                  Icons.task_alt_outlined,
                  'Diserahkan',
                  formatTanggal(
                    item['tanggal_diambil'] ??
                        item['waktu_pengambilan'],
                    includeTime: true,
                  ),
                  valueColor: primaryGreen,
                ),
              if (userNote != '-')
                _infoRow(
                  Icons.chat_bubble_outline_rounded,
                  'Catatan User',
                  userNote,
                ),
              if (adminNote != '-')
                _infoRow(
                  Icons.admin_panel_settings_outlined,
                  'Catatan Admin',
                  adminNote,
                  valueColor:
                      status == 'ditolak'
                          ? redStatus
                          : adminPurple,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                status == 'sudah_diambil'
                    ? Icons.task_alt_rounded
                    : status == 'ditolak'
                        ? Icons.cancel_rounded
                        : status == 'disetujui'
                            ? Icons
                                .inventory_outlined
                            : Icons
                                .hourglass_top_rounded,
                color: warnaStatus(status),
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  teksStatusPanjang(status),
                  style: TextStyle(
                    color: warnaStatus(status),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (status ==
              'menunggu_verifikasi') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    title: 'Tolak',
                    icon: Icons.close_rounded,
                    color: redStatus,
                    onPressed: () {
                      _openRejectionSheet(
                        id: id,
                        item: item,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _actionButton(
                    title: eligible
                        ? 'Tetapkan'
                        : 'Tidak Memenuhi',
                    icon: eligible
                        ? Icons
                            .fact_check_outlined
                        : Icons
                            .person_off_outlined,
                    color: primaryGreen,
                    onPressed: eligible
                        ? () {
                            _openApprovalSheet(
                              id: id,
                              item: item,
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
          if (status == 'disetujui') ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final narrow =
                    constraints.maxWidth < 330;

                if (narrow) {
                  return Column(
                    children: [
                      _actionButton(
                        title: 'Ubah Penetapan',
                        icon: Icons.edit_outlined,
                        color: adminPurple,
                        onPressed: () {
                          _openApprovalSheet(
                            id: id,
                            item: item,
                          );
                        },
                      ),
                      const SizedBox(height: 9),
                      _actionButton(
                        title:
                            'Tandai Sudah Diambil',
                        icon:
                            Icons.task_alt_rounded,
                        color: primaryGreen,
                        onPressed: () {
                          konfirmasiSudahDiambil(
                            id: id,
                            item: item,
                          );
                        },
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        title: 'Ubah Penetapan',
                        icon: Icons.edit_outlined,
                        color: adminPurple,
                        onPressed: () {
                          _openApprovalSheet(
                            id: id,
                            item: item,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _actionButton(
                        title: 'Sudah Diambil',
                        icon:
                            Icons.task_alt_rounded,
                        color: primaryGreen,
                        onPressed: () {
                          konfirmasiSudahDiambil(
                            id: id,
                            item: item,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _eligibilityBanner({
    required bool eligible,
    required Map<dynamic, dynamic>? member,
  }) {
    final color =
        eligible ? primaryGreen : redStatus;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: eligible ? softGreen : softRed,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            eligible
                ? Icons.verified_user_rounded
                : Icons.person_off_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              eligible
                  ? 'Pemohon tercatat sebagai anggota aktif.'
                  : member == null
                      ? 'NIK pemohon tidak ditemukan pada data anggota.'
                      : 'Status anggota tidak aktif. Periksa sebelum menyetujui.',
              style: TextStyle(
                color: color,
                fontSize: 9.8,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 92,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundStatus(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: warnaStatus(status).withValues(
            alpha: 0.13,
          ),
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

  Widget _dataBox({
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: cardBorder,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: adminPurple,
            size: 16,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 99,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10.1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? textDark,
                fontSize: 10.5,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        onPressed: isProcessing
            ? null
            : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              color.withValues(alpha: 0.28),
          disabledForegroundColor:
              Colors.white.withValues(alpha: 0.84),
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          icon,
          size: 17,
        ),
        label: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _sheetHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        10,
        13,
        14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: cardBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            width: 43,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
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
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: const Color(0xffF1F3F6),
                borderRadius:
                    BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  borderRadius:
                      BorderRadius.circular(12),
                  child: const SizedBox(
                    height: 38,
                    width: 38,
                    child: Icon(
                      Icons.close_rounded,
                      color: textGrey,
                      size: 20,
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

  Widget _approvalSummary(
    Map<dynamic, dynamic> item,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            adminNavy,
            adminIndigo,
          ],
        ),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.13,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  ambilJenisPupuk(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${ambilNama(item)} • ${ambilPeriode(item)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.75,
                    ),
                    fontSize: 9.8,
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

  Widget _sheetSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          height: 37,
          width: 37,
          decoration: BoxDecoration(
            color: softPurple,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: adminPurple,
            size: 19,
          ),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 9.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sheetError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: softRed,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: redStatus.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: redStatus,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: redStatus,
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w700,
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
      labelStyle: const TextStyle(
        color: textGrey,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: adminPurple,
        size: 20,
      ),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(
              suffixIcon,
              color: textGrey,
            ),
      filled: true,
      fillColor: const Color(0xffF8F9FC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: cardBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: adminPurple,
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
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.14,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.20,
              ),
            ),
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

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        23,
      ),
      decoration: _cardDecoration(radius: 21),
      child: Column(
        children: [
          Container(
            height: 67,
            width: 67,
            decoration: BoxDecoration(
              color: softPurple,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: adminPurple.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            child: Icon(
              icon,
              color: adminPurple,
              size: 32,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.6,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingContent(
    double horizontalPadding,
  ) {
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
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Column(
              children: [
                _headerPage(0),
                const SizedBox(height: 120),
                const CircularProgressIndicator(
                  color: adminPurple,
                  strokeWidth: 2.7,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorContent(
    double horizontalPadding,
    String error,
  ) {
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
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Column(
              children: [
                _headerPage(0),
                const SizedBox(height: 15),
                _messageState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Data Gagal Dimuat',
                  message:
                      'Periksa koneksi internet lalu muat ulang halaman.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: adminNavy.withValues(alpha: 0.055),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _ApprovalData {
  final double amount;
  final DateTime pickupDate;
  final String location;
  final String adminNote;

  const _ApprovalData({
    required this.amount,
    required this.pickupDate,
    required this.location,
    required this.adminNote,
  });
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

class _AdminPupukBackground extends StatelessWidget {
  const _AdminPupukBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            final baseSize =
                width < height ? width : height;

            final largeCircle =
                (baseSize * 0.98)
                    .clamp(280.0, 470.0)
                    .toDouble();

            final mediumCircle =
                (baseSize * 0.68)
                    .clamp(190.0, 335.0)
                    .toDouble();

            final smallCircle =
                (baseSize * 0.41)
                    .clamp(120.0, 205.0)
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
                          Color(0xff293E62),
                          Color(0xffE8EAF2),
                          Color(0xffF2F4F8),
                        ],
                        stops: [
                          0,
                          0.19,
                          0.45,
                          1,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -largeCircle * 0.55,
                    right: -largeCircle * 0.30,
                    child: _AdminPupukCircle(
                      size: largeCircle,
                      color: const Color(0xff6256A4),
                      alpha: 0.22,
                    ),
                  ),
                  Positioned(
                    top: -smallCircle * 0.14,
                    left: -smallCircle * 0.23,
                    child: _AdminPupukRing(
                      size: smallCircle,
                    ),
                  ),
                  Positioned(
                    top: height * 0.28,
                    left: -mediumCircle * 0.57,
                    child: _AdminPupukCircle(
                      size: mediumCircle,
                      color: const Color(0xff6882A2),
                      alpha: 0.21,
                    ),
                  ),
                  Positioned(
                    top: height * 0.50,
                    right: -mediumCircle * 0.62,
                    child: _AdminPupukCircle(
                      size: mediumCircle * 1.08,
                      color: const Color(0xffE7E0F6),
                      alpha: 0.80,
                    ),
                  ),
                  Positioned(
                    bottom: -largeCircle * 0.52,
                    left: -largeCircle * 0.31,
                    child: _AdminPupukCircle(
                      size: largeCircle,
                      color: const Color(0xffE2E8F2),
                      alpha: 0.85,
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

class _AdminPupukCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;

  const _AdminPupukCircle({
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
        border: Border.all(
          color: color.withValues(alpha: 0.08),
          width: 2,
        ),
      ),
    );
  }
}

class _AdminPupukRing extends StatelessWidget {
  final double size;

  const _AdminPupukRing({
    required this.size,
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
          color: Colors.white.withValues(alpha: 0.12),
          width: 2,
        ),
      ),
    );
  }
}