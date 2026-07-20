import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../widgets/app_background.dart';

class RiwayatAdminPage extends StatefulWidget {
  const RiwayatAdminPage({super.key});

  @override
  State<RiwayatAdminPage> createState() =>
      _RiwayatAdminPageState();
}

class _RiwayatAdminPageState
    extends State<RiwayatAdminPage> {
  static const Color adminNavy = Color(0xff172A46);
  static const Color adminNavyLight = Color(0xff294762);
  static const Color adminPurple = Color(0xff6256A4);
  static const Color adminIndigo = Color(0xff435987);

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color tealColor = Color(0xff28766F);
  static const Color blueStatus = Color(0xff326CA3);
  static const Color orangeStatus = Color(0xffD98212);
  static const Color purpleStatus = Color(0xff725BB4);
  static const Color redStatus = Color(0xffC83B3B);

  static const Color softGreen = Color(0xffE9F5EB);
  static const Color softBlue = Color(0xffE9F2FA);
  static const Color softAmber = Color(0xffFFF3DD);
  static const Color softPurple = Color(0xffF0ECFA);
  static const Color softRed = Color(0xffFBEAEA);
  static const Color softTeal = Color(0xffE7F4F2);
  static const Color softSlate = Color(0xffEEF1F6);

  static const Color pageBackground = Color(0xffF2F4F8);
  static const Color cardBorder = Color(0xffE0E5EC);
  static const Color textDark = Color(0xff18212B);
  static const Color textGrey = Color(0xff66727F);
  static const Color textSoft = Color(0xff8B96A2);

  final FirebaseDatabase _db =
      FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://kelompok-tani-desa-penataan-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  String _selectedFilter = 'Semua';

  static const List<String> _filters = [
    'Semua',
    'Anggota',
    'Pupuk',
    'Alat',
    'Reset',
  ];

  Map<dynamic, dynamic> _asMap(dynamic value) {
    if (value == null || value is! Map) {
      return {};
    }

    return Map<dynamic, dynamic>.from(value);
  }

  String _safeText(
    dynamic value, {
    String fallback = '-',
  }) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text == '-' ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  dynamic _firstValue(
    Map<dynamic, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

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

  String _normalizeNik(dynamic value) {
    return (value ?? '')
        .toString()
        .replaceAll(
          RegExp(r'[^0-9]'),
          '',
        )
        .trim();
  }

  String _cleanStatus(dynamic value) {
    final status = (value ?? 'menunggu')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_');

    if (status.isEmpty) {
      return 'menunggu';
    }

    return status;
  }

  bool _isPendingStatus(dynamic value) {
    final status = _cleanStatus(value);

    const pendingStatuses = {
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

  bool _isRejectedStatus(dynamic value) {
    final status = _cleanStatus(value);

    return status == 'ditolak' ||
        status == 'rejected';
  }

  bool _isCompletedStatus(dynamic value) {
    final status = _cleanStatus(value);

    const completedStatuses = {
      'selesai',
      'completed',
      'sudah_diambil',
      'sudah diambil',
      'dikembalikan',
      'aktif',
    };

    return completedStatuses.contains(status);
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
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
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final text = value.toString().trim();

    if (text.isEmpty || text == '-') {
      return DateTime.fromMillisecondsSinceEpoch(0);
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
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    final parsed = DateTime.tryParse(text);

    if (parsed != null) {
      return parsed.toLocal();
    }

    final cleanDate = text.split(' ').first;

    final slashParts = cleanDate.split('/');

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

    final dashParts = cleanDate.split('-');

    if (dashParts.length == 3 &&
        dashParts[0].length <= 2) {
      final day = int.tryParse(dashParts[0]);
      final month = int.tryParse(dashParts[1]);
      final year = int.tryParse(dashParts[2]);

      if (day != null &&
          month != null &&
          year != null) {
        return DateTime(year, month, day);
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime _readDate(
    Map<dynamic, dynamic> data,
  ) {
    final raw = _firstValue(
      data,
      [
        'tanggal_pengajuan',
        'tanggalPengajuan',
        'tanggal_daftar',
        'tanggalDaftar',
        'tanggal_pinjam',
        'tanggalPinjam',
        'tanggal_permintaan',
        'tanggal_reset',
        'created_at',
        'createdAt',
        'updated_at',
        'updatedAt',
        'waktu',
        'tanggal',
        'timestamp',
      ],
    );

    return _parseDate(raw);
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

  String _shortMonth(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  String _monthYearLabel(DateTime date) {
    if (date.millisecondsSinceEpoch <= 0) {
      return 'Tanggal Tidak Diketahui';
    }

    return '${_monthName(date.month)} ${date.year}';
  }

  String _formatDate(
    dynamic value, {
    bool includeTime = true,
  }) {
    final date = _parseDate(value);

    if (date.millisecondsSinceEpoch <= 0) {
      return '-';
    }

    final day = date.day.toString().padLeft(2, '0');

    final dateText =
        '$day ${_monthName(date.month)} ${date.year}';

    if (!includeTime) {
      return dateText;
    }

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$dateText • $hour:$minute';
  }

  String _formatTime(DateTime date) {
    if (date.millisecondsSinceEpoch <= 0) {
      return '--:--';
    }

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatStatus(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return 'Disetujui';
    }

    if (status == 'aktif') {
      return 'Aktif';
    }

    if (status == 'ditolak' ||
        status == 'rejected') {
      return 'Ditolak';
    }

    if (status == 'sudah_diambil' ||
        status == 'sudah diambil') {
      return 'Sudah Diambil';
    }

    if (status == 'dipinjam') {
      return 'Dipinjam';
    }

    if (status == 'dikembalikan') {
      return 'Dikembalikan';
    }

    if (status == 'selesai' ||
        status == 'completed') {
      return 'Selesai';
    }

    if (status == 'proses' ||
        status == 'diproses' ||
        status == 'sedang_diproses') {
      return 'Diproses';
    }

    return 'Menunggu';
  }

  String _statusDescription(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return 'Pengajuan telah disetujui oleh administrator.';
    }

    if (status == 'aktif') {
      return 'Akun anggota telah aktif di sistem TaniGo.';
    }

    if (_isRejectedStatus(status)) {
      return 'Pengajuan tidak dapat disetujui.';
    }

    if (status == 'sudah_diambil' ||
        status == 'sudah diambil') {
      return 'Bantuan pupuk telah diserahkan kepada anggota.';
    }

    if (status == 'dipinjam') {
      return 'Alat pertanian sedang dipinjam anggota.';
    }

    if (status == 'dikembalikan') {
      return 'Alat pertanian telah dikembalikan.';
    }

    if (status == 'selesai' ||
        status == 'completed') {
      return 'Aktivitas telah selesai diproses.';
    }

    if (status == 'proses' ||
        status == 'diproses' ||
        status == 'sedang_diproses') {
      return 'Data sedang diperiksa oleh administrator.';
    }

    return 'Data masih menunggu proses administrator.';
  }

  Color _statusColor(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return blueStatus;
    }

    if (status == 'aktif') {
      return primaryGreen;
    }

    if (_isRejectedStatus(status)) {
      return redStatus;
    }

    if (status == 'sudah_diambil' ||
        status == 'sudah diambil') {
      return tealColor;
    }

    if (status == 'dipinjam') {
      return purpleStatus;
    }

    if (status == 'dikembalikan' ||
        status == 'selesai' ||
        status == 'completed') {
      return primaryGreen;
    }

    return orangeStatus;
  }

  Color _statusBackground(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return softBlue;
    }

    if (status == 'aktif') {
      return softGreen;
    }

    if (_isRejectedStatus(status)) {
      return softRed;
    }

    if (status == 'sudah_diambil' ||
        status == 'sudah diambil') {
      return softTeal;
    }

    if (status == 'dipinjam') {
      return softPurple;
    }

    if (status == 'dikembalikan' ||
        status == 'selesai' ||
        status == 'completed') {
      return softGreen;
    }

    return softAmber;
  }

  IconData _statusIcon(dynamic value) {
    final status = _cleanStatus(value);

    if (status == 'disetujui' ||
        status == 'approved') {
      return Icons.verified_rounded;
    }

    if (status == 'aktif') {
      return Icons.verified_user_rounded;
    }

    if (_isRejectedStatus(status)) {
      return Icons.cancel_rounded;
    }

    if (status == 'sudah_diambil' ||
        status == 'sudah diambil') {
      return Icons.inventory_rounded;
    }

    if (status == 'dipinjam') {
      return Icons.handyman_rounded;
    }

    if (status == 'dikembalikan') {
      return Icons.assignment_turned_in_rounded;
    }

    if (_isCompletedStatus(status)) {
      return Icons.task_alt_rounded;
    }

    return Icons.schedule_rounded;
  }

  Set<String> _activeMemberNiks(dynamic value) {
    final result = <String>{};
    final data = _asMap(value);

    for (final item in data.values) {
      if (item is! Map) {
        continue;
      }

      final detail =
          Map<dynamic, dynamic>.from(item);

      final nik = _normalizeNik(
        detail['nik'],
      );

      if (nik.isNotEmpty) {
        result.add(nik);
      }
    }

    return result;
  }

  List<_RiwayatAdminItem> _buildHistory({
    required dynamic anggotaValue,
    required dynamic calonAnggotaValue,
    required dynamic bantuanPupukValue,
    required dynamic peminjamanAlatValue,
    required dynamic resetPasswordValue,
  }) {
    final result = <_RiwayatAdminItem>[];

    final activeNiks =
        _activeMemberNiks(anggotaValue);

    result.addAll(
      _extractItems(
        value: calonAnggotaValue,
        defaultTitle: 'Calon anggota baru',
        defaultSubtitle:
            'Mengajukan pendaftaran anggota',
        icon: Icons.person_add_alt_1_rounded,
        color: blueStatus,
        type: 'Verifikasi Anggota',
        category: 'Anggota',
        activeMemberNiks: activeNiks,
      ),
    );

    result.addAll(
      _extractItems(
        value: bantuanPupukValue,
        defaultTitle: 'Pengajuan bantuan pupuk',
        defaultSubtitle:
            'Mengajukan bantuan pupuk',
        icon: Icons.inventory_2_outlined,
        color: primaryGreen,
        type: 'Bantuan Pupuk',
        category: 'Pupuk',
      ),
    );

    result.addAll(
      _extractItems(
        value: peminjamanAlatValue,
        defaultTitle:
            'Pengajuan peminjaman alat',
        defaultSubtitle:
            'Mengajukan peminjaman alat pertanian',
        icon: Icons
            .precision_manufacturing_outlined,
        color: orangeStatus,
        type: 'Peminjaman Alat',
        category: 'Alat',
      ),
    );

    result.addAll(
      _extractItems(
        value: resetPasswordValue,
        defaultTitle:
            'Permintaan reset password',
        defaultSubtitle:
            'Mengajukan pemulihan akun',
        icon: Icons.lock_reset_rounded,
        color: purpleStatus,
        type: 'Reset Password',
        category: 'Reset',
      ),
    );

    result.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return result;
  }

  List<_RiwayatAdminItem> _extractItems({
    required dynamic value,
    required String defaultTitle,
    required String defaultSubtitle,
    required IconData icon,
    required Color color,
    required String type,
    required String category,
    Set<String>? activeMemberNiks,
  }) {
    final data = _asMap(value);

    if (data.isEmpty) {
      return [];
    }

    final result = <_RiwayatAdminItem>[];

    for (final entry in data.entries) {
      if (entry.value is! Map) {
        continue;
      }

      final detail =
          Map<dynamic, dynamic>.from(
        entry.value as Map,
      );

      final nama = _safeText(
        detail['nama'],
        fallback: defaultTitle,
      );

      final nik = _normalizeNik(
        detail['nik'],
      );

      final alat = _safeText(
        detail['nama_alat'] ??
            detail['alat'] ??
            detail['jenis_alat'],
      );

      final jenisPupuk = _safeText(
        detail['jenis_pupuk'] ??
            detail['nama_pupuk'] ??
            detail['pupuk'],
      );

      String status = _cleanStatus(
        detail['status'],
      );

      /*
       * Bila NIK calon anggota sudah masuk ke node
       * anggota, status pada halaman riwayat ditampilkan
       * sebagai disetujui walaupun data lama calon_anggota
       * masih berstatus menunggu.
       */
      if (category == 'Anggota' &&
          nik.isNotEmpty &&
          activeMemberNiks != null &&
          activeMemberNiks.contains(nik) &&
          _isPendingStatus(status)) {
        status = 'disetujui';
      }

      String subtitle = defaultSubtitle;

      if (category == 'Anggota') {
        subtitle = nik.isEmpty
            ? 'Pendaftaran anggota'
            : 'NIK $nik';
      }

      if (category == 'Pupuk') {
        final jumlah = _safeText(
          detail['jumlah_pupuk'] ??
              detail['jumlah_kg'] ??
              detail['jumlah'],
        );

        if (jenisPupuk != '-' &&
            jumlah != '-') {
          subtitle =
              '$jenisPupuk • ${_withUnit(jumlah, 'Kg')}';
        } else if (jenisPupuk != '-') {
          subtitle = jenisPupuk;
        }
      }

      if (category == 'Alat') {
        final jumlah = _safeText(
          detail['jumlah_alat'] ??
              detail['jumlah'],
          fallback: '1',
        );

        if (alat != '-') {
          subtitle =
              '$alat • ${_withUnit(jumlah, 'Unit')}';
        }
      }

      if (category == 'Reset') {
        subtitle = nik.isEmpty
            ? 'Permintaan pemulihan akun'
            : 'NIK $nik';
      }

      result.add(
        _RiwayatAdminItem(
          id: entry.key.toString(),
          title: nama,
          subtitle: subtitle,
          status: status,
          date: _readDate(detail),
          icon: icon,
          color: color,
          type: type,
          category: category,
          rawData: detail,
        ),
      );
    }

    return result;
  }

  String _withUnit(
    dynamic value,
    String unit,
  ) {
    final text = _safeText(value);

    if (text == '-') {
      return '-';
    }

    if (text
        .toLowerCase()
        .contains(unit.toLowerCase())) {
      return text;
    }

    return '$text $unit';
  }

  List<_RiwayatAdminItem> _filterItems(
    List<_RiwayatAdminItem> items,
  ) {
    if (_selectedFilter == 'Semua') {
      return items;
    }

    return items.where(
      (item) =>
          item.category == _selectedFilter,
    ).toList();
  }

  Map<String, List<_RiwayatAdminItem>>
      _groupByMonth(
    List<_RiwayatAdminItem> items,
  ) {
    final grouped =
        <String, List<_RiwayatAdminItem>>{};

    for (final item in items) {
      final key = _monthYearLabel(item.date);

      grouped.putIfAbsent(
        key,
        () => [],
      );

      grouped[key]!.add(item);
    }

    return grouped;
  }

  int _countCategory(
    List<_RiwayatAdminItem> items,
    String category,
  ) {
    if (category == 'Semua') {
      return items.length;
    }

    return items
        .where(
          (item) => item.category == category,
        )
        .length;
  }

  Future<void> _refreshData() async {
    await _db.ref().get();
  }

  List<_AdminDetailItem> _buildDetailItems(
    _RiwayatAdminItem item,
  ) {
    final data = item.rawData;

    final result = <_AdminDetailItem>[
      _AdminDetailItem(
        label: 'Nomor Referensi',
        value: item.id,
        icon: Icons.confirmation_number_outlined,
      ),
      _AdminDetailItem(
        label: 'Jenis Aktivitas',
        value: item.type,
        icon: Icons.category_outlined,
      ),
      _AdminDetailItem(
        label: 'Nama',
        value: item.title,
        icon: Icons.person_outline_rounded,
      ),
    ];

    final nik = _safeText(
      data['nik'],
    );

    if (nik != '-') {
      result.add(
        _AdminDetailItem(
          label: 'NIK',
          value: nik,
          icon: Icons.assignment_ind_outlined,
        ),
      );
    }

    if (item.category == 'Anggota') {
      result.addAll([
        _AdminDetailItem(
          label: 'Nomor Telepon',
          value: _safeText(
            data['telepon'] ??
                data['nomor_telepon'] ??
                data['no_hp'],
          ),
          icon: Icons.phone_outlined,
        ),
        _AdminDetailItem(
          label: 'Jenis Kelamin',
          value: _safeText(
            data['jenis_kelamin'],
          ),
          icon: Icons.wc_rounded,
        ),
        _AdminDetailItem(
          label: 'Alamat',
          value: _safeText(
            data['alamat'],
          ),
          icon: Icons.home_work_outlined,
        ),
        _AdminDetailItem(
          label: 'Luas Lahan',
          value: _formatLandArea(data),
          icon: Icons.landscape_outlined,
        ),
        _AdminDetailItem(
          label: 'Tanggal Pendaftaran',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_daftar',
                'tanggalDaftar',
                'created_at',
                'createdAt',
                'tanggal',
              ],
            ),
          ),
          icon: Icons.calendar_month_outlined,
        ),
      ]);
    }

    if (item.category == 'Pupuk') {
      result.addAll([
        _AdminDetailItem(
          label: 'Jenis Pupuk',
          value: _safeText(
            data['jenis_pupuk'] ??
                data['nama_pupuk'] ??
                data['pupuk'],
          ),
          icon: Icons.inventory_2_outlined,
        ),
        _AdminDetailItem(
          label: 'Jumlah Diajukan',
          value: _withUnit(
            data['jumlah_pupuk'] ??
                data['jumlah_kg'] ??
                data['jumlah'],
            'Kg',
          ),
          icon: Icons.scale_outlined,
        ),
        _AdminDetailItem(
          label: 'Tanggal Pengajuan',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_pengajuan',
                'tanggalPengajuan',
                'created_at',
                'createdAt',
                'tanggal',
              ],
            ),
          ),
          icon: Icons.send_time_extension_outlined,
        ),
        _AdminDetailItem(
          label: 'Tanggal Disetujui',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_disetujui',
                'tanggal_persetujuan',
                'waktu_disetujui',
              ],
            ),
          ),
          icon: Icons.verified_outlined,
        ),
        _AdminDetailItem(
          label: 'Tanggal Pengambilan',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_pengambilan',
                'tanggal_diambil',
                'waktu_pengambilan',
              ],
            ),
          ),
          icon: Icons.inventory_outlined,
        ),
      ]);
    }

    if (item.category == 'Alat') {
      result.addAll([
        _AdminDetailItem(
          label: 'Nama Alat',
          value: _safeText(
            data['nama_alat'] ??
                data['alat'] ??
                data['jenis_alat'],
          ),
          icon: Icons
              .precision_manufacturing_outlined,
        ),
        _AdminDetailItem(
          label: 'Jumlah Alat',
          value: _withUnit(
            data['jumlah_alat'] ??
                data['jumlah'] ??
                '1',
            'Unit',
          ),
          icon: Icons.numbers_rounded,
        ),
        _AdminDetailItem(
          label: 'Tanggal Pengajuan',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_pengajuan',
                'tanggalPengajuan',
                'created_at',
                'createdAt',
                'tanggal',
              ],
            ),
          ),
          icon: Icons.send_time_extension_outlined,
        ),
        _AdminDetailItem(
          label: 'Tanggal Pinjam',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_pinjam',
                'tanggal_mulai',
              ],
            ),
            includeTime: false,
          ),
          icon: Icons.calendar_today_outlined,
        ),
        _AdminDetailItem(
          label: 'Rencana Kembali',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_kembali',
                'tanggal_selesai',
              ],
            ),
            includeTime: false,
          ),
          icon: Icons.event_available_outlined,
        ),
        _AdminDetailItem(
          label: 'Tanggal Dikembalikan',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_dikembalikan',
                'tanggal_kembali_aktual',
              ],
            ),
          ),
          icon:
              Icons.assignment_turned_in_outlined,
        ),
      ]);
    }

    if (item.category == 'Reset') {
      result.addAll([
        _AdminDetailItem(
          label: 'Tanggal Permintaan',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_permintaan',
                'tanggal_reset',
                'tanggal_pengajuan',
                'created_at',
                'createdAt',
                'tanggal',
              ],
            ),
          ),
          icon: Icons.schedule_outlined,
        ),
        _AdminDetailItem(
          label: 'Tanggal Diproses',
          value: _formatDate(
            _firstValue(
              data,
              [
                'tanggal_diproses',
                'tanggal_selesai',
                'updated_at',
                'updatedAt',
              ],
            ),
          ),
          icon: Icons.task_alt_outlined,
        ),
      ]);
    }

    result.add(
      _AdminDetailItem(
        label: 'Status',
        value: _formatStatus(item.status),
        icon: _statusIcon(item.status),
        valueColor: _statusColor(item.status),
      ),
    );

    final note = _safeText(
      _firstValue(
        data,
        [
          'catatan',
          'keterangan',
          'alasan',
          'alasan_penolakan',
          'pesan_admin',
        ],
      ),
    );

    result.add(
      _AdminDetailItem(
        label: 'Catatan',
        value: note,
        icon: Icons.notes_outlined,
      ),
    );

    return result;
  }

  String _formatLandArea(
    Map<dynamic, dynamic> data,
  ) {
    final value = _firstValue(
      data,
      [
        'luas_lahan',
        'luas_sawah',
        'luas_meter_m2',
      ],
    );

    final text = _safeText(value);

    if (text == '-') {
      return '-';
    }

    final unit = _safeText(
      data['satuan_lahan'],
      fallback: 'ha',
    );

    final lowerText = text.toLowerCase();

    if (lowerText.contains('ha') ||
        lowerText.contains('m²') ||
        lowerText.contains('meter')) {
      return text;
    }

    return '$text $unit';
  }

  void _showDetail(
    _RiwayatAdminItem item,
  ) {
    FocusScope.of(context).unfocus();

    final details = _buildDetailItems(item);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor:
          adminNavy.withValues(alpha: 0.50),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.94,
          expand: false,
          builder: (
            context,
            scrollController,
          ) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      _detailHeader(
                        sheetContext,
                        item,
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior
                                  .manual,
                          physics:
                              const ClampingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(
                            17,
                            15,
                            17,
                            28,
                          ),
                          children: [
                            _detailStatusCard(item),
                            const SizedBox(height: 14),
                            _detailDataCard(details),
                            const SizedBox(height: 14),
                            _detailFooter(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenWidth = mediaQuery.size.width;

    final horizontalPadding =
        screenWidth < 340 ? 13.0 : 17.0;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SizedBox.expand(
        child: AppBackground(
          showPattern: false,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const _AdminHistoryBackground(),
                SafeArea(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: _db.ref().onValue,
                    builder: (
                      context,
                      snapshot,
                    ) {
                      if (snapshot.hasError) {
                        return _errorView();
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _loadingView();
                      }

                      final root = _asMap(
                        snapshot
                            .data?.snapshot.value,
                      );

                      final allItems = _buildHistory(
                        anggotaValue:
                            root['anggota'],
                        calonAnggotaValue:
                            root['calon_anggota'],
                        bantuanPupukValue:
                            root['bantuan_pupuk'],
                        peminjamanAlatValue:
                            root['peminjaman_alat'],
                        resetPasswordValue:
                            root['reset_password'],
                      );

                      final filteredItems =
                          _filterItems(allItems);

                      final groupedItems =
                          _groupByMonth(
                        filteredItems,
                      );

                      return RefreshIndicator(
                        color: adminPurple,
                        backgroundColor:
                            Colors.white,
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
                                    _header(),
                                    const SizedBox(
                                      height: 13,
                                    ),
                                    _filterCard(
                                      allItems,
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    _informationBanner(
                                      filteredItems
                                          .length,
                                    ),
                                    const SizedBox(
                                      height: 17,
                                    ),
                                    _historyContent(
                                      groupedItems,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
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
              right: -48,
              top: -58,
              child: Container(
                height: 145,
                width: 145,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.07,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 38,
              bottom: -66,
              child: Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: const Color(
                    0xffB9ACFF,
                  ).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                final compact =
                    constraints.maxWidth < 350;

                return Row(
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
                        Icons.history_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat Admin',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.8,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Catatan aktivitas pengelolaan TaniGo',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Color(0xffDFE5F0),
                              fontSize: 10.1,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            999,
                          ),
                          border: Border.all(
                            color:
                                Colors.white.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.8,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
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
            borderRadius:
                BorderRadius.circular(14),
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

  Widget _filterCard(
    List<_RiwayatAdminItem> items,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        11,
      ),
      decoration: _cardDecoration(
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_alt_outlined,
                color: adminPurple,
                size: 18,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Filter Riwayat',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 39,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics:
                  const ClampingScrollPhysics(),
              itemCount: _filters.length,
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
                final filter = _filters[index];

                return _filterChip(
                  label: filter,
                  count: _countCategory(
                    items,
                    filter,
                  ),
                  selected:
                      _selectedFilter == filter,
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = _filterColor(label);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(13),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? color
                : color.withValues(alpha: 0.07),
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? color
                  : color.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _filterIcon(label),
                color: selected
                    ? Colors.white
                    : color,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : textDark,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 21,
                  minHeight: 20,
                ),
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(
                          alpha: 0.18,
                        )
                      : Colors.white,
                  borderRadius:
                      BorderRadius.circular(999),
                ),
                child: Text(
                  count > 99
                      ? '99+'
                      : count.toString(),
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : color,
                    fontSize: 8.2,
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
  }

  Color _filterColor(String label) {
    if (label == 'Anggota') {
      return blueStatus;
    }

    if (label == 'Pupuk') {
      return primaryGreen;
    }

    if (label == 'Alat') {
      return orangeStatus;
    }

    if (label == 'Reset') {
      return purpleStatus;
    }

    return adminPurple;
  }

  IconData _filterIcon(String label) {
    if (label == 'Anggota') {
      return Icons.person_add_alt_1_outlined;
    }

    if (label == 'Pupuk') {
      return Icons.inventory_2_outlined;
    }

    if (label == 'Alat') {
      return Icons
          .precision_manufacturing_outlined;
    }

    if (label == 'Reset') {
      return Icons.lock_reset_outlined;
    }

    return Icons.grid_view_rounded;
  }

  Widget _informationBanner(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: softPurple.withValues(
          alpha: 0.93,
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: adminPurple.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              color: adminPurple,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              total == 0
                  ? 'Belum ada data pada kategori $_selectedFilter.'
                  : '$total aktivitas ditemukan. Tekan salah satu kartu untuk melihat detail lengkap.',
              style: const TextStyle(
                color: textGrey,
                fontSize: 10.4,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyContent(
    Map<String, List<_RiwayatAdminItem>>
        groupedItems,
  ) {
    if (groupedItems.isEmpty) {
      return _emptyState();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: groupedItems.entries.map(
        (entry) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              _monthHeader(entry.key),
              const SizedBox(height: 8),
              ...entry.value.map(
                _historyCard,
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ).toList(),
    );
  }

  Widget _monthHeader(String month) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2,
        6,
        2,
        2,
      ),
      child: Row(
        children: [
          Container(
            height: 27,
            width: 5,
            decoration: BoxDecoration(
              color: adminPurple,
              borderRadius:
                  BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              month,
              style: const TextStyle(
                color: textDark,
                fontSize: 13.3,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(
            Icons.calendar_month_outlined,
            color: textSoft,
            size: 17,
          ),
        ],
      ),
    );
  }

  Widget _historyCard(
    _RiwayatAdminItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: _cardDecoration(
        radius: 19,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(19),
        child: InkWell(
          onTap: () {
            _showDetail(item);
          },
          borderRadius:
              BorderRadius.circular(19),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center,
              children: [
                _dateBadge(
                  item.date,
                  item.color,
                ),
                const SizedBox(width: 10),
                Container(
                  height: 43,
                  width: 43,
                  decoration: BoxDecoration(
                    color: item.color.withValues(
                      alpha: 0.09,
                    ),
                    borderRadius:
                        BorderRadius.circular(14),
                    border: Border.all(
                      color: item.color.withValues(
                        alpha: 0.09,
                      ),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.type,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                color: item.color,
                                fontSize: 9.1,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          _statusBadge(
                            item.status,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 12.9,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 10.1,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            color: textSoft,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(item.date),
                            style: const TextStyle(
                              color: textSoft,
                              fontSize: 9.3,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusDescription(
                                item.status,
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _statusColor(
                                  item.status,
                                ),
                                fontSize: 9.2,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  height: 31,
                  width: 31,
                  decoration: BoxDecoration(
                    color: item.color.withValues(
                      alpha: 0.07,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: item.color,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dateBadge(
    DateTime date,
    Color color,
  ) {
    if (date.millisecondsSinceEpoch <= 0) {
      return Container(
        height: 52,
        width: 43,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.calendar_today_outlined,
          color: color,
          size: 18,
        ),
      );
    }

    return Container(
      height: 52,
      width: 43,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            date.day
                .toString()
                .padLeft(2, '0'),
            style: TextStyle(
              color: color,
              fontSize: 15.5,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _shortMonth(date.month),
            style: TextStyle(
              color: color,
              fontSize: 7.5,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(dynamic status) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 91,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _statusColor(status).withValues(
            alpha: 0.11,
          ),
        ),
      ),
      child: Text(
        _formatStatus(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 7.7,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _detailHeader(
    BuildContext sheetContext,
    _RiwayatAdminItem item,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        10,
        13,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: cardBorder.withValues(
              alpha: 0.85,
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 43,
            height: 5,
            decoration: BoxDecoration(
              color: cardBorder,
              borderRadius:
                  BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  color: item.color.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Riwayat Admin',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.type,
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 10.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: softSlate,
                borderRadius:
                    BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
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

  Widget _detailStatusCard(
    _RiwayatAdminItem item,
  ) {
    final color =
        _statusColor(item.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        17,
        16,
        16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            adminNavy,
            adminIndigo,
            color.withValues(alpha: 0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: adminNavy.withValues(
              alpha: 0.19,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.15,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: Icon(
              _statusIcon(item.status),
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            _formatStatus(item.status),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _statusDescription(item.status),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(
                alpha: 0.82,
              ),
              fontSize: 10.6,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 13),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.11,
              ),
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.13,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.78,
                    ),
                    fontSize: 10.2,
                    height: 1.35,
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

  Widget _detailDataCard(
    List<_AdminDetailItem> details,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        14,
        3,
      ),
      decoration: _cardDecoration(
        radius: 19,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: adminPurple,
                size: 18,
              ),
              SizedBox(width: 7),
              Text(
                'Rincian Aktivitas',
                style: TextStyle(
                  color: textDark,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(
            details.length,
            (index) {
              return _detailRow(
                details[index],
                isLast:
                    index == details.length - 1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    _AdminDetailItem detail, {
    required bool isLast,
  }) {
    return Container(
      padding: EdgeInsets.only(
        bottom: isLast ? 11 : 12,
      ),
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : 12,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: cardBorder.withValues(
                    alpha: 0.80,
                  ),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: adminPurple.withValues(
                alpha: 0.08,
              ),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              detail.icon,
              color: adminPurple,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  detail.label,
                  style: const TextStyle(
                    color: textGrey,
                    fontSize: 9.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail.value,
                  style: TextStyle(
                    color:
                        detail.valueColor ??
                        textDark,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: softPurple,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: adminPurple.withValues(
            alpha: 0.11,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.admin_panel_settings_outlined,
            color: adminPurple,
            size: 19,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Data ini merupakan catatan aktivitas administrasi yang tersimpan pada sistem TaniGo.',
              style: TextStyle(
                color: textGrey,
                fontSize: 10.2,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final color =
        _filterColor(_selectedFilter);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        25,
        22,
        24,
      ),
      decoration: _cardDecoration(
        radius: 22,
      ),
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.09,
              ),
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: color.withValues(
                  alpha: 0.11,
                ),
              ),
            ),
            child: Icon(
              _filterIcon(_selectedFilter),
              color: color,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Riwayat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textDark,
              fontSize: 15.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'Semua'
                ? 'Riwayat anggota, bantuan pupuk, peminjaman alat, dan reset password akan tampil di halaman ini.'
                : 'Belum ada aktivitas pada kategori $_selectedFilter.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.8,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: adminPurple,
        strokeWidth: 2.7,
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 430,
          ),
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(
            radius: 22,
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                color: redStatus,
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'Riwayat Tidak Dapat Dimuat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Periksa koneksi internet lalu buka kembali halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textGrey,
                  fontSize: 10.8,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({
    double radius = 18,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.98,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: cardBorder,
      ),
      boxShadow: [
        BoxShadow(
          color: adminNavy.withValues(
            alpha: 0.055,
          ),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    );
  }
}

class _RiwayatAdminItem {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String type;
  final String category;
  final Map<dynamic, dynamic> rawData;

  const _RiwayatAdminItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.date,
    required this.icon,
    required this.color,
    required this.type,
    required this.category,
    required this.rawData,
  });
}

class _AdminDetailItem {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _AdminDetailItem({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });
}

class _AdminHistoryBackground
    extends StatelessWidget {
  const _AdminHistoryBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final width =
                constraints.maxWidth;

            final height =
                constraints.maxHeight;

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
                        end:
                            Alignment.bottomCenter,
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
                    top:
                        -largeCircle * 0.55,
                    right:
                        -largeCircle * 0.30,
                    child: _AdminHistoryCircle(
                      size: largeCircle,
                      color:
                          const Color(0xff6256A4),
                      alpha: 0.22,
                      borderColor: Colors.white,
                    ),
                  ),
                  Positioned(
                    top:
                        -smallCircle * 0.14,
                    left:
                        -smallCircle * 0.23,
                    child: _AdminHistoryRing(
                      size: smallCircle,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    top: height * 0.27,
                    left:
                        -mediumCircle * 0.57,
                    child: _AdminHistoryCircle(
                      size: mediumCircle,
                      color:
                          const Color(0xff6882A2),
                      alpha: 0.21,
                      borderColor:
                          const Color(0xff6882A2),
                    ),
                  ),
                  Positioned(
                    top: height * 0.48,
                    right:
                        -mediumCircle * 0.62,
                    child: _AdminHistoryCircle(
                      size:
                          mediumCircle * 1.09,
                      color:
                          const Color(0xffE7E0F6),
                      alpha: 0.79,
                      borderColor:
                          const Color(0xff725BB4),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -largeCircle * 0.52,
                    left:
                        -largeCircle * 0.31,
                    child: _AdminHistoryCircle(
                      size: largeCircle,
                      color:
                          const Color(0xffE2E8F2),
                      alpha: 0.84,
                      borderColor:
                          const Color(0xff435987),
                    ),
                  ),
                  Positioned(
                    bottom:
                        -mediumCircle * 0.37,
                    right:
                        -mediumCircle * 0.42,
                    child: _AdminHistoryCircle(
                      size: mediumCircle,
                      color:
                          const Color(0xffE6EDF4),
                      alpha: 0.88,
                      borderColor:
                          const Color(0xff326CA3),
                    ),
                  ),
                  Positioned(
                    top: height * 0.37,
                    right: 18,
                    child: Transform.rotate(
                      angle: -0.42,
                      child: Container(
                        height: 39,
                        width: 103,
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(
                            alpha: 0.27,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            999,
                          ),
                          border: Border.all(
                            color:
                                Colors.white.withValues(
                              alpha: 0.14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom:
                        height * 0.13,
                    left: 18,
                    child: Transform.rotate(
                      angle: 0.40,
                      child: Container(
                        height: 37,
                        width: 98,
                        decoration: BoxDecoration(
                          color:
                              Colors.white.withValues(
                            alpha: 0.28,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            999,
                          ),
                          border: Border.all(
                            color:
                                const Color(
                                  0xff6256A4,
                                ).withValues(
                              alpha: 0.07,
                            ),
                          ),
                        ),
                      ),
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

class _AdminHistoryCircle
    extends StatelessWidget {
  final double size;
  final Color color;
  final double alpha;
  final Color borderColor;

  const _AdminHistoryCircle({
    required this.size,
    required this.color,
    required this.alpha,
    required this.borderColor,
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
        border: Border.all(
          color: borderColor.withValues(
            alpha: 0.08,
          ),
          width: 2,
        ),
      ),
    );
  }
}

class _AdminHistoryRing
    extends StatelessWidget {
  final double size;
  final Color color;

  const _AdminHistoryRing({
    required this.size,
    required this.color,
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
          color: color.withValues(
            alpha: 0.12,
          ),
          width: 2,
        ),
      ),
    );
  }
}