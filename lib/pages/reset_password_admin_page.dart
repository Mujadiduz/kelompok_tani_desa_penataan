import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/notification_helper.dart';
import '../widgets/app_background.dart';

class ResetPasswordAdminPage extends StatefulWidget {
  const ResetPasswordAdminPage({super.key});

  @override
  State<ResetPasswordAdminPage> createState() =>
      _ResetPasswordAdminPageState();
}

class _ResetPasswordAdminPageState
    extends State<ResetPasswordAdminPage> {
  static const String _databaseUrl =
      'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app';

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color darkGreen = Color(0xff14532D);
  static const Color deepGreen = Color(0xff0F3D25);
  static const Color blue = Color(0xff326FA3);
  static const Color amber = Color(0xffD98212);
  static const Color red = Color(0xffC83B3B);

  static const Color background = Color(0xffF2F7F5);
  static const Color cardBorder = Color(0xffE0E8E5);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softBlue = Color(0xffEAF3FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softRed = Color(0xffFBEAEA);

  final FirebaseDatabase db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: _databaseUrl,
  );

  late final DatabaseReference rootRef;
  late final DatabaseReference anggotaRef;
  late final DatabaseReference resetRef;

  bool isProcessing = false;
  String processingId = '';

  @override
  void initState() {
    super.initState();

    rootRef = db.ref();
    anggotaRef = db.ref('anggota');
    resetRef = db.ref('reset_password');
  }

  Map<String, dynamic> _stringMap(dynamic value) {
    if (value is! Map) {
      return <String, dynamic>{};
    }

    return Map<dynamic, dynamic>.from(value).map(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  String _text(
    dynamic value, {
    String fallback = '-',
  }) {
    final result = (value ?? '').toString().trim();

    if (result.isEmpty ||
        result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  String _normalizeNik(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .trim();
  }

  String _normalizeStatus(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  DateTime _readDate(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toString().length >= 13
            ? value
            : value * 1000,
      ).toLocal();
    }

    if (value is double) {
      final number = value.toInt();

      return DateTime.fromMillisecondsSinceEpoch(
        number.toString().length >= 13
            ? number
            : number * 1000,
      ).toLocal();
    }

    return DateTime.tryParse(
          (value ?? '').toString(),
        )?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<Map<String, dynamic>> _readRequests(
    dynamic value,
  ) {
    if (value is! Map) {
      return <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];

    for (final entry
        in Map<dynamic, dynamic>.from(value).entries) {
      if (entry.value is! Map) {
        continue;
      }

      final item = _stringMap(entry.value);
      final status = _normalizeStatus(item['status']);

      if (status != 'menunggu') {
        continue;
      }

      item['id_reset'] = entry.key.toString();
      result.add(item);
    }

    result.sort(
      (first, second) {
        final firstDate = _readDate(
          first['tanggal_pengajuan'],
        );

        final secondDate = _readDate(
          second['tanggal_pengajuan'],
        );

        return secondDate.compareTo(firstDate);
      },
    );

    return result;
  }

  String _maskedNik(dynamic value) {
    final nik = _normalizeNik(value);

    if (nik.length <= 4) {
      return nik.isEmpty ? '-' : nik;
    }

    return '•••• •••• •••• '
        '${nik.substring(nik.length - 4)}';
  }

  String _monthName(int month) {
    const names = <String>[
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
      return '-';
    }

    return names[month - 1];
  }

  String _formatDate(dynamic value) {
    final date = _readDate(value);

    if (date.millisecondsSinceEpoch <= 0) {
      return '-';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day ${_monthName(date.month)} '
        '${date.year}, $hour.$minute WIB';
  }

  Future<void> _refreshData() async {
    await resetRef.get();
  }

  Future<DatabaseReference?> _findMemberReference(
    String nik,
  ) async {
    final directReference = anggotaRef.child(nik);

    final directSnapshot =
        await directReference.get().timeout(
      const Duration(seconds: 12),
    );

    if (directSnapshot.exists &&
        directSnapshot.value is Map) {
      return directReference;
    }

    final querySnapshot = await anggotaRef
        .orderByChild('nik')
        .equalTo(nik)
        .get()
        .timeout(
          const Duration(seconds: 12),
        );

    if (!querySnapshot.exists ||
        querySnapshot.value is! Map) {
      return null;
    }

    final data = Map<dynamic, dynamic>.from(
      querySnapshot.value as Map,
    );

    if (data.isEmpty) {
      return null;
    }

    return anggotaRef.child(
      data.keys.first.toString(),
    );
  }

  Future<void> _openProcessSheet(
    Map<String, dynamic> item,
  ) async {
    if (isProcessing) {
      return;
    }

    final idReset =
        _text(item['id_reset'], fallback: '');

    final nik = _normalizeNik(item['nik']);

    final nama = _text(
      item['nama'],
      fallback: 'Anggota',
    );

    if (idReset.isEmpty) {
      _showSnack(
        'ID permintaan reset tidak valid.',
        red,
      );
      return;
    }

    if (nik.length != 16) {
      _showSnack(
        'NIK anggota tidak valid.',
        red,
      );
      return;
    }

    final passwordController =
        TextEditingController();

    final confirmationController =
        TextEditingController();

    bool obscurePassword = true;
    bool obscureConfirmation = true;
    String errorText = '';

    final password =
        await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:
          deepGreen.withValues(alpha: 0.48),
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
              child: SafeArea(
                top: false,
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 560,
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.fromLTRB(
                          17,
                          11,
                          17,
                          23,
                        ),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 44,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: cardBorder,
                                  borderRadius:
                                      BorderRadius.circular(
                                    999,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _iconBox(
                                  Icons
                                      .lock_reset_rounded,
                                  primaryGreen,
                                  softGreen,
                                  48,
                                ),
                                const SizedBox(width: 11),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        'Proses Reset Password',
                                        style: TextStyle(
                                          color: textDark,
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight
                                                  .w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Tetapkan password baru untuk anggota.',
                                        style: TextStyle(
                                          color: textGrey,
                                          fontSize: 10.3,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(
                                      sheetContext,
                                    ).pop();
                                  },
                                  icon: const Icon(
                                    Icons.close_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _memberSummary(
                              nama: nama,
                              nik: nik,
                              tanggal:
                                  item['tanggal_pengajuan'],
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller:
                                  passwordController,
                              obscureText:
                                  obscurePassword,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction:
                                  TextInputAction.next,
                              decoration:
                                  _passwordDecoration(
                                label: 'Password Baru',
                                icon:
                                    Icons.lock_outline_rounded,
                                obscure:
                                    obscurePassword,
                                onToggle: () {
                                  setSheetState(() {
                                    obscurePassword =
                                        !obscurePassword;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 11),
                            TextField(
                              controller:
                                  confirmationController,
                              obscureText:
                                  obscureConfirmation,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction:
                                  TextInputAction.done,
                              onSubmitted: (_) {
                                FocusScope.of(
                                  sheetContext,
                                ).unfocus();
                              },
                              decoration:
                                  _passwordDecoration(
                                label:
                                    'Konfirmasi Password',
                                icon:
                                    Icons.password_rounded,
                                obscure:
                                    obscureConfirmation,
                                onToggle: () {
                                  setSheetState(() {
                                    obscureConfirmation =
                                        !obscureConfirmation;
                                  });
                                },
                              ),
                            ),
                            if (errorText.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding:
                                    const EdgeInsets.all(
                                  10,
                                ),
                                decoration: BoxDecoration(
                                  color: softRed,
                                  borderRadius:
                                      BorderRadius.circular(
                                    14,
                                  ),
                                  border: Border.all(
                                    color: red.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    const Icon(
                                      Icons
                                          .error_outline_rounded,
                                      color: red,
                                      size: 18,
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: Text(
                                        errorText,
                                        style:
                                            const TextStyle(
                                          color: red,
                                          fontSize: 10.2,
                                          height: 1.35,
                                          fontWeight:
                                              FontWeight
                                                  .w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding:
                                  const EdgeInsets.all(
                                11,
                              ),
                              decoration: BoxDecoration(
                                color: softAmber,
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),
                                border: Border.all(
                                  color: amber.withValues(
                                    alpha: 0.11,
                                  ),
                                ),
                              ),
                              child: const Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Icon(
                                    Icons
                                        .info_outline_rounded,
                                    color: amber,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Setelah diproses, password anggota diperbarui dan notifikasi dikirim ke NIK pemohon.',
                                      style: TextStyle(
                                        color: textGrey,
                                        fontSize: 10,
                                        height: 1.4,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 17),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  FocusScope.of(
                                    sheetContext,
                                  ).unfocus();

                                  final newPassword =
                                      passwordController
                                          .text
                                          .trim();

                                  final confirmation =
                                      confirmationController
                                          .text
                                          .trim();

                                  if (newPassword.length <
                                      6) {
                                    setSheetState(() {
                                      errorText =
                                          'Password baru minimal 6 karakter.';
                                    });
                                    return;
                                  }

                                  if (newPassword !=
                                      confirmation) {
                                    setSheetState(() {
                                      errorText =
                                          'Konfirmasi password tidak sama.';
                                    });
                                    return;
                                  }

                                  Navigator.of(
                                    sheetContext,
                                  ).pop(newPassword);
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
                                        BorderRadius
                                            .circular(
                                      15,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons
                                      .check_circle_outline_rounded,
                                  size: 19,
                                ),
                                label: const Text(
                                  'Simpan Password Baru',
                                  style: TextStyle(
                                    fontSize: 12.8,
                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),
                              ),
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

    await Future<void>.delayed(
      const Duration(milliseconds: 240),
    );

    passwordController.dispose();
    confirmationController.dispose();

    if (password == null ||
        !mounted) {
      return;
    }

    await _processReset(
      idReset: idReset,
      nik: nik,
      nama: nama,
      passwordBaru: password,
    );
  }

  InputDecoration _passwordDecoration({
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: primaryGreen,
        size: 20,
      ),
      suffixIcon: IconButton(
        tooltip: obscure
            ? 'Tampilkan password'
            : 'Sembunyikan password',
        onPressed: onToggle,
        icon: Icon(
          obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: primaryGreen,
          size: 20,
        ),
      ),
      filled: true,
      fillColor: const Color(0xffF9FBFA),
      labelStyle: const TextStyle(
        color: textGrey,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
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
          color: primaryGreen,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _memberSummary({
    required String nama,
    required String nik,
    required dynamic tanggal,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: blue.withValues(alpha: 0.11),
        ),
      ),
      child: Column(
        children: [
          _summaryLine(
            Icons.person_outline_rounded,
            'Nama',
            nama,
          ),
          _summaryLine(
            Icons.badge_outlined,
            'NIK',
            _maskedNik(nik),
          ),
          _summaryLine(
            Icons.calendar_month_outlined,
            'Diajukan',
            _formatDate(tanggal),
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(
    IconData icon,
    String label,
    String value, {
    bool last = false,
  }) {
    return Container(
      padding: EdgeInsets.only(
        bottom: last ? 0 : 9,
      ),
      margin: EdgeInsets.only(
        bottom: last ? 0 : 9,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: blue.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: blue,
            size: 17,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: textGrey,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: textDark,
                fontSize: 10.4,
                height: 1.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processReset({
    required String idReset,
    required String nik,
    required String nama,
    required String passwordBaru,
  }) async {
    if (isProcessing) {
      return;
    }

    setState(() {
      isProcessing = true;
      processingId = idReset;
    });

    bool notificationSent = true;

    try {
      final requestSnapshot =
          await resetRef.child(idReset).get().timeout(
        const Duration(seconds: 12),
      );

      if (!requestSnapshot.exists ||
          requestSnapshot.value is! Map) {
        throw Exception(
          'Permintaan reset tidak ditemukan.',
        );
      }

      final requestData =
          _stringMap(requestSnapshot.value);

      if (_normalizeStatus(
            requestData['status'],
          ) !=
          'menunggu') {
        throw Exception(
          'Permintaan reset sudah diproses.',
        );
      }

      final memberReference =
          await _findMemberReference(nik);

      if (memberReference == null) {
        throw Exception(
          'Data anggota tidak ditemukan.',
        );
      }

      final now =
          DateTime.now().toIso8601String();

      /*
       * Tetap memakai node database lama:
       * anggota dan reset_password.
       * Multi-location update mencegah satu node berhasil
       * sementara node lainnya gagal.
       */
      await rootRef.update({
        '${memberReference.path}/password':
            passwordBaru,
        '${memberReference.path}/tanggal_reset_password':
            now,
        '${memberReference.path}/tanggal_ubah_password':
            now,
        'reset_password/$idReset/status':
            'selesai',
        'reset_password/$idReset/tanggal_diproses':
            now,
      }).timeout(
        const Duration(seconds: 15),
      );

      try {
        await NotificationHelper
            .passwordBerhasilDireset(
          nik: nik,
          passwordBaru: passwordBaru,
          eventId: '${idReset}_selesai',
        );
      } catch (error) {
        notificationSent = false;

        debugPrint(
          'Reset berhasil, tetapi notifikasi user gagal: $error',
        );
      }

      if (!mounted) {
        return;
      }

      await _showSuccessDialog(
        nama: nama,
        notificationSent:
            notificationSent,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error
          .toString()
          .replaceFirst('Exception: ', '');

      _showSnack(
        message.isEmpty
            ? 'Gagal memproses reset password.'
            : message,
        red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
          processingId = '';
        });
      }
    }
  }

  Future<void> _showSuccessDialog({
    required String nama,
    required bool notificationSent,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 420,
            ),
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                18,
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  _iconBox(
                    Icons
                        .check_circle_rounded,
                    primaryGreen,
                    softGreen,
                    66,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Reset Password Selesai',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textDark,
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Password akun $nama berhasil diperbarui.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: textGrey,
                      fontSize: 11.2,
                      height: 1.45,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  if (!notificationSent) ...[
                    const SizedBox(height: 11),
                    Container(
                      padding:
                          const EdgeInsets.all(
                        10,
                      ),
                      decoration: BoxDecoration(
                        color: softAmber,
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                        border: Border.all(
                          color: amber.withValues(
                            alpha: 0.11,
                          ),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons
                                .info_outline_rounded,
                            color: amber,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Password sudah berubah, tetapi notifikasi belum terkirim. Data utama tetap aman.',
                              style: TextStyle(
                                color: textGrey,
                                fontSize: 9.8,
                                height: 1.4,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 47,
                    child:
                        ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop();
                      },
                      style: ElevatedButton
                          .styleFrom(
                        backgroundColor:
                            primaryGreen,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
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
                        Icons.done_rounded,
                        size: 19,
                      ),
                      label: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w900,
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

  void _showSnack(
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
          margin:
              const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width;

    final horizontalPadding =
        width < 350 ? 13.0 : 17.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: background,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const _ResetAdminBackground(),
              SafeArea(
                child:
                    StreamBuilder<DatabaseEvent>(
                  stream: resetRef.onValue,
                  builder: (
                    context,
                    snapshot,
                  ) {
                    final requests =
                        _readRequests(
                      snapshot.data
                          ?.snapshot.value,
                    );

                    return RefreshIndicator(
                      color: primaryGreen,
                      backgroundColor:
                          Colors.white,
                      onRefresh: _refreshData,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            EdgeInsets.fromLTRB(
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
                                  _header(
                                    requests.length,
                                  ),
                                  const SizedBox(
                                    height: 13,
                                  ),
                                  _statusPanel(
                                    requests.length,
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  _sectionTitle(
                                    requests.length,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  if (snapshot
                                          .connectionState ==
                                      ConnectionState
                                          .waiting)
                                    ...List.generate(
                                      3,
                                      (_) =>
                                          _loadingCard(),
                                    )
                                  else if (snapshot
                                      .hasError)
                                    _messageCard(
                                      icon: Icons
                                          .cloud_off_outlined,
                                      title:
                                          'Data Tidak Dapat Dimuat',
                                      message: snapshot
                                          .error
                                          .toString(),
                                      color: red,
                                      backgroundColor:
                                          softRed,
                                    )
                                  else if (requests
                                      .isEmpty)
                                    _messageCard(
                                      icon: Icons
                                          .task_alt_rounded,
                                      title:
                                          'Tidak Ada Permintaan',
                                      message:
                                          'Semua permintaan reset password sudah selesai diproses.',
                                      color:
                                          primaryGreen,
                                      backgroundColor:
                                          softGreen,
                                    )
                                  else
                                    ...requests.map(
                                      _requestCard,
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
                _processingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int total) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            deepGreen,
            darkGreen,
            primaryGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: deepGreen.withValues(
              alpha: 0.22,
            ),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          _headerButton(),
          const SizedBox(width: 10),
          _iconBox(
            Icons.password_rounded,
            Colors.white,
            Colors.white.withValues(
              alpha: 0.14,
            ),
            46,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Password',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Proses permintaan anggota',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(
                      0xffD7EEE0,
                    ),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints:
                const BoxConstraints(
              minWidth: 42,
              minHeight: 39,
            ),
            alignment: Alignment.center,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.13,
              ),
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white
                    .withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: Text(
              total > 99
                  ? '99+'
                  : total.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPanel(int total) {
    final hasRequests = total > 0;
    final color =
        hasRequests ? amber : primaryGreen;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _iconBox(
            hasRequests
                ? Icons
                    .pending_actions_outlined
                : Icons.task_alt_rounded,
            color,
            color.withValues(alpha: 0.09),
            45,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  hasRequests
                      ? '$total permintaan menunggu'
                      : 'Semua permintaan selesai',
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasRequests
                      ? 'Buka permintaan dan tetapkan password baru.'
                      : 'Belum ada pekerjaan reset password.',
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 10.5,
                    height: 1.35,
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

  Widget _sectionTitle(int total) {
    return Row(
      children: [
        Container(
          height: 31,
          width: 5,
          decoration: BoxDecoration(
            color: primaryGreen,
            borderRadius:
                BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Permintaan Menunggu',
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$total data perlu diproses admin',
                style: const TextStyle(
                  color: textGrey,
                  fontSize: 10.3,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _requestCard(
    Map<String, dynamic> item,
  ) {
    final id = _text(
      item['id_reset'],
      fallback: '',
    );

    final nama = _text(
      item['nama'],
      fallback: 'Anggota',
    );

    final nik = _normalizeNik(
      item['nik'],
    );

    final processing =
        isProcessing &&
        processingId == id;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 11,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: _cardDecoration(
        radius: 21,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _iconBox(
                Icons
                    .person_search_outlined,
                amber,
                softAmber,
                49,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color: textDark,
                        fontSize: 14.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskedNik(nik),
                      style:
                          const TextStyle(
                        color: textGrey,
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: softAmber,
                  borderRadius:
                      BorderRadius.circular(
                    999,
                  ),
                ),
                child: const Text(
                  'MENUNGGU',
                  style: TextStyle(
                    color: amber,
                    fontSize: 7.7,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 0.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(
                0xffF9FBFA,
              ),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: cardBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .calendar_month_outlined,
                  color: blue,
                  size: 17,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(
                      item[
                          'tanggal_pengajuan'],
                    ),
                    style:
                        const TextStyle(
                      color: textGrey,
                      fontSize: 10.2,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            height: 47,
            child: ElevatedButton.icon(
              onPressed:
                  isProcessing
                      ? null
                      : () {
                          _openProcessSheet(
                            item,
                          );
                        },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryGreen,
                foregroundColor:
                    Colors.white,
                disabledBackgroundColor:
                    primaryGreen.withValues(
                  alpha: 0.38,
                ),
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              icon: processing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child:
                          CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : const Icon(
                      Icons
                          .lock_reset_rounded,
                      size: 19,
                    ),
              label: Text(
                processing
                    ? 'Memproses...'
                    : 'Proses Reset Password',
                style: const TextStyle(
                  fontSize: 12.2,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      height: 152,
      margin:
          const EdgeInsets.only(
        bottom: 11,
      ),
      decoration: _cardDecoration(),
      child: const Center(
        child:
            CircularProgressIndicator(
          color: primaryGreen,
          strokeWidth: 2.6,
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 31,
      ),
      decoration: _cardDecoration(
        radius: 22,
      ),
      child: Column(
        children: [
          _iconBox(
            icon,
            color,
            backgroundColor,
            68,
          ),
          const SizedBox(height: 13),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textDark,
              fontSize: 15.5,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.8,
              height: 1.4,
              fontWeight:
                  FontWeight.w600,
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
          color: deepGreen.withValues(
            alpha: 0.28,
          ),
          alignment: Alignment.center,
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              19,
              20,
              17,
            ),
            constraints:
                const BoxConstraints(
              maxWidth: 280,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(21),
              boxShadow: [
                BoxShadow(
                  color: deepGreen.withValues(
                    alpha: 0.16,
                  ),
                  blurRadius: 24,
                  offset:
                      const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                SizedBox(
                  height: 34,
                  width: 34,
                  child:
                      CircularProgressIndicator(
                    color: primaryGreen,
                    strokeWidth: 2.8,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Memproses Reset Password',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Jangan menutup halaman.',
                  style: TextStyle(
                    color: textGrey,
                    fontSize: 9.7,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerButton() {
    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        onTap: isProcessing
            ? null
            : () {
                Navigator.maybePop(
                  context,
                );
              },
        borderRadius:
            BorderRadius.circular(14),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.14,
            ),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          child: const Icon(
            Icons
                .arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 15,
          ),
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
        borderRadius:
            BorderRadius.circular(
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
    double radius = 19,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.98,
      ),
      borderRadius:
          BorderRadius.circular(radius),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: deepGreen.withValues(
            alpha: 0.05,
          ),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _ResetAdminBackground
    extends StatelessWidget {
  const _ResetAdminBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final base =
                constraints.maxWidth <
                        constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;

            final large = (base * 0.98)
                .clamp(280.0, 460.0)
                .toDouble();

            final medium = (base * 0.68)
                .clamp(190.0, 330.0)
                .toDouble();

            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(
                        begin:
                            Alignment.topCenter,
                        end:
                            Alignment.bottomCenter,
                        colors: [
                          Color(0xff0F3D25),
                          Color(0xff2E7D32),
                          Color(0xffDDEFE3),
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
                    child:
                        _BackgroundCircle(
                      size: large,
                      color:
                          const Color(
                        0xff62B979,
                      ),
                      alpha: 0.19,
                    ),
                  ),
                  Positioned(
                    top: constraints
                            .maxHeight *
                        0.31,
                    left: -medium * 0.58,
                    child:
                        _BackgroundCircle(
                      size: medium,
                      color:
                          const Color(
                        0xffA9D9B7,
                      ),
                      alpha: 0.34,
                    ),
                  ),
                  Positioned(
                    bottom: -large * 0.52,
                    left: -large * 0.31,
                    child:
                        _BackgroundCircle(
                      size: large,
                      color:
                          const Color(
                        0xffDDEFE3,
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

class _BackgroundCircle
    extends StatelessWidget {
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
